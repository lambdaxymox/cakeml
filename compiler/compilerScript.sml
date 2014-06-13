(*Generated by Lem from compiler.lem.*)
open HolKernel Parse boolLib bossLib;
open lem_pervasivesTheory semanticPrimitivesTheory astTheory compilerLibTheory intLangTheory toIntLangTheory toBytecodeTheory bytecodeTheory modLangTheory conLangTheory decLangTheory exhLangTheory patLangTheory;

val _ = numLib.prefer_num();



val _ = new_theory "compiler"

(*open import Pervasives*)
(*open import SemanticPrimitives*)
(*open import Ast*)
(*open import CompilerLib*)
(*open import IntLang*)
(*open import ToIntLang*)
(*open import ToBytecode*)
(*open import Bytecode*)
(*open String_extra*)
(*open import ModLang*)
(*open import ConLang*)
(*open import DecLang*)
(*open import ExhLang*)
(*open import PatLang*)

val _ = Hol_datatype `
 compiler_state =
  <| next_global : num
   ; globals_env : (modN, ( (varN, num)fmap)) fmap # (varN, num) fmap
   ; contags_env : num # tag_env # (num, (conN # tid_or_exn)) fmap
   ; exh : exh_ctors_env
   ; rnext_label : num
   |>`;


val _ = Define `
 (init_compiler_state =  
(<| next_global :=( 0)
   ; globals_env := (FEMPTY, FEMPTY)
   ; contags_env := init_tagenv_state
   ; exh := init_exh
   ; rnext_label :=( 0)
   |>))`;


val _ = Define `
 (compile_Cexp env rsz cs Ce =  
(let (Ce,nl) = (label_closures (LENGTH env) cs.next_label Ce) in
  let cs = (compile_code_env ( cs with<| next_label := nl |>) Ce) in
  compile env TCNonTail rsz cs Ce))`;


val _ = Define `
 (tystr types v =  
((case FLOOKUP types v of
      SOME t => t
    | NONE => "<unknown>"
  )))`;


 val _ = Define `

(compile_print_vals _ _ [] s = s)
/\
(compile_print_vals types map (v::vs) s =  
(let s = (emit s (MAP PrintC (EXPLODE (CONCAT ["val ";v;":"; tystr types v;" = "])))) in
  let s = (emit s [Gread (fapply( 0) v map); Print]) in
  let s = (emit s (MAP PrintC (EXPLODE "\n"))) in
    compile_print_vals types map vs s))`;


 val _ = Define `

(compile_print_ctors [] s = s)
/\
(compile_print_ctors ((c,_)::cs) s =  
(compile_print_ctors cs
    (emit s (MAP PrintC (EXPLODE (CONCAT [c;" = <constructor>\n"]))))))`;


 val _ = Define `

(compile_print_types [] s = s)
/\
(compile_print_types ((_,_,cs)::ts) s =  
(compile_print_types ts (compile_print_ctors (REVERSE cs) s)))`;


 val _ = Define `

(compile_print_dec _ _ (Dtype ts) s = (compile_print_types (REVERSE ts) s))
/\
(compile_print_dec _ _ (Dexn c xs) s = (compile_print_types [(([]: tvarN list),"exn",[(c,xs)])] s))
/\
(compile_print_dec types map (Dlet p _) s =  
(compile_print_vals types map (pat_bindings p []) s))
/\
(compile_print_dec types map (Dletrec defs) s =  
(compile_print_vals types map (MAP (\p .  
  (case (p ) of ( (n,_,_) ) => n )) defs) s))`;


val _ = Define `
 (compile_print_err cs =  
(let (cs,n) = (get_label cs) in
  let cs = (emit cs [Stack (Load( 0));
                    Stack (TagEq (block_tag+none_tag));
                    JumpIf (Lab n);
                    Stack (El( 0)) ]) in
  let cs = (emit cs (MAP PrintC (EXPLODE "raise "))) in
  let cs = (emit cs [Print]) in
  let cs = (emit cs (MAP PrintC (EXPLODE "\n"))) in
  let cs = (emit cs [Stop F; Label n; Stack Pop]) in
  cs))`;


val _ = Define `
 (compile_print_top types map top cs =  
(let cs = (compile_print_err cs) in
  let cs = ((case types of   NONE => cs | SOME types =>
    (case top of
      (Tmod mn _ _) =>
        let str = (CONCAT["structure ";mn;" = <structure>\n"]) in
        emit cs (MAP PrintC (EXPLODE str))
    | (Tdec dec) => compile_print_dec types map dec cs
    )    )) in
  emit cs [Stop T]))`;


val _ = Define `
 (compile_top types cs top =  
(let n = (cs.next_global) in
  let (m10,m20) = (cs.globals_env) in  
  (case top_to_i1 n m10 m20 top of
      (_,m1,m2,p) =>
  let (c,exh,p) = (prompt_to_i2 cs.contags_env p) in
  let (n,e) = (prompt_to_i3 (none_tag, SOME (TypeId (Short "option")))
                 (some_tag, SOME (TypeId (Short "option"))) n p) in
  let exh = (FUNION exh cs.exh) in
  let e = (exp_to_exh exh e) in
  let e = (exp_to_pat [] e) in
  let e = (exp_to_Cexp e) in
  let r = (compile_Cexp [] ( 0) <| out := []; next_label := cs.rnext_label |>
             e) in
  let r = (compile_print_top types m2 top r) in
  let cs = (<| next_global := n ; globals_env := (m1,m2) ; contags_env := c
            ; exh := exh ; rnext_label := r.next_label |>) in
  (cs, ( cs with<| globals_env := (m1,m20) |>), r.out)
  )))`;


val _ = Define `
 (compile_prog prog =  
(let n = (init_compiler_state.next_global) in
  let (m1,m2) = (init_compiler_state.globals_env) in  
  (case prog_to_i1 n m1 m2 prog of
      (_,_,m2,p) =>
  (case prog_to_i2 init_compiler_state.contags_env p of
      (_,exh,p) =>
  (case prog_to_i3 (none_tag, SOME (TypeId (Short "option")))
          (some_tag, SOME (TypeId (Short "option"))) n p of
      (_,e) =>
  let e = (exp_to_exh (FUNION exh init_compiler_state.exh) e) in
  let e = (exp_to_pat [] e) in
  let e = (exp_to_Cexp e) in
  let r = (compile_Cexp [] ( 0)
             <| out := []; next_label := init_compiler_state.rnext_label |> 
           e) in
  let r = (compile_print_err r) in
  let r = ((case FLOOKUP m2 "it" of
                 NONE => r
             | SOME n => let r = (emit r [Gread n; Print]) in
                         emit r (MAP PrintC (EXPLODE "\n"))
           )) in let r = (emit r [Stop T]) in REVERSE (r.out)
  )
  )
  )))`;

val _ = export_theory()

