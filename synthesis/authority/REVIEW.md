# Implementation authority activation

The user's latest instruction authorizes review/freezing and implementation of the four-bit contract.
The authoritative semantics remain exactly those at ed8a575c12ac35ee4d3cc09e79c6dd3114eb69e9.
The historical DRAFT label is retained in the frozen file to avoid changing its reviewed bytes;
this activation record supersedes that status, not its semantic requirements.

Review result: the reference uses four low-to-high bits, total structural evaluation, zero-cost
leaves and one cost per operator; the runtime independently implements each bitwise operation.
The representation round trips and total loader cover every model expression. eval_refines and
observed_value connect the actual runtime to the reference. result_transport and result_reflect
provide both result directions. None claims a binary, JSON parser, search, or certificate theorem.

Freeze the model/specification, interpreter laws and bridge, independent test oracles/cases,
existing harness and tool pins. Runtime and implementation proofs may change only against these
checks. The manifest is copied outside the candidate checkout; the implementation authority uses
that external copy. Modifying a candidate's own copy cannot alter the accepted hashes.

The counter-only gate is not a completion test for the synthesizer. Missing certificate, enumeration,
search, parser or machine obligations remain blockers even if every existing proof is green.
Full task completion additionally requires machine refinement and nonempty machine-loading witnesses.
Native tests, a source proof, a hash, or a theorem about an invented machine do not meet that requirement.
