Require Import Reals Interval.Tactic.

Goal forall x, (0 <= x <= 1 -> 2 <= 3)%R.
Proof.
intros x Hx.
interval with (i_bisect_diff x).
Qed.
