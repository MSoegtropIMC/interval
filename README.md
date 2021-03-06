CoqInterval
===========

This library provides vernacular files containing tactics for
simplifying the proofs of inequalities on expressions of real numbers
for the [Coq proof assistant](https://coq.inria.fr/).

This package is free software; you can redistribute it and/or modify it
under the terms of CeCILL-C Free Software License (see the [COPYING](COPYING) file).
Main author is Guillaume Melquiond <guillaume.melquiond@inria.fr>.

See the file [INSTALL.md](INSTALL.md) for installation instructions.


Project Home
------------

Homepage: http://coq-interval.gforge.inria.fr/

Repository: https://gitlab.inria.fr/coqinterval/interval

Bug tracker: https://gitlab.inria.fr/coqinterval/interval/issues


Invocation
----------

In order to use the tactics of the library, one has to import the
`Interval.Tactic` file into a Coq proof script. The main tactic is named
`interval`.

The tactic can be applied on a goal of the form `c1 <= e <= c2` with
`e` an expression involving real-valued operators. Sub-expressions that
are not recognized by the tactic should be either terms `t` appearing in
hypothesis inequalities `c3 <= t <= c4` or simple integers. The
bounds `c1`, `c2`, etc are expressions that contain only constant leaves,
e.g., `5 / sqrt (1 + PI)`.

The complete list of recognized goals is as follows:

  - `c1 <= e <= c2`;
  - `e <= c2`;
  - `c1 <= e`;
  - `0 < e`;
  - `e <> 0`;
  - `Rabs e <= c2`, handled as `-c2 <= e <= c2`;
  - `e1 <= e2`, handled as `e1 - e2 <= 0`;
  - `e1 < e2`, handled as `0 < e2 - e1`;
  - `e1 <> e2`, handled as `e1 - e2 <> 0`.

Operators recognized by the tactic are `PI`, `Ropp`, `Rabs`, `Rinv`,
`Rsqr`, `sqrt`, `cos`, `sin`, `tan`, `atan`, `exp`, `ln`, `pow`,
`powerRZ`, `Rplus`, `Rminus`, `Rmult`, `Rdiv`. Operators `Zfloor`,
`Zceil`, `Ztrunc`, `ZnearestE` (composed with `IZR`) are also recognized.
There are some restrictions on the domain of a few functions: `pow` and
`powerRZ` should be written with a numeric exponent; the input of `cos`
and `sin` should be between `-2*PI` and `2*PI`; the input of `tan` should
be between `-PI/2` and `PI/2`.

The tactic also recognizes integral expressions `RInt` whose bounds are
constants and whose integrand is an expression containing only constant
leaves except for the integration variable. Some improper integral
expressions `RInt_gen` are also supported with bounds `(at_right 0)
(at_point _)` or `(at_point _) (Rbar_locally p_infty)`. In the improper
case, the integrand should be of the form `(fun t => f t * g t)` with `g`
one of the following expressions:

  - `exp (- (_ * t))`,
  - `powerRZ t _ * (ln t) ^ _`,
  - `/ (t * (ln t) ^ _)`.

A helper tactic `interval_intro e` is also available. Instead of proving
the current goal, it computes an enclosure of the expression `e` passed
as argument and it introduces the inequalities into the proof context. If
only one bound is needed, the keywords `lower` and `upper` can be passed
to the tactic, so that it does not perform useless computations. For
example, `interval_intro e lower` introduces only a floating-point lower
bound of `e` in the context. Unless one uses `as` followed by an intro
pattern, the `interval_intro` tactic generates a fresh name for the
hypothesis added to the context.


Fine-tuning
-----------

The behavior of the tactics can be tuned by passing an optional set of
parameters `with (param1, param2, ...)`. These parameters are parsed from
left to right. If some parameters are conflicting, the earlier ones are
discarded. Available parameters are as follows (with the type of their
arguments, if any):

  - `i_prec (p:nat)` sets the precision of the floating-point computations;
  - `i_depth (n:nat)` sets the bisection depth (`2^n` sub-intervals at most);
  - `i_bisect (x:R)`      splits input interval on `x` and repeat until proven;
  - `i_bisect_diff (x:R)` same as `i_bisect`, but studies variations
    along `x` too;
  - `i_bisect_taylor (x:R) (d:nat)` same as `i_bisect_diff`, but computes
    degree-`d` Taylor models instead of performing automatic differentiation;
  - `i_integral_prec (p:nat)` sets the target relative accuracy of
    integral expressions to approximately `p` bits;
  - `i_integral_width (p:Z)` sets the target accuracy of integral
    expressions to an interval width of `2^p`;
  - `i_integral_depth (n:nat)` sets the bisection depth for bounding
    integral expressions (`2^n` sub-intervals at most);
  - `i_integral_deg (d:nat)` sets the degree of Taylor models for
    approximating the integrand when bounding integral expressions;
  - `i_native_compute` uses `native_compute` instead of `vm_compute`;
  - `i_delay` delays proof checking till `Qed`, especially useful when
    experimenting with `interval_intro`.

For both tactics, performing a bisection of depth 1 is not much slower
than performing no bisection. If the current goal can be proven by
`interval` with a bisection of depth n, then increasing the depth to n + 1
will not have any noticeable effect. For `interval_intro`, increasing the
depth from n to n + 1 can, however, doubles the computation time.

Performing an `i_bisect_diff` bisection has a much higher cost per
sub-interval, but it can considerably reduce the amount of sub-intervals
considered. As a consequence, unless there is a huge amount of trivial
propositions to prove, one should use this improved bisection.

If the proof process is still too slow, the `i_bisect_taylor` bisection
can be tried instead, as it usually reduces the number of sub-intervals
much further. In some corner cases though, it will not be able to prove
properties for which `i_bisect_diff` would have succeeded.

By default, the precision of the floating-point computations is 30 bits.
If the user enables a bisection, the default depth is 15 for `interval`
and 5 for `interval_intro`. When bounding integral expressions, the
tactics target 10 bits of accuracy by splitting the domain into 2^3
subdomains at most and by using degree-10 Taylor models.


Examples
--------

```coq
Require Import Reals.
Require Import Interval.Tactic.

Open Scope R_scope.

Goal
  forall x, -1 <= x <= 1 ->
  sqrt (1 - x) <= 3/2.
Proof.
  intros.
  interval.
Qed.

Goal
  forall x, -1 <= x <= 1 ->
  sqrt (1 - x) <= 141422/100000.
Proof.
  intros.
  interval.
Qed.

Goal
  forall x, -1 <= x <= 1 ->
  sqrt (1 - x) <= 141422/100000.
Proof.
  intros.
  interval_intro (sqrt (1 - x)) upper as H'.
  apply Rle_trans with (1 := H').
  interval.
Qed.

Goal
  forall x, 3/2 <= x <= 2 ->
  forall y, 1 <= y <= 33/32 ->
  Rabs (sqrt(1 + x/sqrt(x+y)) - 144/1000*x - 118/100) <= 71/32768.
Proof.
  intros.
  interval with (i_prec 19, i_bisect x).
Qed.

Goal
  forall x, 1/2 <= x <= 2 ->
  Rabs (sqrt x - (((((122 / 7397 * x + (-1733) / 13547) * x
                   + 529 / 1274) * x + (-767) / 999) * x
                   + 407 / 334) * x + 227 / 925))
    <= 5/65536.
Proof.
  intros.
  interval with (i_bisect_taylor x 3).
Qed.

Goal
  forall x, -1 <= x ->
  x < 1 + powerRZ x 3.
Proof.
  intros.
  interval with (i_bisect_diff x).
Qed.

Require Import Coquelicot.Coquelicot.

Goal
  Rabs (RInt (fun x => atan (sqrt (x*x + 2)) / (sqrt (x*x + 2) * (x*x + 1))) 0 1
        - 5/96*PI*PI) <= 1/1000.
Proof.
  interval with (i_integral_prec 9, i_integral_depth 1, i_integral_deg 5).
Qed.

Goal
  RInt_gen (fun x => 1 * (powerRZ x 3 * ln x^2))
           (at_right 0) (at_point 1) = 1/32.
Proof.
  refine ((fun H => Rle_antisym _ _ (proj2 H) (proj1 H)) _).
  interval.
Qed.

Goal
  Rabs (RInt_gen (fun t => 1/sqrt t * exp (-(1*t)))
                 (at_point 1) (Rbar_locally p_infty)
        - 2788/10000) <= 1/1000.
Proof.
  interval.
Qed.
```
