import Base
import ./runtime.bend as R
import ./bridge.bend as B
import ./LAWS.bend as Laws
import ../spec/model.bend as M

def Laws.word_roundtrip(w):
  match w:
    case WCon{b0,t0}:
      match t0:
        case WCon{b1,t1}:
          match t1:
            case WCon{b2,t2}:
              match t2:
                case WCon{b3,t3}:
                  match t3:
                    case WNil{}: {==}

def Laws.bits_roundtrip(b):
  match b:
    case R.Bits{b0,b1,b2,b3}: {==}

law negate_bridge:
  for +a: R.Bits
  {B.word(R.negate(a)) == Word.not(4n,B.word(a)) : Word(4n)}

def negate_bridge(a):
  match a:
    case R.Bits{a0,a1,a2,a3}: {==}

law conjunction_bridge:
  for +a: R.Bits
  for +b: R.Bits
  {B.word(R.conjunction(a,b)) == Word.and(4n,B.word(a),B.word(b)) : Word(4n)}

def conjunction_bridge(a,b):
  match a b:
    case R.Bits{a0,a1,a2,a3} R.Bits{b0,b1,b2,b3}: {==}

law disjunction_bridge:
  for +a: R.Bits
  for +b: R.Bits
  {B.word(R.disjunction(a,b)) == Word.or(4n,B.word(a),B.word(b)) : Word(4n)}

def disjunction_bridge(a,b):
  match a b:
    case R.Bits{a0,a1,a2,a3} R.Bits{b0,b1,b2,b3}: {==}

law exclusive_or_bridge:
  for +a: R.Bits
  for +b: R.Bits
  {B.word(R.exclusive_or(a,b)) == Word.xor(4n,B.word(a),B.word(b)) : Word(4n)}

def exclusive_or_bridge(a,b):
  match a b:
    case R.Bits{a0,a1,a2,a3} R.Bits{b0,b1,b2,b3}: {==}

def Laws.load_total(expr):
  match expr:
    case M.Input{}: {==}
    case M.Constant{value}:
      %Laws.word_roundtrip(value) : {M.Constant{B.word(B.bits(value))} == M.Constant{_} : M.Expr}
      {==}
    case M.Not{arg}:
      %Laws.load_total(arg) : {M.Not{B.model(B.load(arg))} == M.Not{_} : M.Expr}
      {==}
    case M.And{lhs,rhs}:
      %Laws.load_total(rhs) : {M.And{B.model(B.load(lhs)),B.model(B.load(rhs))} == M.And{lhs,_} : M.Expr}
      %Laws.load_total(lhs) : {M.And{B.model(B.load(lhs)),B.model(B.load(rhs))} == M.And{_,B.model(B.load(rhs))} : M.Expr}
      {==}
    case M.Or{lhs,rhs}:
      %Laws.load_total(rhs) : {M.Or{B.model(B.load(lhs)),B.model(B.load(rhs))} == M.Or{lhs,_} : M.Expr}
      %Laws.load_total(lhs) : {M.Or{B.model(B.load(lhs)),B.model(B.load(rhs))} == M.Or{_,B.model(B.load(rhs))} : M.Expr}
      {==}
    case M.Xor{lhs,rhs}:
      %Laws.load_total(rhs) : {M.Xor{B.model(B.load(lhs)),B.model(B.load(rhs))} == M.Xor{lhs,_} : M.Expr}
      %Laws.load_total(lhs) : {M.Xor{B.model(B.load(lhs)),B.model(B.load(rhs))} == M.Xor{_,B.model(B.load(rhs))} : M.Expr}
      {==}

def Laws.eval_refines(expr,input):
  match expr:
    case R.Input{}: {==}
    case R.Constant{value}: {==}
    case R.Not{arg}:
      %Laws.eval_refines(arg,input) : {B.word(R.negate(R.eval(arg,input))) == Word.not(4n,_) : Word(4n)}
      negate_bridge(R.eval(arg,input))
    case R.And{lhs,rhs}:
      %Laws.eval_refines(rhs,input) : {B.word(R.conjunction(R.eval(lhs,input),R.eval(rhs,input))) == Word.and(4n,M.eval(B.model(lhs),B.word(input)),_) : Word(4n)}
      %Laws.eval_refines(lhs,input) : {B.word(R.conjunction(R.eval(lhs,input),R.eval(rhs,input))) == Word.and(4n,_,B.word(R.eval(rhs,input))) : Word(4n)}
      conjunction_bridge(R.eval(lhs,input),R.eval(rhs,input))
    case R.Or{lhs,rhs}:
      %Laws.eval_refines(rhs,input) : {B.word(R.disjunction(R.eval(lhs,input),R.eval(rhs,input))) == Word.or(4n,M.eval(B.model(lhs),B.word(input)),_) : Word(4n)}
      %Laws.eval_refines(lhs,input) : {B.word(R.disjunction(R.eval(lhs,input),R.eval(rhs,input))) == Word.or(4n,_,B.word(R.eval(rhs,input))) : Word(4n)}
      disjunction_bridge(R.eval(lhs,input),R.eval(rhs,input))
    case R.Xor{lhs,rhs}:
      %Laws.eval_refines(rhs,input) : {B.word(R.exclusive_or(R.eval(lhs,input),R.eval(rhs,input))) == Word.xor(4n,M.eval(B.model(lhs),B.word(input)),_) : Word(4n)}
      %Laws.eval_refines(lhs,input) : {B.word(R.exclusive_or(R.eval(lhs,input),R.eval(rhs,input))) == Word.xor(4n,_,B.word(R.eval(rhs,input))) : Word(4n)}
      exclusive_or_bridge(R.eval(lhs,input),R.eval(rhs,input))

