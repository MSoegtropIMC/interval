(**
This file is part of the CoqApprox formalization of rigorous
polynomial approximation in Coq:
http://tamadi.gforge.inria.fr/CoqApprox/

Copyright (C) 2010-2016, ENS de Lyon and Inria.

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

Require Import ZArith Psatz.
Require Import Flocq.Core.Fcore_Raux.
Require Import mathcomp.ssreflect.ssreflect mathcomp.ssreflect.ssrfun mathcomp.ssreflect.ssrbool mathcomp.ssreflect.eqtype mathcomp.ssreflect.ssrnat mathcomp.ssreflect.seq mathcomp.ssreflect.fintype mathcomp.ssreflect.bigop.
Require Import Interval_xreal.
Require Import Interval_generic Interval_interval.
Require Import Interval_definitions.
Require Import Interval_specific_ops.
Require Import Interval_float_sig.
Require Import Interval_interval_float.
Require Import Interval_interval_float_full.
Require Import Interval_xreal_derive.
Require Import Interval_missing.
Require Import Interval_generic_proof.
Require Import Rstruct xreal_ssr_compat.
Require Import seq_compl.
Require Import interval_compl.
Require Import poly_datatypes.
Require Import taylor_poly.
Require Import basic_rec.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

(** The interface *)

Module Type PolyBound (I : IntervalOps) (Pol : PolyIntOps I).
Import Pol Pol.Notations.
Local Open Scope ipoly_scope.

Module Import Aux := IntervalAux I.

Parameter ComputeBound : Pol.U -> Pol.T -> I.type -> I.type.

Parameter ComputeBound_correct :
  forall u pi p,
  pi >:: p ->
  R_extension (PolR.horner tt p) (ComputeBound u pi).

Parameter ComputeBound_propagate :
  forall u pi,
  I.propagate (ComputeBound u pi).

End PolyBound.

Module PolyBoundThm
  (I : IntervalOps)
  (Pol : PolyIntOps I)
  (Bnd : PolyBound I Pol).

Import Pol.Notations Bnd.
Local Open Scope ipoly_scope.

Module Import Aux := IntervalAux I.

Theorem ComputeBound_nth0 prec pi p X :
  pi >:: p ->
  X >: 0 ->
  forall r : R, (Pol.nth pi 0) >: r ->
                ComputeBound prec pi X >: r.
Proof.
move=> Hpi HX0 r Hr.
case E: (Pol.size pi) =>[|n].
  have->: r = PolR.horner tt p 0%R.
  rewrite Pol.nth_default ?E // I.zero_correct /= in Hr.
  have [A B] := Hr.
  have H := Rle_antisym _ _ B A.
  rewrite PolR.hornerE big1 //.
  by move=> i _; rewrite (Pol.nth_default_alt Hpi) ?E // Rmult_0_l.
  exact: ComputeBound_correct.
have->: r = PolR.horner tt (PolR.set_nth p 0 r) 0%R.
  rewrite PolR.hornerE PolR.size_set_nth max1n big_nat_recl //.
  rewrite PolR.nth_set_nth eqxx pow_O Rmult_1_r big1 ?Rplus_0_r //.
  by move=> i _; rewrite pow_ne_zero ?Rmult_0_r.
apply: ComputeBound_correct =>//.
have->: pi = Pol.set_nth pi 0 (Pol.nth pi 0).
  by rewrite Pol.set_nth_nth // E.
exact: Pol.set_nth_correct.
Qed.

Arguments ComputeBound_nth0 [prec pi] p [X] _ _ r _.

End PolyBoundThm.

(** Naive implementation: Horner evaluation *)

Module PolyBoundHorner (I : IntervalOps) (Pol : PolyIntOps I)
  <: PolyBound I Pol.

Import Pol.Notations.
Local Open Scope ipoly_scope.
Module Import Aux := IntervalAux I.

Definition ComputeBound : Pol.U -> Pol.T -> I.type -> I.type :=
  Pol.horner.

Theorem ComputeBound_correct :
  forall prec pi p,
  pi >:: p ->
  R_extension (PolR.horner tt p) (ComputeBound prec pi).
Proof.
move=> Hfifx X x Hx; rewrite /ComputeBound.
by move=> *; apply Pol.horner_correct.
Qed.

Arguments ComputeBound_correct [prec pi p] _ b x _.

Lemma ComputeBound_propagate :
  forall prec pi,
  I.propagate (ComputeBound prec pi).
Proof. by red=> *; rewrite /ComputeBound Pol.horner_propagate. Qed.

Arguments ComputeBound_propagate [prec pi] xi _.

End PolyBoundHorner.
