import Base

type Priority is Data:
  Original{}
  SeedZero{}
  SeedOnes{}
type Order is Data:
  ZeroFirst{}
  OnesFirst{}
  RootAware{}
type Policy is Data:
  Policy{zero_rule: Bool, ones_rule: Bool, proposals: Order}
