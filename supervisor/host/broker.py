"""Receiver-owned IO boundary. Acceptance is exclusively the native Bend port's job.

Worker ingress is only a bounded JSON token array, never an event/effect/contract.
The callback is a trusted supervisor integration point, not a worker API.
"""
from __future__ import annotations
import dataclasses,fcntl,hashlib,json,os,stat,time,threading
from contextlib import contextmanager
from pathlib import Path
from typing import Callable,Mapping

class BoundaryError(RuntimeError): pass


def canonical_tokens(raw: bytes) -> bytes:
    if type(raw) is not bytes or len(raw)>65536:
        raise BoundaryError('artifact byte limit or type')
    try: value=json.loads(raw)
    except (ValueError,UnicodeError,RecursionError) as e: raise BoundaryError('invalid artifact JSON') from e
    if type(value) is not list or not 1<=len(value)<=63 or any(type(t) is not int or not 0<=t<=20 for t in value):
        raise BoundaryError('expected bounded integer token array')
    # AST shape is checked by the receiver's Bend task checker, not by Python.
    return json.dumps(value,separators=(',',':')).encode()


@dataclasses.dataclass(frozen=True)
class Frozen:
    task: int
    epoch: int
    serial: int
    content: bytes


class Broker:
    """Single supervisor-owned directory and one fixed publication destination.

    native_port(context, frozen) runs the receiver-owned Bend supervisor and
    returns its effect JSON. This Python module never decides admissibility or
    quality. Callers able to replace native_port already control the supervisor.
    """
    def __init__(self,root: Path,native_port: Callable[[Mapping,Frozen|None],Mapping]):
        self.root=Path(root);self.root.mkdir(mode=0o700,parents=False,exist_ok=True)
        st=self.root.lstat()
        if not stat.S_ISDIR(st.st_mode) or st.st_uid!=os.getuid() or st.st_mode&0o077:
            raise BoundaryError('broker root must be an owned private directory')
        self.fd=os.open(self.root,os.O_RDONLY|os.O_DIRECTORY|os.O_NOFOLLOW)
        self.lockfd=os.open('lock',os.O_CREAT|os.O_RDWR|os.O_NOFOLLOW,0o600,dir_fd=self.fd)
        self._native_port=native_port;self._thread_lock=threading.RLock()
    def close(self):
        os.close(self.lockfd);os.close(self.fd)
    @contextmanager
    def _locked(self):
        with self._thread_lock:
            fcntl.flock(self.lockfd,fcntl.LOCK_EX)
            try: yield
            finally: fcntl.flock(self.lockfd,fcntl.LOCK_UN)
    def _read(self,name: str) -> bytes|None:
        try: fd=os.open(name,os.O_RDONLY|os.O_NOFOLLOW,dir_fd=self.fd)
        except FileNotFoundError: return None
        with os.fdopen(fd,'rb') as f:
            data=f.read(262145)
        if len(data)>262144: raise BoundaryError('oversized supervisor record')
        return data
    def _json(self,name: str):
        data=self._read(name)
        return None if data is None else json.loads(data)
    def _write(self,name: str,data: bytes):
        tmp=name+'.tmp'
        try: os.unlink(tmp,dir_fd=self.fd)
        except FileNotFoundError: pass
        fd=os.open(tmp,os.O_CREAT|os.O_EXCL|os.O_WRONLY|os.O_NOFOLLOW,0o600,dir_fd=self.fd)
        with os.fdopen(fd,'wb') as f:
            f.write(data);f.flush();os.fsync(f.fileno())
        os.replace(tmp,name,src_dir_fd=self.fd,dst_dir_fd=self.fd);os.fsync(self.fd)
    def _write_json(self,name: str,value):
        self._write(name,json.dumps(value,sort_keys=True,separators=(',',':')).encode())
    def _unlink(self,name: str):
        try: os.unlink(name,dir_fd=self.fd)
        except FileNotFoundError: pass
    @staticmethod
    def _boot(): return Path('/proc/sys/kernel/random/boot_id').read_text().strip()
    def issue(self,task: int,epoch: int,allowance: int,seconds: float,incumbent: bytes|None=None):
        """Trusted control call only; never dispatched from worker JSON."""
        if any(type(v) is not int or v<0 for v in (task,epoch,allowance)) or allowance>128 or not 0<seconds<=3600:
            raise BoundaryError('invalid host allocation')
        fallback=canonical_tokens(incumbent) if incumbent is not None else None
        with self._locked():
            old=self._json('context.json')
            if old and epoch<=old['epoch']:
                raise BoundaryError('contract generation must advance')
            context={'task':task,'epoch':epoch,'allowance':allowance,'received':0,'serial':0,
                     'deadline_ns':time.monotonic_ns()+int(seconds*1e9),'boot':self._boot(),
                     'last_effect':-1,'terminal':False,'snapshots':[]}
            if fallback is not None:
                context['snapshots'].append({'serial':0,'artifact':json.loads(fallback),'source_sha256':hashlib.sha256(incumbent).hexdigest()})
            self._write_json('context.json',context)
            # Once the new governing context is durable, old delivery metadata
            # cannot be authoritative even if a crash interrupts its retirement.
            self._unlink('result.bin');self._unlink('delivered.json');self._unlink('journal.json');self._unlink('pending.bin')
            os.fsync(self.fd)
    def submit(self,raw: bytes) -> Frozen:
        """Untrusted ingress. Even rejected payloads consume an ingress allowance."""
        with self._locked():
            c=self._json('context.json')
            if not c or c['terminal'] or c['boot']!=self._boot() or time.monotonic_ns()>=c['deadline_ns'] or c['received']>=c['allowance']:
                raise BoundaryError('expired or exhausted receiver allocation')
            c['received']+=1;self._write_json('context.json',c)
            content=canonical_tokens(raw)
            c['serial']+=1
            snap={'serial':c['serial'],'artifact':json.loads(content),'source_sha256':hashlib.sha256(raw).hexdigest()}
            c['snapshots'].append(snap);self._write_json('context.json',c)
            return Frozen(c['task'],c['epoch'],c['serial'],content)
    def _snapshot(self,c,frozen):
        if not c or c['boot']!=self._boot() or (frozen.task,frozen.epoch)!=(c['task'],c['epoch']):
            raise BoundaryError('stale snapshot')
        matches=[v for v in c['snapshots'] if v['serial']==frozen.serial]
        if len(matches)!=1 or canonical_tokens(json.dumps(matches[0]['artifact']).encode())!=frozen.content:
            raise BoundaryError('snapshot was not frozen by this receiver')
    def _publish(self,c,frozen,decision,terminal):
        if not isinstance(decision,Mapping) or decision.get('kind')!='publish':return False
        if set(decision)!={'kind','task','epoch','artifact','sequence'} or any(type(decision[v]) is not int for v in ('task','epoch','sequence')):
            raise BoundaryError('invalid native effect protocol')
        actual=canonical_tokens(json.dumps(decision['artifact']).encode())
        selected=next((v for v in c['snapshots'] if canonical_tokens(json.dumps(v['artifact']).encode())==actual),None)
        if (decision['task'],decision['epoch'])!=(c['task'],c['epoch']) or selected is None or decision['sequence']<=c['last_effect']:
            raise BoundaryError('native effect binding or replay failure')
        record={'task':c['task'],'epoch':c['epoch'],'sequence':decision['sequence'],
                'serial':selected['serial'],'terminal':terminal,'artifact':json.loads(actual),'sha256':hashlib.sha256(actual).hexdigest()}
        self._write('pending.bin',actual);self._write_json('journal.json',{'phase':'prepared',**record})
        os.replace('pending.bin','result.bin',src_dir_fd=self.fd,dst_dir_fd=self.fd);os.fsync(self.fd)
        self._write_json('delivered.json',record)
        c['last_effect']=decision['sequence'];c['terminal']=terminal;self._write_json('context.json',c)
        self._write_json('journal.json',{'phase':'complete',**record})
        return True
    def commit(self,frozen: Frozen) -> bool:
        """Recheck in Bend under the same lock as contract replacement.

        Only this receiver-controlled method consumes native effects. The worker
        API is submit(bytes); it cannot select an event or this method.
        """
        with self._locked():
            c=self._json('context.json');self._snapshot(c,frozen)
            if c['terminal'] or time.monotonic_ns()>=c['deadline_ns']:
                raise BoundaryError('worker allocation expired or completed')
            query=json.loads(json.dumps(c));query['phase']='worker'
            delivered=self._json('delivered.json')
            query['incumbent']=delivered['artifact'] if delivered and (delivered['task'],delivered['epoch'])==(c['task'],c['epoch']) else next((v['artifact'] for v in c['snapshots'] if v['serial']==0),None)
            decision=self._native_port(query,frozen)
            if time.monotonic_ns()>=c['deadline_ns']:
                raise BoundaryError('worker allocation expired during decision')
            return self._publish(c,frozen,decision,False)
    def finish(self) -> bool:
        """Receiver-only deadline action: native qualified fallback or failure.

        An incumbent may be frozen at issue or already acknowledged. Its bytes
        are supplied to Bend for a current-contract decision, not trusted here.
        """
        with self._locked():
            c=self._json('context.json')
            if not c or c['boot']!=self._boot():raise BoundaryError('missing current allocation')
            if c['terminal']:return True
            if time.monotonic_ns()<c['deadline_ns']:raise BoundaryError('allocation has not expired')
            delivered=self._json('delivered.json')
            saved=delivered if delivered and (delivered['task'],delivered['epoch'])==(c['task'],c['epoch']) else next((v for v in c['snapshots'] if v['serial']==0),None)
            frozen=Frozen(c['task'],c['epoch'],saved['serial'],canonical_tokens(json.dumps(saved['artifact']).encode())) if saved else None
            query=json.loads(json.dumps(c));query['phase']='expired';query['incumbent']=json.loads(frozen.content) if frozen else None
            decision=self._native_port(query,frozen)
            if isinstance(decision,Mapping) and decision.get('kind')=='failure':
                if set(decision)!={'kind','task','epoch','sequence'} or any(type(decision[v]) is not int for v in ('task','epoch','sequence')) or (decision['task'],decision['epoch'])!=(c['task'],c['epoch']) or decision['sequence']<=c['last_effect']:
                    raise BoundaryError('invalid native terminal effect')
                self._unlink('result.bin');self._unlink('delivered.json')
                c['last_effect']=decision['sequence'];c['terminal']=True;self._write_json('context.json',c)
                self._write_json('journal.json',dict(decision))
                return True
            if frozen is None:raise BoundaryError('native fallback did not bind a frozen artifact')
            self._snapshot(c,frozen)
            if not self._publish(c,frozen,decision,True):raise BoundaryError('native supervisor supplied no terminal outcome')
            return True
    def read_delivered(self) -> bytes|None:
        """The authoritative reader. Raw files are not an authority API."""
        with self._locked():
            c=self._json('context.json');d=self._json('delivered.json');data=self._read('result.bin')
            if not c or not d or data is None or (c['task'],c['epoch'])!=(d['task'],d['epoch']): return None
            if data!=canonical_tokens(json.dumps(d['artifact']).encode()): return None
            return data
    def recover(self):
        """Discard incomplete publication, without replaying an external effect.

        This broker supports only an atomic local file. If delivered.json already
        binds the current bytes, the completed publication is retained; otherwise
        no unacknowledged bytes are exposed by read_delivered(). Services with
        non-idempotent effects require their own transactional recovery protocol.
        """
        with self._locked():
            self._unlink('pending.bin')
            c=self._json('context.json');d=self._json('delivered.json');data=self._read('result.bin')
            if c and c['boot']!=self._boot():
                # A reboot does not grant new worker time or credit. Restore only
                # the trusted terminal path; Bend rechecks the fallback below.
                c['boot']=self._boot();c['deadline_ns']=0;c['received']=c['allowance'];self._write_json('context.json',c)
            valid=bool(c and d and (c['task'],c['epoch'])==(d['task'],d['epoch']))
            if valid:
                # The acknowledged record contains the exact prior bytes. If a
                # crash interrupted replacement, restore that qualified incumbent.
                expected=canonical_tokens(json.dumps(d['artifact']).encode())
                if data!=expected:self._write('result.bin',expected)
                if c['last_effect']<d['sequence']:
                    c['last_effect']=d['sequence'];c['terminal']=d.get('terminal',False);self._write_json('context.json',c)
            else:self._unlink('result.bin');self._unlink('delivered.json')
            self._write_json('journal.json',{'phase':'recovered','retained_delivery':valid})
