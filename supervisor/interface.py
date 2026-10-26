"""One durable task over the real receiver-owned Bend/Broker path.

This is a finite Python IO facade, not a new Bend projector/refinement proof.
REQUIREMENT_STATUS below states the implemented slice and exact remaining work.
This is a controlled driving-agent integration API, not a hostile public RPC.
Metadata actions are not a global physical resource envelope; runtime worker
ingress remains Broker.submit only. Do not route worker control messages here.
Only observe/act/await_events are the agent surface. Underscored receiver methods
are host integration points; never deserialize worker messages into such calls.
"""
from __future__ import annotations
import copy,fcntl,hashlib,hmac,json,os,secrets,stat,threading,time,uuid
from contextlib import contextmanager
from pathlib import Path
from typing import Mapping
try:
    from .host.broker import Broker,Frozen,BoundaryError,canonical_tokens
    from .host.native import BendPort
except ImportError:
    from host.broker import Broker,Frozen,BoundaryError,canonical_tokens
    from host.native import BendPort

SCHEMA='bendloop-work-view-v1'
REQUIREMENT_STATUS={
 'R01':'Partial: receiver intake preserves goal/declaration. English-to-contract fidelity and added-obligation review remain manual.',
 'R02':'Finite slice: HMAC-chained receiver journal reconstructs this task and checkpoints. No unbounded replay/refinement theorem.',
 'R03':'Finite slice: claims retain evidence identity, kind, exact scope and dependencies. General projector proof pending.',
 'R04':'Finite slice: four typed actions share host preconditions between view and dispatcher. General adapter action algebra pending.',
 'R05':'Finite slice: host-defined contract/checker/incumbent/exact-candidate read sets; unrelated notes do not stale actions. General revision/dependency graph pending.',
 'R06':'Concrete adapters only: actual pinned Bend decision controls Broker publication; worker claims are never approval. Independent external evaluator service pending.',
 'R07':'Finite fixed-file scope: content-bound idempotency, durable intents and Broker fencing. External-service leases/exactly-once transactions pending.',
 'R08':'Partial: ingress/evaluation ceilings serialized; metadata actions are not a hostile-RPC/global journal envelope. Measured time excludes final receipt fsync. Aggregate physical accounting/scheduler pending.',
 'R09':'Finite slice: reopen/checkpoint and explicit local-effect reconciliation work without chat. General jobs/leases/provider reconciliation pending.',
 'R10':'Pending: no cross-task reusable-capability index or held-out reuse evaluation.',
 'R11':'Finite slice: notes/retrieval-like observations cannot mutate contract or authorize acceptance. General retrieval subsystem pending.',
 'R12':'Finite slice: Completed/Rejected/Inconclusive/Cancelled/EffectUnknown preserve retained work and recovery. Asynchronous Pending jobs and broad causal slicing pending.',
 'R13':'Concrete checker ordering only; external comparative runtime evidence, frontier portfolio and selection-aware uncertainty pending.',
 'R14':'Partial: one request, status and recovery need no repeated permissions. Human burden/baseline trials pending.',
 'R15':'Partial: bounded integer-artifact native wire shared by Expr and sorting adapters. Analysis/document/design positive-negative-inconclusive journeys pending.',
 'R16':'Bend reducer proofs/native Broker integration remain separately scoped. This Python facade/projector/journal is tested, not kernel proved; model refinement pending.',
 'R17':'Partial: receiver deadline fallback/failure action is exposed. Fair host scheduler and actual hostile-worker execution remain prerequisites; isolation unavailable here.',
 'R18':'Partial: private journal key/contracts/fallback are omitted from worker view; no private release-answer fixture/service or exhaustive disclosure proof.'}

class InterfaceError(RuntimeError): pass

def _wire(v): return json.dumps(v,sort_keys=True,separators=(',',':'),ensure_ascii=True,allow_nan=False).encode()
def _sha(v):return hashlib.sha256(_wire(v)).hexdigest()

def _file_bytes(fd,name,limit=16*1024*1024):
    f=os.open(name,os.O_RDONLY|os.O_NOFOLLOW,dir_fd=fd)
    with os.fdopen(f,'rb') as stream:data=stream.read(limit+1)
    if len(data)>limit:raise InterfaceError('RECORD_TOO_LARGE')
    return data

