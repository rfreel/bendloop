import Base

# JSON syntax trees and sequential character consumption; no indexed byte buffer.
type Value is Data:
  JNull{}
  JBoolean{value: Bool}
  JNumber{lexeme: String}
  JText{value: String}
  JItems{values: List<&2,Value>}
  JObject{keys: List<&2,String>, values: List<&2,Value>}

type JParsed is Data:
  JParsed{value: Value, rest: String}

def space(c: U32) -> Bool:
  match c:
    case 32: True{}
    case 9: True{}
    case 10: True{}
    case 13: True{}
    case _: False{}

def skip_if(ok: Bool, c: Char, t: String, next: String -> String) -> String:
  match ok:
    case True{}: next(t)
    case False{}: SCon{c,t}

def skip(s: String) -> String:
  match s:
    case SNil{}: SNil{}
    case SCon{+h,+t}: skip_if(space(Char.to_u32(h)),h,t,x => skip(t))

def digit(+c: U32) -> Bool:
  Bool.and(U32.is_ge(c,48),U32.is_le(c,57))

def hex(+c: U32) -> Maybe<&2,U32>:
  match c:
    case 48: Some{0}
    case 49: Some{1}
    case 50: Some{2}
    case 51: Some{3}
    case 52: Some{4}
    case 53: Some{5}
    case 54: Some{6}
    case 55: Some{7}
    case 56: Some{8}
    case 57: Some{9}
    case 97: Some{10}
    case 98: Some{11}
    case 99: Some{12}
    case 100: Some{13}
    case 101: Some{14}
    case 102: Some{15}
    case 65: Some{10}
    case 66: Some{11}
    case 67: Some{12}
    case 68: Some{13}
    case 69: Some{14}
    case 70: Some{15}
    case _: None{}

def unicode_step(d: Maybe<&2,U32>, n: U32, t: String, next: U32 -> String -> Maybe<&2,JParsed>) -> Maybe<&2,JParsed>:
  match d:
    case None{}: None{}
    case Some{v}: next((n * 16 + v : U32),t)

def unicode(fuel: Nat, n: U32, s: String) -> Maybe<&2,JParsed>:
  match fuel s:
    case 0n _: Some{JParsed{JText{SCon{Chr{n},SNil{}}},s}}
    case 1n+p SNil{}: None{}
    case 1n+p SCon{h,t}: unicode_step(hex(Char.to_u32(h)),n,t,x => xs => unicode(p,x,xs))

# A string scanner keeps a reversed accumulator. JSON escapes are decoded before key checks.
def escaped(c: U32, t: String) -> Maybe<&2,JParsed>:
  match c:
    case 34: Some{JParsed{JText{"\""},t}}
    case 92: Some{JParsed{JText{"\\"},t}}
    case 47: Some{JParsed{JText{"/"},t}}
    case 98: Some{JParsed{JText{SCon{Chr{8},SNil{}}},t}}
    case 102: Some{JParsed{JText{SCon{Chr{12},SNil{}}},t}}
    case 110: Some{JParsed{JText{"\n"},t}}
    case 114: Some{JParsed{JText{"\r"},t}}
    case 116: Some{JParsed{JText{"\t"},t}}
    case 117: unicode(4n,0,t)
    case _: None{}

def escape(s: String) -> Maybe<&2,JParsed>:
  match s:
    case SNil{}: None{}
    case SCon{h,t}: escaped(Char.to_u32(h),t)

def string_escape(r: Maybe<&2,JParsed>, acc: String, next: String -> String -> Maybe<&2,JParsed>) -> Maybe<&2,JParsed>:
  match r:
    case Some{JParsed{JText{part},t}}: next(t,part ++ acc)
    case _: None{}

def string_char(ok: Bool, c: U32, t: String, acc: String, next: String -> String -> Maybe<&2,JParsed>) -> Maybe<&2,JParsed>:
  match ok:
    case False{}: None{}
    case True{}: next(t,SCon{Chr{c},acc})

def string_code(+c: U32, t: String, acc: String, next: String -> String -> Maybe<&2,JParsed>) -> Maybe<&2,JParsed>:
  match c:
    case 34: Some{JParsed{JText{String.reverse(acc)},t}}
    case 92: string_escape(escape(t),acc,next)
    case _: string_char(U32.is_ge(c,32),c,t,acc,next)

