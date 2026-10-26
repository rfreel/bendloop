# Preserved checker limitation encountered during proof construction

An initial publication corollary reused the dependent qualification equality in
both components of a product after nested destructuring of `Transition` and
`State`. Stock Bend 2.0.39 rejected translation to its formal kernel with:

```text
SOME PROOFS FAIL
In correct_transition:
expected: an annotated term
observed: λx10 => λx11 => ((λx12 => λx13 => ((task.check x12) x13) x10) x11)
Sorry - this is a mismatch between the TypeScript implementation, and the formalized BendTT kernel. Your proofs may or may not be correct, and we cannot validate them yet. This will be addressed in a future update. Meanwhile, feel free to open an issue to report this bug.
```

The failed proof body was:

```bend
case S.Publish{n,+a,+q,p}:
  match s:
    case S.State{+c,spent,left,conserved,mode,stage,inc}:
      (L.checker_ordered(c,a,q),L.checker_preserved(c,a,q))
```

The shipped proof expresses those same publication obligations as a single Boolean
conjunction equality and consumes the qualification equality once. Both individual
checker corollaries remain separately proved. The complete shipped proof import
graph now returns `ALL PROOFS CHECK` with the stock pinned checker. No checker,
compiler output or kernel was patched, and the earlier rejection is not counted
as a logical counterexample or as accepted evidence.
