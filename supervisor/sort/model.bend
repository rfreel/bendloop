import Base

type Record is Data:
  Record{date: Nat,id: Nat,value: Nat}
type Rows is Data:
  Rows{r0: Record,r1: Record,r2: Record,r3: Record,r4: Record,r5: Record,r6: Record,r7: Record}
def date(r: Record) -> Nat:
  Record{d,i,v} = r
  d
def id(r: Record) -> Nat:
  Record{d,i,v} = r
  i
def same(a: Record,b: Record) -> Bool:
  Record{ad,ai,av} = a
  Record{bd,bi,bv} = b
  Nat.is_eq(ad,bd) && Nat.is_eq(ai,bi) && Nat.is_eq(av,bv)
def flag(b: Bool) -> Nat:
  match b:
    case False{}: 0n
    case True{}: 1n
def count(+rows: Rows,+record: Record) -> Nat:
  Rows{r0,r1,r2,r3,r4,r5,r6,r7} = rows
  Nat.add(flag(same(r0,record)),Nat.add(flag(same(r1,record)),Nat.add(flag(same(r2,record)),Nat.add(flag(same(r3,record)),Nat.add(flag(same(r4,record)),Nat.add(flag(same(r5,record)),Nat.add(flag(same(r6,record)),flag(same(r7,record)))))))))
def ordered(rows: Rows) -> Bool:
  Rows{+r0,+r1,+r2,+r3,+r4,+r5,+r6,+r7} = rows
  Nat.is_le(date(r0),date(r1)) && Nat.is_le(date(r1),date(r2)) && Nat.is_le(date(r2),date(r3)) && Nat.is_le(date(r3),date(r4)) && Nat.is_le(date(r4),date(r5)) && Nat.is_le(date(r5),date(r6)) && Nat.is_le(date(r6),date(r7))
def preserved(+reference: Rows,+candidate: Rows) -> Bool:
  Rows{+r0,+r1,+r2,+r3,+r4,+r5,+r6,+r7} = reference
  Nat.is_eq(count(reference,r0),count(candidate,r0)) && Nat.is_eq(count(reference,r1),count(candidate,r1)) && Nat.is_eq(count(reference,r2),count(candidate,r2)) && Nat.is_eq(count(reference,r3),count(candidate,r3)) && Nat.is_eq(count(reference,r4),count(candidate,r4)) && Nat.is_eq(count(reference,r5),count(candidate,r5)) && Nat.is_eq(count(reference,r6),count(candidate,r6)) && Nat.is_eq(count(reference,r7),count(candidate,r7))
def inversion(+a: Record,+b: Record) -> Nat:
  flag(Nat.is_eq(date(a),date(b)) && Nat.is_gt(id(a),id(b)))
def quality(rows: Rows) -> Nat:
  Rows{+r0,+r1,+r2,+r3,+r4,+r5,+r6,+r7} = rows
  Nat.add(inversion(r0,r1),Nat.add(inversion(r0,r2),Nat.add(inversion(r0,r3),Nat.add(inversion(r0,r4),Nat.add(inversion(r0,r5),Nat.add(inversion(r0,r6),Nat.add(inversion(r0,r7),Nat.add(inversion(r1,r2),Nat.add(inversion(r1,r3),Nat.add(inversion(r1,r4),Nat.add(inversion(r1,r5),Nat.add(inversion(r1,r6),Nat.add(inversion(r1,r7),Nat.add(inversion(r2,r3),Nat.add(inversion(r2,r4),Nat.add(inversion(r2,r5),Nat.add(inversion(r2,r6),Nat.add(inversion(r2,r7),Nat.add(inversion(r3,r4),Nat.add(inversion(r3,r5),Nat.add(inversion(r3,r6),Nat.add(inversion(r3,r7),Nat.add(inversion(r4,r5),Nat.add(inversion(r4,r6),Nat.add(inversion(r4,r7),Nat.add(inversion(r5,r6),Nat.add(inversion(r5,r7),inversion(r6,r7))))))))))))))))))))))))))))
def record_tokens(r: Record) -> String:
  Record{d,i,v} = r
  Nat.show(d) ++ "," ++ Nat.show(i) ++ "," ++ Nat.show(v)
def tokens(rows: Rows) -> String:
  Rows{r0,r1,r2,r3,r4,r5,r6,r7} = rows
  record_tokens(r0) ++ "," ++ record_tokens(r1) ++ "," ++ record_tokens(r2) ++ "," ++ record_tokens(r3) ++ "," ++ record_tokens(r4) ++ "," ++ record_tokens(r5) ++ "," ++ record_tokens(r6) ++ "," ++ record_tokens(r7)
