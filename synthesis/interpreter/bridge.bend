import Base
import ./runtime.bend as R
import ../spec/model.bend as M

# Proof-side representation bridge. No runtime import of this module.
def word(bits: R.Bits) -> Word(4n):
  match bits:
    case R.Bits{b0,b1,b2,b3}:
      WCon{b0,WCon{b1,WCon{b2,WCon{b3,WNil{}}}}}

def bits(w: Word(4n)) -> R.Bits:
  match w:
    case WCon{b0,t0}:
      match t0:
        case WCon{b1,t1}:
          match t1:
            case WCon{b2,t2}:
              match t2:
                case WCon{b3,t3}: R.Bits{b0,b1,b2,b3}

def model(expr: R.Expr) -> M.Expr:
  match expr:
    case R.Input{}: M.Input{}
    case R.Constant{value}: M.Constant{word(value)}
    case R.Not{arg}: M.Not{model(arg)}
    case R.And{lhs,rhs}: M.And{model(lhs),model(rhs)}
    case R.Or{lhs,rhs}: M.Or{model(lhs),model(rhs)}
    case R.Xor{lhs,rhs}: M.Xor{model(lhs),model(rhs)}

def load(expr: M.Expr) -> R.Expr:
  match expr:
    case M.Input{}: R.Input{}
    case M.Constant{value}: R.Constant{bits(value)}
    case M.Not{arg}: R.Not{load(arg)}
    case M.And{lhs,rhs}: R.And{load(lhs),load(rhs)}
    case M.Or{lhs,rhs}: R.Or{load(lhs),load(rhs)}
    case M.Xor{lhs,rhs}: R.Xor{load(lhs),load(rhs)}
