# Law patterns

A law declares the required proposition. A def supplies its evidence. An executable IO demo alone is not a universal proof.

| Requirement | Pattern | Counterexample to exclude |
|---|---|---|
| Functional behavior | Exported function equals independent specification, for every admitted input | A proved model disconnected from production |
| Useful success | Valid inputs produce the required result | Always reject |
| Accounting | Spent plus remaining equals initial allowance | Reset or manufacture remaining budget |
| Composition | Producer output satisfies consumer input, and the composite preserves the invariant | Two individually valid stages overspend together |
| Refinement | Representation conversion preserves the relevant meaning | Correct algorithm over the wrong byte order |
| Admission | Accepted candidate carries evidence of the exact proposition | Constructor tag used as a certificate |

This starter implements the first four at the scopes listed in SPEC.md. It does not implement deduction checking, arbitrary realizer extraction, posterior weighting or a general search language.

## Receipt composition

The constructor's balance field is dependent on its fields and allowance. A fabricated `Receipt<0n>` containing spent=1 and remaining=0 requires an impossible equality. `then` consumes a receipt and passes only its remaining Nat to a continuation. The continuation returns another balanced receipt for that remaining allowance. Associativity and equality substitution combine the two balances.

A caller can construct another unrelated empty receipt for the same numeric allowance. Therefore this is not a globally unique spending capability. Enforcing global budgets requires an owner outside the candidate, such as a trusted process supervisor.
