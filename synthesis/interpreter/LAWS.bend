import Base
import ./runtime.bend as R
import ./bridge.bend as B
import ../spec/model.bend as M

law word_roundtrip:
  for +w: Word(4n)
  {B.word(B.bits(w)) == w : Word(4n)}

law bits_roundtrip:
  for +b: R.Bits
  {B.bits(B.word(b)) == b : R.Bits}

# Constructive loading: every model expression is represented, not only handpicked witnesses.
law load_total:
  for +expr: M.Expr
  {B.model(B.load(expr)) == expr : M.Expr}

law eval_refines:
  for +expr: R.Expr
  for +input: R.Bits
  {B.word(R.eval(expr,input)) == M.eval(B.model(expr),B.word(input)) : Word(4n)}

law cost_refines:
  for +expr: R.Expr
  {R.cost(expr) == M.cost(B.model(expr)) : Nat}

law size_refines:
  for +expr: R.Expr
  {R.size(expr) == M.size(B.model(expr)) : Nat}

# A checked model result transports to the actual interpreter API.
law result_transport:
  for +expr: R.Expr
  for +input: R.Bits
  for output: Word(4n)
  for evidence: {M.eval(B.model(expr),B.word(input)) == output : Word(4n)}
  {B.word(R.eval(expr,input)) == output : Word(4n)}

# This is a source-level theorem, not a machine-code or parser theorem.
law loaded_eval:
  for +expr: M.Expr
  for +input: Word(4n)
  {B.word(R.eval(B.load(expr),B.bits(input))) == M.eval(expr,input) : Word(4n)}

law result_reflect:
  for +expr: R.Expr
  for +input: R.Bits
  for output: Word(4n)
  for evidence: {B.word(R.eval(expr,input)) == output : Word(4n)}
  {M.eval(B.model(expr),B.word(input)) == output : Word(4n)}

law number_refines:
  for +value: R.Bits
  {R.number(value) == U32.from_nat(Word.to_nat(4n,B.word(value))) : U32}

law observed_value:
  for +expr: R.Expr
  for +input: R.Bits
  {R.number(R.eval(expr,input)) == U32.from_nat(Word.to_nat(4n,M.eval(B.model(expr),B.word(input)))) : U32}

law nonvacuous_witness:
  {R.number(R.eval(R.Not{R.Xor{R.Input{},R.Constant{R.Bits{True{},False{},True{},False{}}}}},R.Bits{True{},False{},True{},False{}})) == 15 : U32}
