import Base
import ./parser.bend as J
import ../search/grammar.bend as G
import ../interpreter/runtime.bend as R

def contains(+key: String, xs: List<&2,String>) -> Bool:
  match xs:
    case Nil{}: False{}
    case Con{h,t}: Bool.or(String.eq(key,h),contains(key,t))

def distinct(xs: List<&2,String>) -> Bool:
  match xs:
    case Nil{}: True{}
    case Con{h,+t}: Bool.and(Bool.not(contains(h,t)),distinct(t))

def subset(xs: List<&2,String>, +allowed: List<&2,String>) -> Bool:
  match xs:
    case Nil{}: True{}
    case Con{h,t}: Bool.and(contains(h,allowed),subset(t,allowed))

def keys(value: J.Value, +expected: List<&2,String>) -> Bool:
  match value:
    case J.JObject{+ks,vs}: Bool.and(distinct(ks),Bool.and(subset(ks,expected),subset(expected,ks)))
    case _: False{}

def lookup_rows(+key: String, ks: List<&2,String>, vs: List<&2,J.Value>) -> J.Value:
  match ks vs:
    case Con{h,t} Con{v,rest}: Bool.pick(J.Value,String.eq(key,h),v,lookup_rows(key,t,rest))
    case _ _: J.JNull{}

def get(key: String, value: J.Value) -> J.Value:
  match value:
    case J.JObject{ks,vs}: lookup_rows(key,ks,vs)
    case _: J.JNull{}

def digits(s: String) -> Bool:
  match s:
    case SNil{}: True{}
    case SCon{h,t}: Bool.and(J.digit(Char.to_u32(h)),digits(t))

def integer(value: J.Value) -> Bool:
  match value:
    case J.JNumber{SCon{Chr{45},t}}: digits(t)
    case J.JNumber{s}: digits(s)
    case _: False{}

def natural(value: J.Value) -> Maybe<&2,U32>:
  match value:
    case J.JNumber{"-0"}: Some{0}
    case J.JNumber{s}: U32.read(s)
    case _: None{}

def in_range(value: Maybe<&2,U32>, +lo: U32, +hi: U32) -> Bool:
  match value:
    case None{}: False{}
    case Some{+n}: Bool.and(U32.is_ge(n,lo),U32.is_le(n,hi))

def range(value: J.Value, lo: U32, hi: U32) -> Bool:
  in_range(natural(value),lo,hi)

def number_or_zero(n: Maybe<&2,U32>) -> U32:
  match n:
    case None{}: 0
    case Some{value}: value

def num(value: J.Value) -> U32:
  number_or_zero(natural(value))

def ints(xs: List<&2,J.Value>) -> Bool:
  match xs:
    case Nil{}: True{}
    case Con{h,t}: Bool.and(integer(h),ints(t))

def int_array(value: J.Value) -> Bool:
  match value:
    case J.JItems{xs}: ints(xs)
    case _: False{}

def bounded(xs: List<&2,J.Value>, +lo: U32, +hi: U32) -> Bool:
  match xs:
    case Nil{}: True{}
    case Con{h,t}: Bool.and(range(h,lo,hi),bounded(t,lo,hi))

def array_range(value: J.Value, lo: U32, hi: U32, min_size: Nat, max_size: Nat) -> Bool:
  match value:
    case J.JItems{+xs}:
      Bool.and(bounded(xs,lo,hi),Bool.and(Nat.is_ge(List.length(&2,J.Value,xs),min_size),Nat.is_le(List.length(&2,J.Value,xs),max_size)))
    case _: False{}

def numbers(xs: List<&2,J.Value>) -> List<&2,U32>:
  match xs:
    case Nil{}: Nil{}
    case Con{h,t}: Con{num(h),numbers(t)}

def tokens(value: J.Value) -> List<&2,U32>:
  match value:
    case J.JItems{xs}: numbers(xs)
    case _: Nil{}

def ast(value: J.Value) -> Maybe<&2,R.Expr>:
  G.parsed(G.parse(63n,tokens(value)))

def present(value: Maybe<&2,R.Expr>) -> Bool:
  match value:
    case None{}: False{}
    case Some{x}: True{}

def schema(value: J.Value) -> Bool:
  match value:
    case J.JText{"bendloop-synth4-v1"}: True{}
    case _: False{}

def ordered(xs: List<&2,U32>, previous: U32) -> Bool:
  match xs:
    case Nil{}: True{}
    case Con{+h,t}: Bool.and(U32.is_gt(h,previous),ordered(t,h))

def has(+token: U32, xs: List<&2,U32>) -> Bool:
  match xs:
    case Nil{}: False{}
    case Con{h,t}: Bool.or(U32.is_eq(token,h),has(token,t))

