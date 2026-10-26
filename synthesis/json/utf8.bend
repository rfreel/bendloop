import Base

def scalar(+c: U32, min: U32) -> Bool:
  Bool.and(U32.is_ge(c,min),Bool.and(U32.is_le(c,1114111),Bool.not(Bool.and(U32.is_ge(c,55296),U32.is_le(c,57343)))))

def emit(ok: Bool, c: U32, s: String, acc: String, next: String -> String -> Maybe<&2,String>) -> Maybe<&2,String>:
  match ok:
    case False{}: None{}
    case True{}: next(s,SCon{Chr{c},acc})

def continuation(ok: Bool, c: U32, tail: String, value: U32, next: U32 -> String -> Maybe<&2,String>) -> Maybe<&2,String>:
  match ok:
    case False{}: None{}
    case True{}: next((value * 64 + c - 128 : U32),tail)

def tail(fuel: Nat, +value: U32, min: U32, s: String, acc: String, next: String -> String -> Maybe<&2,String>) -> Maybe<&2,String>:
  match fuel s:
    case 0n _: emit(scalar(value,min),value,s,acc,next)
    case 1n+p SCon{Chr{+c},t}: continuation(Bool.and(U32.is_ge(c,128),U32.is_le(c,191)),c,t,value,v => xs => tail(p,v,min,xs,acc,next))
    case _ _: None{}

def lead4(ok: Bool, c: U32, s: String, acc: String, next: String -> String -> Maybe<&2,String>) -> Maybe<&2,String>:
  match ok:
    case False{}: None{}
    case True{}: tail(3n,(c - 240 : U32),65536,s,acc,next)

def lead3(ok: Bool, +c: U32, s: String, acc: String, next: String -> String -> Maybe<&2,String>) -> Maybe<&2,String>:
  match ok:
    case True{}: tail(2n,(c - 224 : U32),2048,s,acc,next)
    case False{}: lead4(Bool.and(U32.is_ge(c,240),U32.is_le(c,244)),c,s,acc,next)

def lead2(ok: Bool, +c: U32, s: String, acc: String, next: String -> String -> Maybe<&2,String>) -> Maybe<&2,String>:
  match ok:
    case True{}: tail(1n,(c - 192 : U32),128,s,acc,next)
    case False{}: lead3(Bool.and(U32.is_ge(c,224),U32.is_le(c,239)),c,s,acc,next)

def lead(ok: Bool, +c: U32, s: String, acc: String, next: String -> String -> Maybe<&2,String>) -> Maybe<&2,String>:
  match ok:
    case True{}: next(s,SCon{Chr{c},acc})
    case False{}: lead2(Bool.and(U32.is_ge(c,194),U32.is_le(c,223)),c,s,acc,next)

def decode(fuel: Nat, s: String, acc: String) -> Maybe<&2,String>:
  match fuel s:
    case _ SNil{}: Some{String.reverse(acc)}
    case 0n _: None{}
    case 1n+p SCon{Chr{+c},t}: lead(U32.is_lt(c,128),c,t,acc,xs => a => decode(p,xs,a))

def bytes(xs: List<&2,U32>) -> String:
  match xs:
    case Nil{}: ""
    case Con{h,t}: SCon{Chr{h},bytes(t)}
