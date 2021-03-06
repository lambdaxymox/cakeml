(*Generated by Lem from bigSmallInvariants.lem.*)
open HolKernel Parse boolLib bossLib;
open lem_pervasivesTheory libTheory namespaceTheory astTheory semanticPrimitivesTheory smallStepTheory bigStepTheory;

val _ = numLib.prefer_num();



val _ = new_theory "bigSmallInvariants"

(*
  Invariants used in the proof relating the big-step and small-step
  version of the CakeML source semantics.
*)
(*open import Pervasives*)
(*open import Lib*)
(*open import Namespace*)
(*open import Ast*)
(*open import SemanticPrimitives*)
(*open import SmallStep*)
(*open import BigStep*)

(* ------ Auxiliary relations for proving big/small step equivalence ------ *)

val _ = Hol_reln ` (! env s v.
T
==>
evaluate_ctxt env s (Craise () ) v (s, Rerr (Rraise v)))

/\ (! env s v pes.
T
==>
evaluate_ctxt env s (Chandle ()  pes) v (s, Rval v))

/\ (! env e v vs1 vs2 es env' bv s1 s2.
(evaluate_list F env s1 es (s2, Rval vs2) /\
(do_opapp ((REVERSE vs2 ++ [v]) ++ vs1) = SOME (env',e)) /\
evaluate F env' s2 e bv)
==>
evaluate_ctxt env s1 (Capp Opapp vs1 ()  es) v bv)

/\ (! env v vs1 vs2 es s1 s2.
(evaluate_list F env s1 es (s2, Rval vs2) /\
(do_opapp ((REVERSE vs2 ++ [v]) ++ vs1) = NONE))
==>
evaluate_ctxt env s1 (Capp Opapp vs1 ()  es) v (s2, Rerr (Rabort Rtype_error)))

/\ (! env op v vs1 vs2 es res s1 s2 new_refs new_ffi.
((op <> Opapp) /\
evaluate_list F env s1 es (s2, Rval vs2) /\
(do_app (s2.refs,s2.ffi) op ((REVERSE vs2 ++ [v]) ++ vs1) = SOME ((new_refs, new_ffi) ,res)))
==>
evaluate_ctxt env s1 (Capp op vs1 ()  es) v (( s2 with<| ffi := new_ffi; refs := new_refs |>), res))

/\ (! env op v vs1 vs2 es s1 s2.
((op <> Opapp) /\
evaluate_list F env s1 es (s2, Rval vs2) /\
(do_app (s2.refs, s2.ffi) op ((REVERSE vs2 ++ [v]) ++ vs1) = NONE))
==>
evaluate_ctxt env s1 (Capp op vs1 ()  es) v (s2, Rerr (Rabort Rtype_error)))

/\ (! env op es vs v err s s'.
(evaluate_list F env s es (s', Rerr err))
==>
evaluate_ctxt env s (Capp op vs ()  es) v (s', Rerr err))

/\ (! env op e2 v e' bv s.
((do_log op v e2 = SOME (Exp e')) /\
evaluate F env s e' bv)
==>
evaluate_ctxt env s (Clog op ()  e2) v bv)

/\ (! env op e2 v v' s.
(do_log op v e2 = SOME (Val v'))
==>
evaluate_ctxt env s (Clog op ()  e2) v (s, Rval v'))

/\ (! env op e2 v s.
(do_log op v e2 = NONE)
==>
evaluate_ctxt env s (Clog op ()  e2) v (s, Rerr (Rabort Rtype_error)))

/\ (! env e2 e3 v e' bv s.
((do_if v e2 e3 = SOME e') /\
evaluate F env s e' bv)
==>
evaluate_ctxt env s (Cif ()  e2 e3) v bv)

/\ (! env e2 e3 v s.
(do_if v e2 e3 = NONE)
==>
evaluate_ctxt env s (Cif ()  e2 e3) v (s, Rerr (Rabort Rtype_error)))

/\ (! env pes v bv s err_v.
(evaluate_match F env s v pes err_v bv)
==>
evaluate_ctxt env s (Cmat ()  pes err_v) v bv)

/\ (! env pes v bv s err_v.
(evaluate_match F env s v pes err_v bv /\
can_pmatch_all env.c s.refs (MAP FST pes) v)
==>
evaluate_ctxt env s (Cmat_check ()  pes err_v) v bv)

/\ (! env pes v s err_v.
(~ (can_pmatch_all env.c s.refs (MAP FST pes) v))
==>
evaluate_ctxt env s (Cmat_check ()  pes err_v) v (s, Rerr (Rabort Rtype_error)))

/\ (! env n e2 v bv s.
(evaluate F ( env with<| v := (nsOptBind n v env.v) |>) s e2 bv)
==>
evaluate_ctxt env s (Clet n ()  e2) v bv)

/\ (! env cn es vs v vs' s1 s2 v'.
(do_con_check env.c cn ((LENGTH vs + LENGTH es) +( 1 : num)) /\
(build_conv env.c cn ((REVERSE vs' ++ [v]) ++ vs) = SOME v') /\
evaluate_list F env s1 es (s2, Rval vs'))
==>
evaluate_ctxt env s1 (Ccon cn vs ()  es) v (s2, Rval v'))

/\ (! env cn es vs v s.
(~ (do_con_check env.c cn ((LENGTH vs + LENGTH es) +( 1 : num))))
==>
evaluate_ctxt env s (Ccon cn vs ()  es) v (s, Rerr (Rabort Rtype_error)))

/\ (! env cn es vs v err s s'.
(do_con_check env.c cn ((LENGTH vs + LENGTH es) +( 1 : num)) /\
evaluate_list F env s es (s', Rerr err))
==>
evaluate_ctxt env s (Ccon cn vs ()  es) v (s', Rerr err))

/\ (! env v s t.
T
==>
evaluate_ctxt env s (Ctannot ()  t) v (s, Rval v))

/\ (! env v s l.
T
==>
evaluate_ctxt env s (Clannot ()  l) v (s, Rval v))`;