def string(fuel: Nat, s: String, acc: String) -> Maybe<&2,JParsed>:
  match fuel s:
    case 0n _: None{}
    case 1n+p SNil{}: None{}
    case 1n+p SCon{h,t}: string_code(Char.to_u32(h),t,acc,x => a => string(p,x,a))

# JNumber grammar DFA: sign, zero/integer, fraction and exponent. Keep original spelling.
def number_step(state: U32, +c: U32) -> U32:
  match state c:
    case 0 45: 1
    case 0 48: 2
    case 1 48: 2
    case 0 _: Bool.pick(U32,digit(c),3,99)
    case 1 _: Bool.pick(U32,digit(c),3,99)
    case 2 46: 4
    case 3 46: 4
    case 2 101: 6
    case 2 69: 6
    case 3 101: 6
    case 3 69: 6
    case 3 _: Bool.pick(U32,digit(c),3,99)
    case 4 _: Bool.pick(U32,digit(c),5,99)
    case 5 101: 6
    case 5 69: 6
    case 5 _: Bool.pick(U32,digit(c),5,99)
    case 6 43: 7
    case 6 45: 7
    case 6 _: Bool.pick(U32,digit(c),8,99)
    case 7 _: Bool.pick(U32,digit(c),8,99)
    case 8 _: Bool.pick(U32,digit(c),8,99)
    case _ _: 99

def number_valid(s: String, +state: U32) -> Bool:
  match s:
    case SNil{}:
      Bool.or(U32.is_eq(state,2),Bool.or(U32.is_eq(state,3),Bool.or(U32.is_eq(state,5),U32.is_eq(state,8))))
    case SCon{h,t}: number_valid(t,number_step(state,Char.to_u32(h)))

def atom_number(ok: Bool, raw: String, rest: String) -> Maybe<&2,JParsed>:
  match ok:
    case False{}: None{}
    case True{}: Some{JParsed{JNumber{raw},rest}}

def atom(+raw: String, rest: String) -> Maybe<&2,JParsed>:
  match raw:
    case "null": Some{JParsed{JNull{},rest}}
    case "true": Some{JParsed{JBoolean{True{}},rest}}
    case "false": Some{JParsed{JBoolean{False{}},rest}}
    case _: atom_number(number_valid(raw,0),raw,rest)

def delimiter(+c: U32) -> Bool:
  Bool.or(space(c),Bool.or(U32.is_eq(c,44),Bool.or(U32.is_eq(c,93),U32.is_eq(c,125))))

def atom_char(done: Bool, h: Char, t: String, acc: String, next: String -> String -> Maybe<&2,JParsed>) -> Maybe<&2,JParsed>:
  match done:
    case True{}: atom(String.reverse(acc),SCon{h,t})
    case False{}: next(t,SCon{h,acc})

def atom_scan(s: String, acc: String) -> Maybe<&2,JParsed>:
  match s:
    case SNil{}: atom(String.reverse(acc),SNil{})
    case SCon{+h,+t}: atom_char(delimiter(Char.to_u32(h)),h,t,acc,x => a => atom_scan(t,a))

def assembled(object: Bool, keys: List<&2,String>, vals: List<&2,Value>, rest: String) -> Maybe<&2,JParsed>:
  match object:
    case False{}: Some{JParsed{JItems{List.reverse(&2,Value,vals)},rest}}
    case True{}: Some{JParsed{JObject{List.reverse(&2,String,keys),List.reverse(&2,Value,vals)},rest}}

def after_value_tail(object: Bool, keys: List<&2,String>, vals: List<&2,Value>, s: String, next: List<&2,String> -> List<&2,Value> -> String -> Maybe<&2,JParsed>) -> Maybe<&2,JParsed>:
  match object s:
    case False{} SCon{Chr{93},t}: assembled(False{},keys,vals,t)
    case True{} SCon{Chr{125},t}: assembled(True{},keys,vals,t)
    case _ SCon{Chr{44},t}: next(keys,vals,skip(t))
    case _ _: None{}

