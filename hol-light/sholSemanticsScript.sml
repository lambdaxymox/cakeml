open HolKernel boolLib bossLib lcsymtacs pred_setTheory listTheory finite_mapTheory sholSyntaxTheory modelSetTheory
val _ = numLib.prefer_num()
val _ = new_theory"sholSemantics"

val (semantics_rules,semantics_ind,semantics_cases) = Hol_reln`
  (typeset τ (Tyvar s) (τ s)) ∧

  (typeset τ (Tyapp (Typrim "bool" 0) []) boolset) ∧

  (typeset τ x mx ∧ typeset τ y my
   ⇒
   typeset τ (Tyapp (Typrim "->" 2) [x;y]) (funspace mx my)) ∧

  (LENGTH (tvars p) = LENGTH ts ∧
   tyin = ZIP (MAP Tyvar (STRING_SORT (tvars p)), ts) ∧
   INST tyin p has_type Fun rty Bool ∧
   semantics FEMPTY τ (INST tyin p) mp ∧
   typeset τ rty mrty
   ⇒
   typeset τ (Tyapp (Tydefined s p) ts) (mrty suchthat holds mp)) ∧

  (FLOOKUP σ (n,ty) = SOME m
   ⇒
   semantics σ τ (Var n ty) m) ∧

  (typeset τ ty mty
   ⇒
   semantics σ τ (Const "=" (Fun ty (Fun ty Bool)) Prim)
    (abstract mty (funspace mty boolset)
       (λx. abstract mty boolset (λy. boolean (x = y))))) ∧

  (typeset τ ty mty
   ⇒
   semantics σ τ (Const "@" (Fun (Fun ty Bool) ty) Prim)
     (abstract (funspace mty boolset) mty
       (λp. let mp = (mty suchthat holds p) in
            ch (if ∃x. x <: mp then mp else mty)))) ∧

  (welltyped t ∧ closed t ∧
   set(tvars t) ⊆ set (tyvars (typeof t)) ∧
   INST tyin t has_type ty ∧
   semantics FEMPTY τ (INST tyin t) mt
   ⇒
   semantics σ τ (Const s ty (Defined t)) mt) ∧

  (typeset τ rty mrty ∧
   typeset τ atr maty
   ⇒
   semantics σ τ (Const s (Fun aty rty) (Tyrep op p))
    (abstract maty mrty (λx. x))) ∧

  (typeset τ rty mrty ∧
   typeset τ atr maty ∧
   welltyped p ∧ closed p ∧
   INST tyin p has_type Fun rty Bool ∧
   semantics FEMPTY τ (INST tyin p) mp
   ⇒
   semantics σ τ (Const s (Fun rty aty) (Tyabs op p))
    (abstract mrty maty (λx. if holds mp x then x else ch maty))) ∧

  (semantics σ τ t mt ∧
   semantics σ τ u mu
   ⇒
   semantics σ τ (Comb t u) (apply mt mu)) ∧

  (typeset τ ty mty ∧
   b has_type tyb ∧
   typeset τ tyb mtyb ∧
   (∀x. semantics (σ |+ ((n,ty),x)) τ b (mb x))
   ⇒
   semantics σ τ (Abs n ty b) (abstract mty mtyb mb))`

val type_valuation_def = Define`
  type_valuation τ ⇔ ∀x. ∃y. y <: τ x`

val term_valuation_def = Define`
  term_valuation τ σ ⇔
    FEVERY (λ(v,m). ∀mty. typeset τ (SND v) mty ⇒ m <: mty) σ`

val _ = Parse.add_infix("|=",450,Parse.NONASSOC)

val sequent_def = xDefine"sequent"`
  h |= c ⇔ EVERY (λt. t has_type Bool) (c::h) ∧
           ∀σ τ. type_valuation τ ∧
                 term_valuation τ σ ∧
                 EVERY (λt. semantics σ τ t true) h
                 ⇒
                 semantics σ τ c true`

