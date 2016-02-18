(**
This file is part of the Coq.Interval library for proving bounds of
real-valued expressions in Coq: http://coq-interval.gforge.inria.fr/

Copyright (C) 2007-2015, Inria

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

Require Import Reals.
Require Import List.
Require Import Coquelicot.
Require Import Interval_missing.
Require Import ZArith.
Require Import Interval_xreal.
Require Import Interval_definitions.
Require Import Interval_generic.
Require Import Interval_generic_proof.
Require Import Interval_float_sig.
Require Import Interval_interval.
Require Import Interval_interval_float_full.
Require Import Interval_integral.
Require Import Interval_integral_taylor.
Require Import Interval_bisect.
Require Import integrability.
Require Import Interval_transcend.

Module IntervalTactic (F : FloatOps with Definition even_radix := true).

Module T := TranscendentalFloatFast F.

Inductive interval_tac_parameters :=
  | i_prec : nat -> interval_tac_parameters
  | i_bisect : R -> interval_tac_parameters
  | i_bisect_diff : R -> interval_tac_parameters
  | i_bisect_taylor : R -> nat -> interval_tac_parameters
  | i_depth : nat -> interval_tac_parameters
  | i_integral_depth : nat -> interval_tac_parameters
  | i_integral_prec : nat -> interval_tac_parameters
  | i_integral_deg : nat -> interval_tac_parameters. (* degree of taylor models at leaves of integration dichotomy  *)

Module Private.

Module I := FloatIntervalFull F.
Module A := IntervalAlgos I.
Module Int := IntegralTactic F.
Module Int' := IntegralTacticTaylor F.
Module Integrability := Integrability F.

Import Integrability.

Ltac get_float t :=
  let get_mantissa t :=
    let rec aux t :=
      match t with
      | 1%R => xH
      | 2%R => constr:(xO xH)
      | 3%R => constr:(xI xH)
      | (2 * ?v)%R =>
        let w := aux v in constr:(xO w)
      | (1 + 2 * ?v)%R =>
        let w := aux v in constr:(xI w)
      end in
    aux t in
  let get_float_rational s n d :=
    let rec aux t :=
      match t with
      | 2%R => xH
      | (2 * ?v)%R =>
        let w := aux v in
        constr:(Psucc w)
      end in
    let e := aux d in
    let m := get_mantissa n in
    eval vm_compute in (F.fromF (@Interval_generic.Float radix2 s m (Zneg e))) in
  let get_float_integer s t :=
    let rec aux m e :=
      match m with
      | xO ?v =>
        let u := constr:(Zsucc e) in
        aux v u
      | _ => constr:(m, e)
      end in
    let m := get_mantissa t in
    let v := aux m Z0 in
    match v with
    | (?m, ?e) => eval vm_compute in (F.fromF (@Interval_generic.Float radix2 s m e))
    end in
  match t with
  | 0%R => F.zero
  | (-?n * /?d)%R => get_float_rational true n d
  | (?n * /?d)%R => get_float_rational false n d
  | (-?n / ?d)%R => get_float_rational true n d
  | (?n / ?d)%R => get_float_rational false n d
  | (-?n)%R => get_float_integer true n
  | ?n => get_float_integer false n
  | _ => false
  end.

Lemma Rabs_contains :
  forall f v,
  contains (I.convert (I.bnd (F.neg f) f)) (Xreal v) ->
  match F.toF f with
  | Interval_generic.Float false m e => (Rabs v <= FtoR F.radix false m e)%R
  | _ => True
  end.
Proof.
intros f v (H1,H2).
generalize (F.real_correct f).
case_eq (F.toF f) ; try easy.
intros [|] m e Hf _.
exact I.
unfold I.I.convert_bound in H1, H2.
rewrite F.neg_correct in H1.
rewrite Fneg_correct in H1.
rewrite Hf in H1, H2.
simpl in H1, H2.
now apply Rabs_def1_le.
Qed.

Lemma Rabs_contains_rev :
  forall f v,
  match F.toF f with
  | Interval_generic.Float false m e => (Rabs v <= FtoR F.radix false m e)%R
  | _ => False
  end ->
  contains (I.convert (I.bnd (F.neg f) f)) (Xreal v).
Proof.
intros f v.
generalize (F.real_correct f).
case_eq (F.toF f) ; try easy.
intros [|] m e Hf _ H.
easy.
destruct (Rabs_def2_le _ _ H) as (H1,H2).
split ; unfold I.I.convert_bound.
rewrite F.neg_correct.
rewrite Fneg_correct.
now rewrite Hf.
now rewrite Hf.
Qed.

Lemma contains_eval :
  forall prec prog bounds n,
  contains (I.convert (nth n (A.BndValuator.eval prec prog (map A.interval_from_bp bounds)) I.nai)) (Xreal (nth n (eval_real prog (map A.real_from_bp bounds)) R0)).
Proof.
intros prec prog bounds n.
set (xi := nth n (A.BndValuator.eval prec prog (map A.interval_from_bp bounds)) I.nai).
apply (xreal_to_real (fun x => contains (I.convert xi) x) (fun x => contains (I.convert xi) (Xreal x))).
now case (I.convert xi).
easy.
unfold xi.
replace (map Xreal (map A.real_from_bp bounds)) with (map A.xreal_from_bp bounds).
apply A.BndValuator.eval_correct.
clear.
induction bounds.
easy.
simpl.
rewrite IHbounds.
now case a.
Qed.

Lemma contains_bound_lr :
  forall x prec proga boundsa na progb boundsb nb,
  Rle (nth na (eval_real proga (map A.real_from_bp boundsa)) R0) x /\
  Rle x (nth nb (eval_real progb (map A.real_from_bp boundsb)) R0) ->
  contains (I.convert (I.meet (I.upper_extent (nth na (A.BndValuator.eval prec proga (map A.interval_from_bp boundsa)) I.nai)) (I.lower_extent (nth nb (A.BndValuator.eval prec progb (map A.interval_from_bp boundsb)) I.nai)))) (Xreal x).
Proof.
intros x prec proga boundsa na progb boundsb nb [Hx1 Hx2].
generalize (contains_eval prec proga boundsa na).
case (nth na (A.BndValuator.eval prec proga (map A.interval_from_bp boundsa)) I.nai).
easy.
simpl.
intros l _ [Hl _].
generalize (contains_eval prec progb boundsb nb).
case (nth nb (A.BndValuator.eval prec progb (map A.interval_from_bp boundsb)) I.nai).
easy.
simpl.
intros _ u [_ Hu].
rewrite 4!I.I.real_correct.
unfold I.I.convert_bound in *.
rewrite F.nan_correct.
simpl.
split.
case_eq (FtoX (F.toF l)).
intros _.
now rewrite F.nan_correct.
intros lr Hlr.
rewrite Hlr in Hl.
rewrite Hlr.
now apply Rle_trans with (2 := Hx1).
destruct (FtoX (F.toF u)) as [|ur].
exact I.
now apply Rle_trans with (1 := Hx2).
Qed.

Lemma contains_bound_lr' :
  forall x prec proga boundsa na progb boundsb nb,
  let ia := nth na (A.BndValuator.eval prec proga (map A.interval_from_bp boundsa)) I.nai in
  let ib := nth nb (A.BndValuator.eval prec progb (map A.interval_from_bp boundsb)) I.nai in
  I.upper_bounded ia = true ->
  I.lower_bounded ib = true ->
  contains (I.convert (I.bnd (I.upper ia) (I.lower ib))) (Xreal x) ->
  Rle (nth na (eval_real proga (map A.real_from_bp boundsa)) R0) x /\
  Rle x (nth nb (eval_real progb (map A.real_from_bp boundsb)) R0).
Proof.
intros x prec proga boundsa na progb boundsb nb.
generalize (contains_eval prec proga boundsa na) (contains_eval prec progb boundsb nb).
case (nth nb (A.BndValuator.eval prec progb (map A.interval_from_bp boundsb)) I.nai).
easy.
case (nth na (A.BndValuator.eval prec proga (map A.interval_from_bp boundsa)) I.nai).
easy.
intros la ua lb ub [_ Hua] [Hlb _] ia ib.
generalize (I.upper_bounded_correct ia) (I.lower_bounded_correct ib).
unfold ia, ib.
simpl.
case F.real.
2: easy.
case F.real.
2: easy.
intros Ha Hb _ _.
specialize (Ha eq_refl).
specialize (Hb eq_refl).
revert Hua.
destruct Ha as [-> _].
revert Hlb.
destruct Hb as [-> _].
intros H1b H1a [H2 H3].
split.
now apply Rle_trans with (1 := H1a).
now apply Rle_trans with (2 := H1b).
Qed.

Lemma contains_bound_l :
  forall x prec prog bounds n,
  Rle (nth n (eval_real prog (map A.real_from_bp bounds)) R0) x ->
  contains (I.convert (I.upper_extent (nth n (A.BndValuator.eval prec prog (map A.interval_from_bp bounds)) I.nai))) (Xreal x).
Proof.
intros x prec prog bounds n Hx.
generalize (contains_eval prec prog bounds n).
case (nth n (A.BndValuator.eval prec prog (map A.interval_from_bp bounds)) I.nai).
easy.
simpl.
intros l _ [Hl _].
split.
destruct (I.I.convert_bound l) as [|lr].
exact I.
now apply Rle_trans with (2 := Hx).
unfold I.I.convert_bound.
now rewrite F.nan_correct.
Qed.

Lemma contains_bound_l' :
  forall x prec prog bounds n,
  let i := nth n (A.BndValuator.eval prec prog (map A.interval_from_bp bounds)) I.nai in
  I.upper_bounded i = true ->
  contains (I.convert (I.bnd (I.upper i) F.nan)) (Xreal x) ->
  Rle (nth n (eval_real prog (map A.real_from_bp bounds)) R0) x.
Proof.
intros x prec prog bounds n.
generalize (contains_eval prec prog bounds n).
case (nth n (A.BndValuator.eval prec prog (map A.interval_from_bp bounds)) I.nai).
easy.
intros l u [_ Hu].
generalize (I.upper_bounded_correct (Interval_interval_float.Ibnd l u)).
simpl.
case F.real.
2: easy.
intros H _.
specialize (H eq_refl).
revert Hu.
destruct H as [-> _].
intros H1 [H2 H3].
now apply Rle_trans with (1 := H1).
Qed.

Lemma contains_bound_r :
  forall x prec prog bounds n,
  Rle x (nth n (eval_real prog (map A.real_from_bp bounds)) R0) ->
  contains (I.convert (I.lower_extent (nth n (A.BndValuator.eval prec prog (map A.interval_from_bp bounds)) I.nai))) (Xreal x).
Proof.
intros x prec prog bounds n Hx.
generalize (contains_eval prec prog bounds n).
case (nth n (A.BndValuator.eval prec prog (map A.interval_from_bp bounds)) I.nai).
easy.
simpl.
intros _ u [_ Hu].
split.
unfold I.I.convert_bound.
now rewrite F.nan_correct.
destruct (I.I.convert_bound u) as [|ur].
exact I.
now apply Rle_trans with (1 := Hx).
Qed.

Lemma contains_bound_r' :
  forall x prec prog bounds n,
  let i := nth n (A.BndValuator.eval prec prog (map A.interval_from_bp bounds)) I.nai in
  I.lower_bounded i = true ->
  contains (I.convert (I.bnd F.nan (I.lower i))) (Xreal x) ->
  Rle x (nth n (eval_real prog (map A.real_from_bp bounds)) R0).
Proof.
intros x prec prog bounds n.
generalize (contains_eval prec prog bounds n).
case (nth n (A.BndValuator.eval prec prog (map A.interval_from_bp bounds)) I.nai).
easy.
intros l u [Hl _].
generalize (I.lower_bounded_correct (Interval_interval_float.Ibnd l u)).
simpl.
case F.real.
2: easy.
intros H _.
specialize (H eq_refl).
revert Hl.
destruct H as [-> _].
intros H1 [H2 H3].
now apply Rle_trans with (2 := H1).
Qed.

Lemma contains_bound_ar :
  forall x prec prog bounds n,
  Rle (Rabs x) (nth n (eval_real prog (map A.real_from_bp bounds)) R0) ->
  let xi := I.lower_extent (nth n (A.BndValuator.eval prec prog (map A.interval_from_bp bounds)) I.nai) in
  contains (I.convert (I.meet (I.neg xi) xi)) (Xreal x).
Proof.
intros x prec prog bounds n Hx.
generalize (contains_eval prec prog bounds n).
case (nth n (A.BndValuator.eval prec prog (map A.interval_from_bp bounds)) I.nai).
easy.
simpl.
intros _ u [_ Hu].
rewrite 4!I.I.real_correct.
unfold I.I.convert_bound in *.
rewrite 2!F.neg_correct, 2!Fneg_correct.
rewrite F.nan_correct.
simpl.
case_eq (FtoX (F.toF u)).
intros _.
simpl.
now rewrite F.nan_correct.
simpl.
intros ur Hur.
rewrite F.neg_correct, Fneg_correct.
rewrite Hur in Hu.
rewrite Hur.
simpl.
apply Rabs_def2_le.
now apply Rle_trans with (1 := Hx).
Qed.

Lemma contains_bound_ar' :
  forall x prec prog bounds n,
  let i := nth n (A.BndValuator.eval prec prog (map A.interval_from_bp bounds)) I.nai in
  I.lower_bounded i = true ->
  contains (I.convert (let l := I.lower i in I.bnd (F.neg l) l)) (Xreal x) ->
  Rle (Rabs x) (nth n (eval_real prog (map A.real_from_bp bounds)) R0).
Proof.
intros x prec prog bounds n.
generalize (contains_eval prec prog bounds n).
case (nth n (A.BndValuator.eval prec prog (map A.interval_from_bp bounds)) I.nai).
easy.
intros l u [Hl _].
generalize (I.lower_bounded_correct (Interval_interval_float.Ibnd l u)).
simpl.
case F.real.
2: easy.
intros H _.
specialize (H eq_refl).
revert Hl.
destruct H as [Hl _].
unfold I.I.convert_bound in Hl |- *.
rewrite F.neg_correct, Fneg_correct.
rewrite Hl.
intros H1 [H2 H3].
apply Rle_trans with (2 := H1).
apply Rabs_le.
now split.
Qed.

Require Import Ssreflect.ssreflect Ssreflect.ssrfun Ssreflect.ssrbool.
Require Import xreal_ssr_compat.

Section IntegralProg.

Variable prec : F.precision.
Variables prog proga progb : list term.
Variables bounds boundsa boundsb : list A.bound_proof.

Let a := nth 0 (eval_real proga (map A.real_from_bp boundsa)) R0.
Let b := nth 0 (eval_real progb (map A.real_from_bp boundsb)) R0.
Let ia := nth 0 (A.BndValuator.eval prec proga (map A.interval_from_bp boundsa)) I.nai.
Let ib := nth 0 (A.BndValuator.eval prec progb (map A.interval_from_bp boundsb)) I.nai.

Lemma Hconta:  contains (I.convert ia) (Xreal a).
Proof.
by apply: contains_eval.
Qed.

Lemma Hcontb:  contains (I.convert ib) (Xreal b).
Proof.
by apply: contains_eval.
Qed.


Let f := fun x => nth 0 (eval_real prog (x::map A.real_from_bp bounds)) R0.
Let iF := (fun xi => nth 0 (A.BndValuator.eval prec prog (xi::map A.interval_from_bp bounds)) I.nai).

Variable estimator : F.type -> F.type -> I.type.

Hypothesis Hcorrect : Int.integralEstimatorCorrect f estimator.

Lemma all_integrals_correct_prog :
  forall ia ib a b,
   contains (I.convert ia) (Xreal a) ->
   contains (I.convert ib) (Xreal b) ->
notInan (Int.all_integrals prec
                    (fun xi : I.type =>
                     nth 0
                       (A.BndValuator.eval prec prog
                          (xi :: map A.interval_from_bp bounds)) I.nai)
                    ia
                    ib) ->
ex_RInt f a b.
Proof.
move  => ia1 ib1 a1 b1 Hconta1 Hcontb1.
rewrite /Int.all_integrals.
set iFab := (X in Int.EF.I.mul _ X _).
move => HnotInan.
suff HiFNI : notInan iFab =>  [|].
rewrite /f.
move: HiFNI.
rewrite /iFab -/evalInt => HiFNI.
apply: (integrableProg prec _ _ _ _ _ (I.join ia1 ib1)) => //.
move => x Hx.
case: (Rle_dec a1 b1) => [Hleab | Hltba].
- apply: (contains_connected _ a1 b1); try apply: I.join_correct.
  + by left.
  + by right.
  by rewrite Rmin_left // Rmax_right // in Hx.
- have Hltba1 := (Rlt_le _ _  (Rnot_le_lt _ _ Hltba)).
  apply: (contains_connected _ b1 a1); try apply: I.join_correct.
  + by right.
  + by left.
  by rewrite Rmin_right // Rmax_left // in Hx.
rewrite /boundsToInt /evalInt.
move: HnotInan.
by case: (iFab) => //.
Qed.


Lemma Xcmp_rev x y:
  Xcmp y x = match Xcmp x y with
    | Xeq => Xeq
    | Xlt => Xgt
    | Xgt => Xlt
    | Xund => Xund end.
Proof.
case: x; case: y => // rx ry.
rewrite /Xcmp.
by rewrite Rcompare_sym; case: (Rcompare ry rx).
Qed.

Section IntervalMissing.

Lemma ImulcancelRight dummy : Int.EF.I.mul prec dummy Interval_interval_float.Inan = Interval_interval_float.Inan.
Proof.
by case: dummy.
Qed.

Lemma ImulcancelLeft dummy : Int.EF.I.mul prec I.nai dummy = Interval_interval_float.Inan.
Proof.
by case: dummy.
Qed.

Lemma IsubcancelRight dummy : Int.EF.I.sub prec dummy Interval_interval_float.Inan = Interval_interval_float.Inan.
Proof.
by case: dummy.
Qed.

Lemma IsubcancelLeft dummy : Int.EF.I.sub prec I.nai dummy = Interval_interval_float.Inan.
Proof.
by case: dummy.
Qed.

Lemma IaddcancelRight dummy : Int.EF.I.add prec dummy Interval_interval_float.Inan = Interval_interval_float.Inan.
Proof.
by case: dummy.
Qed.

Lemma IaddcancelLeft dummy : Int.EF.I.add prec I.nai dummy = Interval_interval_float.Inan.
Proof.
by case: dummy.
Qed.

End IntervalMissing.

Let integral_float_epsilon' :=
  Int.integral_float_epsilon' prec estimator.

Lemma integral_float_epsilon_real_arguments depth l u epsilon :
  notInan (integral_float_epsilon' depth l u epsilon) -> (F.real l) /\ (F.real u).
Proof.
rewrite /integral_float_epsilon' /Int.integral_float_epsilon'.
by case Hlreal: (F.real l) => [|]; case Hureal: (F.real u) => // .
Qed.

Lemma Fcmp_aux1_not_Xund bb y : Fcmp_aux1 bb y = Xund -> False.
Proof.
by rewrite /Fcmp_aux1; case: (Z.pos bb ?= Z.pos y)%Z .
Qed.

Lemma Fcmp_aux2_not_Xund bb c y z :  Fcmp_aux2 F.radix bb c y z = Xund -> False.
Proof.
rewrite /Fcmp_aux2.
case: (c + Z.pos (count_digits F.radix bb)
      ?= z + Z.pos (count_digits F.radix y))%Z => // .
case: (c - z)%Z=> //.
- by have := Fcmp_aux1_not_Xund bb y.
- by move => p; have := (Fcmp_aux1_not_Xund (shift F.radix bb p) y).
- by move => p; have := (Fcmp_aux1_not_Xund bb (shift F.radix y p)).
Qed.

Lemma Fcmp_not_Xund l u :
  F.real l -> F.real u -> F.cmp l u = Xund -> False.
Proof.
move => Hlreal Hureal.
move: (F.real_correct l).
move: (F.real_correct u).
case Hu : (F.toF u) Hureal => [|| aa bb c] -> => // ;
case Hl : (F.toF l) Hlreal => [|| x y z]-> => // .
- by rewrite F.cmp_correct Hu Hl.
- by rewrite F.cmp_correct Hu Hl /Fcmp; case: x Hl.
- by rewrite F.cmp_correct Hu Hl /Fcmp; by case: aa Hu.
- rewrite F.cmp_correct Hu Hl /Fcmp.
  case: x Hl; case: aa Hu => // .
    by have := (Fcmp_aux2_not_Xund bb c y z).
  by have := (Fcmp_aux2_not_Xund y z bb c).
Qed.

Lemma aux (u0 l1 : F.type) x :
  F.real u0 -> F.real l1 ->
  I.Fle u0 l1 ->
  Rmin (T.toR u0) (T.toR l1) <= x <= Rmax (T.toR u0) (T.toR l1) ->
  contains (I.convert (Interval_interval_float.Ibnd u0 l1)) (Xreal x).
Proof.
move => Fr_u0 Fr_l1; move/Int.EF.F_realP: (Fr_u0) => Hrealu0.
move/Int.EF.F_realP: (Fr_l1) => Hreall1  Horder Hx.
rewrite /Int.EF.I.convert_bound in Hrealu0.
rewrite /Int.EF.I.convert_bound in Hreall1.
have Hleu0l1 : (T.toR u0) <= (T.toR l1) by apply: Int.Fle_Rle.
  have Hcontu0 : contains (I.convert (Interval_interval_float.Ibnd u0 l1))  (Xreal (T.toR u0)).
    rewrite /contains /I.convert /I.I.convert /I.I.convert_bound Hrealu0 Hreall1.
    by split; first exact: Rle_refl.
have Hcontl1 : contains (I.convert (Interval_interval_float.Ibnd u0 l1))  (Xreal (T.toR l1)).
  rewrite /contains /I.convert /I.I.convert /I.I.convert_bound Hrealu0 Hreall1.
  by split; last exact: Rle_refl.
apply: (contains_connected _ (T.toR u0) (T.toR l1)) => // .
rewrite Rmin_left in Hx => // .
by rewrite Rmax_right in Hx => //.
Qed.

Definition ex_RInt_base_case :=
  forall u0 l1,
  F.real u0 ->
  F.real l1 ->
  I.Fle u0 l1 ->
  notInan (estimator u0 l1) ->
  ex_RInt
    (fun x =>
       List.nth
         0
         (eval_real
            prog
            (x::boundsToR bounds)) R0)
    (T.toR u0)
    (T.toR l1).



Let integral_float_epsilon_signed := Int.integral_float_epsilon_signed prec estimator.

Let integral_float_epsilon :=
  Int.integral_float_epsilon prec estimator.

Lemma Fle_true_real u0 l1 : I.Fle u0 l1 -> F.real u0 /\ F.real l1.
Proof.
rewrite /I.Fle.
rewrite F.cmp_correct.
move: (F.real_correct u0) (F.real_correct l1).
case: F.toF => [ | | s0 m0 e0] -> ;
  case: F.toF => [ | | s1 m1 e1] -> ; try easy.
by case s0.
Qed.

Lemma integral_float_epsilon_ex_RInt
      (depth : nat) u0 l1 epsilon :
  ex_RInt_base_case ->
  notInan (integral_float_epsilon depth u0 l1 epsilon) ->
  I.Fle u0 l1 ->
  ex_RInt
    (fun x =>
       List.nth
         0
         (eval_real
            prog
            (x::boundsToR bounds)) R0)
    (T.toR u0)
    (T.toR l1).
Proof.
move => ex_RInt_base_case HnotInan Hleu0l1.
rewrite /integral_float_epsilon in HnotInan (* /Int.integral_float_epsilon *).
have [Hrealu0 Hreall1] := (Fle_true_real u0 l1 Hleu0l1).
elim: depth u0 l1 epsilon Hreall1 Hrealu0 HnotInan Hleu0l1 => [|d HId] u0 l1 epsilon Hreall1 Hrealu0 HnotInan Horder.
- by apply: ex_RInt_base_case => // .
- pose m := I.midpoint (I.bnd u0 l1).
  have Hleu0ml1 := (Int.Fle_Rle u0 l1 Hrealu0 Hreall1 Horder).
  have Hrealm : (F.real m).
    suff: I.convert_bound m = Xreal (T.toR m).
      by move/Int.EF.F_realP.
    have := (I.midpoint_correct ((I.bnd u0 l1))).
      case.
      exists (Xreal (T.toR u0)).
      move: (Int.EF.contains_convert_bnd_l u0 l1 Hrealu0 Hreall1 Hleu0ml1).
      by move/Int.EF.F_realP :Hrealu0 => -> .
    by [].
  (* first we establish a useful inequality on u0, m and l1 *)
  have := (Int.EF.midpoint_bnd_in u0 l1 Hrealu0 Hreall1 Hleu0ml1).
  rewrite -[Int.EF.I.midpoint _]/m.
  move => [Hleu0m Hleml1].
  apply: (ex_RInt_Chasles _ _ (T.toR m)).
  + move: HnotInan.
    rewrite Int.integral_float_epsilon_Sn -[Int.EF.I.midpoint _]/m.
    set b1 := (X in (if X then _ else _)).
    set b2 := (X in (if X then (I.add prec _ _) else _)).
    case Hb1 : b1.
    * by case Hb2 : b2; move => HnotInan;
      apply: (ex_RInt_base_case) => // ;
        try apply: Int.Rle_Fle => // ; move: HnotInan;
      by case:(estimator u0 m).
    * set b3 :=  (X in (if X then _ else _)).
      case Hb3 : b3.
      - set epsilon' := (F.sub_exact _ _); move => HnotInan.
        apply: (HId u0 m epsilon' _ _ _) => // .
          move: HnotInan.
          by case: (Int.integral_float_epsilon prec estimator d u0 m epsilon').
        by apply: Int.Rle_Fle.
      - set epsilon' := (Int.div2 _); move => HnotInan.
        apply: (HId u0 m epsilon' _ _ _) => // .
          move: HnotInan.
          by case: (Int.integral_float_epsilon prec estimator d u0 m epsilon').
        by apply: Int.Rle_Fle.
  + move: HnotInan.
    rewrite Int.integral_float_epsilon_Sn -[Int.EF.I.midpoint _]/m.
    set b1 := (X in (if X then _ else _)).
    set b2 := (X in (if X then (I.add prec _ _) else _)).
    case Hb1 : b1.
    * case Hb2 : b2.
      + move => HnotInan;
      apply: (ex_RInt_base_case) => // .
        by apply: Int.Rle_Fle.
      move: HnotInan.
      by  case:(estimator m l1); case:( estimator u0 m).
      + set epsilon' := (F.sub_exact _ _); move => HnotInan.
        apply: (HId m l1 epsilon' _ _ _) => // .
          move: HnotInan.
          by case: (Int.integral_float_epsilon prec estimator d m l1 epsilon') => // ; rewrite /= IaddcancelRight.
        by apply: Int.Rle_Fle.
    * set b3 :=  (X in (if X then _ else _)).
      case Hb3 : b3.
      - move => HnotInan; apply: (ex_RInt_base_case) => // .
          by apply: Int.Rle_Fle. rewrite -/iF.
           move: HnotInan; case: (estimator m l1) => //.
             by rewrite /= IaddcancelRight.
             set epsilon' := (Int.div2 _); move => HnotInan.
        apply: (HId m l1 epsilon' _ _ _) => // .
          move: HnotInan.
          by case: (Int.integral_float_epsilon prec estimator d m l1 epsilon'); rewrite /= ?IaddcancelRight.
        by apply: Int.Rle_Fle.
Qed.


Lemma integral_float_epsilon'_ex_RInt
      (depth : nat) u0 l1 epsilon :
  ex_RInt_base_case ->
  notInan (integral_float_epsilon' depth u0 l1 epsilon) ->
  I.Fle u0 l1 ->
  ex_RInt
    (fun x =>
       List.nth
         0
         (eval_real
            prog
            (x::boundsToR bounds)) R0)
    (T.toR u0)
    (T.toR l1).
Proof.
rewrite /integral_float_epsilon' /Int.integral_float_epsilon'.
move => ex_RInt_base_case HnotInan Hleu0l1.
have [Hrealu0 Hreall1] := (Fle_true_real u0 l1 Hleu0l1).
move: HnotInan.
rewrite Hrealu0 Hreall1.
case: depth => [|depth].
exact: ex_RInt_base_case.
case: Int.Int.I.Fle.
- exact: ex_RInt_base_case.
- set epsilon1 := (if Int.EF.I.bounded (estimator u0 l1)
          then
           F.mul rnd_UP prec epsilon
             (Int.EF.I.upper (Int.EF.I.abs (estimator u0 l1)))
          else epsilon).
  set arg1 := (X in if true && true then X else _).
  set depth1 := S depth.
  move => HnotInan.
  exact: integral_float_epsilon_ex_RInt HnotInan _.
Qed.

Lemma integral_float_epsilon_signed_ex_RInt
      (depth : nat) u0 l1 epsilon :
  let i := Int.integral_float_epsilon_signed
             prec
             estimator
             depth u0 l1 epsilon
  in
  ex_RInt_base_case ->
  notInan (Int.integral_float_epsilon_signed prec estimator depth u0 l1 epsilon) ->
  ex_RInt
    (fun x =>
       List.nth
         0
         (eval_real
            prog
            (x::boundsToR bounds)) R0)
    (T.toR u0)
    (T.toR l1).
Proof.
move => ex_RInt_base_case i.
rewrite /Int.integral_float_epsilon_signed.
move => HnotInan.
case Horder : (Int.Int.I.Fle  u0 l1) HnotInan => HnotInan.
- exact: integral_float_epsilon'_ex_RInt HnotInan _.
- suff HnotInan2 : notInan (Int.integral_float_epsilon' prec estimator depth l1 u0 epsilon).
  have [Hreall1 Hrealu0] := (integral_float_epsilon_real_arguments depth l1 u0 epsilon HnotInan2).
  apply: ex_RInt_swap.
  apply: integral_float_epsilon'_ex_RInt HnotInan2 _ => //.
  exact: Int.Fle_rev.
- move: HnotInan.
  by case: (Int.integral_float_epsilon' prec estimator depth l1 u0).
Qed.

Lemma integral_epsilon_correct :
  forall (depth : nat) epsilon,
  let i := Int.integral_intBounds_epsilon
             prec
             iF
             estimator depth ia ib epsilon
  in
  ex_RInt_base_case ->
  (notInan i ->
   ex_RInt f a b) /\
  contains (I.convert i) (Xreal (RInt f a b)).
Proof.
move => depth epsilon i ex_RInt_base_case.
case Hibndlu : i =>[|l u]; first by [].
rewrite -Hibndlu.
suff fInt : ex_RInt f a b.
  split => //;  apply: Int.integral_epsilon_correct => // .
  - by move => xi x; apply: contains_eval_arg.
  - by apply: contains_eval.
  - by apply: contains_eval.
rewrite {}/i in Hibndlu.
case Hia : ia Hibndlu => [|l0 u0] Hibndlu;
case Hib : ib Hibndlu => [|l1 u1] => //.
rewrite /Int.integral_intBounds_epsilon /=.
set res := Int.EF.I.add _ _ _.
suff res_ok :
   F.cmp u0 l1 = Xeq \/ F.cmp u0 l1 = Xlt ->
   res = Interval_interval_float.Ibnd l u -> ex_RInt f a b.
    by move: res_ok; case Horder: (F.cmp u0 l1) => //; apply; [left | right].
move=> Horder; rewrite {}/res => Hibndlu.
suff: notInan ((Int.all_integrals prec iF (Interval_interval_float.Ibnd l0 u0)
           (Int.EF.thin u0))) /\
        notInan ((Int.integral_float_epsilon_signed prec estimator depth u0 l1 epsilon)) /\
        notInan ((Int.all_integrals prec iF (Int.EF.thin l1)
        (Interval_interval_float.Ibnd l1 u1))).
  case => HnotInan1.
  case => HnotInan2 HnotInan3.
  have Hint1 : ex_RInt f a (T.toR u0).
    apply: (all_integrals_correct_prog  ia (Int.EF.thin u0) a (T.toR u0)) => // .
    * by apply: contains_eval.
    * by apply: Int.EF.thin_correct_toR.
    * rewrite Hia; exact: HnotInan1.
  have Hint3 : ex_RInt f (T.toR l1) b.
    apply: (all_integrals_correct_prog (Int.EF.thin l1) ib).
    * by apply: Int.EF.thin_correct_toR.
    * by apply: contains_eval.
    * rewrite Hib; exact: HnotInan3.
  have Hint2 : ex_RInt f (T.toR u0) (T.toR l1).
  by apply: (integral_float_epsilon_signed_ex_RInt depth  _ _ epsilon).
  apply: (ex_RInt_Chasles _ _ (T.toR u0)) => //.
  by apply: (ex_RInt_Chasles _ _ (T.toR l1)).
move: Hibndlu.
case: (Int.all_integrals prec iF (Interval_interval_float.Ibnd l0 u0)
      (Int.EF.thin u0)) => // l2 u2 .
case: (Int.integral_float_epsilon_signed prec estimator depth u0 l1) => // l3 u3.
by case: (Int.all_integrals prec iF (Int.EF.thin l1)
        (Interval_interval_float.Ibnd l1 u1)).
Qed.

End IntegralProg.

Section naive_ex_RInt_base_case.

Require Import seq_patch.

Lemma HfiF prec prog bounds :
  let f := fun x => nth 0 (eval_real prog (x::map A.real_from_bp bounds)) R0 in
  let iF := (fun xi => nth 0 (A.BndValuator.eval prec prog (xi::map A.interval_from_bp bounds)) I.nai) in
  forall (xi : Interval_interval_float.f_interval F.type) (x : R),
    contains (Int.EF.I.convert xi) (Xreal x) ->
    contains (Int.EF.I.convert (iF xi)) (Xreal (f x)).
Proof.
by apply: Integrability.contains_eval_arg.
Qed.

Lemma ex_RInt_base_case_naive u0 l1 (prec : F.precision) prog bounds:
  F.real u0 ->
  F.real l1 ->
  I.Fle u0 l1 ->
  let f := fun x => nth 0 (eval_real prog (x::map A.real_from_bp bounds)) R0 in
  let iF := (fun xi => nth 0 (A.BndValuator.eval prec prog (xi::map A.interval_from_bp bounds)) I.nai) in
  notInan (Int.naive_integral prec iF  u0 l1) ->
  ex_RInt
    (fun x =>
       List.nth
         0
         (eval_real
            prog
            (x::boundsToR bounds)) R0)
    (T.toR u0)
    (T.toR l1).
Proof.
move => Hrealu0 Hreall1 Hleu0l1 f iF HnotInan.
apply: (integrableProg prec _ _ _ _ _ (Interval_interval_float.Ibnd u0 l1)).
- move => x; apply: aux => // .
- move: HnotInan; rewrite /Int.naive_integral /=  /iF. set j := nth _ _ _.
  rewrite /boundsToInt.
  by case: j.
Qed.

Lemma ex_RInt_base_case_naive' prec prog bounds :
  let f := fun x => nth 0 (eval_real prog (x::map A.real_from_bp bounds)) R0 in
  let iF := (fun xi => nth 0 (A.BndValuator.eval prec prog (xi::map A.interval_from_bp bounds)) I.nai) in
ex_RInt_base_case prog bounds (Int.naive_integral prec iF).
Proof.
move => f iF.
move => u0 l1 Hleu0l1 HnotInan.
by apply: ex_RInt_base_case_naive.
Qed.

Lemma ex_RInt_base_case_taylor_integral_naive_intersection :
  forall prec deg prog bounds,
  let iF' := fun xi => A.TaylorValuator.TM.get_tm (prec, deg) xi
    (nth 0 (A.TaylorValuator.eval prec deg xi prog (A.TaylorValuator.TM.var ::
        map (fun b => A.TaylorValuator.TM.const (A.interval_from_bp b)) bounds)) A.TaylorValuator.TM.dummy) in
  let iF := fun xi => nth 0 (A.BndValuator.eval prec prog (xi::map A.interval_from_bp bounds)) I.nai in
  let estimator := fun fa fb =>
    let xi := I.bnd fa fb in
    Int'.taylor_integral_naive_intersection prec iF (iF' xi) xi fa fb (Int.EF.thin fa) (Int.EF.thin fb) in
ex_RInt_base_case prog bounds estimator.
Proof.
move => prec deg prog bounds iF' iF estimator.
move => u0 l1 Hu0real Hl1real Hleu0l1.
rewrite /estimator /Int'.taylor_integral_naive_intersection.
move => HnotInan.
apply: (ex_RInt_base_case_naive _ _ prec) => // .
move: HnotInan.
rewrite /iF. replace Int'.IntTac.naive_integral with Int.naive_integral .
by case: (Int.naive_integral prec
        (fun xi : I.type =>
         nth 0
           (A.BndValuator.eval prec prog
              (xi :: map A.interval_from_bp bounds)) I.nai) u0 l1) => // .
by [].
Qed.

End naive_ex_RInt_base_case.

Section Correction_lemmas_integral_for_tactic.

Lemma naive_integral_epsilon_correct :
  forall prec depth proga boundsa progb boundsb prog bounds epsilon,
  let f := fun x => nth 0 (eval_real prog (x::map A.real_from_bp bounds)) R0 in
  let iF := fun xi => nth 0 (A.BndValuator.eval prec prog (xi::map A.interval_from_bp bounds)) I.nai in
  let a := nth 0 (eval_real proga (map A.real_from_bp boundsa)) R0 in
  let b := nth 0 (eval_real progb (map A.real_from_bp boundsb)) R0 in
  let ia := nth 0 (A.BndValuator.eval prec proga (map A.interval_from_bp boundsa)) I.nai in
  let ib := nth 0 (A.BndValuator.eval prec progb (map A.interval_from_bp boundsb)) I.nai in
  let estimator := Int.naive_integral prec iF in
  let i := Int.integral_intBounds_epsilon prec iF estimator depth ia ib epsilon in
  (notInan i ->
   ex_RInt f a b) /\
  contains (I.convert i) (Xreal (RInt f a b)).
Proof.
move => prec depth proga boundsa progb boundsb prog bounds epsilon f iF a b ia ib estimator i.
apply: integral_epsilon_correct.
apply: Int.naive_integral_correct.
apply: contains_eval_arg.
apply: ex_RInt_base_case_naive'.
Qed.

Lemma taylor_integral_naive_intersection_epsilon_correct :
  forall prec deg depth proga boundsa progb boundsb prog bounds epsilon,
  let f := fun x => nth 0 (eval_real prog (x::map A.real_from_bp bounds)) R0 in
  let iF'' := fun xi =>
    nth 0 (A.TaylorValuator.eval prec deg xi prog (A.TaylorValuator.TM.var ::
      map (fun b => A.TaylorValuator.TM.const (A.interval_from_bp b)) bounds)
) A.TaylorValuator.TM.dummy in
  let iF' := fun xi => A.TaylorValuator.TM.get_tm (prec, deg) xi (iF'' xi) in
  let iF := fun xi => nth 0 (A.BndValuator.eval prec prog (xi::map A.interval_from_bp bounds)) I.nai in
  let a := nth 0 (eval_real proga (map A.real_from_bp boundsa)) R0 in
  let b := nth 0 (eval_real progb (map A.real_from_bp boundsb)) R0 in
  let ia := nth 0 (A.BndValuator.eval prec proga (map A.interval_from_bp boundsa)) I.nai in
  let ib := nth 0 (A.BndValuator.eval prec progb (map A.interval_from_bp boundsb)) I.nai in
  let estimator := fun fa fb =>
    let xi := I.bnd fa fb in
    Int'.taylor_integral_naive_intersection prec iF (iF' xi) xi fa fb (Int.EF.thin fa) (Int.EF.thin fb) in
  let i := Int.integral_intBounds_epsilon prec iF estimator depth ia ib epsilon in
  (notInan i ->
   ex_RInt f a b) /\
  contains (I.convert i) (Xreal (RInt f a b)).
Proof.
move => prec deg depth proga boundsa progb boundsb prog bounds epsilon f iF'' iF' iF a b ia ib estimator i.
apply: integral_epsilon_correct.
move => fa fb Hint Hle Hra Hrb.
apply: (Int'.taylor_integral_naive_intersection_correct prec f) => // .
  move => x xi Hxi.
  by apply (contains_eval_arg prec prog bounds 0).
rewrite /f.
have: (Int'.TM.TMI.i_validTM (Int'.iX0 (I.bnd fa fb)) (Int'.iX (I.bnd fa fb)) (iF' (I.bnd fa fb))
    (fun x => nth 0 (eval_ext prog (x :: map (fun b => Xmask (A.xreal_from_bp b) x) bounds)) Xnan)).
  apply A.TaylorValuator.TM.get_tm_correct.
  apply: A.TaylorValuator.eval_correct_aux.
  exists (Int.EF.T.toR fa).
  split.
  move /Int.EF.F_realP : Hra.
  rewrite -[Int.EF.I.convert_bound]/I.convert_bound => ->.
  apply Rle_refl.
  move /Int.EF.F_realP : Hrb.
  by rewrite -[Int.EF.I.convert_bound]/I.convert_bound => ->.
rewrite /Int'.TM.TMI.i_validTM /Int'.TM.TMI.Aux.eqNai.
case: (Int'.EF.I.convert (taylor_model_int_sharp.error (iF' (I.bnd fa fb)))).
  by case.
move => l u [H1 H2 H3 H4].
split => //.
move => x0 Hx0.
case: (H4 x0 Hx0) => {H4} [Q H4 H4'].
exists Q => //.
move => x Hx.
move: (H1 x Hx) (H4' x Hx) => {H1 H4'}.
rewrite /Xmask /toXreal_fun /interval_compl.toR_fun
  /Interval_xreal_derive.proj_fun /interval_compl.defined.
set bx := A.Bproof x (I.bnd fa fb) Hx.
rewrite -[_::map _ _]/(map _ (bx::_)).
rewrite -[_::map _ _]/(map A.real_from_bp (bx::_)).
case E: (nth 0 _ Xnan) => H.
  by move: (H eq_refl).
rewrite -[Xreal (_ - _)]/(Xsub (Xreal _) (Xreal _)).
rewrite -E.
rewrite (_ : map [eta A.xreal_from_bp] (bx :: bounds) = (map Xreal (map A.real_from_bp (bx :: bounds)))).
exact: (xreal_to_real (fun x => contains _ (Xsub x (Xreal _))) (fun x => contains _ (Xreal (x - _)))).
rewrite map_map.
apply map_ext.
by case.
rewrite -(Int.EF.F_realP _ Hra).
exact: Int.EF.thin_correct.
rewrite -(Int.EF.F_realP _ Hrb).
exact: Int.EF.thin_correct.
split.
  move /Int'.EF.F_realP : Hra => ->.
  apply Rle_refl.
  by move /Int'.EF.F_realP : Hrb => ->.
split.
  by move /Int'.EF.F_realP : Hra => ->.
  move /Int'.EF.F_realP : Hrb => ->.
  apply Rle_refl.
exact: ex_RInt_base_case_taylor_integral_naive_intersection.
Qed.

End Correction_lemmas_integral_for_tactic.

Lemma xreal_to_contains :
  forall prog terms n xi,
  A.check_p (A.subset_check xi) (nth n (eval_ext prog (map Xreal terms)) Xnan) ->
  contains (I.convert xi) (Xreal (nth n (eval_real prog terms) R0)).
Proof.
intros prog terms n xi.
simpl A.check_p.
apply (xreal_to_real (fun x => contains (I.convert xi) x) (fun x => contains (I.convert xi) (Xreal x))).
now case (I.convert xi).
easy.
Qed.

Lemma xreal_to_positive :
  forall prog terms n,
  A.check_p A.positive_check (nth n (eval_ext prog (map Xreal terms)) Xnan) ->
  (0 < nth n (eval_real prog terms) R0)%R.
Proof.
intros prog terms n.
simpl A.check_p.
now apply (xreal_to_real (fun x => match x with Xnan => False | Xreal r => (0 < r)%R end) (fun x => (0 < x)%R)).
Qed.

Lemma xreal_to_nonzero :
  forall prog terms n,
  A.check_p A.nonzero_check (nth n (eval_ext prog (map Xreal terms)) Xnan) ->
  nth n (eval_real prog terms) R0 <> R0.
Proof.
intros prog terms n.
simpl A.check_p.
now apply (xreal_to_real (fun x => match x with Xnan => False | Xreal r => r <> R0 end) (fun x => x <> R0)).
Qed.

Definition toR := I.T.toR.

Inductive expr :=
  | Econst : nat -> expr
  | Eunary : unary_op -> expr -> expr
  | Ebinary : binary_op -> expr -> expr -> expr.

Ltac list_add a l :=
  let rec aux a l n :=
    match l with
    | nil        => constr:(n, cons a l)
    | cons a _   => constr:(n, l)
    | cons ?x ?l =>
      match aux a l (S n) with
      | (?n, ?l) => constr:(n, cons x l)
      end
    end in
  aux a l O.

Ltac reify t l :=
  let rec aux t l :=
    match get_float t with
    | false =>
      let aux_u o a :=
        match aux a l with
        | (?u, ?l) => constr:(Eunary o u, l)
        end in
      let aux_b o a b :=
        match aux b l with
        | (?v, ?l) =>
          match aux a l with
          | (?u, ?l) => constr:(Ebinary o u v, l)
          end
        end in
      match t with
      | Ropp ?a => aux_u Neg a
      | Rabs ?a => aux_u Abs a
      | Rinv ?a => aux_u Inv a
      | Rsqr ?a => aux_u Sqr a
      | Rmult ?a ?a => aux_u Sqr a
      | sqrt ?a => aux_u Sqrt a
      | cos ?a => aux_u Cos a
      | sin ?a => aux_u Sin a
      | tan ?a => aux_u Tan a
      | atan ?a => aux_u Atan a
      | exp ?a => aux_u Exp a
      | ln ?a => aux_u Ln a
      | powerRZ ?a ?b => aux_u (PowerInt b) a
      | pow ?a ?b => aux_u (PowerInt (Z_of_nat b)) a
      | Rplus ?a ?b => aux_b Add a b
      | Rminus ?a ?b => aux_b Sub a b
      | Rplus ?a (Ropp ?b) => aux_b Sub a b
      | Rmult ?a ?b => aux_b Mul a b
      | Rdiv ?a ?b => aux_b Div a b
      | Rmult ?a (Rinv ?b) => aux_b Div a b
      | _ =>
        match list_add t l with
        | (?n, ?l) => constr:(Econst n, l)
        end
      end
    | ?f =>
      let u := constr:(toR f) in
      match list_add u l with
      | (?n, ?l) => constr:(Econst n, l)
      end
    end in
  aux t l.

Ltac list_find1 a l :=
  let rec aux l n :=
    match l with
    | nil       => false
    | cons a _  => n
    | cons _ ?l => aux l (S n)
    end in
  aux l O.

Ltac get_non_constants t :=
  let rec aux t l :=
    match t with
    | Econst _ => l
    | _ =>
      match list_find1 t l with
      | false =>
        let m :=
          match t with
          | Eunary _ ?a => aux a l
          | Ebinary _ ?a ?b => aux a ltac:(aux b l)
          end in
        constr:(cons t m)
      | _ => l
      end
    end in
  aux t (@nil expr).

Ltac list_find2 a l :=
  let rec aux l n :=
    match l with
    | nil       => false
    | cons a _  => n
    | cons _ ?l => aux l (S n)
    end in
  match a with
  | Econst ?n => eval compute in (n + length l)%nat
  | _ => aux l O
  end.

Ltac generate_machine l :=
  let rec aux l q :=
    match l with
    | nil => q
    | cons ?t ?l =>
      let m :=
        match t with
        | Eunary ?o ?a =>
          let u := list_find2 a l in
          constr:(Unary o u)
        | Ebinary ?o ?a ?b =>
          let u := list_find2 a l in
          let v := list_find2 b l in
          constr:(Binary o u v)
        end in
      aux l (cons m q)
    end in
  aux l (@nil term).

Ltac extract_algorithm t l :=
  match reify t l with
  | (Econst ?n, ?lc) =>
    constr:(cons (Forward n) nil, lc)
  | (?t, ?lc) =>
    let lnc := get_non_constants t in
    let lm := generate_machine lnc in
    constr:(lm, lc)
  end.

Ltac xalgorithm_post lx :=
  match goal with
  | |- contains (I.convert ?xi) (Xreal ?y) =>
    match extract_algorithm y lx with
    | (?a, ?b) =>
      let formula := fresh "formula" in
      pose (formula := a) ;
      refine (xreal_to_contains formula b O xi _)
    end
  | |- (0 < ?y)%R =>
    match extract_algorithm y lx with
    | (?a, ?b) =>
      let formula := fresh "formula" in
      pose (formula := a) ;
      refine (xreal_to_positive formula b O _)
    end
  | |- (?y <> 0)%R =>
    match extract_algorithm y lx with
    | (?a, ?b) =>
      let formula := fresh "formula" in
      pose (formula := a) ;
      refine (xreal_to_nonzero formula b O _)
    end
  end.

Ltac list_warn l :=
  let rec aux l :=
    match l with
    | nil => idtac
    | cons ?a ?l => idtac a ; aux l
    end in
  aux l.

Ltac list_warn_rev l :=
  let rec aux l :=
    match l with
    | nil => idtac
    | cons ?a ?l => aux l ; idtac a
    end in
  aux l.

Ltac warn_whole l :=
  match l with
  | nil => idtac
  | cons _ nil =>
    idtac "Warning: Silently use the whole real line for the following term:" ;
    list_warn_rev l ; idtac "You may need to unfold this term."
  | cons _ _ =>
    idtac "Warning: Silently use the whole real line for the following terms:" ;
    list_warn_rev l ; idtac "You may need to unfold some of these terms."
  end.

Ltac get_trivial_bounds l prec :=
  let rec aux l prec :=
    match l with
    | nil => constr:(@nil A.bound_proof)
    | cons ?x ?l =>
      let i :=
      match x with
      | PI => constr:(A.Bproof x (I.pi prec) (I.pi_correct prec))
      | toR ?v =>
        constr:(let f := v in let x := toR f in A.Bproof x (I.bnd f f) (conj (Rle_refl x) (Rle_refl x)))
      end in
      match aux l prec with
      | ?m => constr:(cons i m)
      end
    end in
  aux l prec.

Ltac get_bounds_aux x prec :=
  match goal with
  | H: Rle ?a x /\ Rle x ?b |- _ =>
    let v := get_float a in
    let w := get_float b in
    constr:(A.Bproof x (I.bnd v w) H)
  | H: Rle ?a x /\ Rle x ?b |- _ =>
    let va := extract_algorithm a (@nil R) in
    let vb := extract_algorithm b (@nil R) in
    match va with
    | (?pa, ?la) =>
      let lca := get_trivial_bounds la prec in
      match vb with
      | (?pb, ?lb) =>
        let lcb := get_trivial_bounds lb prec in
        constr:(let proga := pa in let boundsa := lca in let progb := pb in let boundsb := lcb in
          A.Bproof x _ (contains_bound_lr x prec proga boundsa 0 progb boundsb 0 H))
      end
    end
  | H: Rle ?a x |- _ =>
    let v := get_float a in
    constr:(A.Bproof x (I.bnd v F.nan) (conj H I))
  | H: Rle ?a x |- _ =>
    let v := extract_algorithm a (@nil R) in
    match v with
    | (?p, ?l) =>
      let lc := get_trivial_bounds l prec in
      constr:(let prog := p in let bounds := lc in A.Bproof x _ (contains_bound_l x prec prog bounds 0 H))
    end
  | H: Rle x ?b |- _ =>
    let v := get_float b in
    constr:(A.Bproof x (I.bnd F.nan v) (conj I H))
  | H: Rle x ?b |- _ =>
    let v := extract_algorithm b (@nil R) in
    match v with
    | (?p, ?l) =>
      let lc := get_trivial_bounds l prec in
      constr:(let prog := p in let bounds := lc in A.Bproof x _ (contains_bound_r x prec prog bounds 0 H))
    end
  | H: Rle (Rabs x) ?b |- _ =>
    let v := get_float b in
    constr:(A.Bproof x (I.bnd (F.neg v) v) (Rabs_contains_rev v x H))
  | H: Rle (Rabs x) ?b |- _ =>
    let v := extract_algorithm b (@nil R) in
    match v with
    | (?p, ?l) =>
      let lc := get_trivial_bounds l prec in
      constr:(let prog := p in let bounds := lc in A.Bproof x _ (contains_bound_ar x prec prog bounds 0 H))
    end
  end.

Definition reify_var : R.
Proof.
exact R0.
Qed.

Ltac get_RInt_bounds prec rint_depth rint_prec rint_deg x :=
  match x with
  | RInt ?f ?a ?b =>
    let f := eval cbv beta in (f reify_var) in
    let vf := extract_algorithm f (cons reify_var nil) in
    let va := extract_algorithm a (@nil R) in
    let vb := extract_algorithm b (@nil R) in
    match va with
    | (?pa, ?la) =>
      let lca := get_trivial_bounds la prec in
      match vb with
      | (?pb, ?lb) =>
        let lcb := get_trivial_bounds lb prec in
        match vf with
        | (?pf, _ :: ?lf) =>
          let lcf := get_trivial_bounds lf prec in
          let epsilon := constr:(F.scale2 (F.fromZ 1) (F.ZtoS (- Z.of_nat(rint_prec)))) in
          (* let c := constr:(proj2 (naive_integral_epsilon_correct prec rint_depth pa lca pb lcb pf lcf epsilon)) in *)
          (* let c := constr:(proj2 (taylor_integral_correct prec 10%nat rint_depth pa lca pb lcb pf lcf)) in *)
          let c := constr:(proj2 (taylor_integral_naive_intersection_epsilon_correct prec rint_deg rint_depth pa lca pb lcb pf lcf epsilon)) in
          (* work-around for a bug in the pretyper *)
          match type of c with
          | contains (Integrability.I.convert ?i) _ => constr:(A.Bproof x i c, @None R)
          end
        end
      end
    end
  end.

Ltac get_bounds l prec rint_depth rint_prec rint_deg :=
  let rec aux l prec lw :=
    match l with
    | nil => constr:(@nil A.bound_proof, @nil R)
    | cons ?x ?l =>
      let i :=
      match x with
      | PI => constr:(A.Bproof x (I.pi prec) (I.pi_correct prec), @None R)
      | toR ?v =>
        constr:(let f := v in A.Bproof x (I.bnd f f) (conj (Rle_refl x) (Rle_refl x)), @None R)
      | _ => get_RInt_bounds prec rint_depth rint_prec rint_deg x
      | _ =>
        match goal with
        | _ =>
          let v := get_bounds_aux x prec in
          constr:(v, @None R)
        | _ =>
          match goal with
          | H: Rle ?a x /\ Rle x ?b |- _ => idtac
          | H: Rle ?a x |- _ => idtac
          | H: Rle x ?b |- _ => idtac
          | H: Rle (Rabs x) ?b |- _ => idtac
          end ;
          fail 100 "Atom" x "is neither a constant value nor bounded by constant values."
        | _ =>
          constr:(A.Bproof x (I.bnd F.nan F.nan) (conj I I), @Some R x)
        end
      end in
      match aux l prec lw with
      | (?m, ?lw) =>
        match i with
        | (?i, @None R) => constr:(cons i m, lw)
        | (?i, @Some R ?aw) => constr:(cons i m, cons aw lw)
        end
      end
    end in
  aux l prec (@nil R).

Ltac xalgorithm_pre prec :=
  match goal with
  | |- Rge _ _ =>
    apply Rle_ge ;
    xalgorithm_pre prec
  | |- Rgt _ _ =>
    unfold Rgt ;
    xalgorithm_pre prec
  | |- Rle ?a ?x /\ Rle ?x ?b =>
    let v := get_float a in
    let w := get_float b in
    change (contains (I.convert (I.bnd v w)) (Xreal x))
  | |- Rle ?a ?x /\ Rle ?x ?b =>
    let va := extract_algorithm a (@nil R) in
    let vb := extract_algorithm b (@nil R) in
    match va with
    | (?pa, ?la) =>
      let lca := get_trivial_bounds la prec in
      match vb with
      | (?pb, ?lb) =>
        let lcb := get_trivial_bounds lb prec in
        refine (let proga := pa in let boundsa := lca in let progb := pb in let boundsb := lcb in contains_bound_lr' x prec proga boundsa 0 progb boundsb 0 _ _ _) ;
        [ vm_cast_no_check (eq_refl true) | vm_cast_no_check (eq_refl true) | idtac ]
      end
    end
  | |- Rle (Rabs ?a) ?b =>
    let v := get_float b in
    refine (Rabs_contains v a _)
  | |- Rle (Rabs ?a) ?b =>
    let v := extract_algorithm b (@nil R) in
    match v with
    | (?p, ?l) =>
      let lc := get_trivial_bounds l prec in
      refine (let prog := p in let bounds := lc in contains_bound_ar' a prec prog bounds 0 _ _) ;
      [ vm_cast_no_check (eq_refl true) | idtac ]
    end
  | |- Rle ?a ?b =>
    let v := get_float b in
    refine (proj2 (_ : contains (I.convert (I.bnd F.nan v)) (Xreal a)))
  | |- Rle ?a ?b =>
    let v := get_float a in
    refine (proj1 (_ : contains (I.convert (I.bnd v F.nan)) (Xreal b)))
  | |- Rle ?a ?b =>
    let v := extract_algorithm b (@nil R) in
    match v with
    | (?p, ?l) =>
      let lc := get_trivial_bounds l prec in
      refine (let prog := p in let bounds := lc in contains_bound_r' a prec prog bounds 0 _ _) ;
      [ vm_cast_no_check (eq_refl true) | idtac ]
    end
  | |- Rle ?a ?b =>
    let v := extract_algorithm a (@nil R) in
    match v with
    | (?p, ?l) =>
      let lc := get_trivial_bounds l prec in
      refine (let prog := p in let bounds := lc in contains_bound_l' b prec prog bounds 0 _ _) ;
      [ vm_cast_no_check (eq_refl true) | idtac ]
    end
  | |- Rle ?a ?b =>
    apply Rminus_le ;
    refine (proj2 (_ : contains (I.convert (I.bnd F.nan F.zero)) (Xreal (a - b))))
  | |- Rlt 0 ?b =>
    idtac
  | |- Rlt ?a ?b =>
    apply Rminus_gt ;
    unfold Rgt
  | |- (?a <> 0)%R =>
    idtac
  | |- (?a <> ?b)%R =>
    apply Rminus_not_eq
  | _ => fail 100 "Goal is not an inequality with constant bounds."
  end.

Ltac xalgorithm lx prec :=
  match goal with
  | |- A.check_p ?check (nth ?n (eval_ext ?formula (map Xreal ?constants)) Xnan) => idtac
  | _ => xalgorithm_pre prec ; xalgorithm_post lx
  end.

Lemma interval_helper_evaluate :
  forall bounds check formula prec n,
  A.check_f check (nth n (A.BndValuator.eval prec formula (map A.interval_from_bp bounds)) I.nai) = true ->
  A.check_p check (nth n (eval_ext formula (map A.xreal_from_bp bounds)) Xnan).
Proof.
intros bound (check_f, check_p, check_th). simpl.
intros.
apply check_th with (2 := H).
apply A.BndValuator.eval_correct.
Qed.

Lemma interval_helper_bisection :
  forall bounds check formula prec depth n,
  match bounds with
  | cons (A.Bproof _ (Interval_interval_float.Ibnd l u) _) tail =>
    let fi := fun b => nth n (A.BndValuator.eval prec formula (b :: map A.interval_from_bp tail)) I.nai in
    A.bisect_1d l u (fun b => A.check_f check (fi b)) depth = true
  | _ => False
  end ->
  A.check_p check (nth n (eval_ext formula (map A.xreal_from_bp bounds)) Xnan).
Proof.
intros [|[x [|l u] Hx] bounds] check formula prec depth n ; try easy.
pose (f := fun x => nth n (eval_ext formula (x :: map A.xreal_from_bp bounds)) Xnan).
pose (fi := fun b => nth n (A.BndValuator.eval prec formula (b :: map A.interval_from_bp bounds)) I.nai).
change (A.bisect_1d l u (fun b => A.check_f check (fi b)) depth = true -> A.check_p check (f (Xreal x))).
intros H.
apply A.bisect_1d_correct with (P := fun x => A.check_p check (f x)) (2 := H) (3 := Hx).
intros y yi Hy Hb.
destruct check as [b P HP].
apply (HP (f y) (fi yi)) with (2 := Hb).
now apply A.BndValuator.eval_correct_ext.
Qed.

Lemma interval_helper_bisection_diff :
  forall bounds check formula prec depth n,
  match bounds with
  | cons (A.Bproof _ (Interval_interval_float.Ibnd l u) _) tail =>
    let fi := fun b => A.DiffValuator.eval prec formula (map A.interval_from_bp tail) n b in
    A.bisect_1d l u (fun b => A.check_f check (fi b)) depth = true
  | _ => False
  end ->
  A.check_p check (nth n (eval_ext formula (map A.xreal_from_bp bounds)) Xnan).
Proof.
intros [|[x [|l u] Hx] bounds] check formula prec depth n ; try easy.
pose (f := fun x => nth n (eval_ext formula (x :: map A.xreal_from_bp bounds)) Xnan).
pose (fi := fun b => A.DiffValuator.eval prec formula (map A.interval_from_bp bounds) n b).
change (A.bisect_1d l u (fun b => A.check_f check (fi b)) depth = true -> A.check_p check (f (Xreal x))).
intros H.
apply A.bisect_1d_correct with (P := fun x => A.check_p check (f x)) (2 := H) (3 := Hx).
intros y yi Hy Hb.
destruct check as [b P HP].
apply (HP (f y) (fi yi)) with (2 := Hb).
now apply A.DiffValuator.eval_correct_ext.
Qed.

Lemma interval_helper_bisection_taylor :
  forall bounds check formula prec deg depth n,
  match bounds with
  | cons (A.Bproof _ (Interval_interval_float.Ibnd l u) _) tail =>
    let fi := fun b => A.TaylorValuator.TM.eval (prec, deg)
      (nth n (A.TaylorValuator.eval prec deg b formula (A.TaylorValuator.TM.var ::
        map (fun b => A.TaylorValuator.TM.const (A.interval_from_bp b)) tail)) A.TaylorValuator.TM.dummy) b b in
    A.bisect_1d l u (fun b => A.check_f check (fi b)) depth = true
  | _ => False
  end ->
  A.check_p check (nth n (eval_ext formula (map A.xreal_from_bp bounds)) Xnan).
Proof.
intros [|[x [|l u] Hx] bounds] check formula prec deg depth n ; try easy.
pose (f := fun x => nth n (eval_ext formula (x :: map (fun b => Xmask (A.xreal_from_bp b) x) bounds)) Xnan).
pose (fi := fun b => A.TaylorValuator.TM.eval (prec, deg)
  (nth n (A.TaylorValuator.eval prec deg b formula (A.TaylorValuator.TM.var ::
    map (fun b => A.TaylorValuator.TM.const (A.interval_from_bp b)) bounds)) A.TaylorValuator.TM.dummy)
  b b).
change (A.bisect_1d l u (fun b => A.check_f check (fi b)) depth = true -> A.check_p check (f (Xreal x))).
intros H.
apply A.bisect_1d_correct with (P := fun x => A.check_p check (f x)) (2 := H) (3 := Hx).
intros y yi Hy Hb.
destruct check as [b P HP].
apply (HP (f y) (fi yi)) with (2 := Hb).
now apply A.TaylorValuator.eval_correct_ext.
Qed.

(*
Lemma interval_helper_bisection_first_order :
  forall bounds output formula prec depth n,
  match bounds with
  | cons (V.Bproof _ (interval_float.Ibnd l u) _) tail =>
    V.Algos.bisect_1d (fun b => V.eval_first_order_nth prec formula (map V.interval_from_bp tail) n b) l u output depth = true
  | _ => False
  end ->
  contains (I.convert output) (nth n (V.eval_ext formula (map V.xreal_from_bp bounds)) (Xreal 0)).
intro.
case bounds.
intros.
elim H.
intro.
case b.
intros x xi.
case xi.
intros.
elim H.
intros.
clear bounds b xi.
pose (f := fun x => nth n (V.eval_ext formula (x :: map V.xreal_from_bp l0)) (Xreal 0)).
pose (fi := fun b => V.eval_first_order_nth prec formula (map V.interval_from_bp l0) n b).
change (contains (I.convert output) (f (Xreal x))).
refine (V.Algos.bisect_1d_correct depth f fi _ _ _ _ H _ c).
exact (V.eval_first_order_correct_ext _ _ _ _).
Qed.
*)

Definition prec_of_nat prec :=
  match Z_of_nat prec with Zpos p => F.PtoP p | _ => F.PtoP xH end.

Ltac do_interval vars prec depth rint_depth rint_prec rint_deg eval_tac :=
  (abstract (
    let prec := eval vm_compute in (prec_of_nat prec) in
    xalgorithm vars prec ;
    match goal with
    | |- A.check_p ?check (nth ?n (eval_ext ?formula (map Xreal ?constants)) Xnan) =>
      match get_bounds constants prec rint_depth rint_prec rint_deg with
      | (?bounds_, ?lw) =>
        let bounds := fresh "bounds" in
        pose (bounds := bounds_) ;
        change (map Xreal constants) with (map A.xreal_from_bp bounds) ;
        eval_tac bounds check formula prec depth n ;
        let ibounds := fresh "ibounds" in
        set (ibounds := map A.interval_from_bp bounds) ;
        cbv beta iota zeta delta [map A.interval_from_bp bounds] in ibounds ;
        clear ;
        (abstract vm_cast_no_check (refl_equal true))
        || warn_whole lw
      end
    end)) ||
  fail 100 "Numerical evaluation failed to conclude. You may want to adjust some parameters.".

Ltac do_interval_eval bounds output formula prec depth n :=
  refine (interval_helper_evaluate bounds output formula prec n _).

Ltac do_interval_bisect bounds output formula prec depth n :=
  refine (interval_helper_bisection bounds output formula prec depth n _).

Ltac do_interval_bisect_diff bounds output formula prec depth n :=
  refine (interval_helper_bisection_diff bounds output formula prec depth n _).

Ltac do_interval_bisect_taylor deg bounds output formula prec depth n :=
  refine (interval_helper_bisection_taylor bounds output formula prec deg depth n _).

Ltac tuple_to_list params l :=
  match params with
  | pair ?a ?b => tuple_to_list a (b :: l)
  | ?b => constr:(b :: l)
  | ?z => fail 100 "Unknown tactic parameter" z "."
  end.

Ltac do_interval_parse params :=
  let rec aux vars prec depth rint_depth rint_prec rint_deg eval_tac params :=
    match params with
    | nil => do_interval vars prec depth rint_depth rint_prec rint_deg eval_tac
    | cons (i_prec ?p) ?t => aux vars p depth rint_depth rint_prec rint_deg eval_tac t
    | cons (i_bisect ?x) ?t => aux (cons x nil) prec depth rint_depth rint_prec rint_deg do_interval_bisect t
    | cons (i_bisect_diff ?x) ?t => aux (cons x nil) prec depth rint_depth rint_prec rint_deg do_interval_bisect_diff t
    | cons (i_bisect_taylor ?x ?d) ?t => aux (cons x nil) prec depth rint_depth rint_prec rint_deg ltac:(do_interval_bisect_taylor d) t
    | cons (i_depth ?d) ?t => aux vars prec d rint_depth rint_prec rint_deg eval_tac t
    | cons (i_integral_depth ?d) ?t => aux vars prec depth d rint_prec rint_deg eval_tac t
    | cons (i_integral_prec ?rint_prec) ?t => aux vars prec depth rint_depth rint_prec rint_deg eval_tac t
    | cons (i_integral_deg ?rint_deg) ?t => aux vars prec depth rint_depth rint_prec rint_deg eval_tac t
    | cons ?h _ => fail 100 "Unknown tactic parameter" h "."
    end in
  aux (@nil R) 30%nat 15%nat 3%nat 10%nat 10%nat do_interval_eval params.

Ltac do_interval_generalize t b :=
  match eval vm_compute in (I.convert b) with
  | Inan => fail 100 "Nothing known about" t
  | Ibnd ?l ?u =>
    match goal with
    | |- ?P =>
      match l with
      | Xnan =>
        match u with
        | Xnan => fail 100 "Nothing known about" t
        | Xreal ?u => refine ((_ : (t <= u)%R -> P) _)
        end
      | Xreal ?l =>
        match u with
        | Xnan => refine ((_ : (l <= t)%R -> P) _)
        | Xreal ?u => refine ((_ : (l <= t <= u)%R -> P) _)
        end
      end
    end
  end.

Ltac do_interval_intro_eval extend bounds formula prec depth :=
  eval vm_compute in (extend (nth 0 (A.BndValuator.eval prec formula (map A.interval_from_bp bounds)) I.nai)).

Ltac do_interval_intro_bisect extend bounds formula prec depth :=
  eval vm_compute in
   (match bounds with
    | cons (A.Bproof _ (Interval_interval_float.Ibnd l u) _) tail =>
      A.lookup_1d (fun b => nth 0 (A.BndValuator.eval prec formula (b :: map A.interval_from_bp tail)) I.nai) l u extend depth
    | _ => I.nai
    end).

Ltac do_interval_intro_bisect_diff extend bounds formula prec depth :=
  eval vm_compute in
   (match bounds with
    | cons (A.Bproof _ (Interval_interval_float.Ibnd l u) _) tail =>
      A.lookup_1d (fun b => A.DiffValuator.eval prec formula (map A.interval_from_bp tail) 0 b) l u extend depth
    | _ => I.nai
    end).

Ltac do_interval_intro_bisect_taylor deg extend bounds formula prec depth :=
  eval vm_compute in
   (match bounds with
    | cons (A.Bproof _ (Interval_interval_float.Ibnd l u) _) tail =>
      A.lookup_1d (fun b => A.TaylorValuator.TM.eval (prec, deg) (nth 0 (A.TaylorValuator.eval prec deg b formula (A.TaylorValuator.TM.var :: map (fun b => A.TaylorValuator.TM.const (A.interval_from_bp b)) tail)) A.TaylorValuator.TM.dummy) b b) l u extend depth
    | _ => I.nai
    end).

Ltac do_interval_intro t extend params vars prec depth rint_depth rint_prec rint_deg eval_tac :=
  let prec := eval vm_compute in (prec_of_nat prec) in
  match extract_algorithm t vars with
  | (?formula, ?constants) =>
    match get_bounds constants prec rint_depth rint_prec rint_deg with
    | (?bounds, ?lw) =>
      warn_whole lw ;
      let v := eval_tac extend bounds formula prec depth in
      do_interval_generalize t v ;
      [ | do_interval_parse params ]
    end
  end.

Ltac do_interval_intro_parse t_ extend params_ :=
  let rec aux vars prec depth rint_depth rint_prec rint_deg eval_tac params :=
    match params with
    | nil => do_interval_intro t_ extend params_ vars prec depth rint_depth rint_prec rint_deg eval_tac
    | cons (i_prec ?p) ?t => aux vars p depth rint_depth rint_prec rint_deg eval_tac t
    | cons (i_bisect ?x) ?t => aux (cons x nil) prec depth rint_depth rint_prec rint_deg do_interval_intro_bisect t
    | cons (i_bisect_diff ?x) ?t => aux (cons x nil) prec depth rint_depth rint_prec rint_deg do_interval_intro_bisect_diff t
    | cons (i_bisect_taylor ?x ?d) ?t => aux (cons x nil) prec depth rint_depth rint_prec rint_deg ltac:(do_interval_intro_bisect_taylor d) t
    | cons (i_depth ?d) ?t => aux vars prec d rint_depth rint_prec rint_deg eval_tac t
    | cons (i_integral_depth ?d) ?t => aux vars prec depth d rint_prec rint_deg eval_tac t
    | cons (i_integral_prec ?p) ?t => aux vars prec depth rint_depth p rint_deg eval_tac t
    | cons (i_integral_deg ?p) ?t => aux vars prec depth rint_depth rint_prec p eval_tac t
    | cons ?h _ => fail 100 "Unknown tactic parameter" h "."
    end in
  aux (@nil R) 30%nat 5%nat 3%nat 10%nat 10%nat do_interval_intro_eval params_.

End Private.

Import Private.

Tactic Notation "interval" :=
  do_interval_parse (@nil interval_tac_parameters).

Tactic Notation "interval" "with" constr(params) :=
  do_interval_parse ltac:(tuple_to_list params (@nil interval_tac_parameters)).

Tactic Notation "interval_intro" constr(t) :=
  do_interval_intro_parse t (fun v : I.type => v) (@nil interval_tac_parameters) ; intro.

Tactic Notation "interval_intro" constr(t) "lower" :=
  do_interval_intro_parse t I.upper_extent (@nil interval_tac_parameters) ; intro.

Tactic Notation "interval_intro" constr(t) "upper"  :=
  do_interval_intro_parse t I.lower_extent (@nil interval_tac_parameters) ; intro.

Tactic Notation "interval_intro" constr(t) "with" constr(params) :=
  do_interval_intro_parse t (fun v : I.type => v) ltac:(tuple_to_list params (@nil interval_tac_parameters)) ; intro.

Tactic Notation "interval_intro" constr(t) "lower" "with" constr(params) :=
  do_interval_intro_parse t I.upper_extent ltac:(tuple_to_list params (@nil interval_tac_parameters)) ; intro.

Tactic Notation "interval_intro" constr(t) "upper" "with" constr(params) :=
  do_interval_intro_parse t I.lower_extent ltac:(tuple_to_list params (@nil interval_tac_parameters)) ; intro.

Tactic Notation "interval_intro" constr(t) "as" simple_intropattern(H) :=
  do_interval_intro_parse t (fun v : I.type => v) (@nil interval_tac_parameters) ; intros H.

Tactic Notation "interval_intro" constr(t) "lower" "as" simple_intropattern(H) :=
  do_interval_intro_parse t I.upper_extent (@nil interval_tac_parameters) ; intros H.

Tactic Notation "interval_intro" constr(t) "upper" "as" simple_intropattern(H)  :=
  do_interval_intro_parse t I.lower_extent (@nil interval_tac_parameters) ; intros H.

Tactic Notation "interval_intro" constr(t) "with" constr(params) "as" simple_intropattern(H) :=
  do_interval_intro_parse t (fun v : I.type => v) ltac:(tuple_to_list params (@nil interval_tac_parameters)) ; intros H.

Tactic Notation "interval_intro" constr(t) "lower" "with" constr(params) "as" simple_intropattern(H) :=
  do_interval_intro_parse t I.upper_extent ltac:(tuple_to_list params (@nil interval_tac_parameters)) ; intros H.

Tactic Notation "interval_intro" constr(t) "upper" "with" constr(params) "as" simple_intropattern(H) :=
  do_interval_intro_parse t I.lower_extent ltac:(tuple_to_list params (@nil interval_tac_parameters)) ; intros H.

End IntervalTactic.

(*Require Import Interval_stdz_carrier.*)
Require Import Interval_bigint_carrier.
Require Import Interval_specific_ops.
Module SFBI2 := SpecificFloat BigIntRadix2.
Module ITSFBI2 := IntervalTactic SFBI2.
Export ITSFBI2.

(*
Require Import Interval_generic_ops.
Module GFSZ2 := GenericFloat Radix2.
Module ITGFSZ2 := IntervalTactic GFSZ2.
Export ITGFSZ2.
*)

(*
Lemma blo0 :
   1 <= RInt (fun x => exp x) 0 1 <= 2.
Proof.
interval.
Qed.
*)

(*
Lemma blo1 :
  forall x, (Rabs x <= 15/3)%R ->
  (-4 <= x + 1)%R.
intros.
interval.
Qed.
*)

(*
Lemma blo2 :
  (2/3 <= 5/7)%R.
intros.
interval_intro (5/7)%R lower with (i_prec 4%nat).
apply Rle_trans with (2 := H).
interval.
Qed.
*)

(*
Lemma blo3 :
  forall x, (x <= 0)%R ->
  (0 <= x - x <= 0)%R.
intros.
Time interval with (i_bisect_diff x).
Qed.
*)

(*
Lemma blo4 :
  forall x, (3/2 <= x <= 2)%R ->
  forall y, (1 <= y <= 33/32)%R ->
  (Rabs (sqrt(1 + x/sqrt(x+y)) - 144/1000*x - 118/100) <= 71/32768)%R.
intros.
interval with (i_bisect x).
Qed.
*)

(*
Lemma blo5 :
  forall x, (-1 <= x <= 1)%R ->
  (0 <= exp x - (1 + x) <= 3/4)%R.
Proof.
intros.
interval_intro (1 + x)%R with (i_bisect_taylor x 2).
interval with (i_bisect_taylor x 2).
Qed.
*)

(*
Lemma pi10 : (31415926535/10000000000 < PI < 31415926536/10000000000)%R.
Proof.
split; interval with (i_prec 40).
Qed.
*)