def Laws.cost_refines(expr):
  match expr:
    case R.Input{}: {==}
    case R.Constant{value}: {==}
    case R.Not{arg}:
      %Laws.cost_refines(arg) : {1n+R.cost(arg) == 1n+_ : Nat}
      {==}
    case R.And{lhs,rhs}:
      %Laws.cost_refines(rhs) : {1n+Nat.add(R.cost(lhs),R.cost(rhs)) == 1n+Nat.add(M.cost(B.model(lhs)),_) : Nat}
      %Laws.cost_refines(lhs) : {1n+Nat.add(R.cost(lhs),R.cost(rhs)) == 1n+Nat.add(_,R.cost(rhs)) : Nat}
      {==}
    case R.Or{lhs,rhs}:
      %Laws.cost_refines(rhs) : {1n+Nat.add(R.cost(lhs),R.cost(rhs)) == 1n+Nat.add(M.cost(B.model(lhs)),_) : Nat}
      %Laws.cost_refines(lhs) : {1n+Nat.add(R.cost(lhs),R.cost(rhs)) == 1n+Nat.add(_,R.cost(rhs)) : Nat}
      {==}
    case R.Xor{lhs,rhs}:
      %Laws.cost_refines(rhs) : {1n+Nat.add(R.cost(lhs),R.cost(rhs)) == 1n+Nat.add(M.cost(B.model(lhs)),_) : Nat}
      %Laws.cost_refines(lhs) : {1n+Nat.add(R.cost(lhs),R.cost(rhs)) == 1n+Nat.add(_,R.cost(rhs)) : Nat}
      {==}

def Laws.size_refines(expr):
  match expr:
    case R.Input{}: {==}
    case R.Constant{value}: {==}
    case R.Not{arg}:
      %Laws.size_refines(arg) : {1n+R.size(arg) == 1n+_ : Nat}
      {==}
    case R.And{lhs,rhs}:
      %Laws.size_refines(rhs) : {1n+Nat.add(R.size(lhs),R.size(rhs)) == 1n+Nat.add(M.size(B.model(lhs)),_) : Nat}
      %Laws.size_refines(lhs) : {1n+Nat.add(R.size(lhs),R.size(rhs)) == 1n+Nat.add(_,R.size(rhs)) : Nat}
      {==}
    case R.Or{lhs,rhs}:
      %Laws.size_refines(rhs) : {1n+Nat.add(R.size(lhs),R.size(rhs)) == 1n+Nat.add(M.size(B.model(lhs)),_) : Nat}
      %Laws.size_refines(lhs) : {1n+Nat.add(R.size(lhs),R.size(rhs)) == 1n+Nat.add(_,R.size(rhs)) : Nat}
      {==}
    case R.Xor{lhs,rhs}:
      %Laws.size_refines(rhs) : {1n+Nat.add(R.size(lhs),R.size(rhs)) == 1n+Nat.add(M.size(B.model(lhs)),_) : Nat}
      %Laws.size_refines(lhs) : {1n+Nat.add(R.size(lhs),R.size(rhs)) == 1n+Nat.add(_,R.size(rhs)) : Nat}
      {==}

def Laws.result_transport(expr,input,output,evidence):
  Equal.trans(Word(4n),B.word(R.eval(expr,input)),M.eval(B.model(expr),B.word(input)),output,
    Laws.eval_refines(expr,input),evidence)

def Laws.loaded_eval(expr,input):
  %Laws.word_roundtrip(input) : {B.word(R.eval(B.load(expr),B.bits(input))) == M.eval(expr,_) : Word(4n)}
  %Laws.load_total(expr) : {B.word(R.eval(B.load(expr),B.bits(input))) == M.eval(_,B.word(B.bits(input))) : Word(4n)}
  Laws.eval_refines(B.load(expr),B.bits(input))

def Laws.result_reflect(expr,input,output,evidence):
  Equal.trans(Word(4n),M.eval(B.model(expr),B.word(input)),B.word(R.eval(expr,input)),output,
    Equal.sym(Word(4n),B.word(R.eval(expr,input)),M.eval(B.model(expr),B.word(input)),Laws.eval_refines(expr,input)),evidence)

def Laws.number_refines(value):
  match value:
    case R.Bits{False{},False{},False{},False{}}: {==}
    case R.Bits{False{},False{},False{},True{}}: {==}
    case R.Bits{False{},False{},True{},False{}}: {==}
    case R.Bits{False{},False{},True{},True{}}: {==}
    case R.Bits{False{},True{},False{},False{}}: {==}
    case R.Bits{False{},True{},False{},True{}}: {==}
    case R.Bits{False{},True{},True{},False{}}: {==}
    case R.Bits{False{},True{},True{},True{}}: {==}
    case R.Bits{True{},False{},False{},False{}}: {==}
    case R.Bits{True{},False{},False{},True{}}: {==}
    case R.Bits{True{},False{},True{},False{}}: {==}
    case R.Bits{True{},False{},True{},True{}}: {==}
    case R.Bits{True{},True{},False{},False{}}: {==}
    case R.Bits{True{},True{},False{},True{}}: {==}
    case R.Bits{True{},True{},True{},False{}}: {==}
    case R.Bits{True{},True{},True{},True{}}: {==}

def Laws.observed_value(expr,input):
  %Laws.eval_refines(expr,input) : {R.number(R.eval(expr,input)) == U32.from_nat(Word.to_nat(4n,_)) : U32}
  Laws.number_refines(R.eval(expr,input))

def Laws.nonvacuous_witness():
  {==}