def after_value(object: Bool, keys: List<&2,String>, vals: List<&2,Value>, parsed: Maybe<&2,JParsed>, next: List<&2,String> -> List<&2,Value> -> String -> Maybe<&2,JParsed>) -> Maybe<&2,JParsed>:
  match parsed:
    case None{}: None{}
    case Some{JParsed{v,t}}: after_value_tail(object,keys,Con{v,vals},skip(t),next)

def colon(keys: List<&2,String>, vals: List<&2,Value>, s: String, child: String -> Maybe<&2,JParsed>, next: List<&2,String> -> List<&2,Value> -> String -> Maybe<&2,JParsed>) -> Maybe<&2,JParsed>:
  match s:
    case SCon{Chr{58},t}: after_value(True{},keys,vals,child(skip(t)),next)
    case _: None{}

def key_value(keys: List<&2,String>, vals: List<&2,Value>, parsed: Maybe<&2,JParsed>, child: String -> Maybe<&2,JParsed>, next: List<&2,String> -> List<&2,Value> -> String -> Maybe<&2,JParsed>) -> Maybe<&2,JParsed>:
  match parsed:
    case Some{JParsed{JText{key},t}}: colon(Con{key,keys},vals,skip(t),child,next)
    case _: None{}

def member(object: Bool, keys: List<&2,String>, vals: List<&2,Value>, s: String, child: String -> Maybe<&2,JParsed>, next: List<&2,String> -> List<&2,Value> -> String -> Maybe<&2,JParsed>) -> Maybe<&2,JParsed>:
  match object s:
    case True{} SCon{Chr{34},t}: key_value(keys,vals,string(65536n,t,""),child,next)
    case True{} _: None{}
    case False{} _: after_value(False{},keys,vals,child(s),next)

def container(object: Bool, s: String, next: String -> Maybe<&2,JParsed>) -> Maybe<&2,JParsed>:
  match object s:
    case True{} SCon{Chr{125},t}: Some{JParsed{JObject{Nil{},Nil{}},t}}
    case False{} SCon{Chr{93},t}: Some{JParsed{JItems{Nil{}},t}}
    case _ _: next(s)

def value_start(s: String, next: U32 -> List<&2,String> -> List<&2,Value> -> String -> Maybe<&2,JParsed>) -> Maybe<&2,JParsed>:
  match s:
    case SCon{Chr{34},t}: string(65536n,t,"")
    case SCon{Chr{91},t}: container(False{},skip(t),xs => next(2,Nil{},Nil{},xs))
    case SCon{Chr{123},t}: container(True{},skip(t),xs => next(1,Nil{},Nil{},xs))
    case _: atom_scan(s,"")

def task(mode: U32, keys: List<&2,String>, vals: List<&2,Value>, s: String, child: String -> Maybe<&2,JParsed>, next: U32 -> List<&2,String> -> List<&2,Value> -> String -> Maybe<&2,JParsed>) -> Maybe<&2,JParsed>:
  match mode:
    case 0: value_start(skip(s),next)
    case 1: member(True{},keys,vals,s,child,ks => vs => t => next(1,ks,vs,t))
    case _: member(False{},keys,vals,s,child,ks => vs => t => next(2,ks,vs,t))

def parse_task(fuel: Nat, mode: U32, keys: List<&2,String>, vals: List<&2,Value>, s: String) -> Maybe<&2,JParsed>:
  match fuel:
    case 0n: None{}
    case 1n+p0:
      +p = p0
      task(mode,keys,vals,s,t => parse_task(p,0,Nil{},Nil{},t),m => ks => vs => t => parse_task(p,m,ks,vs,t))

def finished_tail(value: Value, rest: String) -> Maybe<&2,Value>:
  match rest:
    case SNil{}: Some{value}
    case _: None{}

def finished(parsed: Maybe<&2,JParsed>) -> Maybe<&2,Value>:
  match parsed:
    case None{}: None{}
    case Some{JParsed{value,rest}}: finished_tail(value,skip(rest))

def parse(s: String) -> Maybe<&2,Value>:
  finished(parse_task(65536n,0,Nil{},Nil{},s))
