(**
This file is part of the CoqApprox formalization of rigorous
polynomial approximation in Coq:
http://tamadi.gforge.inria.fr/CoqApprox/

Copyright (c) 2010-2014, ENS de Lyon and Inria.

This library is governed by the CeCILL-C license under French law and
abiding by the rules of distribution of free software. You can use,
modify and/or redistribute the library under the terms of the CeCILL-C
license as circulated by CEA, CNRS and Inria at the following URL:
http://www.cecill.info/

As a counterpart to the access to the source code and rights to copy,
modify and redistribute granted by the license, users are provided
only with a limited warranty and the library's author, the holder of
the economic rights, and the successive licensors have only limited
liability. See the COPYING file for more details.
*)

Require Import ZArith Reals Psatz.
Require Import mathcomp.ssreflect.ssreflect mathcomp.ssreflect.ssrbool mathcomp.ssreflect.ssrfun mathcomp.ssreflect.eqtype mathcomp.ssreflect.ssrnat mathcomp.ssreflect.bigop.
Require Import Coquelicot.Coquelicot.
Require Import Interval_missing.
Require Import Interval_xreal.
Require Import Interval_interval.
Require Import Rstruct xreal_ssr_compat taylor_thm.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Local Open Scope nat_scope.

(****************************************************************************)
(** Additional support results on extended reals and/or interval arithmetic *)
(****************************************************************************)

Lemma contains_trans (X : interval) (a b c : ExtendedR) :
  contains X a -> contains X b -> contains (Interval_interval.Ibnd a b) c ->
  contains X c.
Proof.
intros Ha Hb Hc.
destruct a as [|a]; destruct b as [|b]; destruct c as [|c];
  destruct X as [|l u]; trivial.
- now destruct Ha.
- now destruct Ha.
- now destruct Hb.
- destruct l as [|l]; destruct u as [|u]; trivial; simpl in *.
  + now repeat split; apply Rle_trans with (1 := proj2 Hc) (2 := proj2 Hb).
  + now repeat split; apply Rle_trans with (1 := proj1 Ha) (2 := proj1 Hc).
  + split.
    * now apply Rle_trans with (1 := proj1 Ha) (2 := proj1 Hc).
    * now apply Rle_trans with (1 := proj2 Hc) (2 := proj2 Hb).
Qed.

Notation IInan := Interval_interval.Inan (only parsing).

Lemma subset_refl : forall x, subset x x.
Proof.
case => [|l u] =>//=; rewrite /le_lower /le_upper; split.
  by case (-l)%XR => //; apply Rle_refl.
by case u => //; apply Rle_refl.
Qed.

Lemma contains_subset (X Y : interval) :
  (exists t, contains X t) ->
  (forall v : ExtendedR, contains X v -> contains Y v) ->
  subset X Y.
Proof.
case: X =>[|l u]; case: Y =>[|L U] //; first by move=>_ /(_ Xnan); apply.
move=>[t Ht] Hmain.
have {t Ht} [r Hr] : exists r : R, contains (Ibnd l u) (Xreal r).
  exact: contains_not_empty Ht.
