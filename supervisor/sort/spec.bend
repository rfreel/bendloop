import Base
import ./model.bend as R

# Reference meaning: each of eight positions contributes exactly one iff all
# record fields match. Field order and summation tree differ from production.
def matches(a: R.Record,b: R.Record) -> Bool:
  R.Record{ad,ai,av} = a
  R.Record{bd,bi,bv} = b
  Nat.is_eq(av,bv) && Nat.is_eq(ai,bi) && Nat.is_eq(ad,bd)
def indicator(b: Bool) -> Nat:
  match b:
    case True{}: 1n
    case False{}: 0n
def count(+rows: R.Rows,+record: R.Record) -> Nat:
  R.Rows{r0,r1,r2,r3,r4,r5,r6,r7} = rows
  Nat.add(Nat.add(Nat.add(indicator(matches(r0,record)),indicator(matches(r1,record))),Nat.add(indicator(matches(r2,record)),indicator(matches(r3,record)))),Nat.add(Nat.add(indicator(matches(r4,record)),indicator(matches(r5,record))),Nat.add(indicator(matches(r6,record)),indicator(matches(r7,record)))))
def ordered(rows: R.Rows) -> Bool:
  R.Rows{R.Record{+d0,i0,v0},R.Record{+d1,i1,v1},R.Record{+d2,i2,v2},R.Record{+d3,i3,v3},R.Record{+d4,i4,v4},R.Record{+d5,i5,v5},R.Record{+d6,i6,v6},R.Record{+d7,i7,v7}} = rows
  Bool.not(Nat.is_gt(d0,d1) || Nat.is_gt(d1,d2) || Nat.is_gt(d2,d3) || Nat.is_gt(d3,d4) || Nat.is_gt(d4,d5) || Nat.is_gt(d5,d6) || Nat.is_gt(d6,d7))