def parse(values: List<&2,U32>) -> Maybe<&2,Rows>:
  match values:
    case Con{v0,Con{v1,Con{v2,Con{v3,Con{v4,Con{v5,Con{v6,Con{v7,Con{v8,Con{v9,Con{v10,Con{v11,Con{v12,Con{v13,Con{v14,Con{v15,Con{v16,Con{v17,Con{v18,Con{v19,Con{v20,Con{v21,Con{v22,Con{v23,Nil{}}}}}}}}}}}}}}}}}}}}}}}}}: Some{Rows{Record{U32.to_nat(v0),U32.to_nat(v1),U32.to_nat(v2)},Record{U32.to_nat(v3),U32.to_nat(v4),U32.to_nat(v5)},Record{U32.to_nat(v6),U32.to_nat(v7),U32.to_nat(v8)},Record{U32.to_nat(v9),U32.to_nat(v10),U32.to_nat(v11)},Record{U32.to_nat(v12),U32.to_nat(v13),U32.to_nat(v14)},Record{U32.to_nat(v15),U32.to_nat(v16),U32.to_nat(v17)},Record{U32.to_nat(v18),U32.to_nat(v19),U32.to_nat(v20)},Record{U32.to_nat(v21),U32.to_nat(v22),U32.to_nat(v23)}}}
    case _: None{}

type Missing is Data:
  Missing{record: Record,expected: Nat,observed: Nat}
def missing_if(+record: Record,+expected: Nat,+observed: Nat,ok: Bool,next: Unit -> Maybe<&2,Missing>) -> Maybe<&2,Missing>:
  match ok:
    case True{}: next(Unit{})
    case False{}: Some{Missing{record,expected,observed}}
def missing_one(+reference: Rows,+candidate: Rows,+record: Record,next: Unit -> Maybe<&2,Missing>) -> Maybe<&2,Missing>:
  +expected = count(reference,record)
  +observed = count(candidate,record)
  missing_if(record,expected,observed,Nat.is_eq(expected,observed),next)
def missing(+reference: Rows,+candidate: Rows) -> Maybe<&2,Missing>:
  Rows{r0,r1,r2,r3,r4,r5,r6,r7} = reference
  missing_one(reference,candidate,r0,u => missing_one(reference,candidate,r1,u => missing_one(reference,candidate,r2,u => missing_one(reference,candidate,r3,u => missing_one(reference,candidate,r4,u => missing_one(reference,candidate,r5,u => missing_one(reference,candidate,r6,u => missing_one(reference,candidate,r7,u => None{}))))))))
type Unordered is Data:
  Unordered{index: Nat,left: Record,right: Record}
def unordered_if(index: Nat,left: Record,right: Record,ok: Bool,next: Unit -> Maybe<&2,Unordered>) -> Maybe<&2,Unordered>:
  match ok:
    case True{}: next(Unit{})
    case False{}: Some{Unordered{index,left,right}}
def unordered_pair(index: Nat,+left: Record,+right: Record,next: Unit -> Maybe<&2,Unordered>) -> Maybe<&2,Unordered>:
  unordered_if(index,left,right,Nat.is_le(date(left),date(right)),next)
def unordered(rows: Rows) -> Maybe<&2,Unordered>:
  Rows{+r0,+r1,+r2,+r3,+r4,+r5,+r6,+r7} = rows
  unordered_pair(0n,r0,r1,u => unordered_pair(1n,r1,r2,u => unordered_pair(2n,r2,r3,u => unordered_pair(3n,r3,r4,u => unordered_pair(4n,r4,r5,u => unordered_pair(5n,r5,r6,u => unordered_pair(6n,r6,r7,u => None{})))))))
type Slot is Data:
  Slot0{}
  Slot1{}
  Slot2{}
  Slot3{}
  Slot4{}
  Slot5{}
  Slot6{}
  Slot7{}
def record_at(rows: Rows,slot: Slot) -> Record:
  Rows{r0,r1,r2,r3,r4,r5,r6,r7} = rows
  match slot:
    case Slot0{}: r0
    case Slot1{}: r1
    case Slot2{}: r2
    case Slot3{}: r3
    case Slot4{}: r4
    case Slot5{}: r5
    case Slot6{}: r6
    case Slot7{}: r7
