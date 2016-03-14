(*
   Copyright 2008-2015 Abhishek Anand, Nikhil Swamy and Microsoft Research

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*)
#light "off"
module FStar.Extraction.ML.Modul
open FStar
open FStar.Util
open FStar.Syntax
open FStar.Syntax.Syntax
open FStar.Const
open FStar.Extraction.ML.Syntax
open FStar.Extraction.ML.UEnv
open FStar.Extraction.ML.Util
open FStar.Ident

module MLS = FStar.Extraction.ML.Syntax
module S  = FStar.Syntax.Syntax
module SS = FStar.Syntax.Subst
module U  = FStar.Syntax.Util
module TC = FStar.TypeChecker.Tc
module N  = FStar.TypeChecker.Normalize
module C  = FStar.Syntax.Const

(*This approach assumes that failwith already exists in scope. This might be problematic, see below.*)
let fail_exp (lid:lident) (t:typ) = 
    mk (Tm_app(S.fvar C.failwith_lid Delta_constant None, 
               [ S.iarg t
               ; S.iarg <| mk (Tm_constant (Const_string (Bytes.string_as_unicode_bytes ("Not yet implemented:"^(Print.lid_to_string lid)), Range.dummyRange))) None Range.dummyRange])) 
        None 
        Range.dummyRange

let mangle_projector_lid (x: lident) : lident =
    let projecteeName = x.ident in
    let prefix, constrName = Util.prefix x.ns in
    let mangledName = Ident.id_of_text ("___"^constrName.idText^"___"^projecteeName.idText) in
    lid_of_ids (prefix@[mangledName])

let lident_as_mlsymbol (id : lident) : mlsymbol = id.ident.idText


(*****************************************************************************)
(* Extracting type definitions from the signature                            *)
(*****************************************************************************)
let bv_as_ml_tyvar x = prependTick (convIdent x.ppname)

let binders_as_mlty_binders g bs = 
    let g, bs = List.fold_left (fun (env, bs) (bv, _) ->
        if Term.is_type bv.sort
        then UEnv.extend_ty g bv (Some (MLTY_Var (bv_as_ml_tyvar bv))), bv_as_ml_tyvar bv::bs
        else UEnv.extend_bv g bv ([], erasedContent) false false false, bv_as_ml_tyvar bv::bs) 
    (g, []) bs in
    List.rev bs, g

//Type abbreviations
let extract_typ_abbrev env lid quals def = 
    let def = SS.compress def |> U.unmeta |> U.un_uinst in
    let bs, body = match def.n with 
        | Tm_abs(bs, body, _) -> SS.open_term bs body
        | _ -> [], def in
    let ml_bs, env = binders_as_mlty_binders env bs in
    let body = Term.term_as_mlty env body |> Util.eraseTypeDeep (Util.udelta_unfold env) in
    let td = [(lident_as_mlsymbol lid, ml_bs, Some (MLTD_Abbrev body))] in 
    let def = [MLM_Loc (Util.mlloc_of_range (Ident.range_of_lid lid)); MLM_Ty td] in
    let env = UEnv.extend_tydef env td in
    env, def


//Extracting inductive type definitions

(*just enough info to generate OCaml code; add more info as needed*)
type data_constructor = {
  dname: lident;
  dtyp : typ;
}

type inductive_family = {
  iname  : lident;
  iparams: binders;
  ityp   : term;
  idatas : list<data_constructor>;
  iquals : list<S.qualifier>
}