val term_valuation_FUPDATE = store_thm("term_valuation_FUPDATE",
  ``∀τ σ v m.
    term_valuation τ σ ∧
    (∀mty. typeset τ (SND v) mty ⇒ m <: mty)
    ⇒
    term_valuation τ (σ |+ (v,m))``,
  rw[term_valuation_def,FEVERY_DEF,FAPPLY_FUPDATE_THM]>>PROVE_TAC[])

val semantics_closed = store_thm("semantics_closed",
  ``∀t σ τ mt. semantics σ τ t mt ⇒
      ∀n ty. VFREE_IN (Var n ty) t ⇒ (n,ty) ∈ FDOM σ``,
  reverse Induct >- (
    simp[Once semantics_cases] >>
    rpt gen_tac >> strip_tac >>
    simp[CONJ_SYM] >>
    simp[GSYM AND_IMP_INTRO] >>
    rpt gen_tac >> strip_tac >>
    `(n,ty) ∈ FDOM (σ |+ ((s,t),x))` by PROVE_TAC[] >>
    fs[] ) >>
  simp[Once semantics_cases] >>
  simp[FLOOKUP_DEF] >>
  metis_tac[])

val type_ind =
  TypeBase.induction_of``:type``
  |> Q.SPECL[`K T`,`P`,`K T`,`K T`,`EVERY P`]
  |> SIMP_RULE std_ss [EVERY_DEF]
  |> UNDISCH_ALL
  |> CONJUNCT1
  |> DISCH_ALL
  |> Q.GEN`P`

val MEM_LIST_INSERT = store_thm("MEM_LIST_INSERT",
  ``∀l x. set (LIST_INSERT x l) = x INSERT set l``,
  Induct >> simp[LIST_INSERT_def] >> rw[] >>
  rw[EXTENSION] >> metis_tac[])

val MEM_LIST_UNION = store_thm("MEM_LIST_UNION",
  ``∀l1 l2. set (LIST_UNION l1 l2) = set l1 ∪ set l2``,
  Induct >> fs[LIST_UNION_def,MEM_LIST_INSERT] >>
  rw[EXTENSION] >> metis_tac[])

