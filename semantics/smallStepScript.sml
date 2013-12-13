(*Generated by Lem from smallStep.lem.*)
open HolKernel Parse boolLib bossLib;
open lem_pervasives_extraTheory libTheory astTheory semanticPrimitivesTheory;

val _ = numLib.prefer_num();



val _ = new_theory "smallStep"

(*open import Pervasives_extra*)
(*open import Lib*)
(*open import Ast*) 
(*open import SemanticPrimitives*)

(* Small-step semantics for expression only.  Modules and definitions have
 * big-step semantics only *)

(* Evaluation contexts
 * The hole is denoted by the unit type
 * The env argument contains bindings for the free variables of expressions in
     the context *)
val _ = Hol_datatype `
 ctxt_frame =
    Craise of unit
  | Chandle of unit => (pat # exp) list
  | Capp1 of op => unit => exp
  | Capp2 of op => v => unit
  | Clog of lop => unit => exp
  | Cif of unit => exp => exp
  (* The value is raised if none of the patterns match *)
  | Cmat of unit => (pat # exp) list => v
  | Clet of varN => unit => exp
  (* Evaluating a constructor's arguments
   * The v list should be in reverse order. *)
  | Ccon of  ( conN id)option => v list => unit => exp list
  | Cuapp of uop => unit`;

