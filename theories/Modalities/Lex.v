(* -*- mode: coq; mode: visual-line -*- *)
Require Import HoTT.Basics HoTT.Types.
Require Import EquivalenceVarieties Fibrations Extensions Pullback NullHomotopy Factorization.
Require Import Modality Accessible.
Require Import HoTT.Tactics.

Local Open Scope path_scope.


(** * Lex modalities *)

(** ** Basic theory *)

(** A lex modality is one that preserves finite limits, or equivalently pullbacks.  It turns out that a more basic and useful way to say this is that all path-spaces of connected types are connected.  Note how different this is from the behavior of, say, truncation modalities!

  This is a "large" definition, and we don't know of any small one that's equivalent to it (see <https://mathoverflow.net/questions/185980/a-small-definition-of-sub-∞-1-topoi>.  However, so far we never need to apply it "at multiple universes at once".  Thus, rather than making it a module type, we can make it a typeclass and rely on ordinary universe polymorphism. *)

Module Lex_Modalities_Theory (Os : Modalities).

  Module Export Os_Theory := Modalities_Theory Os.

  Class Lex (O : Modality@{u a})
    := isconnected_paths : forall (A : Type@{i}) (x y : A),
                             IsConnected@{u a i} O A ->
                             IsConnected@{u a i} O (x = y).

  Global Existing Instance isconnected_paths.

  (** The following numbered lemmas are all actually equivalent characterizations of lex-ness.  We prove this for some of them, but we don't make the reverse implications Instances; usually [isconnected_paths] is the easier way to prove lexness. *)

  (** 1. Every map between connected types is a connected map. *)
  Global Instance conn_map_lex {O : Modality} `{Lex O}
         {A : Type@{i}} {B : Type@{j}} {f : A -> B}
         `{IsConnected O A} `{IsConnected O B}
  : IsConnMap O f.
  Proof.
    intros b; refine (isconnected_sigma O).
  Defined.

  Definition lex_from_conn_map_lex {O : Modality}
             (H : forall A B (f : A -> B),
                         (IsConnected O A) -> (IsConnected O B) ->
                         IsConnMap O f)
    : Lex O.
  Proof.
    intros A x y AC.
    refine (isconnected_equiv' O (hfiber (unit_name x) y) _ _).
    unfold hfiber.
    refine (equiv_contr_sigma (fun _ => x = y)).
  Defined.

  (** 2. Connected maps are left- as well as right-cancellable. *)
  Definition cancelL_conn_map (O : Modality) `{Lex O}
             {A B C : Type} (f : A -> B) (g : B -> C)
  : IsConnMap O g -> IsConnMap O (g o f) -> IsConnMap O f.
  Proof.
    intros ? ? b.
    refine (isconnected_equiv O _ (hfiber_hfiber_compose_map f g b) _).
  Defined.

  (** 3. Every map inverted by [O] is [O]-connected. *)
  Definition isconnected_O_inverts (O : Modality) `{Lex O}
             {A B : Type} (f : A -> B) `{O_inverts O f}
  : IsConnMap O f.
  Proof.
    refine (cancelL_conn_map O f (to O B) _ _).
    refine (conn_map_homotopic O _ _ (to_O_natural O f) _).
    (** Typeclass magic! *)
  Defined.

  (** 4. Connected types are closed under pullbacks.  (Closure under fibers is [conn_map_lex] above. *)
  Global Instance isconnected_pullback (O : Modality) `{Lex O}
         {A B C : Type} {f : A -> C} {g : B -> C}
         `{IsConnected O A} `{IsConnected O B} `{IsConnected O C}
  : IsConnected O (Pullback f g).
  Proof.
    apply isconnected_sigma; [ exact _ | intros a ].
    refine (isconnected_equiv O (hfiber g (f a))
                              (equiv_functor_sigma' (equiv_idmap _)
                              (fun b => equiv_path_inverse _ _))
                              _).
  Defined.

  (** 5. The reflector preserves pullbacks.  This justifies the terminology "lex". *)
  Definition O_functor_pullback (O : Modality) `{Lex O}
             {A B C} (f : B -> A) (g : C -> A)
  : IsPullback (O_functor_square O _ _ _ _ (pullback_commsq f g)).
  Proof.
    refine (isequiv_O_inverts O _).
    refine (O_inverts_conn_map O _).
    refine (cancelR_conn_map O (to O (Pullback f g)) _).
    refine (conn_map_homotopic O
             (functor_pullback f g (O_functor O f) (O_functor O g)
                               (to O A) (to O B) (to O C)
                               (to_O_natural O f) (to_O_natural O g))
             _ _ _).
    (** This *seems* like it ought to be the easier goal, but it turns out to involve lots of naturality wrangling.  If we ever want to make real use of this theorem, we might want to separate out this goal into an opaque lemma so we could make the main theorem transparent. *)
    - intros [b [c e]];
        unfold functor_pullback, functor_sigma, pullback_corec;
        simpl.
      refine (path_sigma' _ (to_O_natural O pullback_pr1 (b;(c;e)))^ _).
      rewrite transport_sigma'; simpl.
      refine (path_sigma' _ (to_O_natural O pullback_pr2 (b;(c;e)))^ _).
      rewrite transport_paths_Fl.
      rewrite transport_paths_Fr.
      Open Scope long_path_scope.
      unfold O_functor_square.
      rewrite ap_V, inv_V, O_functor_homotopy_beta, !concat_p_pp.
      unfold pullback_commsq; simpl.
      rewrite to_O_natural_compose, !concat_pp_p.
      do 3 apply whiskerL.
      rewrite ap_V, <- inv_pp.
      rewrite <- (inv_V (O_functor_compose _ _ _ _)), <- inv_pp.
      apply inverse2, to_O_natural_compose.
      Close Scope long_path_scope.
    (** By contrast, this goal, which seems to contain all the mathematical content, is solved fairly easily by [hfiber_functor_pullback] and typeclass magic invoking [isconnected_pullback]. *)
    - intros [ob [oc oe]].
      refine (isconnected_equiv O _
                (hfiber_functor_pullback _ _ _ _ _ _ _ _ _ _)^-1 _).
  Qed.

  (** 6. The reflector preserves fibers.  This is a slightly simpler version of the previous. *)
  Global Instance isequiv_O_functor_hfiber (O : Modality) `{Lex O}
             {A B} (f : A -> B) (b : B)
  : IsEquiv (O_functor_hfiber O f b).
  Proof.
    refine (isequiv_O_inverts O _).
    apply O_inverts_conn_map.
    refine (cancelR_conn_map O (to O _) _).
    unfold O_functor_hfiber.
    refine (conn_map_homotopic O
             (@functor_hfiber _ _ _ _ f (O_functor O f)
                               (to O A) (to O B)
                               (fun x => (to_O_natural O f x)^) b)
             _ _ _).
    - intros [a p].
      rewrite O_rec_beta.
      unfold functor_hfiber, functor_sigma. apply ap.
      apply whiskerR, inv_V.
    - intros [oa p].
      refine (isconnected_equiv O _
               (hfiber_functor_hfiber _ _ _ _)^-1 _).
  Defined.

  Definition equiv_O_functor_hfiber (O : Modality) `{Lex O}
             {A B} (f : A -> B) (b : B)
  : O (hfiber f b) <~> hfiber (O_functor O f) (to O B b)
    := BuildEquiv _ _ (O_functor_hfiber O f b) _.

  (** 7. Lex modalities preserve path-spaces. *)
  Definition O_path_cmp (O : Modality) {A} (x y : A)
  : O (x = y) -> (to O A x = to O A y)
    := O_rec (ap (to O A)).

  Global Instance isequiv_O_path_cmp {O : Modality} `{Lex O} {A} (x y : A)
  : IsEquiv (O_path_cmp O x y).
  Proof.
    refine (isequiv_conn_ino_map O _).
    refine (cancelR_conn_map O (to O (x = y)) _).
    refine (conn_map_homotopic O (ap (to O A)) _ _ _).
    - intros ?; symmetry; by apply O_rec_beta.
    - intros p.
      refine (isconnected_equiv O _ (hfiber_ap p)^-1 _).
  Defined.

  (** 8. Any modal map between connected types is an equivalence. *)
  Global Instance isequiv_ismodal_isconnected_types
         {O : Modality} `{Lex O} {A B} {f : A -> B}
         `{IsConnected O A} `{IsConnected O B} `{MapIn O _ _ f}
    : IsEquiv f.
  Proof.
    apply (isequiv_conn_ino_map O); exact _.
  Defined.

  Definition lex_from_isequiv_ismodal_isconnected_types
             {O : Modality}
             (H : forall A B (f : A -> B),
                         (IsConnected O A) -> (IsConnected O B) -> 
                         (MapIn O f) -> IsEquiv f)
    : Lex O.
  Proof.
    apply lex_from_conn_map_lex.
    intros A B f AC BC.
    apply (conn_map_homotopic O _ _ (fact_factors (image O f))).
    apply conn_map_compose; [ exact _ | ].
    apply conn_map_isequiv.
    apply H; [ | exact _ | exact _ ].
    apply isconnected_conn_map_to_unit.
    apply (cancelR_conn_map O (factor1 (image O f)) (const tt)).
  Defined.

  (** 9. Any commutative square with connected maps in one direction and modal ones in the other must necessarily be a pullback. *)
  Definition ispullback_connmap_mapino_commsq (O : Modality) `{Lex O} {A B C D}
             {f : A -> B} {g : C -> D} {h : A -> C} {k : B -> D}
             `{IsConnMap O _ _ f} `{IsConnMap O _ _ g}
             `{MapIn O _ _ h} `{MapIn O _ _ k}
             (p : k o f == g o h)
  : IsPullback p.
  Proof.
    refine (isequiv_conn_ino_map O (pullback_corec p)).
    - refine (cancelL_conn_map O (pullback_corec p) (k^* g) _ _).
    - refine (cancelL_mapinO O _ (equiv_pullback_symm k g) _ _).
      refine (cancelL_mapinO O _ (g^* k) _ _).
  Defined.

  Definition lex_from_ispullback_connmap_mapino_commsq (O : Modality)
             (H : forall {A B C D}
                         (f : A -> B) (g : C -> D) (h : A -> C) (k : B -> D),
                 (IsConnMap O f) -> (IsConnMap O g) ->
                 (MapIn O h) -> (MapIn O k) ->
                 forall (p : k o f == g o h), IsPullback p)
    : Lex O.
  Proof.
    apply lex_from_isequiv_ismodal_isconnected_types.
    intros A B f AC BC fM.
    specialize (H A Unit B Unit (const tt) (const tt) f idmap _ _ _ _
               (fun _ => 1)).
    unfold IsPullback, pullback_corec in H.
    refine (@isequiv_compose _ _ _ H _ (fun x => x.2.1) _).
    unfold Pullback.
    refine (@isequiv_compose _ {b:Unit & B}
                             (functor_sigma idmap (fun a => pr1))
                             _ _ pr2 _).
    refine (@isequiv_compose _ _ (equiv_sigma_prod0 Unit B)
                             _ _ snd _).
    apply (equiv_isequiv (prod_unit_l B)).
  Defined.

  (** 10. Families of modal types indexed by connected types are constant. *)
  Definition modal_over_connected_isconst_lex (O : Modality) `{Lex O}
             (A : Type) `{IsConnected O A} (P : A -> Type) `{forall x, In O (P x)}
    : {Q : Type & In O Q * forall x, P x <~> Q}.
  Proof.
    exists (O {x:A & P x}); split; [ exact _ | intros x].
    refine (BuildEquiv _ _ (fun p => to O _ (x ; p)) _).
    refine (isequiv_conn_map_ino O _).
    revert x.
    apply conn_map_fiber.
    refine (cancelL_conn_map O _ (fun z:{x:A & O {x : A & P x}} => z.2) _ _).
    intros z.
    refine (isconnected_equiv' O A _ _).
    unfold hfiber.
    refine (equiv_adjointify (fun x => ((x ; z) ; 1))
                             (fun y => y.1.1) _ _). 
    - intros [[x y] []]; reflexivity.
    - intros x; reflexivity.
  Defined.

  (** And conversely. *)
  Definition lex_from_modal_over_connected_isconst (O : Modality)
             (H : forall (A : Type) (P : A -> Type),
                 (IsConnected O A) -> (forall x, In O (P x)) ->
                 {Q : Type & In O Q * forall x, P x <~> Q})
    : Lex O.
  Proof.
    intros A x y ?.
    apply isconnected_from_elim_to_O.
    (** By assumption, [fun y => O (x = y) : A -> Type_ O] is constant.  Thus, [to O (x=x) 1] can be transported around to make it contractible everywhere. *)
    specialize (H A (fun z => O (x = z)) _ _).
    destruct H as [Q [? H]].
    unfold NullHomotopy.
    exists ((H y)^-1 ((H x) (to O _ 1))).
    intros [].
    symmetry; apply eissect.
  Defined.

  (** Lex modalities preserve [n]-types for all [n].  This is definitely not equivalent to lex-ness, since it is true for the truncation modalities that are not lex.  But it is also not true of all modalities; e.g. the shape modality in a cohesive topos can take 0-types to [oo]-types. *)
  Global Instance istrunc_O_lex `{Funext} {O : Modality} `{Lex O}
         {n} {A} `{IsTrunc n A}
  : IsTrunc n (O A).
  Proof.
    generalize dependent A; simple_induction n n IHn; intros A ?.
    - exact _.               (** Already proven for all modalities. *)
    - refine (O_ind (fun x => forall y, IsTrunc n (x = y)) _); intros x.
      refine (O_ind (fun y => IsTrunc n (to O A x = y)) _); intros y.
      refine (trunc_equiv _ (O_path_cmp O x y)).
  Defined.

End Lex_Modalities_Theory.

(** ** Lex reflective subuniverses *)

(** A reflective subuniverse that preserves fibers is in fact a modality (and hence lex). *)
Module Type Preserves_Fibers (Os : ReflectiveSubuniverses).

  Export Os.
  Module Export Os_Theory := ReflectiveSubuniverses_Theory Os.

  Parameter isequiv_O_functor_hfiber :
     forall (O : ReflectiveSubuniverse) {A B} (f : A -> B) (b : B),
       IsEquiv (O_functor_hfiber O f b).

End Preserves_Fibers.

Module Lex_Reflective_Subuniverses
       (Os : ReflectiveSubuniverses) (Opf : Preserves_Fibers Os)
  <: SigmaClosed Os.

  Import Opf.

  Definition inO_sigma@{u a i j k} (O : ReflectiveSubuniverse@{u a})
             (A:Type@{i}) (B:A -> Type@{j})
             (A_inO : In@{u a i} O A)
             (B_inO : forall a, In@{u a j} O (B a))
  : In@{u a k} O {x:A & B x}.
  Proof.
    pose (g := O_rec@{u a k i k k i} pr1 : O {x : A & B x} -> A).
    transparent assert (p : (forall x, g (to O _ x) = x.1)).
    { intros x; subst g; apply O_rec_beta. }
    apply inO_isequiv_to_O@{u a k k}.
    apply isequiv_fcontr; intros x.
    refine (contr_equiv' _ (hfiber_hfiber_compose_map@{k k i k k k k k} _ g x)).
    apply fcontr_isequiv.
    unfold hfiber_compose_map.
    transparent assert (h : (Equiv@{k k} (hfiber@{k i} (@pr1 A B) (g x))
                                         (hfiber@{k i} g (g x)))).
    { refine (_ oE equiv_to_O@{u a k k} O _).
      refine (_ oE BuildEquiv _ _
                (O_functor_hfiber O (@pr1 A B) (g x)) _).
      unfold hfiber.
      refine (equiv_functor_sigma' 1 _). intros y; cbn.
      refine (_ oE (equiv_moveR_equiv_V _ _)).
      apply equiv_concat_l.
      apply moveL_equiv_V.
      unfold g, O_functor.
      revert y; apply O_indpaths@{u a k i i k k}; intros [a q]; cbn.
      refine (_ @ (O_rec_beta _ _)^).
      apply ap, O_rec_beta. }
    refine (isequiv_homotopic (h oE equiv_hfiber_homotopic _ _ p (g x)) _).
    intros [[a b] q]; cbn. clear h.
    unfold O_functor_hfiber.
    rewrite O_rec_beta.
    unfold functor_sigma; cbn.
    refine (path_sigma' _ 1 _).
    rewrite O_indpaths_beta; cbn.
    unfold moveL_equiv_V, moveR_equiv_V.
    Open Scope long_path_scope.
    Local Opaque eissect. (* work around bug 4533 *)
    set (k := @eissect); change @eissect with k; subst k. (* work around bug 4543 *)
    rewrite !ap_pp, !concat_p_pp, !ap_V.
    unfold to_O_natural.
    rewrite concat_pV_p.
    subst p.
    rewrite concat_pp_V.
    rewrite concat_pp_p; apply moveR_Vp.
    rewrite <- !(ap_compose (to O A) (to O A)^-1).
    rapply @concat_A1p.
    Local Transparent eissect. (* work around bug 4533 *)
    Close Scope long_path_scope.
  Qed.

End Lex_Reflective_Subuniverses.

(** ** Accessible lex modalities *)

(** We now restrict to lex modalities that are also accessible. *)
Module Accessible_Lex_Modalities_Theory
       (Os : Modalities)
       (Acc : Accessible_Modalities Os).

  Module Export Acc_Theory := Accessible_Modalities_Theory Os Acc.
  Module Export Lex_Theory := Lex_Modalities_Theory Os.

  (** Unfortunately, another subtlety of modules bites us here.  It appears that each application of a parametrized module to arguments creates a *new* module, and Coq has no algorithm (not even syntactic identity) for considering two such modules "the same".  In particular, the applications [Module Os_Theory := Modalities_Theory Os] that occur in both [Accessible_Modalities_Theory Os Acc] and [Lex_Modalities_Theory Os] create two *different* modules, which appear here as [Acc_Theory.Os_Theory] and [Lex_Theory.Os_Theory].  Thus, for instance, we have two different definitions [Acc_Theory.Os_Theory.O_ind] and [Lex_Theory.Os_Theory.O_ind], etc.

  Fortunately, since these duplicate pairs of definitions each have the same body *and are (usually) transparent*, Coq is willing to consider them identical.  Thus, this doesn't cause a great deal of trouble.  However, there are certain contexts in which this doesn't apply.  For instance, if any definition in [Modalities_Theory] is opaque, then Coq will be unable to notice that its duplicate copies in [Acc_Theory.Os_Theory] and [Lex_Theory.Os_Theory] were identical, potentially causing problems.  But since we generally only make definitions opaque if we aren't going to depend on their actual value anywhere else, this is unlikely to be much of an issue.

  A more serious issue is that there are some declarations that function up to a syntactic equality that is stricter than judgmental conversion.  For instance, [Inductive] and [Record] definitions, like modules, always create a new object not convertible to any previously existing one.  There are no [Inductive] or [Record] definitions in [Modalities_Theory], but there are [Class] declarations, and these function similarly.  In particular, typeclass search is unable to use [Instance]s defined in [Acc_Theory] to instantiate typeclasses from [Modalities_Theory] (such as [IsConnected]) needed by functions in [Lex_Theory], and vice versa.

  Fortunately, all the typeclasses defined in [Modalities_Theory] are *singleton* or *definitional* classes (defined with `:= unique_field` rather than `{ field1 ; field2 ; ... }`), which means that they do not actually introduce a new record wrapper.  Thus, the [Instance]s from [Acc_Theory] can in fact be typechecked to *belong* to the typeclasses needed by [Lex_Theory], and hence can be supplied explicitly.

  We can also do this once and for all by defining [Instance]s translating automatically between the two typeclasses, although unfortunately we probably can't declare such instances in both directions at once for fear of infinite loops.  Fortunately, there is not a lot in [Acc_Theory], so this direction seems likely to be the most useful. *)

  Global Instance isconnected_acc_to_lex {O : Modality} {A : Type}
         {H : Acc_Theory.Os_Theory.RSU.IsConnected O A}
            : Lex_Theory.Os_Theory.RSU.IsConnected O A
         := H.

  (** Probably the most important thing about an accessible lex modality is that the universe of modal types is again modal.  Here by "the universe" we mean a universe large enough to contain the generating family; this is why we need accessibility. *)
  Global Instance inO_typeO `{Univalence} (O : Modality) `{Lex O}
  : In O (Type_ O).
  Proof.
    apply (snd (inO_iff_isnull O _)); intros i n; simpl in *.
    destruct n; [ exact tt | split ].
    - intros P.
      (** The case [n=0] is basically just one of the above characterizations of lex-ness. *)
      destruct (modal_over_connected_isconst_lex O (acc_gen O i) P)
        as [Q [QinO f]].
      exists (fun _ => (Q ; QinO)).
      intros x; symmetry; apply path_TypeO. 
      refine (path_universe (f x)).
    - intros A B.
      (** The case [n>0] is actually quite easy, using univalence and the fact that modal types are closed under [Equiv]. *)
      refine (extendable_postcompose' n _ _ _
                (fun b => (equiv_path_TypeO O (A b) (B b))
                            oE (equiv_path_universe (A b) (B b)))
                _).
      refine (extendable_conn_map_inO O n (@const (acc_gen O i) Unit tt)
                                      (fun b => A b <~> B b)).
      (** Typeclass magic! *)
  Defined.

  (** [inO_typeO] is also an equivalent characterization of lex-ness for a modality, by the converse of the characterization of lex-ness we used above. *)
  Definition lex_inO_typeO (O : Modality) `{In O (Type_ O)}
  : Lex O.
  Proof.
    apply lex_from_modal_over_connected_isconst.
    intros A P ? PO.
    destruct (isconnected_elim O (Type_ O) (fun x => (P x ; PO x)))
      as [Q f].
    exists Q; split; [ exact _ | intros x ].
    apply equiv_path. 
    exact (ap pr1 (f x)).
  Defined.

End Accessible_Lex_Modalities_Theory.
