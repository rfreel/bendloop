----------------------------- MODULE Supervisor -----------------------------
EXTENDS Naturals, FiniteSets
CONSTANTS Workers, Budget, WorkerBudget, Deadline, MaxEpoch, MaxCrashes, HasFallback, None
ASSUME /\ Workers # {} /\ Budget \in Nat /\ WorkerBudget \in Nat
       /\ Deadline \in Nat /\ MaxEpoch \in Nat /\ MaxCrashes \in Nat
       /\ HasFallback \in BOOLEAN
Artifacts == {"A", "B", "X", "Y"}
Epochs == 0..MaxEpoch
Snapshot(e, a) == [epoch |-> e, artifact |-> a]
Snapshots == [epoch : Epochs, artifact : Artifacts \cup {"base"}]
(* Receiver-owned reference policy, never a worker-supplied approval flag. *)
Required(e, a) == (a = "base") \/ (a = "Y") \/ (a = IF e % 2 = 0 THEN "A" ELSE "B")
Requested(a) == IF a \in {"X", "Y"} THEN {"secret"} ELSE {"report"}
Permitted(e) == {"report"}
Qualified(e, a) == Required(e, a) /\ Requested(a) \subseteq Permitted(e)
Score(a) == CASE a = "A" -> 2 [] a = "B" -> 3 [] a = "base" -> 0 [] OTHER -> 99
Fallback(e) == IF HasFallback THEN Snapshot(e, "base") ELSE None
Messages == [worker : Workers, artifact : Artifacts, claimedEpoch : Epochs, review : BOOLEAN]
Evaluations == [snapshot : Snapshots, qualified : BOOLEAN, score : 0..99]
Effects == [snapshot : Snapshots, operation : {"report", "secret"}]
VARIABLES epoch, stamp, clock, credits, workerSpent, up, crashes,
          inbox, frozen, evaluation, incumbent, pool, prepared, published, effects, outcome, bindings, evaluationsSpent
vars == <<epoch, stamp, clock, credits, workerSpent, up, crashes,
          inbox, frozen, evaluation, incumbent, pool, prepared, published, effects, outcome, bindings, evaluationsSpent>>
Done == outcome # "searching"
Init == /\ epoch = 0 /\ stamp = 0 /\ clock = 0 /\ credits = Budget
        /\ workerSpent = [w \in Workers |-> 0] /\ up = TRUE /\ crashes = 0
        /\ inbox = None /\ frozen = None /\ evaluation = None
        /\ incumbent = Fallback(0) /\ pool = {} /\ prepared = None
        /\ published = None /\ effects = {} /\ outcome = "searching" /\ bindings = {} /\ evaluationsSpent = 0
(* Replayed epoch labels, fabricated reviews and conflicts are arbitrary. *)
Submit == /\ ~Done /\ \E m \in Messages: inbox' = m
          /\ UNCHANGED <<epoch, stamp, clock, credits, workerSpent, up, crashes, frozen, evaluation, incumbent, pool, prepared, published, effects, outcome, bindings, evaluationsSpent>>
WorkerCompute == /\ ~Done /\ clock < Deadline
                 /\ \E w \in Workers:
                      /\ workerSpent[w] < WorkerBudget
                      /\ workerSpent' = [workerSpent EXCEPT ![w] = @ + 1]
                 /\ UNCHANGED <<epoch, stamp, clock, credits, up, crashes, inbox, frozen, evaluation, incumbent, pool, prepared, published, effects, outcome, bindings, evaluationsSpent>>
Freeze == /\ ~Done /\ up /\ clock < Deadline /\ inbox # None
          /\ frozen' = Snapshot(epoch, inbox.artifact) /\ inbox' = None
          (* Outstanding evaluation deliberately survives replacement. *)
          /\ UNCHANGED <<epoch, stamp, clock, credits, workerSpent, up, crashes, evaluation, incumbent, pool, prepared, published, effects, outcome, bindings, evaluationsSpent>>
Evaluate == /\ ~Done /\ up /\ clock < Deadline /\ credits > 0
            /\ frozen # None /\ frozen.epoch = epoch
            /\ evaluation' = [snapshot |-> frozen,
                               qualified |-> Qualified(frozen.epoch, frozen.artifact),
                               score |-> Score(frozen.artifact)]
            /\ credits' = credits - 1 /\ evaluationsSpent' = evaluationsSpent + 1
            /\ UNCHANGED <<epoch, stamp, clock, workerSpent, up, crashes, inbox, frozen, incumbent, pool, prepared, published, effects, outcome, bindings>>
Admit == /\ ~Done /\ up /\ clock < Deadline /\ evaluation # None
         /\ evaluation.snapshot = frozen /\ evaluation.snapshot.epoch = epoch
         /\ evaluation.qualified
         /\ incumbent' = IF incumbent = None THEN evaluation.snapshot
                          ELSE IF evaluation.score > Score(incumbent.artifact)
                               THEN evaluation.snapshot ELSE incumbent
         /\ pool' = pool \cup {evaluation.snapshot}
         /\ bindings' = bindings \cup {[frozen |-> frozen, checked |-> evaluation.snapshot]}
         /\ frozen' = None /\ evaluation' = None
         /\ UNCHANGED <<epoch, stamp, clock, credits, workerSpent, up, crashes, inbox, prepared, published, effects, outcome, evaluationsSpent>>
