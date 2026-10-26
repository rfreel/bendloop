"""Pinned native Bend adapter. Worker bytes never configure this adapter."""
from __future__ import annotations
import copy,hashlib,json,os,selectors,shutil,signal,subprocess,time
from pathlib import Path
try:
    from .broker import BoundaryError,Frozen
except ImportError:
    from broker import BoundaryError,Frozen

class BendPort:
    def __init__(self,executable: Path,sha256: str,contracts: dict,timeout_seconds: float=10):
        self.executable=Path(executable).resolve();self.sha256=sha256
        self._contracts=copy.deepcopy(contracts);self.timeout=timeout_seconds
        if not 0<timeout_seconds<=60:raise ValueError('invalid receiver checker timeout')
    def _invoke(self,request: dict,command: str="decide"):
        if hashlib.sha256(self.executable.read_bytes()).hexdigest()!=self.sha256:
            raise BoundaryError('receiver Bend executable identity changed')
        data=json.dumps(request,separators=(',',':')).encode()
        if len(data)>65536:raise BoundaryError('native request byte limit')
        prlimit=shutil.which('prlimit')
        if prlimit is None:raise BoundaryError('receiver resource-limit launcher unavailable')
        process=subprocess.Popen([prlimit,'--as='+str(16*1024**3),'--fsize=1048576','--',str(self.executable),command,'+RTS','--threads','1','--gpu','off','-RTS'],
            stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,start_new_session=True,close_fds=True,
            env={'PATH':'/usr/bin:/bin'})
        chunks={'stdout':bytearray(),'stderr':bytearray()};selector=selectors.DefaultSelector();start=time.monotonic()
        try:
            os.set_blocking(process.stdin.fileno(),False);selector.register(process.stdin,selectors.EVENT_WRITE,'stdin');cursor=0
            for name,stream in [('stdout',process.stdout),('stderr',process.stderr)]:
                os.set_blocking(stream.fileno(),False);selector.register(stream,selectors.EVENT_READ,name)
            while selector.get_map() or process.poll() is None:
                if time.monotonic()-start>=self.timeout:raise BoundaryError('receiver native timeout')
                for key,_ in selector.select(.02):
                    if key.data=='stdin':
                        cursor+=os.write(key.fileobj.fileno(),data[cursor:])
                        if cursor==len(data):selector.unregister(key.fileobj);key.fileobj.close()
                        continue
                    chunk=os.read(key.fileobj.fileno(),4096)
                    if not chunk:selector.unregister(key.fileobj);continue
                    chunks[key.data].extend(chunk)
                    if sum(map(len,chunks.values()))>65536:raise BoundaryError('receiver native output limit')
            if process.wait(timeout=1)!=0:
                raise BoundaryError('receiver native failure: '+bytes(chunks['stderr']).decode(errors='replace')[:1024])
            try:result=json.loads(bytes(chunks['stdout']))
            except (ValueError,UnicodeError,RecursionError) as e:raise BoundaryError('receiver native invalid JSON') from e
            if type(result) is not dict:raise BoundaryError('receiver native result must be an object')
            return result
        finally:
            selector.close()
            # The compiled receiver is trusted pure Bend, not hostile code. This
            # process-group timeout is not advertised as the worker sandbox.
            try:os.killpg(process.pid,signal.SIGKILL)
            except ProcessLookupError:pass
            process.wait(timeout=5)
            for stream in (process.stdin,process.stdout,process.stderr):stream.close()
    def _request(self,context: dict,frozen: Frozen|None):
        try:contract=copy.deepcopy(self._contracts[(context['task'],context['epoch'])])
        except KeyError as e:raise BoundaryError('no receiver-owned contract for this generation') from e
        allowed={'evaluator','permission','reference','allowed_ops','max_nodes','fallback','budget'}
        if set(contract)-allowed or not {'evaluator','permission','reference','allowed_ops','max_nodes','fallback'}<=set(contract):
            raise BoundaryError('invalid receiver contract configuration')
        contract.setdefault('budget',5)
        # Only the receiver registry can supply a fallback, including explicit
        # absence. A configured default must not resurrect an unregistered one.
        contract['fallback']=context.get('incumbent')
        phase='expired' if context['phase']=='expired' else 'active'
        request={**contract,'task':context['task'],'epoch':context['epoch'],
                 'candidate':None if phase=='expired' or frozen is None else json.loads(frozen.content),
                 'phase':phase,'sequence':context['last_effect']+1}
        return request
    def __call__(self,context: dict,frozen: Frozen|None):
        return self._invoke(self._request(context,frozen))
    def inspect(self,context: dict,frozen: Frozen|None):
        """Receiver-only diagnostic command; never supplies publication authority."""
        return self._invoke(self._request(context,frozen),command="inspect")
