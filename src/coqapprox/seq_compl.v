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

Require Import Ssreflect.ssreflect Ssreflect.ssrfun Ssreflect.ssrbool Ssreflect.eqtype Ssreflect.ssrnat Ssreflect.seq.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Section NatCompl.

Lemma nat_ind_gen (P : nat -> Prop) :
  (forall x, (forall y, (y < x)%N -> P y) -> P x) -> (forall x, P x).
Proof.
move=> H x.
suff [H1 H2] : P x /\ (forall y, (y < x)%N -> P y) by done.
elim: x =>[|x [Hx IH]]; first by split; [apply: H|] => y Hy.
split; [apply: H|]=> y; rewrite ltnS => Hy; case: (leqP x y) => Hxy.
- suff<-: x = y by done. by apply: anti_leq; rewrite Hxy Hy.
- exact: IH.
- suff<-: x = y by done. by apply: anti_leq; rewrite Hxy Hy.
- exact: IH.
Qed.

Lemma predn_leq (m n : nat) : m <= n -> m.-1 <= n.-1.
Proof. by case: m n =>[//|m] [//|n]; rewrite ltnS. Qed.

Lemma ltn_subr (m n p : nat) : m < n -> n - p.+1 < n.
Proof.
rewrite subnS => Hn.
case Ek: (n-p)=>[//|k] /=; first exact: leq_trans _ Hn.
apply: leq_trans (leq_trans _ (_ : k.+1 <= n - p)) (_ : n - p <= n);
  by [ |rewrite Ek|rewrite leq_subr].
Qed.

Lemma minnl (m n : nat) : m <= n -> minn m n = m.
Proof.
move=> Hmn; rewrite /minn; case: ltnP =>// Hnm.
by apply/eqP; rewrite eqn_leq Hmn Hnm.
Qed.

Lemma minnr (m n : nat) : n <= m -> minn m n = n.
Proof.
move=> Hnm; rewrite /minn; case: ltnP =>// Hmn; exfalso.
have: n < n by exact: leq_ltn_trans Hnm Hmn.
by rewrite ltnn.
Qed.

End NatCompl.

Section Take.
Variable (T : Type).

Lemma size_take_minn (n : nat) (s : seq T) : size (take n s) = minn n (size s).
Proof.
rewrite size_take.
case: ltnP =>Hn; symmetry; by [apply/minn_idPl; exact: ltnW | apply/minn_idPr].
Qed.

End Take.

Section Map2.
Variable C : Type.
Variable op : C -> C -> C.
Fixpoint map2 (s1 : seq C) (s2 : seq C) : seq C :=
  match s1, s2 with
    | _, [::] => s1
    | [::], _ => s2
    | a :: s3, b :: s4 => op a b :: map2 s3 s4
  end.
End Map2.

Section map_proof.
Variables (V T : Type) (Rel : V -> T -> Prop).
Variables (vop : V -> V) (top : T -> T).
Variables (dv : V) (dt : T).
Hypothesis H0 : Rel dv dt.
Hypothesis H0v : forall v : V, Rel v dt -> Rel (vop v) dt.
Hypothesis H0t : forall t : T, Rel dv t -> Rel dv (top t).
Lemma map_correct :
  forall sv st,
    (forall v t, Rel v t -> Rel (vop v) (top t)) ->
    (forall k : nat, Rel (nth dv sv k) (nth dt st k)) ->
    forall k : nat, Rel (nth dv (map vop sv) k) (nth dt (map top st) k).
Proof.
move=> sv st Hop Hnth k.
case: (ltnP k (size sv)) => Hsv; case: (ltnP k (size st)) => Hst.
- rewrite (nth_map dv) // (nth_map dt) //.
  apply: Hop; apply: Hnth.
- rewrite (nth_default dt) ?size_map //.
  rewrite (nth_map dv) //.
  apply: H0v.
  rewrite -(nth_default dt Hst); apply: Hnth.
- rewrite (nth_default dv) ?size_map //.
  rewrite (nth_map dt) //.
  apply: H0t.
  rewrite -(nth_default dv Hsv); apply: Hnth.
  by rewrite !nth_default ?size_map.
Qed.
End map_proof.

Lemma nth_map2 (C1 : Type) (x1 : C1) (f : C1 -> C1 -> C1) (n : nat) (s1 s2 : seq C1) :
  n < size s1 -> n < size s2 -> nth x1 (map2 f s1 s2) n = f (nth x1 s1 n) (nth x1 s2 n).
Proof.
move=> H1 H2.
admit. (* Exercice *)
Qed.

Lemma size_map2 C f (s1 : seq C) (s2 : seq C) :
  size (map2 f s1 s2) = minn (size s1) (size s2).
Proof.
elim: s1 s2 => [|x1 s1 IH1] [|x2 s2] //=; admit.
(* by rewrite IH1 -addn1 addn_minl 2!addn1. *)
Qed.

Section map2_proof.
Variables (V T : Type) (Rel : V -> T -> Prop).
Variables (vop : V -> V -> V) (top : T -> T -> T).
Variables (dv : V) (dt : T).
Hypothesis H0 : Rel dv dt.
Hypothesis H0t1 : forall (v1 v2 : V) (t1 : T), Rel v1 t1 ->
                                               Rel v2 dt ->
                                               Rel (vop v1 v2) t1.
Hypothesis H0t2 : forall (v1 v2 : V) (t2 : T), Rel v1 dt ->
                                               Rel v2 t2 ->
                                               Rel (vop v1 v2) t2.
Hypothesis H0v1 : forall (v1 : V) (t1 t2 : T), Rel v1 t1 ->
                                               Rel dv t2 ->
                                               Rel v1 (top t1 t2).
Hypothesis H0v2 : forall (v2 : V) (t1 t2 : T), Rel dv dt ->
                                               Rel v2 t2 ->
                                               Rel v2 (top t1 t2).
Hypothesis Hop : (forall v1 v2 t1 t2, Rel v1 t1 -> Rel v2 t2 -> Rel (vop v1 v2) (top t1 t2)).

Lemma map2_correct :
  forall sv1 sv2 st1 st2,
  (forall k : nat, Rel (nth dv sv1 k) (nth dt st1 k)) ->
  (forall k : nat, Rel (nth dv sv2 k) (nth dt st2 k)) ->
  forall k : nat, Rel (nth dv (map2 vop sv1 sv2) k) (nth dt (map2 top st1 st2) k).
Proof using H0 H0t1 H0t2 H0v1 H0v2 Hop.
admit.
(*
move=> sv1 sv2 st1 st2 Hnth1 Hnth2 k.
case: (ltnP k (size sv1)) => Hsv1; case: (ltnP k (size st1)) => Hst1;
case: (ltnP k (size sv2)) => Hsv2; case: (ltnP k (size st2)) => Hst2.
- rewrite (nth_map2 dv) // (nth_map2 dt) //;
    apply: Hop; apply: Hnth1 || apply: Hnth2.

- rewrite (nth_default dt) ?size_map //.
  rewrite (nth_map dv) //.
  apply: H0v.
  rewrite -(nth_default dt Hst); apply: Hnth.
- rewrite (nth_default dv) ?size_map //.
  rewrite (nth_map dt) //.
  apply: H0t.
  rewrite -(nth_default dv Hsv); apply: Hnth.
  by rewrite !nth_default ?size_map.
*)
Qed.
End map2_proof.

(*
Lemma nth_map2 s1 s2 (k : nat) da (x y : V) (g : V -> V -> V) :
  A (nth da s1 k) x ->
  A (nth da s2 k) y ->
  A (nth da (map2 s1 s2) k) (g x y).
Proof.
elim: s1 s2 k => [|x1 s1 IH1] s2 k Hx Hy.
  rewrite nth_default // in Hx *.
  admit.
  (* by rewrite (size0nil) !nth_nil.*)
case: s2 Hy =>[//|x2 s2]  Hy; rewrite nth_default //=.
  rewrite nth_default //in Hy.
  admit.
  admit.
admit.
(* case: k IH1 =>[//|k]; exact. *)
Qed.

End Map2.
*)

Section Head_Last.
Variables (T : Type) (d : T).

Lemma head_cons : forall s, s <> [::] -> s = head d s :: behead s.
Proof. by case. Qed.

Definition hb s := head d (behead s).

Lemma nth1 : forall s, nth d s 1 = hb s.
Proof. by move=> s; rewrite /hb -nth0 nth_behead. Qed.

Lemma last_rev : forall s, last d (rev s) = head d s.
Proof. by elim=> [//|s IHs]; rewrite rev_cons last_rcons. Qed.

Definition rmlast (l : seq T) := (belast (head d l) (behead l)).
End Head_Last.

Lemma rmlast_cons T (d e f : T) (s : seq T) :
  s <> [::] -> rmlast e (f :: s) = f :: rmlast d s.
Proof. by case: s. Qed.

Section Fold.
Variables (A B : Type) (f : A -> B).

Lemma foldr_cons (r : seq A) (s : seq B) :
  foldr (fun x acc => f x :: acc) s r = map f r ++ s.
Proof. by elim: r => [//|x r' IHr]; rewrite /= -IHr. Qed.

Corollary foldr_cons0 (r : seq A) :
  foldr (fun x acc => f x :: acc) [::] r = map f r.
Proof. by rewrite foldr_cons cats0. Qed.

Lemma foldl_cons (r : seq A) (s : seq B) :
  foldl (fun acc x => f x :: acc) s r = (catrev (map f r) s).
Proof. by elim: r s => [//|a r' IHr] s; rewrite /= -IHr. Qed.

Corollary foldl_cons0 (r : seq A) :
  foldl (fun acc x => f x :: acc) [::] r = rev (map f r).
Proof. by rewrite foldl_cons. Qed.

End Fold.