val _ = Hol_reln ` (! res s.
T
==>
evaluate_ctxts s [] res (s, res))

/\ (! c cs env v res bv s1 s2.
(evaluate_ctxt env s1 c v (s2, res) /\
evaluate_ctxts s2 cs res bv)
==>
evaluate_ctxts s1 ((c,env)::cs) (Rval v) bv)

/\ (! c cs env err s bv.
(evaluate_ctxts s cs (Rerr err) bv /\
((! pes. c <> Chandle ()  pes) \/
 (! v. err <> Rraise v)))
==>
evaluate_ctxts s ((c,env)::cs) (Rerr err) bv)

/\ (! cs env s res2 pes v.
(~ (can_pmatch_all env.c s.refs (MAP FST pes) v) /\
evaluate_ctxts s cs (Rerr (Rabort Rtype_error)) res2)
==>
evaluate_ctxts s ((Chandle ()  pes,env)::cs) (Rerr (Rraise v)) res2)

/\ (! cs env s s' res1 res2 pes v.
(evaluate_match F env s v pes v (s', res1) /\
can_pmatch_all env.c s.refs (MAP FST pes) v /\
evaluate_ctxts s' cs res1 res2)
==>
evaluate_ctxts s ((Chandle ()  pes,env)::cs) (Rerr (Rraise v)) res2)`;

val _ = Hol_reln ` (! env e c res bv ffi refs st.
(evaluate F env <| ffi := ffi; clock :=(( 0 : num)); refs := refs; next_type_stamp :=(( 0 : num)); next_exn_stamp :=(( 0 : num)); eval_state := NONE |> e (st, res) /\
evaluate_ctxts st c res bv)
==>
evaluate_state (env, (refs, ffi), Exp e, c) bv)

/\ (! env ffi refs v c bv.
(evaluate_ctxts <| ffi := ffi; clock :=(( 0 : num)); refs := refs; next_type_stamp :=(( 0 : num)); next_exn_stamp :=(( 0 : num)); eval_state := NONE |> c (Rval v) bv)
==>
evaluate_state (env, (refs, ffi), Val v, c) bv)`;
val _ = export_theory()
