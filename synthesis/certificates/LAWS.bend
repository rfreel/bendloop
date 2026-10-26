import Base
import ./runtime.bend as C
import ../interpreter/runtime.bend as R
import ../interpreter/bridge.bend as B
import ../spec/model.bend as M

law certification_sound:
  for +reference: R.Expr
  for +candidate: R.Expr
  for certificate: C.Certificate<reference,candidate>
  for +input: R.Bits
  {R.eval(reference,input) == R.eval(candidate,input) : R.Bits}

law certification_complete:
  for +reference: R.Expr
  for +candidate: R.Expr
  for all: @+input: R.Bits -> {R.eval(reference,input) == R.eval(candidate,input) : R.Bits}
  {C.accepted(reference,candidate,C.certify(reference,candidate)) == True{} : Bool}

law model_equivalent:
  for +reference: R.Expr
  for +candidate: R.Expr
  for certificate: C.Certificate<reference,candidate>
  for +input: R.Bits
  {M.eval(B.model(reference),B.word(input)) == M.eval(B.model(candidate),B.word(input)) : Word(4n)}

# Explicitly compose the certificate with the reviewed result_transport theorem.
law certified_result:
  for +reference: R.Expr
  for +candidate: R.Expr
  for certificate: C.Certificate<reference,candidate>
  for +input: R.Bits
  for output: Word(4n)
  for expected: {M.eval(B.model(reference),B.word(input)) == output : Word(4n)}
  {B.word(R.eval(candidate,input)) == output : Word(4n)}

law accepts_self:
  for +expr: R.Expr
  {C.accepted(expr,expr,C.certify(expr,expr)) == True{} : Bool}

law rejects_wrong_constant:
  {C.accepted(R.Input{},R.Constant{C.input_0()},C.certify(R.Input{},R.Constant{C.input_0()})) == False{} : Bool}