val _ = type_abbrev( "ctxt" , ``: ctxt_frame # all_env``);

(* State for CEK-style expression evaluation
 * - constructor data
 * - the store
 * - the environment for the free variables of the current expression
 * - the current expression to evaluate, or a value if finished
 * - the context stack (continuation) of what to do once the current expression
 *   is finished.  Each entry has an environment for it's free variables *)
val _ = Hol_datatype `
 exp_or_val =
    Exp of exp
  | Val of v`;


val _ = type_abbrev( "state" , ``: all_env # store # exp_or_val # ctxt list``);

val _ = Hol_datatype `
 e_step_result =
    Estep of state
  | Etype_error
  | Estuck`;


(* The semantics are deterministic, and presented functionally instead of
 * relationally for proof rather that readability; the steps are very small: we
 * push individual frames onto the context stack instead of finding a redex in a
 * single step *)

(*val push : all_env -> store -> exp -> ctxt_frame -> list ctxt -> e_step_result*)
val _ = Define `
 (push env s e c' cs = (Estep (env, s, Exp e, ((c',env)::cs))))`;


(*val return : all_env -> store -> v -> list ctxt -> e_step_result*)
val _ = Define `
 (return env s v c = (Estep (env, s, Val v, c)))`;


(* apply a context to a value *)
(*val continue : store -> v -> list ctxt -> e_step_result*)
val _ = Define `
 (continue s v cs =  
((case cs of
      [] => Estuck
    | (Craise () , env) :: c=>
        (case c of
            [] => Estuck
          | ((Chandle ()  pes,env') :: c) =>
              Estep (env,s,Val v,((Cmat ()  pes v, env')::c))
          | _::c => Estep (env,s,Val v,((Craise () ,env)::c))
        )
    | (Chandle ()  pes, env) :: c =>
        return env s v c
    | (Capp1 op ()  e, env) :: c =>
        push env s e (Capp2 op v () ) c
    | (Capp2 op v' () , env) :: c =>
        (case do_app env s op v' v of
            SOME (env,s',e) => Estep (env, s', Exp e, c)
          | NONE => Etype_error
        )
    | (Clog l ()  e, env) :: c =>
        (case do_log l v e of
            SOME e => Estep (env, s, Exp e, c)
          | NONE => Etype_error
        )
    | (Cif ()  e1 e2, env) :: c =>
        (case do_if v e1 e2 of
            SOME e => Estep (env, s, Exp e, c)
          | NONE => Etype_error
        )
    | (Cmat ()  [] err_v, env) :: c =>
        Estep (env, s, Val err_v, ((Craise () , env) ::c))
    | (Cmat ()  ((p,e)::pes) err_v, (menv, cenv, env)) :: c =>
        if ALL_DISTINCT (pat_bindings p []) then
          (case pmatch cenv s p v env of
              Match_type_error => Etype_error
            | No_match => Estep ((menv, cenv, env), s, Val v, ((Cmat ()  pes err_v,(menv, cenv, env))::c))
            | Match env' => Estep ((menv, cenv, env'), s, Exp e, c)
          )
        else
          Etype_error
    | (Clet n ()  e, (menv, cenv, env)) :: c =>
        Estep ((menv, cenv, bind n v env), s, Exp e, c)
    | (Ccon n vs ()  [], env) :: c =>
        if do_con_check (all_env_to_cenv env) n (LENGTH vs + 1) then
          return env s (Conv n (REVERSE (v::vs))) c
        else
          Etype_error
    | (Ccon n vs ()  (e::es), env) :: c =>
        if do_con_check (all_env_to_cenv env) n (((LENGTH vs + 1) + 1) + LENGTH es) then
          push env s e (Ccon n (v::vs) ()  es) c
        else
          Etype_error
    | (Cuapp uop () , env) :: c =>
       (case do_uapp s uop v of
           SOME (s',v') => return env s' v' c
         | NONE => Etype_error
       )
  )))`;


(* The single step expression evaluator.  Returns None if there is nothing to
 * do, but no type error.  Returns Type_error on encountering free variables,
 * mis-applied (or non-existent) constructors, and when the wrong kind of value
 * if given to a primitive.  Returns Bind_error when no pattern in a match
 * matches the value.  Otherwise it returns the next state *)

(*val e_step : state -> e_step_result*)
val _ = Define `
 (e_step (env, s, ev, c) =  
((case ev of
      Val v  =>
	continue s v c
    | Exp e =>
        (case e of
            Lit l => return env s (Litv l) c
          | Raise e =>
              push env s e (Craise () ) c
          | Handle e pes =>
              push env s e (Chandle ()  pes) c
          | Con n es =>
              if do_con_check (all_env_to_cenv env) n (LENGTH es) then
                (case es of
                    [] => return env s (Conv n []) c
                  | e::es =>
                      push env s e (Ccon n [] ()  es) c
                )
              else
                Etype_error
          | Var n =>
              (case lookup_var_id n env of
                  NONE => Etype_error
                | SOME v => 
                    return env s v c
              )
          | Fun n e => return env s (Closure env n e) c
          | App op e1 e2 => push env s e1 (Capp1 op ()  e2) c
          | Log l e1 e2 => push env s e1 (Clog l ()  e2) c
          | If e1 e2 e3 => push env s e1 (Cif ()  e2 e3) c
          | Mat e pes => push env s e (Cmat ()  pes (Conv (SOME (Short "Bind")) [])) c
          | Let n e1 e2 => push env s e1 (Clet n ()  e2) c
          | Letrec funs e =>
              if ~ (ALL_DISTINCT (MAP (\ (x,y,z) .  x) funs)) then
                Etype_error
              else
                Estep ((all_env_to_menv env, all_env_to_cenv env, build_rec_env funs env (all_env_to_env env)), 
                       s, Exp e, c)
          | Uapp uop e =>
              push env s e (Cuapp uop () ) c
        )
  )))`;


(* Define a semantic function using the steps *)

(*val e_step_reln : state -> state -> bool*)
(*val small_eval : all_env -> store -> exp -> list ctxt -> store * result v -> bool*)

val _ = Define `
 (e_step_reln st1 st2 =
  (e_step st1 = Estep st2))`;


 val _ = Define `

(small_eval env s e c (s', Rval v) =  
(? env'. (RTC e_step_reln) (env,s,Exp e,c) (env',s',Val v,[])))
/\
(small_eval env s e c (s', Rerr (Rraise v)) =  
(? env' env''. (RTC e_step_reln) (env,s,Exp e,c) (env',s',Val v,[(Craise () , env'')])))
/\
(small_eval env s e c (s', Rerr Rtype_error) =  
(? env' e' c'.
    (RTC e_step_reln) (env,s,Exp e,c) (env',s',e',c') /\
    (e_step (env',s',e',c') = Etype_error)))
/\
(small_eval env s e c (s', Rerr Rtimeout_error) = F)`;


(*val e_diverges : all_env -> store -> exp -> bool*)
val _ = Define `
 (e_diverges env s e =  
(! env' s' e' c'.
    (RTC e_step_reln) (env,s,Exp e,[]) (env',s',e',c')
    ==>    
(? env'' s'' e'' c''.
      e_step_reln (env',s',e',c') (env'',s'',e'',c''))))`;


val _ = export_theory()