class Task:
    """Receiver-owned authenticated task. Do not run worker code in this process."""
    @classmethod
    def create(cls,root: Path,goal: str,receiver_contract: Mapping,executable: Path,expected_sha256: str,
               ingress_allowance: int=16,seconds: float=60,adapter: str='four-bit-expression',declaration: Mapping|None=None):
        root=Path(root);root.mkdir(mode=0o700,parents=False,exist_ok=False)
        fd=os.open(root,os.O_RDONLY|os.O_DIRECTORY|os.O_NOFOLLOW)
        try:
            key=os.open('journal.key',os.O_CREAT|os.O_EXCL|os.O_WRONLY|os.O_NOFOLLOW,0o600,dir_fd=fd)
            with os.fdopen(key,'wb') as f:f.write(secrets.token_bytes(32));f.flush();os.fsync(f.fileno())
            j=os.open('journal.jsonl',os.O_CREAT|os.O_EXCL|os.O_WRONLY|os.O_NOFOLLOW,0o600,dir_fd=fd);os.close(j);os.fsync(fd)
        finally:os.close(fd)
        obj=cls(root,initializing=True)
        contract=copy.deepcopy(dict(receiver_contract))
        if not isinstance(goal,str) or not goal or len(goal)>4096:raise InterfaceError('INVALID_GOAL')
        if set(contract)-{'task','epoch','evaluator','permission','reference','allowed_ops','max_nodes','fallback','budget'}:
            raise InterfaceError('UNKNOWN_RECEIVER_CONTRACT_FIELD')
        if not {'task','epoch','evaluator','permission','reference','allowed_ops','max_nodes'}<=set(contract):raise InterfaceError('MISSING_RECEIVER_CONTRACT_FIELD')
        contract.setdefault('fallback',None);contract.setdefault('budget',5)
        initial={'task_id':uuid.uuid4().hex,'goal':goal,'contract':contract,'contract_id':_sha(contract),
                 'checker_sha256':expected_sha256,'executable':str(Path(executable).resolve()),'adapter':adapter,
                 'declaration':copy.deepcopy(dict(declaration or {})),'ingress_allowance':ingress_allowance,
                 'evaluation_allowance':ingress_allowance+1,'seconds':seconds}
        obj._append('issued',initial)
        obj._connect()
        incumbent=None if contract['fallback'] is None else canonical_tokens(_wire(contract['fallback']))
        obj.broker.issue(contract['task'],contract['epoch'],ingress_allowance,seconds,incumbent=incumbent)
        return obj
    @classmethod
    def reopen(cls,root: Path):
        obj=cls(root);obj._connect()
        with obj._locked():
            obj._load()
            for key,intent in list(obj.state['pending'].items()):
                obj._receipt(key,intent,'EffectUnknown','ACKNOWLEDGEMENT_MISSING',
                    'Inspect local broker state with resume before any new publication; this action is not retried.',
                    {'dispatch_wall_ns':None,'scope':'interrupted action; cost is not assumed zero'},[],intent['action'].get('candidate_id'))
        return obj
    def __init__(self,root: Path,initializing=False):
        self.root=Path(root);st=self.root.lstat()
        if not stat.S_ISDIR(st.st_mode) or st.st_uid!=os.getuid() or st.st_mode&0o077:raise InterfaceError('PRIVATE_RECEIVER_DIRECTORY_REQUIRED')
        self.fd=os.open(self.root,os.O_RDONLY|os.O_DIRECTORY|os.O_NOFOLLOW)
        self.lockfd=os.open('task.lock',os.O_CREAT|os.O_RDWR|os.O_NOFOLLOW,0o600,dir_fd=self.fd)
        self._mutex=threading.RLock();self._condition=threading.Condition(self._mutex);self.broker=None
        keyfd=os.open('journal.key',os.O_RDONLY|os.O_NOFOLLOW,dir_fd=self.fd);kst=os.fstat(keyfd)
        with os.fdopen(keyfd,'rb') as f:self._key=f.read(33)
        if kst.st_uid!=os.getuid() or kst.st_mode&0o077 or len(self._key)!=32:raise InterfaceError('PRIVATE_JOURNAL_KEY_REQUIRED')
        self.events=[];self.state={};self._load(initializing)
    def close(self):
        if self.broker:self.broker.close()
        os.close(self.lockfd);os.close(self.fd)
    @contextmanager
    def _locked(self):
        with self._mutex:
            fcntl.flock(self.lockfd,fcntl.LOCK_EX)
            try:yield
            finally:fcntl.flock(self.lockfd,fcntl.LOCK_UN)
    def _mac(self,v):return hmac.new(self._key,_wire(v),hashlib.sha256).hexdigest()
    def _replace(self,name,data):
        tmp=name+'.tmp'
        try:os.unlink(tmp,dir_fd=self.fd)
        except FileNotFoundError:pass
        fd=os.open(tmp,os.O_CREAT|os.O_EXCL|os.O_WRONLY|os.O_NOFOLLOW,0o600,dir_fd=self.fd)
        with os.fdopen(fd,'wb') as f:f.write(data);f.flush();os.fsync(f.fileno())
        os.replace(tmp,name,src_dir_fd=self.fd,dst_dir_fd=self.fd);os.fsync(self.fd)
    def _load(self,initializing=False):
        try:head=json.loads(_file_bytes(self.fd,'head.json'))
        except FileNotFoundError:
            if not initializing:raise InterfaceError('AUTHENTICATED_HEAD_MISSING')
            head={'seq':0,'tail':'0'*64};head['auth']=self._mac(head)
        expected={'seq':head.get('seq'),'tail':head.get('tail')}
        if not hmac.compare_digest(str(head.get('auth','')),self._mac(expected)):raise InterfaceError('JOURNAL_HEAD_AUTHENTICATION_FAILED')
        raw=_file_bytes(self.fd,'journal.jsonl');lines=raw.splitlines(keepends=True);events=[];prev='0'*64;length=0
        if type(head['seq']) is not int or head['seq']<0 or len(lines)<head['seq']:raise InterfaceError('JOURNAL_TRUNCATED')
        for line in lines[:head['seq']]:
            try:r=json.loads(line);event=r['event'];mac=r['auth']
            except (ValueError,KeyError,TypeError) as e:raise InterfaceError('JOURNAL_RECORD_INVALID') from e
            if event.get('seq')!=len(events)+1 or event.get('previous')!=prev or event.get('principal')!='receiver' or not hmac.compare_digest(str(mac),self._mac(event)):
                raise InterfaceError('JOURNAL_AUTHENTICATION_FAILED')
            events.append(event);prev=mac;length+=len(line)
        if prev!=head['tail']:raise InterfaceError('JOURNAL_HEAD_MISMATCH')
        # Only the authenticated committed prefix is authoritative. A crash may
        # leave an uncommitted trailing record; never import it as a fact.
        if len(raw)!=length:
            fd=os.open('journal.jsonl',os.O_WRONLY|os.O_NOFOLLOW,dir_fd=self.fd)
            try:os.ftruncate(fd,length);os.fsync(fd)
            finally:os.close(fd)
        self.events=events;self._reduce()
    def _append(self,kind,body):
        previous='0'*64 if not self.events else self._mac(self.events[-1])
        event={'seq':len(self.events)+1,'previous':previous,'principal':'receiver','kind':kind,'body':copy.deepcopy(body)}
        auth=self._mac(event);line=_wire({'event':event,'auth':auth})+b'\n'
        fd=os.open('journal.jsonl',os.O_WRONLY|os.O_APPEND|os.O_NOFOLLOW,dir_fd=self.fd)
        try:
            with os.fdopen(fd,'ab') as f:f.write(line);f.flush();os.fsync(f.fileno())
            head={'seq':event['seq'],'tail':auth};self._replace('head.json',_wire({**head,'auth':self._mac(head)}))
        except Exception:
            # Restore the authenticated committed prefix before any error receipt
            # is appended. A failed head write must not strand an extra record.
            self._load(initializing=not self.events)
            raise
        self.events.append(event);self._reduce()
        with self._condition:self._condition.notify_all()
        return event['seq']
    def _reduce(self):
        s={'artifacts':{},'evidence':{},'claims':{},'pending':{},'receipts':{},'requests':{},'unresolved':{},
           'incumbent':None,'checkpoint':None,'cancelled':None,'evaluations':0}
        for event in self.events:
            b=event['body'];kind=event['kind']
            if kind=='issued':s.update(copy.deepcopy(b))
            elif kind=='intent':
                s['pending'][b['key']]=b;s['requests'][b['key']]=b['request']
                if b.get('reserved') and b['action']['type']=='evaluate_publish':s['evaluations']+=1
            elif kind=='artifact':s['artifacts'][b['id']]=b
            elif kind=='evidence':s['evidence'][b['id']]=b
            elif kind=='claim':s['claims'][b['id']]=b
            elif kind=='receipt':
                s['receipts'][b['idempotency_key']]=b;s['pending'].pop(b['idempotency_key'],None)
                if b['outcome']=='EffectUnknown':s['unresolved'][b['idempotency_key']]=b
            elif kind=='delivered':s['incumbent']=b
            elif kind=='checkpoint':s['checkpoint']=b
            elif kind=='reconciled':
                for key in b['keys']:s['unresolved'].pop(key,None)
            elif kind=='cancelled':s['cancelled']=b
        self.state=s
    def _connect(self):
        s=self.state;c=s['contract']
        native={k:v for k,v in c.items() if k not in ('task','epoch')}
        self.port=BendPort(Path(s['executable']),s['checker_sha256'],{(c['task'],c['epoch']):native})
        self._last_native=None;self._native_request_total=0
        def native_port(context,frozen):
            self._native_request_total+=1
            self._last_native={'task':context['task'],'epoch':context['epoch'],'phase':context['phase'],
                               'candidate':None if frozen is None else json.loads(frozen.content)}
            result=self.port(context,frozen);self._last_native['reply']=copy.deepcopy(result);return result
        self.broker=Broker(self.root/'broker',native_port)
    def _basis(self,visible=None):
        s=self.state
        artifacts=s['artifacts'] if visible is None else {k:s['artifacts'][k] for k in visible}
        return {'contract':s.get('contract_id'),'checker':s.get('checker_sha256'),
                'incumbent':None if s['incumbent'] is None else s['incumbent']['artifact_id'],
                'frozen':{k:v['sha256'] for k,v in artifacts.items()}}
    @staticmethod
    def _reads(action):
        if action['type']=='evaluate_publish':return ('contract','checker','incumbent','frozen')
        return ('contract','checker')
    def _request(self,action,basis):
        reads=self._reads(action);selected={k:basis.get(k) for k in reads if k!='frozen'}
        if 'frozen' in reads:
            cid=action.get('candidate_id');selected['frozen']={} if cid is None else {cid:basis.get('frozen',{}).get(cid)}
        return {'action':copy.deepcopy(action),'basis':selected}
    def _precondition(self,action):
        s=self.state;t=action['type']
        if s['cancelled'] and t not in ('checkpoint','resume'):return 'TASK_CANCELLED'
        if t=='submit_candidate':
            c=self.broker._json('context.json')
            if c['terminal'] or c['boot']!=self.broker._boot() or time.monotonic_ns()>=c['deadline_ns'] or c['received']>=c['allowance']:return 'INGRESS_EXPIRED_OR_EXHAUSTED'
        if t=='evaluate_publish':
            if s['unresolved'] or s['pending']:return 'UNRESOLVED_EFFECT_REQUIRES_RESUME'
            if s['evaluations']>=s['evaluation_allowance']:return 'EVALUATION_ALLOWANCE_EXHAUSTED'
            cid=action.get('candidate_id');c=self.broker._json('context.json')
            if cid is not None and cid not in s['artifacts']:return 'FROZEN_CANDIDATE_REQUIRED'
            if cid is None and time.monotonic_ns()<c['deadline_ns']:return 'DEADLINE_NOT_REACHED'
            if cid is not None and (c['terminal'] or time.monotonic_ns()>=c['deadline_ns']):return 'CANDIDATE_LEASE_EXPIRED'
        return None
    def _sorting(self):return self.state.get('adapter')=='sort8'
    def _display(self,value):
        if self._sorting() and len(value)==24:
            return {'codec':'flat-triples-date-id-value-v1','canonical_sha256':hashlib.sha256(_wire(value)).hexdigest(),
                    'records':[{'date':value[i],'id':value[i+1],'value':value[i+2]} for i in range(0,24,3)]}
        return {'codec':'bounded-integer-array-v1','value':copy.deepcopy(value),'canonical_sha256':hashlib.sha256(_wire(value)).hexdigest()}
    def _descriptor(self,kind):
        samples={'submit_candidate':{'type':kind,'artifact':'array<int 0..20>, length 1..63'},
                 'evaluate_publish':{'type':kind,'candidate_id':'frozen artifact ID or null at task deadline'},
                 'checkpoint':{'type':kind},'resume':{'type':kind}}
        pre={'submit_candidate':['current contract/checker','live remaining ingress allowance'],
             'evaluate_publish':['current contract/checker/incumbent/exact frozen artifact','no unresolved effect','evaluation allowance','live candidate or task deadline for fallback'],
             'checkpoint':['current contract/checker'],'resume':['authenticated journal','current contract/checker']}
        effect={'submit_candidate':'receiver-private frozen artifact only','evaluate_publish':'native-qualified fixed result.bin or permitted failure','checkpoint':'receiver-private checkpoint record','resume':'local broker reconciliation; no native publication replay'}
        return {'type':kind,'schema':samples[kind],'preconditions':pre[kind],
                'required_capability':'receiver-dispatched task action; no worker authorization Boolean',
                'read_set':list(self._reads({'type':kind})),'reservation_ceiling':{'ingress':int(kind=='submit_candidate'),'native_transactions':(2 if self._sorting() else 1)*int(kind=='evaluate_publish')},
                'estimated_cost':{'value':None,'uncertainty':'not calibrated; actual dispatch time recorded'},
                'effect_scope':effect[kind],'completion_predicate':effect[kind]+' recorded with evidence',
                'recoverable_failures':['Rejected: inspect exact precondition','Inconclusive: inspect checker observation','EffectUnknown: resume before retry'],
                'retry':'same key plus same semantic request returns original receipt; changed request conflicts'}
    def _bounded(self,value,budget):
        required=len(_wire(value))
        if type(budget) is not int or budget<required:return {'schema_version':SCHEMA,'task_id':self.state['task_id'],'error':'VIEW_BUDGET_TOO_SMALL','required_bytes':required}
        return copy.deepcopy(value)
    def observe(self,cursor=None,focus=None,context_budget=16384):
        """Side-effect-free task projection. context_budget is encoded JSON bytes."""
        with self._locked():
            self._load();s=self.state
            if focus is not None and type(focus) is not str:raise InterfaceError('FOCUS_MUST_BE_STABLE_ID')
            receipt=next((v for v in s['receipts'].values() if v['id']==focus),None)
            if receipt is not None:return self._bounded({'schema_version':SCHEMA,'task_id':s['task_id'],'cursor':len(self.events),'receipt':receipt},context_budget)
            if focus in s['evidence']:return self._bounded({'schema_version':SCHEMA,'task_id':s['task_id'],'cursor':len(self.events),'evidence':copy.deepcopy(s['evidence'][focus])},context_budget)
            if focus in s['claims']:return self._bounded({'schema_version':SCHEMA,'task_id':s['task_id'],'cursor':len(self.events),'claim':copy.deepcopy(s['claims'][focus])},context_budget)
            visible=list(s['artifacts'])[-2:]
            if focus in s['artifacts']:visible=[focus]
            c=self.broker._json('context.json')
            actions=[];blocked=[]
            for kind in ('submit_candidate','evaluate_publish','checkpoint','resume'):
                sample={'type':kind}
                if kind=='evaluate_publish':sample['candidate_id']=visible[-1] if visible else None
                failure=self._precondition(sample)
                if failure:blocked.append({'type':kind,'reason':failure})
                else:actions.append(self._descriptor(kind))
            declaration=copy.deepcopy(s['declaration'])
            view={'interface_contract':{
                    'binding':'receiver-supplied Python Task handle already bound to this task_id; no public RPC or credential is supplied by this view',
                    'module':'supervisor.interface.Task',
                    'observe':'task.observe(cursor=None, focus=STABLE_ID, context_budget=16384) -> WorkView or scoped detail; budget unit is encoded JSON bytes',
                    'act':'task.act(action=ACTION_OBJECT, basis=VIEW[\"basis\"], idempotency_key=FRESH_KEY) -> ActionReceipt; task_id is implicit in the supplied handle',
                    'await':'task.await_events(cursor=VIEW[\"cursor\"], event_filter=[\"receipt\"], deadline=RECEIVER_MONOTONIC_SECONDS) -> EventBatch or TimedOut; timeout does not cancel',
                    'action_envelope':{'action':'one typed object from actions[].schema','basis':'copy the current view basis unchanged','idempotency_key':'new nonempty string <=128characters, e.g. uuid.uuid4().hex; retain exact key+semantic request for retry'},
                    'expansion':{'method':'task.observe(focus=ID)','ids':'details.expandable_ids; receipt/evidence/claim/artifact IDs are stable'},
                    'authority':'copying a descriptor or choosing a key creates no capability; receiver dispatch and native admission remain controlling'},
                  'schema_version':SCHEMA,'task_id':s['task_id'],'cursor':len(self.events),'basis':self._basis(visible),
                  'outcome_required':s['goal'],'contract':{'id':s['contract_id'],'task':s['contract']['task'],'epoch':s['contract']['epoch'],
                    'adapter':s['adapter'],'checker_sha256':s['checker_sha256'],'declaration':declaration,
                    'authority':'receiver-owned contract; notes and worker artifacts are data',
                    'input_reference':self._display(s['contract']['reference'])},
                  'recent_receipts':[{k:v[k] for k in ('id','action','outcome','code','recovery','candidate_id','evidence_ids','retained_artifact_ids','causal_witness')} for v in list(s['receipts'].values())[-2:]],
                  'established_claims':list(s['claims'].values())[-3:],'incumbent':None if s['incumbent'] is None else {**s['incumbent'],'display':self._display(s['incumbent']['value'])},
                  'candidates':[{'id':v,'sha256':s['artifacts'][v]['sha256'],'scope':s['artifacts'][v]['scope']} for v in visible],
                  'details':{'artifacts_total':len(s['artifacts']),'claims_total':len(s['claims']),'evidence_total':len(s['evidence']),
                             'expandable_ids':{'artifacts':list(s['artifacts']),'claims':list(s['claims']),'evidence':list(s['evidence']),'receipts':[v['id'] for v in s['receipts'].values()]}},
                  'deadline':{'monotonic_ns':c['deadline_ns'],'observed_monotonic_ns':time.monotonic_ns(),'unit':'nanoseconds; receiver time.monotonic_ns clock on this boot, not UTC','await_unit':'deadline argument is seconds on the same receiver monotonic clock'},
                  'budget':{'ingress_spent':c['received'],'ingress_remaining':c['allowance']-c['received'],
                            'evaluations_spent_or_reserved':s['evaluations'],'evaluations_remaining':s['evaluation_allowance']-s['evaluations'],
                            'native_logical_transaction_budget':s['contract']['budget'],'physical_total_envelope':'not implemented by this facade'},
                  'open_decisions':[{'effect_keys':list(s['unresolved']),'decision':'reconcile before another publication'}] if s['unresolved'] else [],
                  'actions':actions,'blocked_actions':blocked,'checkpoint':s['checkpoint'],'cancelled':s['cancelled'],
                  'assurance_scope':'actual pinned Bend admission plus tested Python facade/Broker; no facade kernel proof or general refinement'}
            if focus in s['artifacts']:view['artifact']={**s['artifacts'][focus],'display':self._display(s['artifacts'][focus]['value'])}
            if cursor is not None:view['delta']=[{'cursor':e['seq'],'kind':e['kind']} for e in self.events if e['seq']>cursor]
            return self._bounded(view,context_budget)
    def _evidence(self,kind,result,scope,details):
        eid='e'+str(len(self.events)+1);body={'id':eid,'kind':kind,'result':result,'scope':scope,'dependencies':self._basis(), 'details':copy.deepcopy(details)}
        self._append('evidence',body);return eid
    def _claim(self,result,scope,evidence):
        cid='c'+str(len(self.events)+1)
        self._append('claim',{'id':cid,'kind':'empirical','result':result,'scope':scope,'evidence_ids':list(evidence),'basis':self._basis()})
        return cid
    def _receipt(self,key,intent,outcome,code,recovery,cost,evidence,candidate=None):
        receipt={'schema_version':'bendloop-action-receipt-v1','id':'r'+str(len(self.events)+1),'task_id':self.state['task_id'],
                 'idempotency_key':key,'action':intent['action']['type'],'outcome':outcome,'code':code,'recovery':recovery,
                 'retained_artifact_ids':list(self.state['artifacts']),'candidate_id':candidate,'evidence_ids':list(evidence),
                 'immutable_result_refs':[] if self.state['incumbent'] is None else [{k:self.state['incumbent'][k] for k in ('artifact_id','sha256')}],
                 'causal_witness':next(({'source_evidence_id':eid,'scope':self.state['evidence'][eid]['scope'],
                    'observation':self.state['evidence'][eid]['details']['observation']} for eid in evidence if self.state['evidence'][eid]['kind']=='native_diagnostic'),None),
                 'cost':cost,'affected_basis':self._basis(),'outstanding_reservations':list(self.state['pending']) if outcome=='EffectUnknown' else []}
        self._append('receipt',receipt);return copy.deepcopy(receipt)
    @staticmethod
    def _action_valid(action):
        if type(action) is not dict or type(action.get('type')) is not str:return False
        t=action['type'];expected={'submit_candidate':{'type','artifact'},'evaluate_publish':{'type','candidate_id'},'checkpoint':{'type'},'resume':{'type'}}
        good=t in expected and set(action)==expected[t] and (t!='evaluate_publish' or action['candidate_id'] is None or type(action['candidate_id']) is str)
        if good and t=='submit_candidate':
            value=action['artifact'];good=type(value) is list and 1<=len(value)<=63 and all(type(x) is int and 0<=x<=20 for x in value)
        return good
    def act(self,action,basis,idempotency_key):
        started=time.monotonic_ns()
        with self._locked():
            self._load();s=self.state
            if not self._action_valid(action) or type(basis) is not dict or type(basis.get('frozen',{})) is not dict or type(idempotency_key) is not str or not 1<=len(idempotency_key)<=128:
                return {'schema_version':'bendloop-action-receipt-v1','task_id':s['task_id'],'outcome':'Rejected','code':'ACTION_SCHEMA_OR_KEY_INVALID','recovery':'Use the advertised typed action schema; no effect executed.'}
            request=self._request(action,basis);key=idempotency_key
            if key in s['requests']:
                if s['requests'][key]!=request:return {'schema_version':'bendloop-action-receipt-v1','task_id':s['task_id'],'outcome':'Rejected','code':'IDEMPOTENCY_CONFLICT','recovery':'Use the original immutable request or a fresh key; no effect executed.'}
                return copy.deepcopy(s['receipts'].get(key,{'outcome':'EffectUnknown','code':'INTENT_WITHOUT_RECEIPT','recovery':'Resume before retry; do not reexecute.'}))
            expected=self._request(action,self._basis())['basis']
            intent={'key':key,'request':request,'action':copy.deepcopy(action),'reserved':False,'broker_before':self.broker._json('context.json')}
            if request['basis']!=expected:
                self._append('intent',intent)
                return self._receipt(key,intent,'Rejected','STALE_SEMANTIC_BASIS','Observe the current relevant contract/checker/incumbent/candidate dependencies.',{'dispatch_wall_ns':time.monotonic_ns()-started,'scope':'before receipt fsync'},[])
            failure=self._precondition(action)
            if failure:
                self._append('intent',intent)
                return self._receipt(key,intent,'Cancelled' if failure=='TASK_CANCELLED' else 'Rejected',failure,'Inspect the named precondition; retained artifacts remain available.',{'dispatch_wall_ns':time.monotonic_ns()-started,'scope':'before receipt fsync'},[])
            intent['reserved']=True;self._append('intent',intent);kind=action['type'];calls_before=self._native_request_total;evidence=[];outcome='Completed';code='COMPLETED';recovery='Observe the updated view and choose an admissible next action.';candidate=None
            try:
                if kind=='submit_candidate':
                    raw=_wire(action['artifact']);frozen=self.broker.submit(raw);candidate='a'+str(frozen.epoch)+'-'+str(frozen.serial)
                    artifact={'id':candidate,'task':frozen.task,'epoch':frozen.epoch,'serial':frozen.serial,'value':json.loads(frozen.content),
                              'sha256':hashlib.sha256(frozen.content).hexdigest(),'scope':'immutable bounded integer artifact; admission not yet established'}
                    self._append('artifact',artifact)
                    evidence=[self._evidence('observation','satisfied','receiver copied these exact canonical candidate bytes',{'artifact_id':candidate,'sha256':artifact['sha256']})]
                elif kind=='evaluate_publish':
                    candidate=action['candidate_id'];self._last_native=None
                    if candidate is None:self.broker.finish()
                    else:
                        frozen=s['artifacts'][candidate];self.broker.commit(Frozen(frozen['task'],frozen['epoch'],frozen['serial'],_wire(frozen['value'])))
                    delivered=self.broker.read_delivered()
                    native=self._last_native or {'reply':{'kind':'none'}}
                    evidence=[self._evidence('native_execution','satisfied','this pinned receiver invocation and fixed-file broker observation only',{'checker_sha256':s['checker_sha256'],'native':native,'delivery_sha256':None if delivered is None else hashlib.sha256(delivered).hexdigest()})]
                    if delivered is not None:
                        digest=hashlib.sha256(delivered).hexdigest();aid=next((a['id'] for a in self.state['artifacts'].values() if a['sha256']==digest),'receiver-incumbent:'+digest)
                        self._append('delivered',{'artifact_id':aid,'sha256':digest,'value':json.loads(delivered),'evidence_ids':evidence,'scope':'current receiver-acknowledged local result'})
                        selected=candidate is None or delivered==_wire(self.state['artifacts'][candidate]['value'])
                        self._claim('satisfied','receiver selected and acknowledged this exact artifact under the current contract',evidence)
                        if not selected:
                            outcome='Rejected';code='CANDIDATE_NOT_SELECTED';recovery='The native selector retained another qualified result. Inadmissibility versus non-improvement is unresolved here; inspect exact task predicates before repair.'
                    else:
                        outcome='Rejected';code='NO_AUTHORIZED_PUBLICATION';recovery='No artifact became authoritative. Inspect receiver policy/budget and retain the frozen candidate; this is not a fabricated proof of a particular failed property.'
                    if self._sorting() and candidate is not None and outcome=='Rejected':
                        ctx=copy.deepcopy(self.broker._json('context.json'));ctx['phase']='worker'
                        delivered_record=self.broker._json('delivered.json')
                        ctx['incumbent']=delivered_record['artifact'] if delivered_record else next((v['artifact'] for v in ctx['snapshots'] if v['serial']==0),None)
                        frozen=self.state['artifacts'][candidate];diagnostic=None
                        try:
                            self._native_request_total+=1
                            diagnostic=self.port.inspect(ctx,Frozen(frozen['task'],frozen['epoch'],frozen['serial'],_wire(frozen['value'])))
                            evidence.append(self._evidence('native_diagnostic','satisfied','sorting checker diagnostics for this exact frozen candidate only; never publication authority',{'candidate_id':candidate,'checker_sha256':s['checker_sha256'],'observation':diagnostic}))
                            recovery='Inspect the retained native sorting diagnostic and exact frozen records, repair locally, and submit a new candidate; diagnostic output never authorizes publication.'
                        except BoundaryError as error:
                            evidence.append(self._evidence('observation','inconclusive','sorting diagnostic unavailable; exact failed predicate remains unresolved',{'error':str(error)[:2048]}))
                elif kind=='checkpoint':
                    self._append('checkpoint',{'id':'checkpoint:'+str(len(self.events)+1),'basis':self._basis(),'artifact_ids':list(s['artifacts']),
                        'evidence_ids':list(s['evidence']),'incumbent':s['incumbent'],'unresolved_effect_keys':list(s['unresolved']),
                        'evaluations_spent':s['evaluations'],'scope':'authenticated task handoff; no private evaluation answers'})
                elif kind=='resume':
                    self.broker.recover();current=self.broker.read_delivered()
                    ctx=self.broker._json('context.json')
                    submitted=[v['action']['artifact'] for v in self.state['requests'].values() if v['action']['type']=='submit_candidate']
                    for saved in ctx['snapshots']:
                        aid='a'+str(ctx['epoch'])+'-'+str(saved['serial'])
                        if saved['serial'] and aid not in self.state['artifacts'] and saved['artifact'] in submitted:
                            raw=_wire(saved['artifact'])
                            self._append('artifact',{'id':aid,'task':ctx['task'],'epoch':ctx['epoch'],'serial':saved['serial'],'value':saved['artifact'],
                                'sha256':hashlib.sha256(raw).hexdigest(),'scope':'recovered exact receiver-frozen candidate; admission not asserted'})
                    evidence=[self._evidence('observation','satisfied','local fixed-file broker recovery, not external service reconciliation',{'delivery_sha256':None if current is None else hashlib.sha256(current).hexdigest(),'unknown_keys':list(s['unresolved'])})]
                    self._append('reconciled',{'keys':list(s['unresolved']),'evidence_ids':evidence})
                    if current is not None:
                        digest=hashlib.sha256(current).hexdigest();aid=next((a['id'] for a in self.state['artifacts'].values() if a['sha256']==digest),'receiver-incumbent:'+digest)
                        self._append('delivered',{'artifact_id':aid,'sha256':digest,'value':json.loads(current),'evidence_ids':evidence,'scope':'recovered acknowledged local result'})
            except BoundaryError as error:
                outcome='Inconclusive';code='CHECKER_OR_BOUNDARY_ERROR';recovery='Inspect the retained receiver observation and fix/retry only within a fresh authorized attempt; no property is declared false by this error.'
                evidence=[self._evidence('observation','inconclusive','receiver checker or IO boundary failed; no universal claim',{'error':str(error)[:2048]})]
            except OSError as error:
                outcome='EffectUnknown';code='LOCAL_EFFECT_ACKNOWLEDGEMENT_UNKNOWN';recovery='Resume/reconcile local broker state before another publication; never blindly retry this effect.'
                evidence=[self._evidence('observation','inconclusive','local effect acknowledgement interrupted',{'error':str(error)[:2048]})]
            return self._receipt(key,intent,outcome,code,recovery,{'dispatch_wall_ns':time.monotonic_ns()-started,'native_transactions':self._native_request_total-calls_before,'scope':'actual dispatch through evidence recording; excludes final receipt fsync and response serialization'},evidence,candidate)
    def _public_event(self,e):
        if e['kind'] in ('receipt','artifact','evidence','claim','delivered','checkpoint','observation','cancelled','reconciled'):
            body=copy.deepcopy(e['body'])
        elif e['kind']=='issued':
            body={k:e['body'][k] for k in ('task_id','goal','contract_id','checker_sha256','adapter')}
        else:
            body={'scope':'receiver-private journal details omitted; use stable public claim/evidence/artifact references'}
        return {'cursor':e['seq'],'kind':e['kind'],'body':body}
    def await_events(self,cursor,event_filter,deadline):
        """In-process condition wait; caller deadline expiry does not cancel work.

        Cross-process event notification transport is not implemented. Reopened
        tasks reconstruct durably, but an active waiter must share this instance.
        """
        if type(cursor) is not int or cursor<0 or not isinstance(event_filter,(list,tuple,set)) or any(type(v) is not str for v in event_filter):raise InterfaceError('AWAIT_ARGUMENT_INVALID')
        with self._condition:
            while True:
                matches=[self._public_event(e) for e in self.events if e['seq']>cursor and (not event_filter or e['kind'] in event_filter or e['kind']=='cancelled')]
                if matches:return {'outcome':'Events','cursor':len(self.events),'events':matches}
                remaining=deadline-time.monotonic()
                if remaining<=0:return {'outcome':'TimedOut','cursor':len(self.events),'cancelled':False,'meaning':'await deadline elapsed; task/work termination is not asserted'}
                self._condition.wait(timeout=remaining)
    def _receiver_note(self,text):
        with self._locked():self._load();self._append('observation',{'text':str(text)[:2048],'scope':'receiver note only; cannot alter authority or admission'})
    def _receiver_cancel(self,reason):
        with self._locked():
            self._load()
            with self.broker._locked():
                c=self.broker._json('context.json');c['terminal']=True;c['deadline_ns']=0;self.broker._write_json('context.json',c)
            self._append('cancelled',{'reason':str(reason)[:2048],'cleanup':'this facade launches no worker processes; no descendant termination claim'})


