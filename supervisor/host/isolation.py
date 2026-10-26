"""Linux worker boundary. No unsandboxed fallback exists.

The receiver must supply a delegated cgroup-v2 directory. A namespace probe alone
is insufficient: descendant termination and aggregate resource accounting need
that delegated cgroup as well.
"""
from __future__ import annotations
import dataclasses,hashlib,json,os,selectors,shutil,subprocess,tempfile,time,uuid,threading
from pathlib import Path

class IsolationUnavailable(RuntimeError): pass

@dataclasses.dataclass(frozen=True)
class Allocation:
    wall_seconds: float=5
    cpu_seconds: float=2
    memory_bytes: int=268435456
    pids: int=16
    output_bytes: int=65536
    def validate(self):
        if not (0<self.wall_seconds<=3600 and 0<self.cpu_seconds<=3600 and
                16777216<=self.memory_bytes<=8589934592 and 1<=self.pids<=128 and 1<=self.output_bytes<=1048576):
            raise ValueError('invalid receiver resource allocation')

class WorkerBoundary:
    def __init__(self,delegated_cgroup: Path):
        self.base=Path(delegated_cgroup).resolve();self.bwrap=shutil.which('bwrap')
        if not self.base.is_relative_to(Path('/sys/fs/cgroup')):
            raise IsolationUnavailable('a delegated cgroup-v2 directory is required')
    def _namespace_command(self,workspace: Path|None,argv: list[str],snapshot_file: Path|None=None):
        if not self.bwrap: raise IsolationUnavailable('bwrap is unavailable')
        cmd=[self.bwrap,'--unshare-all','--die-with-parent','--new-session','--cap-drop','ALL','--clearenv',
             '--setenv','PATH','/usr/bin:/bin','--ro-bind','/usr','/usr']
        for p in ('/bin','/lib','/lib64'):
            if Path(p).exists(): cmd+=['--ro-bind',p,p]
        cmd+=['--proc','/proc','--dev','/dev','--tmpfs','/tmp']
        if workspace is not None:
            cmd+=['--bind',str(workspace),'/work','--chdir','/work']
            if snapshot_file is not None:cmd+=['--ro-bind',str(snapshot_file),'/work/snapshot.bin']
        return cmd+['--']+argv
    def _new_cgroup(self,a: Allocation):
        cg=self.base/('bendloop-'+uuid.uuid4().hex)
        try:
            cg.mkdir()
            for name,value in [('memory.max',str(a.memory_bytes)),('memory.swap.max','0'),('pids.max',str(a.pids)),('cpu.max','100000 100000')]:
                (cg/name).write_text(value)
            if not (cg/'cgroup.kill').is_file(): raise IsolationUnavailable('atomic cgroup termination unavailable')
            return cg
        except Exception as e:
            try:cg.rmdir()
            except OSError:pass
            raise IsolationUnavailable('cgroup delegation/resource controls unavailable: '+str(e)) from e
    def probe(self):
        reasons=[];a=Allocation();cg=None;process=None
        if threading.active_count()!=1:
            return {'available':False,'reasons':['worker launch requires a dedicated single-threaded launcher process'],
                    'scope':'fail closed before fork; do not use Python pre-exec hooks in a threaded host'}
        try:
            cg=self._new_cgroup(a)
        except IsolationUnavailable as e:reasons.append(str(e))
        if cg is not None:
            try:
                def attach(): (cg/'cgroup.procs').write_text(str(os.getpid()))
                process=subprocess.Popen(self._namespace_command(None,['/bin/true']),stdout=subprocess.PIPE,stderr=subprocess.PIPE,
                    preexec_fn=attach,close_fds=True,env={'PATH':'/usr/bin:/bin'})
                stdout,stderr=process.communicate(timeout=5)
                if process.returncode:reasons.append('namespace probe: '+stderr.decode(errors='replace')[:2048].strip())
            except (OSError,subprocess.TimeoutExpired,IsolationUnavailable,subprocess.SubprocessError) as e:
                reasons.append('namespace probe: '+str(e))
            finally:
                self._kill(cg)
                if process is not None:
                    process.wait(timeout=5)
                    for stream in (process.stdout,process.stderr):stream.close()
                cg.rmdir()
        return {'available':not reasons,'reasons':reasons,'bwrap':self.bwrap,
                'bwrap_sha256':hashlib.sha256(Path(self.bwrap).read_bytes()).hexdigest() if self.bwrap else None,
                'cgroup':str(self.base),'namespace_probe':'performed within bounded cgroup' if cg is not None else 'not attempted without required cgroup',
                'scope':'host capability observation, not a proof of the Linux boundary'}
    @staticmethod
    def _cpu(cg: Path):
        fields=dict(line.split() for line in (cg/'cpu.stat').read_text().splitlines())
        return int(fields['usage_usec'])/1e6
    @staticmethod
    def _kill(cg: Path):
        (cg/'cgroup.kill').write_text('1')
        deadline=time.monotonic()+5
        while time.monotonic()<deadline:
            fields=dict(line.split() for line in (cg/'cgroup.events').read_text().splitlines())
            if fields.get('populated')=='0':return
            time.sleep(.01)
        raise IsolationUnavailable('descendants did not terminate; cgroup retained for operator recovery')
    def run(self,argv: list[str],snapshot: bytes,a: Allocation=Allocation()):
        """argv is trusted launcher configuration, never worker-supplied JSON.

        Only snapshot.bin and a private writable workspace are visible. The
        worker gets no inherited credentials, authority directory or network.
        stdout/stderr are bounded arbitrary bytes; neither is an effect channel.
        """
        operation_start=time.monotonic();a.validate()
        status=self.probe()
        if not status['available']:raise IsolationUnavailable(json.dumps(status,sort_keys=True))
        if type(snapshot) is not bytes or len(snapshot)>65536:raise ValueError('snapshot limit')
        cg=self._new_cgroup(a);process=None;reason='completed';output={'stdout':bytearray(),'stderr':bytearray()}
        try:
            with tempfile.TemporaryDirectory(prefix='bendloop-worker-') as work:
                workspace=Path(work)/'workspace';workspace.mkdir();(workspace/'snapshot.bin').touch()
                snapshot_file=Path(work)/'snapshot.bin';snapshot_file.write_bytes(snapshot)
                def attach():
                    # This runs before exec: worker code never executes outside
                    # the bounded cgroup. Any failure aborts Popen, fail closed.
                    (cg/'cgroup.procs').write_text(str(os.getpid()))
                process=subprocess.Popen(self._namespace_command(workspace,argv,snapshot_file),stdout=subprocess.PIPE,stderr=subprocess.PIPE,
                    stdin=subprocess.DEVNULL,close_fds=True,env={'PATH':'/usr/bin:/bin'},preexec_fn=attach)
                selector=selectors.DefaultSelector()
                for name,stream in [('stdout',process.stdout),('stderr',process.stderr)]:
                    os.set_blocking(stream.fileno(),False);selector.register(stream,selectors.EVENT_READ,name)
                start=time.monotonic()
                try:
                    while selector.get_map() or process.poll() is None:
                        if time.monotonic()-start>=a.wall_seconds:reason='wall_exhausted';break
                        if self._cpu(cg)>=a.cpu_seconds:reason='cpu_exhausted';break
                        for key,_ in selector.select(.02):
                            chunk=os.read(key.fileobj.fileno(),4096)
                            if not chunk:selector.unregister(key.fileobj);continue
                            remaining=a.output_bytes-sum(map(len,output.values()))
                            output[key.data].extend(chunk[:remaining])
                            if len(chunk)>remaining:reason='output_exhausted';break
                        if reason!='completed':break
                finally:selector.close()
                self._kill(cg);process.wait(timeout=5)
                for stream in (process.stdout,process.stderr):stream.close()
                return {'status':reason,'returncode':process.returncode,'stdout':bytes(output['stdout']),
                        'stderr':bytes(output['stderr']),'cpu_seconds':self._cpu(cg),'worker_wall_seconds':time.monotonic()-start,
                        'operation_wall_seconds':time.monotonic()-operation_start,
                        'limits':'CPU/wall are sampled kill thresholds with scheduling/termination overshoot; memory/pids use cgroup limits'}
        finally:
            if process is not None:
                self._kill(cg)
                if process.poll() is None:process.wait(timeout=5)
            cg.rmdir()