have H'r := Hmain _ Hr; split; move: Hmain Hr H'r.
  case: L=>[//|L]; case: l=>[|l] Hmain Hr H'r; first exfalso.
    move/(_ (Xreal (L - 1))): Hmain.
    by move: Hr H'r; rewrite /contains; case: u; intuition psatzl R.
  case/(_ (Xreal l)): Hmain.
    by move: Hr H'r; rewrite /contains; case: u; intuition psatzl R.
  by rewrite /le_lower => top _ /=; psatzl R.
case: U=>[//|U]; case: u=>[|u] Hmain Hr H'r; first exfalso.
  move/(_ (Xreal (U + 1))): Hmain.
  by move: Hr H'r; rewrite /contains; case: l; intuition psatzl R.
case/(_ (Xreal u)): Hmain =>//.
by move: Hr H'r; rewrite /contains; case: l; intuition psatzl R.
Qed.

Definition toR_fun (f : ExtendedR -> ExtendedR) (x : R) : R :=
  proj_fun R0 f x.

Lemma toR_toXreal (f : R -> R) :
  toR_fun (Xlift f) = f.
Proof. done. Qed.

Lemma contains_Xreal (xi : interval) (x : ExtendedR) :
  contains xi x -> contains xi (Xreal (proj_val x)).
Proof. by case: x =>//; case: xi. Qed.

(*******************************************************************************)
(** For convenience, define a predicate [not_empty'] equivalent to [not_empty] *)
(*******************************************************************************)

Definition not_empty' (xi : interval) := exists v : ExtendedR, contains xi v.

Lemma not_emptyE xi : not_empty' xi -> not_empty xi.
Proof.
case: xi =>[|l u] [v Hv]; first by exists R0.
case: v Hv =>[//|r] Hr.
by exists r.
Qed.

Lemma not_empty'E xi : not_empty xi -> not_empty' xi.
Proof.
case=>[r Hr]; by exists (Xreal r).
Qed.

(***************************************************************)
(** Some Reals-based specs to ease the CoqApprox formalization *)
(***************************************************************)

Lemma Xreal_neg x : Xreal (Ropp x) = Xneg (Xreal x).
Proof. done. Qed.

Lemma Xreal_sub x y : Xreal (x - y) = Xsub (Xreal x) (Xreal y).
Proof. done. Qed.

Lemma Xreal_add x y : Xreal (x + y) = Xadd (Xreal x) (Xreal y).
Proof. done. Qed.

(**************************************************************)
(** Some support results relating inequalities and [contains] *)
(**************************************************************)

Definition intvl a b x := (a <= x <= b)%R.

Lemma intvl_connected a b : connected (intvl a b).
Proof.
move=> x y Hx Hy z Hz; split.
- exact: Rle_trans (proj1 Hx) (proj1 Hz).
- exact: Rle_trans (proj2 Hz) (proj2 Hy).
Qed.

Lemma intvl_trans x y a b z :
  intvl a b x -> intvl a b y -> intvl x y z -> intvl a b z.
Proof. by move=> H1 H2 H3; apply: (@intvl_connected a b _ _ H1 H2 _ H3). Qed.

Lemma contains_intvl_trans : forall x y X z,
  contains X (Xreal x) ->
  contains X (Xreal y) ->
  intvl x y z ->
  contains X (Xreal z).
Proof.
clear; move=> x y X z.
rewrite /contains.
case: X => [//|l u].
case: l => [|l]; case: u => [|u]; move=> [H1 H2] [H3 H4] [H5 H6]; split=>//.
exact: Rle_trans H6 H4.
exact: Rle_trans H1 H5.
exact: Rle_trans H1 H5.
exact: Rle_trans H6 H4.
Qed.

Lemma intvl_lx l u x0 :
  intvl l u x0 -> intvl l x0 x0.
Proof. by case=> [H1 H2]; split =>//; apply: Rle_refl. Qed.

Lemma intvl_xu l u x0 :
  intvl l u x0 -> intvl x0 u x0.
Proof. by case=> [H1 H2]; split =>//; apply: Rle_refl. Qed.

Lemma intvl_l l u x0 :
  intvl l u x0 -> intvl l u l.
Proof. by case=> [H1 H2]; split =>//; apply: Rle_refl || apply: Rle_trans H2. Qed.

Lemma intvl_u l u x0 :
  intvl l u x0 -> intvl l u u.
Proof. by case=> [H1 H2]; split =>//; apply: Rle_refl || apply: Rle_trans H2. Qed.

Lemma intvl_lVu l u x0 x :
  intvl l u x -> intvl l u x0 -> intvl l x0 x \/ intvl x0 u x.
Proof.
move=> [H1 H2] [H3 H4].
have [Hle|Hlt] := Rle_lt_dec x x0.
by left.
by move/Rlt_le in Hlt; right.
Qed.

(********************************************)
(** Some support results about monotonicity *)
(********************************************)

Section PredArg.
Variable P : R -> Prop.

Definition Rincr (f : R -> R) :=
  forall x y : R,
  P x -> P y ->
  (x <= y -> f x <= f y)%R.

Definition Rdecr (f : R -> R) :=
  forall x y : R,
  P x -> P y ->
  (x <= y -> f y <= f x)%R.

Definition Rmonot (f : R -> R) :=
  Rincr f \/ Rdecr f.

Definition Rpos_over (g : R -> R) :=
  forall x : R, (P x -> 0 <= g x)%R.

Definition Rneg_over (g : R -> R) :=
  forall x : R, (P x -> g x <= 0)%R.

Definition Rcst_sign (g : R -> R) :=
  Rpos_over g \/ Rneg_over g.

Lemma eq'_Rcst_sign (f g : R -> R) :
  (forall x, P x -> f x = g x) ->
  Rcst_sign f -> Rcst_sign g.
Proof.
move=> H; rewrite /Rcst_sign /Rpos_over /Rneg_over.
by case=> Hf; [left|right] => x Hx; rewrite -H //; apply: Hf.
Qed.

Definition Rderive_over (f f' : R -> R) :=
  forall x : R, P x -> is_derive f x (f' x).

Lemma Rderive_pos_imp_incr (f f' : R -> R) :
  connected P -> Rderive_over f f' -> Rpos_over f' -> Rincr f.
Proof.
rewrite /Rpos_over /Rincr.
move=> Hco Hder H0 x y Hx Hy Hxy; rewrite //=.
eapply (derivable_pos_imp_increasing f f' P) =>//.
move=> r Hr.
move/(_ _ Hr) in Hder.
move/(_ _ Hr) in H0.
split; last by auto with real.
exact/is_derive_Reals.
Qed.

Lemma Rderive_neg_imp_decr (f f' : R -> R) :
  connected P -> Rderive_over f f' -> Rneg_over f' -> Rdecr f.
Proof.
rewrite /Rneg_over /Rdecr.
move=> Hco Hder H0 x y Hx Hy Hxy; rewrite //=.
eapply (derivable_neg_imp_decreasing f f' P) =>//.
move=> r Hr.
move/(_ _ Hr) in Hder.
move/(_ _ Hr) in H0.
split; last by auto with real.
exact/is_derive_Reals.
Qed.

Lemma Rderive_cst_sign (f f' : R -> R) :
  connected P -> Rderive_over f f' -> Rcst_sign f' -> Rmonot f.
Proof.
move=> Hco Hder [H|H].
left; exact: Rderive_pos_imp_incr H.
right; exact: Rderive_neg_imp_decr H.
Qed.

End PredArg.

(********************************************************************)
(** Instantiation of [taylor_thm.Cor_Taylor_Lagrange] for intervals *)
(********************************************************************)

Section NDerive.
Variable xf : ExtendedR -> ExtendedR.
Let f := toR_fun xf.
Let Dn := Derive_n f.
Variable X : interval.
Variable n : nat.
Let dom r := contains X (Xreal r).
Let Hdom : connected dom. Proof (contains_connected _).
Hypothesis Hdef : forall r, dom r -> xf (Xreal r) <> Xnan.
Hypothesis Hder : forall n r, dom r -> ex_derive_n f n r.

Theorem ITaylor_Lagrange x0 x :
  dom x0 ->
  dom x ->
  exists xi : R,
  dom xi /\
  (f x - \big[Rplus/0%R]_(0 <= i < n.+1)
          (Dn i x0 / INR (fact i) * (x - x0)^i))%R =
  (Dn n.+1 xi / INR (fact n.+1) * (x - x0) ^ n.+1)%R /\
  (x <= xi <= x0 \/ x0 <= xi <= x)%R.
Proof.
move=> Hx0 Hx.
case (Req_dec x0 x)=> [->|Hneq].
  exists x; split =>//=; split; last by auto with real.
  rewrite (Rminus_diag_eq x) // Rmult_0_l Rmult_0_r.
  rewrite big_nat_recl // pow_O big1 /Dn /=; try field.
  by move=> i _; rewrite Rmult_0_l Rmult_0_r.
have Hlim x1 x2 : (x1 < x2)%Re -> dom x1 -> dom x2 ->
  forall (k : nat) (r1 : R), (k <= n)%coq_nat ->
  (fun r2 : R => x1 <= r2 <= x2)%Re r1 ->
  derivable_pt_lim (Dn k) r1 (Dn (S k) r1).
  move=> Hx12 Hdom1 Hdom2 k y Hk Hy.
  have Hdy: (dom y) by move: Hdom; rewrite /connected; move/(_ x1 x2); apply.
  by apply/is_derive_Reals/Derive_correct; apply: (Hder k.+1 Hdy).
destruct (total_order_T x0 x) as [[H1|H2]|H3]; last 2 first.
    by case: Hneq.
  have H0 : (x <= x0 <= x0)%Re by auto with real.
  have H : (x <= x <= x0)%Re by auto with real.
  case: (Cor_Taylor_Lagrange x x0 n (fun n r => (Dn n r))
    (Hlim _ _ (Rgt_lt _ _ H3) Hx Hx0) x0 x H0 H) => [c [Hc Hc1]].
  exists c.
  have Hdc : dom c.
    move: Hdom; rewrite /connected; move/(_ x x0); apply=>//.
    by case: (Hc1 Hneq)=> [J|K]; auto with real; psatzl R.
  split=>//; split; last by case:(Hc1 Hneq);rewrite /=; [right|left]; intuition.
  rewrite sum_f_to_big in Hc.
  exact: Hc.
have H0 : (x0 <= x0 <= x)%Re by auto with real.
have H : (x0 <= x <= x)%Re by auto with real.
case: (Cor_Taylor_Lagrange x0 x n (fun n r => Dn n r)
  (Hlim _ _ (Rgt_lt _ _ H1) Hx0 Hx) x0 x H0 H) => [c [Hc Hc1]].
exists c.
have Hdc : dom c.
  move: Hdom; rewrite /connected; move/(_ x0 x); apply=>//.
  by case: (Hc1 Hneq)=> [J|K]; auto with real; psatzl R.
split=>//; split; last by case:(Hc1 Hneq);rewrite /=; [right|left]; intuition.
rewrite sum_f_to_big in Hc.
exact: Hc.
Qed.

End NDerive.

(******************************************************************************)
(** The sequel of the file is parameterized by an implementation of intervals *)
(******************************************************************************)

Module IntervalAux (I : IntervalOps).

Local Notation Ibnd2 x := (I.bnd x x) (only parsing).

Lemma bounded_singleton_contains_lower_upper (X : I.type) :
  I.bounded X = true ->
  contains (I.convert (Ibnd2 (I.lower X))) (I.convert_bound (I.lower X)) /\
  contains (I.convert (Ibnd2 (I.upper X))) (I.convert_bound (I.upper X)).
Proof.
move=> HX.
have [H1 H2] := I.bounded_correct X HX.
have [H1a H1b] := I.lower_bounded_correct X H1.
have [H2a H2b] := I.upper_bounded_correct X H2.
by rewrite !I.bnd_correct /contains H1a H2a; psatzl R.
Qed.

(** The following predicate will be used by [Ztech]. *)
Definition isNNegOrNPos (X : I.type) : bool :=
  if I.sign_large X is Xund then false else true.

Lemma isNNegOrNPos_false (X : I.type) :
  I.convert X = IInan -> isNNegOrNPos X = false.
Proof.
move=> H; rewrite /isNNegOrNPos; have := I.sign_large_correct X.
by case: I.sign_large =>//; rewrite H; move/(_ Xnan I) =>//; case.
Qed.

Lemma bounded_contains_lower (x : ExtendedR) (X : I.type) :
  I.bounded X = true -> contains (I.convert X) x ->
  contains (I.convert X) (Xreal (proj_val (I.convert_bound (I.lower X)))).
Proof.
move=> HX Hx.
have [H1 H2] := I.bounded_correct X HX.
have [H3 H4] := I.lower_bounded_correct X H1.
move: H4 Hx; rewrite /I.bounded_prop =>->.
rewrite -H3 /contains H3.
by case Er : x =>[//|r]; case Es: (I.convert_bound (I.upper X))=>[|s]; lra.
Qed.

(* Erik: May also prove lower/upper-related lemmas involving subset *)

Lemma bounded_contains_upper (X : I.type) (x : ExtendedR) :
  I.bounded X = true -> contains (I.convert X) x ->
  contains (I.convert X) (Xreal (proj_val (I.convert_bound (I.upper X)))).
Proof.
move=> HX Hx.
have [H1 H2] := I.bounded_correct X HX.
have [H3 H4] := I.upper_bounded_correct X H2.
move: H4 Hx; rewrite /I.bounded_prop =>->.
rewrite -H3 /contains H3.
by case Er : x =>[//|r]; case Es : (I.convert_bound (I.lower X)) =>[|s]; lra.
Qed.

Definition gt0 xi : bool :=
  if I.sign_strict xi is Xgt then true else false.

Definition apart0 xi : bool :=
  match I.sign_strict xi with
  | Xlt | Xgt => true
  | _ => false
  end.

Lemma gt0_correct X x :
  contains (I.convert X) (Xreal x) -> gt0 X -> (0 < x)%R.
Proof.
move=> Hx; rewrite /gt0.
have := I.sign_strict_correct X; case: I.sign_strict=>//.
by case/(_ _ Hx) =>/=.
Qed.

Lemma apart0_correct X x :
  contains (I.convert X) (Xreal x) -> apart0 X -> (x <> 0)%R.
Proof.
move=> Hx; rewrite /apart0.
have := I.sign_strict_correct X; case: I.sign_strict=>//;
  by case/(_ _ Hx) =>/=; auto with real.
Qed.

Lemma intvlP X :
  I.bounded X = true ->
  forall x,
  (contains (I.convert X) (Xreal x) <->
   intvl (proj_val (I.convert_bound (I.lower X)))
         (proj_val (I.convert_bound (I.upper X))) x).
Proof.
move/I.bounded_correct => [/I.lower_bounded_correct [Hl H] /I.upper_bounded_correct [Hu _]] x.
by rewrite H Hl Hu.
Qed.

Lemma upper_le (X : I.type) x :
  contains (I.convert X) x -> le_upper x (I.convert_bound (I.upper X)).
Proof.
rewrite I.upper_correct.
case (I.convert X) => // l u /=.
case: x => // x [Hl Hu] //.
Qed.

Lemma lower_le (X : I.type) x :
  contains (I.convert X) x -> le_lower (I.convert_bound (I.lower X)) x.
Proof.
rewrite I.lower_correct.
case (I.convert X) => // l u /=.
case: x => // x [Hl Hu].
case: l Hl => // l Hl /=.
now apply Ropp_le_contravar.
Qed.

(*******************************************************)
(** Support results about [I.midpoint] and [not_empty] *)
(*******************************************************)

Definition Imid i : I.type := I.bnd (I.midpoint i) (I.midpoint i).

Lemma not_empty_Imid (X : I.type) :
  not_empty (I.convert X) -> not_empty (I.convert (Imid X)).
Proof.
case=>[v Hv].
rewrite /Imid I.bnd_correct.
apply: not_emptyE.
exists (I.convert_bound (I.midpoint X)).
red.
have e : exists x : ExtendedR, contains (I.convert X) x by exists (Xreal v).
have [-> _] := I.midpoint_correct X e.
by auto with real.
Qed.

Lemma Imid_subset (X : I.type) :
  not_empty (I.convert X) ->
  subset (I.convert (Imid X)) (I.convert X).
Proof.
case=>[v Hv].
rewrite /Imid I.bnd_correct.
have HX : exists x : ExtendedR, contains (I.convert X) x by exists (Xreal v).
have [-> Hreal] := I.midpoint_correct X HX.
case E: I.convert =>[//|l u].
split.
- have := lower_le Hreal.
  have->: l = Xlower (I.convert X) by rewrite E.
  by rewrite I.lower_correct.
- have := upper_le Hreal.
  have->: u = Xupper (I.convert X) by rewrite E.
  by rewrite I.upper_correct.
Qed.

Lemma Imid_contains (X : I.type) :
  not_empty (I.convert X) ->
  contains (I.convert (Imid X)) (I.convert_bound (I.midpoint X)).
Proof.
move=>[v Hv].
rewrite /Imid I.bnd_correct.
have HX : exists x : ExtendedR, contains (I.convert X) x by exists (Xreal v).
have [-> Hreal] := I.midpoint_correct X HX.
by red; auto with real.
Qed.

Lemma Xreal_Imid_contains (X : I.type) :
  not_empty (I.convert X) ->
  contains (I.convert (Imid X)) (Xreal (proj_val (I.convert_bound (I.midpoint X)))).
Proof.
move=>[v Hv].
rewrite /Imid I.bnd_correct.
have HX : exists x : ExtendedR, contains (I.convert X) x by exists (Xreal v).
have [-> Hreal] := I.midpoint_correct X HX.
by red; auto with real.
Qed.

(******************************************************************************)
(** Correctness predicates dealing with reals only, weaker than [I.extension] *)
(******************************************************************************)

Definition R_extension f fi :=
  forall (b : I.type) (x : R),
    contains (I.convert b) (Xreal x) ->
    contains (I.convert (fi b))
             (Xreal (f x)).

Definition R_extension_2 f fi :=
  forall (ix iy : I.type) (x y : R),
    contains (I.convert ix) (Xreal x) ->
    contains (I.convert iy) (Xreal y) ->
    contains (I.convert (fi ix iy)) (Xreal (f x y)).

Lemma R_div_correct (prec : I.precision) :
  R_extension_2 Rdiv (I.div prec).
Proof.
intros xi yi x y Hx Hy.
move: (I.div_correct prec _ _ _ _ Hx Hy) => /=.
case is_zero => //.
now case I.convert.
Qed.

Lemma R_neg_correct : R_extension Ropp I.neg.
Proof. intros xi x. exact: I.neg_correct. Qed.

Lemma R_sub_correct prec : R_extension_2 Rminus (I.sub prec).
Proof. intros xi yi x y. exact: I.sub_correct. Qed.

Lemma R_add_correct prec : R_extension_2 Rplus (I.add prec).
Proof. intros xi yi x y. exact: I.add_correct. Qed.

Lemma R_mul_correct prec : R_extension_2 Rmult (I.mul prec).
Proof. intros xi yi x y. exact: I.mul_correct. Qed.

Lemma R_sqr_correct prec : R_extension Rsqr (I.sqr prec).
Proof. intros xi x. exact: I.sqr_correct. Qed.

Lemma R_power_int_correct prec (n : Z) :
  R_extension (powerRZ ^~ n) (I.power_int prec ^~ n).
Proof.
intros xi x.
move/(I.power_int_correct prec n) => /=.
case: n => // n.
case is_zero => //.
now case I.convert.
Qed.

Lemma R_from_nat_correct :
  forall (b : I.type) (n : nat),
  contains (I.convert (I.fromZ (Z.of_nat n)))
           (Xreal (INR n)).
Proof. move=> b n; rewrite INR_Z2R; exact: I.fromZ_correct. Qed.

Lemma R_inv_correct : forall prec, R_extension Rinv (I.inv prec).
Proof.
intros prec xi x.
move/(I.inv_correct prec) => /=.
case is_zero => //.
now case I.convert.
Qed.

Lemma R_sqrt_correct : forall prec, R_extension sqrt (I.sqrt prec).
Proof.
intros prec xi x.
move/(I.sqrt_correct prec) => /=.
case is_negative => //.
now case I.convert.
Qed.

Lemma R_cos_correct : forall prec, R_extension cos (I.cos prec).
Proof. intros prec xi x. exact: I.cos_correct. Qed.

Lemma R_sin_correct : forall prec, R_extension sin (I.sin prec).
Proof. intros prec xi x. exact: I.sin_correct. Qed.

Lemma R_tan_correct : forall prec, R_extension tan (I.tan prec).
Proof.
intros prec xi x.
move/(I.tan_correct prec).
unfold Xtan, Xsin, Xcos, Xdiv, Xbind2, Xlift, Xbind.
case is_zero => //.
now case I.convert.
Qed.

Lemma R_atan_correct : forall prec, R_extension atan (I.atan prec).
Proof. intros prec xi x Hx. exact: I.atan_correct Hx. Qed.

Lemma R_exp_correct : forall prec, R_extension exp (I.exp prec).
Proof. intros prec xi x Hx. exact: I.exp_correct Hx. Qed.

Lemma R_ln_correct : forall prec, R_extension ln (I.ln prec).
Proof.
intros prec xi x.
move/(I.ln_correct prec) => /=.
case is_positive => //.
now case I.convert.
Qed.

Lemma R_mask_correct : R_extension_2 (fun c x => c) I.mask.
Proof.
move=> ci xi c x Hc Hx /=.
change (Xreal c) with (Xmask (Xreal c) (Xreal x)).
exact: I.mask_correct.
Qed.

Arguments R_mask_correct [ix iy x] y _ _.

Lemma cont0 : contains (I.convert I.zero) (Xreal 0).
Proof. by rewrite I.zero_correct //=; split; exact: Rle_refl. Qed.

Lemma only0 v : contains (I.convert I.zero) (Xreal v) -> v = 0%R.
Proof. by rewrite I.zero_correct; case; symmetry; apply Rle_antisym. Qed.

Section PrecArgument.

Variable prec : I.precision.

Lemma mul_0_contains_0_l y Y X :
  contains (I.convert Y) y ->
  contains (I.convert X) (Xreal 0) ->
  contains (I.convert (I.mul prec X Y)) (Xreal 0).
Proof.
move=> Hy H0.
have H0y ry : (Xreal 0) = (Xreal 0 * Xreal ry)%XR by rewrite /= Rmult_0_l.
case: y Hy => [|ry] Hy; [rewrite (H0y 0%R)|rewrite (H0y ry)];
  apply: I.mul_correct =>//.
by case ->: (I.convert Y) Hy.
Qed.

Lemma mul_0_contains_0_r y Y X :
  contains (I.convert Y) y ->
  contains (I.convert X) (Xreal 0) ->
  contains (I.convert (I.mul prec Y X)) (Xreal 0).
Proof.
move=> Hy H0.
have Hy0 ry : (Xreal 0) = (Xreal ry * Xreal 0)%XR by rewrite /= Rmult_0_r.
case: y Hy => [|ry] Hy; [rewrite (Hy0 0%R)|rewrite (Hy0 ry)];
  apply: I.mul_correct=>//.
by case: (I.convert Y) Hy.
Qed.

Lemma pow_contains_0 (X : I.type) (n : Z) :
  (n > 0)%Z ->
  contains (I.convert X) (Xreal 0) ->
  contains (I.convert (I.power_int prec X n)) (Xreal 0).
Proof.
move=> Hn HX.
rewrite (_: (Xreal 0) = (Xpower_int (Xreal 0) n)); first exact: I.power_int_correct.
case: n Hn =>//= p Hp; rewrite pow_ne_zero //.
by zify; auto with zarith.
Qed.

Lemma subset_sub_contains_0 x0 (X0 X : I.type) :
  contains (I.convert X0) x0 ->
  subset (I.convert X0) (I.convert X) ->
  contains (I.convert (I.sub prec X X0)) (Xreal 0).
Proof.
move=> Hx0 Hsub.
  have H1 : contains (I.convert X) x0.
    exact: (subset_contains (I.convert X0)).
have Hs := I.sub_correct prec X X0 x0 x0 H1 Hx0.
case cx0 : x0 Hs Hx0 => [|rx0].
  by case: (I.convert (I.sub prec X X0)).
rewrite (_: Xreal 0 = Xreal rx0 - Xreal rx0)%XR;
  last by rewrite /= Rminus_diag_eq.
by move=>*; apply: I.sub_correct=>//; apply: (subset_contains (I.convert X0)).
Qed.

End PrecArgument.
End IntervalAux.
