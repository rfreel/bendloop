import Base
import ./runtime.bend as C
import ./LAWS.bend as Laws
import ../interpreter/runtime.bend as R
import ../interpreter/bridge.bend as B
import ../interpreter/LAWS.bend as I
import ../interpreter/PROOF.bend as IP
import ../spec/model.bend as M

def Laws.certification_sound(reference,candidate,certificate,input):
  C.sound(reference,candidate,certificate,input)

def Laws.certification_complete(reference,candidate,all):
  C.complete_result(reference,candidate,C.certify(reference,candidate),all)

def Laws.model_equivalent(reference,candidate,certificate,input):
  Equal.trans(Word(4n),M.eval(B.model(reference),B.word(input)),B.word(R.eval(candidate,input)),M.eval(B.model(candidate),B.word(input)),
    I.result_reflect(reference,input,B.word(R.eval(candidate,input)),
      Equal.cong(R.Bits,Word(4n),B.word,R.eval(reference,input),R.eval(candidate,input),C.sound(reference,candidate,certificate,input))),
    I.eval_refines(candidate,input))

def Laws.certified_result(reference,candidate,certificate,input,output,expected):
  I.result_transport(candidate,input,output,
    Equal.trans(Word(4n),M.eval(B.model(candidate),B.word(input)),M.eval(B.model(reference),B.word(input)),output,
      Equal.sym(Word(4n),M.eval(B.model(reference),B.word(input)),M.eval(B.model(candidate),B.word(input)),
        Laws.model_equivalent(reference,candidate,certificate,input)),expected))

def Laws.accepts_self(expr):
  Laws.certification_complete(expr,expr,+input => {==})

def Laws.rejects_wrong_constant():
  {==}