Prepare == /\ ~Done /\ up /\ incumbent # None /\ prepared # incumbent
           /\ prepared' = incumbent
           /\ UNCHANGED <<epoch, stamp, clock, credits, workerSpent, up, crashes, inbox, frozen, evaluation, incumbent, pool, published, effects, outcome, bindings, evaluationsSpent>>
Commit == /\ ~Done /\ up /\ prepared # None
          /\ prepared.epoch = epoch /\ prepared = incumbent
          /\ Qualified(epoch, prepared.artifact)
          /\ published' = prepared
          /\ effects' = {[snapshot |-> prepared, operation |-> op] : op \in Requested(prepared.artifact)}
          /\ outcome' = "delivered"
          /\ UNCHANGED <<epoch, stamp, clock, credits, workerSpent, up, crashes, inbox, frozen, evaluation, incumbent, pool, prepared, bindings, evaluationsSpent>>
ContractUpdate == /\ ~Done /\ up /\ epoch < MaxEpoch
                  /\ epoch' = epoch + 1 /\ stamp' = stamp + 1
                  /\ incumbent' = Fallback(epoch + 1)
                  (* Retained stale snapshots exercise revocation guards. *)
                  /\ UNCHANGED <<clock, credits, workerSpent, up, crashes, inbox, frozen, evaluation, pool, prepared, published, effects, outcome, bindings, evaluationsSpent>>
Tick == /\ ~Done /\ clock < Deadline /\ clock' = clock + 1
        /\ UNCHANGED <<epoch, stamp, credits, workerSpent, up, crashes, inbox, frozen, evaluation, incumbent, pool, prepared, published, effects, outcome, bindings, evaluationsSpent>>
Failure == /\ ~Done /\ up /\ clock = Deadline /\ incumbent = None
           /\ outcome' = "permitted_failure"
           /\ UNCHANGED <<epoch, stamp, clock, credits, workerSpent, up, crashes, inbox, frozen, evaluation, incumbent, pool, prepared, published, effects, bindings, evaluationsSpent>>
Crash == /\ ~Done /\ up /\ crashes < MaxCrashes /\ up' = FALSE /\ crashes' = crashes + 1
         /\ UNCHANGED <<epoch, stamp, clock, credits, workerSpent, inbox, frozen, evaluation, incumbent, pool, prepared, published, effects, outcome, bindings, evaluationsSpent>>
Recover == /\ ~Done /\ ~up /\ up' = TRUE
           /\ UNCHANGED <<epoch, stamp, clock, credits, workerSpent, crashes, inbox, frozen, evaluation, incumbent, pool, prepared, published, effects, outcome, bindings, evaluationsSpent>>
Next == Submit \/ WorkerCompute \/ Freeze \/ Evaluate \/ Admit \/ Prepare \/ Commit
        \/ ContractUpdate \/ Tick \/ Failure \/ Crash \/ Recover
Spec == Init /\ [][Next]_vars /\ WF_vars(Tick) /\ WF_vars(Recover)
        /\ WF_vars(Prepare) /\ WF_vars(Commit) /\ WF_vars(Failure)
TypeOK == /\ epoch \in Epochs /\ stamp \in Epochs /\ clock \in 0..Deadline
          /\ evaluationsSpent \in 0..Budget /\ credits \in 0..Budget /\ workerSpent \in [Workers -> 0..WorkerBudget]
          /\ up \in BOOLEAN /\ crashes \in 0..MaxCrashes
          /\ inbox \in Messages \cup {None} /\ frozen \in Snapshots \cup {None}
          /\ evaluation \in Evaluations \cup {None}
          /\ incumbent \in Snapshots \cup {None} /\ pool \subseteq Snapshots
          /\ prepared \in Snapshots \cup {None} /\ published \in Snapshots \cup {None}
          /\ bindings \subseteq [frozen : Snapshots, checked : Snapshots]
          /\ effects \subseteq Effects /\ outcome \in {"searching", "delivered", "permitted_failure"}
ExactFrozenEvidence == \A b \in bindings: b.frozen = b.checked
BudgetConservation == evaluationsSpent + credits = Budget
ContractIntegrity == stamp = epoch
EvidenceBinding == evaluation = None \/
                   /\ evaluation.qualified = Qualified(evaluation.snapshot.epoch, evaluation.snapshot.artifact)
                   /\ evaluation.score = Score(evaluation.snapshot.artifact)
Admission == /\ (incumbent = None \/ (incumbent.epoch = epoch /\ Qualified(epoch, incumbent.artifact)))
             /\ \A s \in pool: Qualified(s.epoch, s.artifact)
Winner == incumbent = None \/ \A s \in pool:
          s.epoch = epoch => Score(incumbent.artifact) >= Score(s.artifact)
NoStaleCommit == published = None \/ published.epoch = epoch
EffectConfinement == \A e \in effects:
                     /\ e.snapshot = published /\ e.snapshot.epoch = epoch
                     /\ e.operation \in Permitted(epoch)
                     /\ Qualified(epoch, e.snapshot.artifact)
AtomicPublication == /\ (outcome = "delivered" <=> published # None)
                     /\ (published = None => effects = {})
                     /\ (published # None => effects =
                          {[snapshot |-> published, operation |-> op] : op \in Requested(published.artifact)})
SelectedPublication == published = None \/ published = incumbent
FailureMeaning == outcome = "permitted_failure" => incumbent = None /\ clock = Deadline
Progress == <>Done
=============================================================================