def ops(+value: J.Value) -> G.Ops:
  G.Ops{has(17,tokens(value)),has(18,tokens(value)),has(19,tokens(value)),has(20,tokens(value))}

def bound(n: U32) -> G.Bound:
  match n:
    case 1: G.N1{}
    case 2: G.N2{}
    case 3: G.N3{}
    case 4: G.N4{}
    case 5: G.N5{}
    case 6: G.N6{}
    case _: G.N7{}

def request_keys(value: J.Value) -> Bool:
  keys(value,["schema","reference","allowed_ops","max_nodes","budget"])

def request_types(+v: J.Value) -> Bool:
  Bool.and(schema(get("schema",v)),Bool.and(int_array(get("reference",v)),Bool.and(int_array(get("allowed_ops",v)),Bool.and(integer(get("max_nodes",v)),integer(get("budget",v))))))

def request_ranges(+v: J.Value) -> Bool:
  Bool.and(array_range(get("reference",v),0,20,1n,63n),Bool.and(array_range(get("allowed_ops",v),17,20,0n,4n),Bool.and(ordered(tokens(get("allowed_ops",v)),16),Bool.and(range(get("max_nodes",v),1,7),range(get("budget",v),0,1000000)))))

def certificate_keys(v: J.Value) -> Bool:
  keys(v,["schema","reference","candidate","candidate_cost","outputs"])

def certificate_types(+v: J.Value) -> Bool:
  Bool.and(schema(get("schema",v)),Bool.and(int_array(get("reference",v)),Bool.and(int_array(get("candidate",v)),Bool.and(integer(get("candidate_cost",v)),int_array(get("outputs",v))))))

def certificate_ranges(+v: J.Value) -> Bool:
  Bool.and(array_range(get("reference",v),0,20,1n,63n),Bool.and(array_range(get("candidate",v),0,20,1n,7n),Bool.and(range(get("candidate_cost",v),0,7),array_range(get("outputs",v),0,15,16n,16n))))

# Error selection is category-first, then decoded key-name order.
def error_if(ok: Bool, label: String, next: Unit -> String) -> String:
  match ok:
    case True{}: next(Unit{})
    case False{}: label

def earlier(+a: String, +b: String) -> String:
  match a b:
    case "" _: b
    case _ "": a
    case _ _: Bool.pick(String,String.is_lt(a,b),a,b)

def key_problem(ok: Bool, key: String) -> String:
  match ok:
    case True{}: ""
    case False{}: "key: " ++ key

def key_errors(ks: List<&2,String>, +expected: List<&2,String>) -> String:
  match ks:
    case Nil{}: ""
    case Con{+k,+t}: earlier(key_problem(Bool.and(contains(k,expected),Bool.not(contains(k,t))),k),key_errors(t,expected))

def key_error(v: J.Value, expected: List<&2,String>) -> String:
  match v:
    case J.JObject{ks,vs}: key_errors(ks,expected)
    case _: ""

def request_type_error(+v: J.Value) -> String:
  error_if(int_array(get("allowed_ops",v)),"type: allowed_ops",u => error_if(integer(get("budget",v)),"type: budget",u => error_if(integer(get("max_nodes",v)),"type: max_nodes",u => error_if(int_array(get("reference",v)),"type: reference",u => error_if(schema(get("schema",v)),"type: schema",u => "")))))

def request_range_error(+v: J.Value) -> String:
  error_if(Bool.and(array_range(get("allowed_ops",v),17,20,0n,4n),ordered(tokens(get("allowed_ops",v)),16)),"range: allowed_ops",u => error_if(range(get("budget",v),0,1000000),"range: budget",u => error_if(range(get("max_nodes",v),1,7),"range: max_nodes",u => error_if(array_range(get("reference",v),0,20,1n,63n),"range: reference",u => ""))))

def certificate_type_error(+v: J.Value) -> String:
  error_if(int_array(get("candidate",v)),"type: candidate",u => error_if(integer(get("candidate_cost",v)),"type: candidate_cost",u => error_if(int_array(get("outputs",v)),"type: outputs",u => error_if(int_array(get("reference",v)),"type: reference",u => error_if(schema(get("schema",v)),"type: schema",u => "")))))

def certificate_range_error(+v: J.Value) -> String:
  error_if(array_range(get("candidate",v),0,20,1n,7n),"range: candidate",u => error_if(range(get("candidate_cost",v),0,7),"range: candidate_cost",u => error_if(array_range(get("outputs",v),0,15,16n,16n),"range: outputs",u => error_if(array_range(get("reference",v),0,20,1n,63n),"range: reference",u => ""))))