val TYPE_SUBST_tyvars = store_thm("TYPE_SUBST_tyvars",
  ``∀ty tyin tyin'.
    (TYPE_SUBST tyin ty = TYPE_SUBST tyin' ty) ⇔
    ∀x. MEM x (tyvars ty) ⇒
        REV_ASSOCD (Tyvar x) tyin' (Tyvar x) =
        REV_ASSOCD (Tyvar x) tyin  (Tyvar x)``,
  ho_match_mp_tac type_ind >>
  simp[tyvars_def] >>
  conj_tac >- metis_tac[] >>
  Induct >> simp[] >>
  gen_tac >> strip_tac >> fs[] >>
  rpt gen_tac >> EQ_TAC >> strip_tac >> fs[] >>
  fs[MEM_LIST_UNION] >> metis_tac[])

(*
val INST_CORE_tvars = store_thm("INST_CORE_tvars",
  ``∀t env tyin tyin'.
    (∀x. MEM x (tvars t) ⇒
         REV_ASSOCD (Tyvar x) tyin' (Tyvar x) =
         REV_ASSOCD (Tyvar x) tyin  (Tyvar x))
    ⇒
    INST_CORE env tyin t = INST_CORE env tyin' t``,
  Induct >- (
    simp[INST_CORE_def] >>
    rw[]
  ho_match_mp_tac term_ind

val semantics_11 = store_thm("semantics_11",
  ``(∀τ ty mty. typeset τ ty mty ⇒
        ∀mty'. typeset τ ty mty' ⇒ mty' = mty) ∧
    (∀σ τ t mt. semantics σ τ t mt ⇒
        ∀mt'. semantics σ τ t mt' ⇒ mt' = mt)``,
  ho_match_mp_tac semantics_ind >>
  conj_tac >- simp[Once semantics_cases] >>
  conj_tac >- simp[Once semantics_cases] >>
  conj_tac >- (
    rpt gen_tac >> strip_tac >>
    simp[Once semantics_cases] >>
    PROVE_TAC[] ) >>
  conj_tac >- (
    rpt gen_tac >> strip_tac >>
    simp[Once semantics_cases] >> rw[] >>
    `Fun ty Bool = Fun rty Bool` by (
      metis_tac[WELLTYPED_LEMMA] ) >>
    fs[] ) >>
  conj_tac >- simp[Once semantics_cases] >>
  conj_tac >- (
    rpt gen_tac >> strip_tac >>
    simp[Once semantics_cases] >> rw[] >> rw[]) >>
  conj_tac >- (
    rpt gen_tac >> strip_tac >>
    simp[Once semantics_cases] >> rw[] >> rw[]) >>
  conj_tac >- (
    rpt gen_tac >> strip_tac >>
    simp[Once semantics_cases] >> rw[] >> rw[] >>
    qspecl_then[`sizeof t`,`t`,`[]`,`tyin`]mp_tac INST_CORE_HAS_TYPE >>
    qspecl_then[`sizeof t`,`t`,`[]`,`tyin'`]mp_tac INST_CORE_HAS_TYPE >>
    simp[] >> ntac 2 strip_tac >> fs[INST_def] >>
    imp_res_tac WELLTYPED_LEMMA >> rw[] >> fs[]

    `tyt' = tyt` by metis_tac[WELLTYPED_LEMMA] >> rw[] >>
    TYPE_SUBST
    print_find"TYPE_SUBST"

    ) >>


val semantics_typeset = store_thm("semantics_typeset",
  ``∀tm ty. tm has_type ty ⇒
      ∀σ τ mtm mty. type_valuation τ ∧ term_valuation τ σ ∧
                    typeset τ ty mty ∧ semantics σ τ tm mtm
                    ⇒ mtm <: mty``,
  ho_match_mp_tac has_type_strongind >>
  conj_tac >- (
    simp[Once (CONJUNCT2 semantics_cases)] >>
    rw[term_valuation_def] >>
    imp_res_tac FEVERY_FLOOKUP >> fs[]) >>
  conj_tac >- (
    rpt gen_tac >> strip_tac >>
    pop_assum mp_tac >>
    simp[Once (CONJUNCT2 semantics_cases)] >>
    rw[] >- (
      qpat_assum`typeset τ (Fun X Y) Z`mp_tac >>
      simp[Once (CONJUNCT1 semantics_cases)] >> strip_tac >>
      qpat_assum`typeset τ (Fun X Y) Z`mp_tac >>
      simp[Once (CONJUNCT1 semantics_cases)] >> strip_tac >>
      pop_assum mp_tac >>
      simp[Once (CONJUNCT1 semantics_cases)] >> strip_tac >>
      rpt BasicProvers.VAR_EQ_TAC >>
      match_mp_tac ABSTRACT_IN_FUNSPACE

      print_apropos``x <: funspace y z``


val semantics_typeset = store_thm("semantics_typeset",
  ``(∀τ ty mty. typeset τ ty mty ⇒
        ∀σ t mt. type_valuation τ ∧ term_valuation τ σ ∧
                 t has_type ty ∧ semantics σ τ t mt ⇒
                 mt <: mty) ∧
    (∀σ τ t mt. semantics σ τ t mt ⇒
        ∀ty mty. type_valuation τ ∧ term_valuation τ σ ∧
                 t has_type ty ∧ typeset τ ty mty ⇒
                 mt <: mty)``,

  ho_match_mp_tac semantics_ind >>
  simp[INDSET_INHABITED,FUNSPACE_INHABITED] >>
  conj_tac >- simp[type_valuation_def] >>
  conj_tac >- metis_tac[BOOLEAN_IN_BOOLSET] >>

  gen_tac >> Induct >> simp[Once semantics_cases]
  Induct
*)

val _ = export_theory()