def run_controlled_sort(root: Path,goal: str,records: list,executable: Path,expected_sha256: str):
    """One request -> wrong output feedback -> durable handoff -> usable result.

    executable/hash are receiver/operator deployment configuration, not user role
    choices. The two producers are deliberately controlled fixtures, not hostile
    sandbox executions. Python produces candidates; only Bend/Broker admits them.
    This demonstrates the bounded eight-record journey, not general sorting or
    measured ergonomic superiority. The duplicate witness and all failed work stay.
    """
    if type(records) is not list or len(records)!=8 or any(type(r) is not dict or set(r)!={'date','id','value'} or any(type(r[k]) is not int or not 0<=r[k]<=20 for k in r) for r in records):
        raise InterfaceError('SORT8_INPUT_REQUIRES_EIGHT_DATE_ID_VALUE_RECORDS_0_TO_20')
    reference=[x for r in records for x in (r['date'],r['id'],r['value'])]
    good=sorted(copy.deepcopy(records),key=lambda r:(r['date'],r['id']))
    baseline=sorted(copy.deepcopy(records),key=lambda r:(r['date'],-r['id']))
    bad=copy.deepcopy(good)
    # Prefer a duplicate so the receipt visibly distinguishes multiplicity, e.g.
    # expected two occurrences versus one. If all records coincide, alter a value.
    target=next((r for r in good if good.count(r)>1),good[-1])
    replacement=next((r for r in good if r!=target),{**target,'value':(target['value']+1)%21})
    bad[bad.index(target)]=copy.deepcopy(replacement);bad.sort(key=lambda r:(r['date'],r['id']))
    flatten=lambda xs:[x for r in xs for x in (r['date'],r['id'],r['value'])]
    contract={'task':1,'epoch':0,'evaluator':2,'permission':'publish','reference':reference,'allowed_ops':[],
              'max_nodes':7,'fallback':flatten(baseline),'budget':5}
    declaration={'required_result':goal,'mandatory_properties':['date order','every whole input record preserved, including multiplicity'],
       'preferences':[{'rule':'reduce same-date ID inversions','origin':'added receiver comparison preference, not a mandatory user obligation'}],
       'permitted_effects':['one receiver-owned fixed result.bin'],'codec':'eight records, flat triples date/id/value; integers0..20',
       'evaluation':'pinned native Bend sort8 checker; no worker review or claim authorizes publication'}
    task=Task.create(root,goal,contract,executable,expected_sha256,8,60,adapter='sort8',declaration=declaration)
    try:
        def act(action,key):return task.act(action,task.observe()['basis'],key)
        frozen_bad=act({'type':'submit_candidate','artifact':flatten(bad)},'controlled-bad-output')
        rejected=act({'type':'evaluate_publish','candidate_id':frozen_bad['candidate_id']},'receiver-check-bad')
        if rejected['outcome']!='Rejected' or rejected['causal_witness'] is None:raise InterfaceError('CONTROLLED_BAD_OUTPUT_DID_NOT_PRODUCE_REJECTED_NATIVE_WITNESS')
        checkpoint=act({'type':'checkpoint'},'handoff-checkpoint')
        task.close();task=Task.reopen(root)
        handoff=task.observe();task._replace('handoff-view.json',_wire(handoff))
        resumed=act({'type':'resume'},'successor-resume')
        frozen_good=act({'type':'submit_candidate','artifact':flatten(good)},'controlled-good-output')
        accepted=act({'type':'evaluate_publish','candidate_id':frozen_good['candidate_id']},'receiver-check-good')
        view=task.observe()
        if accepted['outcome']!='Completed' or view['incumbent'] is None:raise InterfaceError('CONTROLLED_SORT_HAS_NO_QUALIFIED_DELIVERY')
        usable={'schema_version':'bendloop-sort8-result-v1','records':view['incumbent']['display']['records'],
                'canonical_sha256':view['incumbent']['sha256'],'receipt_id':accepted['id'],'evidence_ids':accepted['evidence_ids']}
        task._replace('result-records.json',_wire(usable))
        report={'outcome':'Completed','task_id':view['task_id'],'goal':goal,'artifact':usable,
                'rejected_receipt':rejected,'checkpoint_receipt':checkpoint,'resume_receipt':resumed,'accepted_receipt':accepted,
                'handoff_view':str(Path(root)/'handoff-view.json'),'durable_task':str(root),
                'scope':'one real native sort8 request-to-artifact journey with controlled candidate producers; no all18 or host-isolation claim'}
        task._replace('journey.json',_wire(report));return report
    finally:task.close()
