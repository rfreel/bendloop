# Bounded learning and revision experiment

This extension executes a finite policy language inside Bend. Policies can enable
two structural rule families and revise the order in which they propose later
policies. Every expression candidate is checked against all sixteen four-bit
inputs before acceptance. The proposal language cannot change the evaluator,
protected contract, acceptance criterion or candidate allowance.

Build with the pinned Bend 2.0.39 and Clang 18:

```sh
CC=clang-18 bend synthesis/policy/main.bend -o /tmp/bendloop-policy
/tmp/bendloop-policy experiment +RTS --threads 1 --gpu off -RTS \
  < synthesis/policy/examples/learn-and-revise.json
python3 synthesis/policy/verify.py --tools /path/to/tools
```

The tools directory has the layout used by `scripts/bootstrap.py` and the existing
component verifiers. `PROOF.bend` and `../replay/PROOF.bend` are separate kernel
entry points. Running only the starter gate does not check this extension.

The JSON request contains an initial policy, training episodes, validation
episodes, subsequent-cycle tasks, protected retention tasks and explicit caps.
Each episode gives one adaptation problem, transfer problems, protected problems
and its adaptation proposal allowance. Training chooses a revised proposal
procedure; validation is evaluated after that choice is frozen. Cycle branches
start from the original and revised policies and receive the same task sequence
and revision allowance. No caller-supplied score or acceptance Boolean is read.

The boundary rejects duplicate learning/test references within a partition,
overlap between training, validation and cycle partitions, and overlap of any
such reference with protected tasks. Protected tasks may recur. These checks
establish AST separation, not absence of prior exposure or family novelty.
The caller and an independent experiment custodian remain responsible for
sampling unfamiliar families and withholding external evaluation data.

The example starts both learners with the same rule flags and equal cold costs.
It learns `root-aware` proposal ordering through actual measured proposals.
The revised order can acquire a useful rule on a new form sooner. Inspect
`heldout_learning_comparison` for cold and learned costs and both revision branches
for accepted cost reductions. Full traces include rejected proposals and attempted
expression candidates. Histories are explicitly newest first.

Acceptance priorities are explicit: correctness is required by the certificate;
all measured task costs must be no worse and at least one must be lower. Learning
comparisons additionally require identical starting rule flags and cold costs.
This prevents initial rule coverage from counting as a learning-process gain.
`observed_recursive_gain` requires a held-out learning gain and a larger sum of
accepted cost reductions in subsequent cycles. It describes only that experiment.

Budgets count policy proposals and expression attempts per search. The report
also counts certificate input comparisons and AST nodes visited by those
comparisons. Verification costs include both sides of rejected policy comparisons.
They exclude grammar generation, rule recognition, parsing, printing, checker
builds and physical CPU/memory/money. Equal proposal caps are not equal total
physical development effort. On an infrastructure failure the command exits 1;
it does not return a complete partial ledger. Invalid input exits 2; a normally
completed experiment, including one without improvement, exits 0.

The independent Python oracle supplies test expectations only. Production never
imports it, the reference policy specification, or example answers. The verifier
checks complete native JSON reports, every expression of size at most three under
all twelve policies and selected budgets, and mutations of the actual proof path.

Read [AUDIT.md](AUDIT.md) for unresolved findings. This is a bounded example of
policies revising policies, with two built-in rule schemas. It is not evidence of
open-ended RSI, autonomous discovery of new rule schemas, statistical superiority
on unseen distributions, or full machine-code correctness.
