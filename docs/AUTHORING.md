# Adapting the starter

1. State the actual public interface, admitted inputs, error behavior, result and resource metric in SPEC.md. List external standards or references when applicable.
2. Write an independent, simple executable specification under spec/. Do not have it call src/.
3. State universal public-API laws in LAWS.bend. Include positive success obligations: refusal of every input must not pass. For parsers, define malformed input behavior; for collections, preserve elements as well as ordering; for stateful programs, prove allowed transitions and their composition.
4. Reuse core/receipt.bend only when additive, nonnegative accounting fits. Its type ensures a sum identity, not provenance, uniqueness, physical expenditure or progress. Add task-specific refinements to establish those properties.
5. Implement src/ and supporting proofs. PROOF.bend must import LAWS.bend and fill each law. Keep ordinary IO in the entry adapter.
6. Supply independent test outputs and wrong implementations that should fail. Update mutation anchors when the implementation shape changes, as an explicit harness change. An invalid anchor is an infrastructure error, never a pass.
7. Review the exact specification, trusted boundary and completion criteria. After authorization, update acceptance/protected.json from the protected file set. Never update it as an automatic response to a failed check.
8. Run scripts/verify.py from a clean checkout; preserve its receipt. Only then consider publication or a new autonomous run.

The ordinary agent is the search procedure. Start with one concrete hypothesis, run a fast check, use the diagnostic to repair the candidate, then run the complete gate. Adding an orchestrator should solve an actual coordination need.
