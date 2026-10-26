"""Independent test oracle. Never imported by the Bend runtime or used to supply answers."""
import itertools
from functools import lru_cache

@lru_cache(None)
def grammar(n):
    if n==1:return tuple((i,) for i in range(17))
    rows=[(17,)+x for x in grammar(n-1)]
    for op in (18,19,20):
        for left in range(1,n-1):
            rows.extend((op,)+x+y for x in grammar(left) for y in grammar(n-1-left))
    return tuple(sorted(rows))
@lru_cache(None)
def space(bound):
    # Test/API caps <=128 never reach size four: size<=3 already has 918 members.
    return tuple(x for n in range(1,min(bound,3)+1) for x in grammar(n))
def evaluate(tokens,value):
    stack=[]
    for t in reversed(tokens):
        if t==0:stack.append(value)
        elif 1<=t<=16:stack.append(t-1)
        elif t==17:stack.append(stack.pop()^15)
        else:
            a,b=stack.pop(),stack.pop()
            stack.append(a&b if t==18 else a|b if t==19 else a^b)
    assert len(stack)==1
    return stack[0]
def cost(tokens):return sum(t>=17 for t in tokens)
def children(tokens):
    slots=1
    for i,t in enumerate(tokens[1:],1):
        slots-=1
        slots+=1 if t==17 else 2 if t>=18 else 0
        if slots==0:return tokens[1:i+1],tokens[i+1:]
    raise ValueError('bad AST')
def zero_form(tokens):
    if tokens[0] not in (18,20):return False
    a,b=children(tuple(tokens))
    return a==b if tokens[0]==20 else a==(1,) or b==(1,)
def ones_form(tokens):
    if tokens[0]==17:return tuple(tokens[1:])==(1,)
    if tokens[0]!=19:return False
    a,b=children(tuple(tokens));return a==(16,) or b==(16,)
def priority(p,reference):
    if p['zero'] and zero_form(reference):return 1
    if p['ones'] and ones_form(reference):return 16
    return 0
def task(reference,config):return (tuple(reference),config['max_nodes'],config['candidate_budget'])
def observe(p,t):
    reference,bound,cap=t;g=space(bound);best=cost(reference);found=False;trials=[]
    seed=priority(p,reference)
    attempts=min(cap,len(g))
    for rank in range(attempts):
        source=seed if rank==0 else 0 if rank==seed else rank
        candidate=g[source];checks=0;equivalent=admitted=False
        if cost(candidate)<best:
            equivalent=True
            for v in range(16):
                checks+=1
                if evaluate(reference,v)!=evaluate(candidate,v):equivalent=False;break
            if equivalent:admitted=True;found=True;best=cost(candidate)
        trials.append({'rank':rank,'grammar_rank':source,'candidate':list(candidate),
                       'checked_inputs':checks,'equivalent':equivalent,'admitted':admitted})
    return {'attempts':attempts,'remaining':cap-attempts,'best_cost':best,'improved':found,
      'checked_inputs':sum(x['checked_inputs'] for x in trials),
      'verification_nodes':sum(x['checked_inputs']*(len(reference)+len(x['candidate'])) for x in trials),
      'trials_newest_first':list(reversed(trials))}
def assess(p,tasks):
    observations=[observe(p,t) for t in tasks]
    return {'costs':[o['best_cost'] for o in observations],
            **{k:sum(o[k] for o in observations) for k in ('attempts','checked_inputs','verification_nodes')},
            'observations':observations}
def dominates(new,old):return all(a<=b for a,b in zip(new,old)) and any(a<b for a,b in zip(new,old))
def compare(old,new,tasks):
    a,b=assess(old,tasks),assess(new,tasks)
    return {'before':old,'proposed':new,'old':a,'new':b,'accepted':dominates(b['costs'],a['costs'])}
def proposal(p,reference,index):
    if index in (0,1):
        z=p['order']=='zero-first' or p['order']=='root-aware' and zero_form(reference)
        if index==1:z=not z
        return {**p,('zero' if z else 'ones'):True}
    if index<5:return {**p,'order':('root-aware','zero-first','ones-first')[index-2]}
    return None
