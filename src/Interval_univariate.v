Require Import Reals.
Require Import Interval_interval.
Require Import Interval_xreal.

Module Type UnivariateApprox (I : IntervalOps).

(* Local Coercion I.convert : I.type >-> interval. *)

Parameter T : Type.

Definition U := (I.precision * nat (* for degree *) )%type.

Parameter approximates : I.type -> T -> (ExtendedR -> ExtendedR) -> Prop.

Parameter approximates_ext :
  forall f g xi t,
  (forall x, f x = g x) ->
  approximates xi t f -> approximates xi t g.

Parameter const : I.type -> T.

Parameter const_correct :
  forall (c : I.type) (r : R), contains (I.convert c) (Xreal r) ->
  forall (X : I.type),
  approximates X (const c) (Xmask (Xreal r)).

Parameter dummy : T.

Parameter dummy_correct :
  forall xi f, f Xnan = Xnan -> approximates xi dummy f.

Parameter var : T.

Parameter var_correct :
  forall (X : I.type), approximates X var (fun x => x).

Parameter eval : U -> T -> I.type -> I.type -> I.type.

Parameter eval_correct :
  forall u (Y : I.type) t f,
  approximates Y t f -> I.extension f (eval u t Y).

Parameter add : U -> I.type -> T -> T -> T.

Parameter add_correct :
  forall u (Y : I.type) tf tg f g,
  approximates Y tf f -> approximates Y tg g ->
  approximates Y (add u Y tf tg) (fun x => Xadd (f x) (g x)).

Parameter opp : U -> I.type -> T -> T.

Parameter opp_correct :
  forall u (Y : I.type) tf f,
  approximates Y tf f ->
  approximates Y (opp u Y tf) (fun x => Xneg (f x)).

Parameter sub : U -> I.type -> T -> T -> T.

Parameter sub_correct :
  forall u (Y : I.type) tf tg f g,
  approximates Y tf f -> approximates Y tg g ->
  approximates Y (sub u Y tf tg) (fun x => Xsub (f x) (g x)).

Parameter mul : U -> I.type -> T -> T -> T.

Parameter mul_correct :
  forall u (Y : I.type) tf tg f g,
  approximates Y tf f -> approximates Y tg g ->
  approximates Y (mul u Y tf tg) (fun x => Xmul (f x) (g x)).

Parameter abs : U -> I.type -> T -> T.

Parameter abs_correct :
  forall u (Y : I.type) tf f,
  approximates Y tf f ->
  approximates Y (abs u Y tf) (fun x => Xabs (f x)).

Parameter div : U -> I.type -> T -> T -> T.

Parameter div_correct :
  forall u (Y : I.type) tf tg f g,
  approximates Y tf f -> approximates Y tg g ->
  approximates Y (div u Y tf tg) (fun x => Xdiv (f x) (g x)).

Parameter inv : U -> I.type -> T -> T.

Parameter inv_correct :
  forall u (Y : I.type) tf f,
  approximates Y tf f ->
  approximates Y (inv u Y tf) (fun x => Xinv (f x)).

Parameter sqrt : U -> I.type -> T -> T.

Parameter sqrt_correct :
  forall u (Y : I.type) tf f,
  approximates Y tf f ->
  approximates Y (sqrt u Y tf) (fun x => Xsqrt (f x)).

Parameter exp : U -> I.type -> T -> T.

Parameter exp_correct :
  forall u (Y : I.type) tf f,
  approximates Y tf f ->
  approximates Y (exp u Y tf) (fun x => Xexp (f x)).

Parameter cos : U -> I.type -> T -> T.

Parameter cos_correct :
  forall u (Y : I.type) tf f,
  approximates Y tf f ->
  approximates Y (cos u Y tf) (fun x => Xcos (f x)).

Parameter sin : U -> I.type -> T -> T.

Parameter sin_correct :
  forall u (Y : I.type) tf f,
  approximates Y tf f ->
  approximates Y (sin u Y tf) (fun x => Xsin (f x)).

Parameter tan : U -> I.type -> T -> T.

Parameter tan_correct :
  forall u (Y : I.type) tf f,
  approximates Y tf f ->
  approximates Y (tan u Y tf) (fun x => Xtan (f x)).

Parameter atan : U -> I.type -> T -> T.

Parameter atan_correct :
  forall u (Y : I.type) tf f,
  approximates Y tf f ->
  approximates Y (atan u Y tf) (fun x => Xatan (f x)).

End UnivariateApprox.
