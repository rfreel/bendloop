import Base
import ./runtime.bend as Policy
import ./experiment.bend as E
import ./learning.bend as L
import ../interpreter/runtime.bend as R

# Protected tasks deliberately recur to measure retention. Learning and test
# references cannot recur across the three experimental partitions.
def append(xs: +List<R.Expr>,+ys: +List<R.Expr>) -> +List<R.Expr>:
  match xs:
    case Nil{}: ys
    case Con{x,tail}: x <> append(tail,ys)
def references(xs: +List<E.Task>) -> +List<R.Expr>:
  match xs:
    case Nil{}: Nil{}
    case Con{E.Task{r,ops,bound,cap},tail}: r <> references(tail)
def episodes(xs: +List<L.Episode>) -> +List<R.Expr>:
  match xs:
    case Nil{}: Nil{}
    case Con{L.Episode{E.Task{r,ops,bound,cap},transfer,protected,budget},tail}:
      r <> append(references(transfer),episodes(tail))
def absent(+x: R.Expr,xs: +List<R.Expr>) -> Bool:
  match xs:
    case Nil{}: True{}
    case Con{y,tail}: Bool.not(Policy.expr_same(x,y)) && absent(x,tail)
def disjoint(xs: +List<R.Expr>,+ys: +List<R.Expr>) -> Bool:
  match xs:
    case Nil{}: True{}
    case Con{x,tail}: absent(x,ys) && disjoint(tail,ys)
def unique(xs: +List<R.Expr>) -> Bool:
  match xs:
    case Nil{}: True{}
    case Con{x,+tail}: absent(x,tail) && unique(tail)
def partitions(+a: +List<R.Expr>,+b: +List<R.Expr>,+c: +List<R.Expr>) -> Bool:
  unique(a) && unique(b) && unique(c) && disjoint(a,b) && disjoint(a,c) && disjoint(b,c)
def guards(xs: +List<L.Episode>) -> +List<R.Expr>:
  match xs:
    case Nil{}: Nil{}
    case Con{L.Episode{training,transfer,protected,budget},tail}:
      append(references(protected),guards(tail))
def checked(+a: +List<R.Expr>,+b: +List<R.Expr>,+c: +List<R.Expr>,+guard: +List<R.Expr>) -> Bool:
  partitions(a,b,c) && disjoint(a,guard) && disjoint(b,guard) && disjoint(c,guard)
def valid(+a: +List<L.Episode>,+b: +List<L.Episode>,c: +List<E.Task>,guard: +List<E.Task>) -> Bool:
  checked(episodes(a),episodes(b),references(c),append(guards(a),append(guards(b),references(guard))))