let bundle_as_inductive_families env ses quals : list<inductive_family> = 
    ses |> List.collect 
        (function 
            | Sig_inductive_typ(l, _us, bs, t, _mut_i, datas, _, r) -> 
                let bs, t = SS.open_term bs t in
                let datas = ses |> List.collect (function
                    | Sig_datacon(d, _, t, l', nparams, _, _, _) when Ident.lid_equals l l' -> 
                        let bs', body = U.arrow_formals t in
                        let bs_params, rest = Util.first_N (List.length bs) bs' in
                        let subst = List.map2 (fun (b', _) (b, _) -> S.NT(b', S.bv_to_tm b)) bs_params bs in
                        let t = U.abs rest body None |> SS.subst subst in
                        [{dname=d; dtyp=t}]
                    | _ -> []) in
                [{  iname=l
                  ; iparams=bs
                  ; ityp=t
                  ; idatas=datas
                  ; iquals=quals  }]
    
            | _ -> [])
            
let extract_bundle env se = 
    let extract_ctor (ml_tyvars:list<(mlsymbol*int)>) (c:env) (ctor: data_constructor):  env * (mlsymbol * list<mlty>) =
        let mlt = Util.eraseTypeDeep (Util.udelta_unfold c) (Term.term_as_mlty c ctor.dtyp) in
        let tys = (ml_tyvars, mlt) in 
        let fvv = mkFvvar ctor.dname ctor.dtyp in
                //printfn "(* extracting the type of constructor %s\n" (lident2mlsymbol ctor.cname);
                //printfn "%s\n" (typ_to_string ctor.ctype);
                //printfn "%A *)\n" (tys);
        extend_fv c fvv tys false false, 
        (lident_as_mlsymbol ctor.dname, argTypes mlt) in

    let extract_one_family env ind = 
       let vars, env = binders_as_mlty_binders env ind.iparams in
       let env, ctors = ind.idatas |> Util.fold_map (extract_ctor vars) env in
       let indices, _ = U.arrow_formals ind.ityp in
       let ml_params = List.append vars (indices |> List.mapi (fun i _ -> "'dummyV" ^ Util.string_of_int i, 0)) in
       let tbody = match Util.find_opt (function RecordType _ -> true | _ -> false) ind.iquals with
            | Some (RecordType ids) ->
              let _, c_ty = List.hd ctors in
              assert (List.length ids = List.length c_ty);
              let fields = List.map2 (fun lid ty -> lident_as_mlsymbol lid, ty) ids c_ty in
              MLTD_Record fields

            | _ -> MLTD_DType ctors in
        env,  (lident_as_mlsymbol ind.iname,  ml_params, Some tbody) in


    match se with 
        | Sig_bundle([Sig_datacon(l, _, t, _, _, _, _, _)], [ExceptionConstructor], _, r) -> 
          let env, ctor = extract_ctor [] env ({dname=l; dtyp=t}) in
          env, [MLM_Exn ctor]

        | Sig_bundle(ses, quals, _, r) -> 
          let ifams = bundle_as_inductive_families env ses quals in
          let env, td = Util.fold_map extract_one_family env ifams in
          env, [MLM_Ty td]

        | _ -> failwith "Unexpected signature element"


(*****************************************************************************)
(* Extracting the top-level definitions in a module                          *)
(*****************************************************************************)
let rec extract_sig (g:env) (se:sigelt) : env * list<mlmodule1> =
   (debug g (fun u -> Util.print_string (Util.format1 "now extracting :  %s \n" (Print.sigelt_to_string se))));
     match se with
        | Sig_bundle _
        | Sig_inductive_typ _
        | Sig_datacon _ -> 
          extract_bundle g se

        | Sig_declare_typ(lid, _, t, quals, _)  when Term.univ t = Term.UPlus -> //lid is a type
          if quals |> Util.for_some (function Assumption -> true | _ -> false) |> not
          then g, []
          else let bs, _ = Util.arrow_formals t in
               extract_typ_abbrev g lid quals (U.abs bs TypeChecker.Common.t_unit None)

        | Sig_let((false, [lb]), _, quals, _) when Term.is_type lb.lbtyp ->
          extract_typ_abbrev g (right lb.lbname).fv_name.v quals lb.lbdef

        | Sig_let (lbs, r, _, quals) ->
          let elet = mk (Tm_let(lbs, Const.exp_false_bool)) None r in
          let ml_let, _, _ = Term.term_as_mlexpr g elet in
          begin match ml_let.expr with
            | MLE_Let(ml_lbs, _) ->
              let g, ml_lbs' = List.fold_left2 (fun (env, ml_lbs) (ml_lb:mllb) {lbname=lbname; lbtyp=t} ->
//              debug g (fun () -> printfn "Translating source lb %s at type %s to %A" (Print.lbname_to_string lbname) (Print.typ_to_string t) (must (mllb.mllb_tysc)));
                  let lb_lid = (right lbname).fv_name.v in
                  let g, ml_lb =
                    if quals |> Util.for_some (function Projector _ -> true | _ -> false) //projector names have to mangled
                    then let mname = mangle_projector_lid lb_lid |> mlpath_of_lident in
                         let env = UEnv.extend_fv' env (right lbname) mname (must ml_lb.mllb_tysc) ml_lb.mllb_add_unit false in
                         env, {ml_lb with mllb_name=(snd mname, 0)}
                    else fst <| UEnv.extend_lb env lbname t (must ml_lb.mllb_tysc) ml_lb.mllb_add_unit false, ml_lb in
                 g, ml_lb::ml_lbs)
              (g, []) (snd ml_lbs) (snd lbs) in
              g, [MLM_Loc (Util.mlloc_of_range r); MLM_Let (fst ml_lbs, List.rev ml_lbs')]

            | _ -> //printfn "%A\n" ml_let;
                failwith "impossible"
          end

       | Sig_declare_typ(lid, _, t, quals, r) ->
         if quals |> List.contains Assumption
         //&& not (quals |> Util.for_some (function Projector _ -> true | _ -> false))
         then let bs, t = U.arrow_formals t in
              let imp = match bs with 
                | [] -> fail_exp lid t
                | _ -> U.abs bs (fail_exp lid t) None in
              let se = Sig_let((false, [{lbname=Inr (S.lid_as_fv lid Delta_constant None); 
                                         lbunivs=[];
                                         lbtyp=t; 
                                         lbeff=Const.effect_ML_lid; 
                                         lbdef=imp}]), r, [], quals) in
              let g, mlm = extract_sig g se in
              match Util.find_map quals (function Discriminator l -> Some l |  _ -> None) with
                  | Some l -> g, [MLM_Loc (Util.mlloc_of_range r); Term.ind_discriminator_body g lid l] //records are single constructor types; there should be no discriminators for them
                  | _ ->
                    begin match Util.find_map quals (function  Projector (l,_)  -> Some l |  _ -> None) with
                        | Some _ -> g, [] //records are extracted as ML records; no projectors for them
                        | _ -> g, mlm
                    end
         else g, []

       | Sig_main(e, r) ->
         let ml_main, _, _ = Term.term_as_mlexpr g e in
         g, [MLM_Loc (Util.mlloc_of_range r); MLM_Top ml_main]


       | Sig_assume _ //not needed; purely logical
       | Sig_new_effect _
       | Sig_sub_effect  _
       | Sig_effect_abbrev _  //effects are all primitive; so these are not extracted; this may change as we add user-defined non-primitive effects
       | Sig_pragma _ -> //pragmas are currently not relevant for codegen; they may be in the future
         g, []

let extract_iface (g:env) (m:modul) =  Util.fold_map extract_sig g m.declarations |> fst

let rec extract (g:env) (m:modul) : env * list<mllib> =
    S.reset_gensym();
    let name = MLS.mlpath_of_lident m.name in
    let g = {g with currentModule = name}  in
    if m.name.str = "Prims" 
    || m.is_interface
    || List.contains m.name.str !Options.no_extract
    then let g = extract_iface g m in
         g, [] //MLLib([Util.flatten_mlpath name, None, MLLib []])
    else let g, sigs = Util.fold_map extract_sig g m.declarations in
         let mlm : mlmodule = List.flatten sigs in
         g, [MLLib ([Util.flatten_mlpath name, Some ([], mlm), (MLLib [])])]