def adapt(p,t,guard,cap):
    initial=p;history=[];used=0
    for i in range(cap):
        q=proposal(p,t[0],i)
        if q is None:break
        measured=compare(p,q,[t,*guard]);used+=1
        history.append({'index':i,'comparison':measured})
        if measured['accepted']:p=q
    return {'initial':initial,'final':p,'proposed':used,'remaining':cap-used,'history_newest_first':list(reversed(history))}
def episode(p,e,config):
    transfer=[task(x,config) for x in e['transfer']]
    adaptation=adapt(p,task(e['training'],config),[task(x,config) for x in e['protected']],e['learning_budget'])
    return {'cold':assess(p,transfer),'after':assess(adaptation['final'],transfer),'adaptation':adaptation}
def assess_learning(p,episodes,config):
    results=[episode(p,e,config) for e in episodes]
    profiles=[]
    for r in results:
        profiles.extend([r['cold'],r['after']])
        for trial in r['adaptation']['history_newest_first']:
            profiles.extend([trial['comparison']['old'],trial['comparison']['new']])
    return {'cold_costs':[x for r in results for x in r['cold']['costs']],
      'after_costs':[x for r in results for x in r['after']['costs']],
      'policy_proposals':sum(r['adaptation']['proposed'] for r in results),
      'candidate_attempts':sum(r['attempts'] for r in profiles),
      **{k:sum(r[k] for r in profiles) for k in ('checked_inputs','verification_nodes')},'episodes':results}
def compare_learning(p,q,episodes,config):
    a,b=assess_learning(p,episodes,config),assess_learning(q,episodes,config)
    return {'before':p,'proposed':q,'old':a,'new':b,
      'accepted':p['zero']==q['zero'] and p['ones']==q['ones'] and a['cold_costs']==b['cold_costs'] and dominates(b['after_costs'],a['after_costs'])}
def improve(p,config):
    initial=p;history=[];used=0
    for i in range(config['meta_budget']):
        q=proposal(p,config['training'][0]['training'],i)
        if q is None:break
        measured=compare_learning(p,q,config['training'],config);used+=1
        history.append({'index':i,'comparison':measured})
        if measured['accepted']:p=q
    return {'initial':initial,'final':p,'proposed':used,'remaining':config['meta_budget']-used,'history_newest_first':list(reversed(history))}
def branch(p,config):
    initial=p;history=[];used=accepted=0
    for reference in config['cycles']:
        if used>=config['cycle_budget']:break
        a=adapt(p,task(reference,config),[task(x,config) for x in config['protected']],1)
        used+=a['proposed'];accepted+=sum(t['comparison']['accepted'] for t in a['history_newest_first'])
        history.append(a);p=a['final']
    comparisons=[t['comparison'] for c in history for t in c['history_newest_first']]
    profiles=[p for c in comparisons for p in (c['old'],c['new'])]
    gain=sum(sum(x-y for x,y in zip(c['old']['costs'],c['new']['costs'])) for c in comparisons if c['accepted'])
    return {'initial':initial,'final':p,'accepted_cost_reduction':gain,
      'candidate_attempts':sum(p['attempts'] for p in profiles),
      **{k:sum(p[k] for p in profiles) for k in ('checked_inputs','verification_nodes')},'cap':config['cycle_budget'],'proposed':used,
      'remaining':config['cycle_budget']-used,'accepted':accepted,'cycles_newest_first':list(reversed(history))}
def experiment(config):
    old=config['policy'];training=improve(old,config);new=training['final']
    validation=compare_learning(old,new,config['validation'],config)
    a,b=branch(old,config),branch(new,config)
    return {'schema':'bendloop-policy-experiment-v1','training':training,'heldout_learning_comparison':validation,
      'original_revision_branch':a,'revised_revision_branch':b,
      'observed_recursive_gain':validation['accepted'] and b['accepted_cost_reduction']>a['accepted_cost_reduction']}
