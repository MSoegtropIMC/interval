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
Require Import ZArith.
Require Import Flocq.Core.Fcore_Raux.
Require Import Interval_xreal.
Require Import Interval_missing.

Inductive rounding_mode : Set :=
  rnd_UP | rnd_DN | rnd_ZR | rnd_NE.

Definition radix2 := Build_radix 2 (refl_equal _).

Section Definitions.

Variable beta : radix.

Fixpoint count_digits_aux nb pow (p q : positive) { struct q } : positive :=
  if Zlt_bool (Zpos p) pow then nb
  else
    match q with
    | xH => nb
    | xI r => count_digits_aux (Psucc nb) (Zmult beta pow) p r
    | xO r => count_digits_aux (Psucc nb) (Zmult beta pow) p r
    end.

Definition count_digits n :=
  count_digits_aux 1 beta n n.

Definition FtoR (s : bool) m e :=
  let sm := if s then Zneg m else Zpos m in
  match e with
  | Zpos p => Z2R (sm * Zpower_pos beta p)
  | Z0 => Z2R sm
  | Zneg p => (Z2R sm / Z2R (Zpower_pos beta p))%R
  end.

End Definitions.
