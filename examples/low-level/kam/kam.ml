(*
  let mk_list n =
  Camlstack.push_frame ();
  let out = Camlstack.mkref [] in
  for i = 0 to n do
    out := Camlstack.cons i !out;
  done;
  Camlstack.pop_frame()
*)

(**
 * Cf.
 *     An abstract machine for Lambda-terms normalization
 *     P. Cregut
 *     Proceedings of the 1990 ACM conference on LISP and functional programming  
 *     http://dl.acm.org/citation.cfm?doid=91556.91681&CFID=723138393&CFTOKEN=40299162
 **)

type tm =
  | Var of int          (* de Bruijn *)
  | Name of int
  | Abs of tm
  | App of tm  * tm 

type env = closure list

and closure = 
  | Open of int
  | Clos of env * tm

open Camlstack
let mk_open (n:int) = 
  let x = mkref_noscan n in (* basically, a ref is a "one tuple" *)
  let r = Obj.repr x in
  Obj.set_tag r 0;
  Obj.magic x
let mk_clos (e:env) (t:tm) : closure = 
 let p = mkpair e t in
 let r = Obj.repr p in
 Obj.set_tag r 1;
 Obj.magic p
let mkpair e t = Camlstack.mkpair e t
let cons e l = Camlstack.cons e l
let push_frame () = Camlstack.push_frame()
let pop_frame () = Camlstack.pop_frame()
type stack = closure list

let rec find env x = match env with 
  | k::tl -> 
    if x=0 then k else find tl (x - 1)
  | [] -> raise Not_found

let rec norm (env:env) (stack:stack) (tm:tm) (n:int) : tm = match tm with 
  | Abs body -> 
    begin match stack with 
      | [] -> let m = n + 1 in 
	     Abs (norm' (cons (mk_open m) env) stack body m)
      | hd::tl -> 
	     norm (cons hd env) tl body n 
    end

  | App(t1, t2) -> 
    norm env (cons (mk_clos env t2) stack) t1 n

  | Var x -> 
    let k = find env x in
    begin match k with 
      | Open m -> 
        rebuild env (Var (n - m)) stack n

      | Clos(env', tm) -> 
        norm env' stack tm n
    end

  | Name _ -> failwith "OPEN TERM"

and rebuild env head stack n = match stack with 
  | [] -> head
  | hd::tl -> 
     let arg = match hd with
       | Open m -> Var (n - m)
       | Clos (env, tm) -> norm' env [] tm n in
     rebuild env (App(head, arg)) tl n

and norm' env stack e n = 
  push_frame();
  let x = norm env stack e n in 
  pop_frame(); 
  x


let norm e = norm' [] [] e 0

let rec close x ix body = match body with 
  | Var _ -> body
  | Name y -> if y=x then Var ix else body
  | App(t1, t2) -> App(close x ix t1, close x ix t2)
  | Abs t -> Abs (close x (ix + 1) t)
let abs (x, body) = Abs (close x 0 body)

let x = 0
let y = 1
let f = 2
let g = 3
let n = 4
let h = 5
let z = abs(f, abs(x, Name x))
let one = abs(f, abs(x, App(Name f, Name x)))
let succ n = abs(f, abs(x, App(Name f, App(App(n, Name f), Name x))))
let pred = abs(n, abs(f, abs(x, App(App(App(Name n, (abs(g, abs(h, App(Name h, App(Name g, Name f)))))), abs(y, Name x)), abs(y, Name y)))))


let push m = 
  let next_char = fst m + 1 in
  let x = Char.chr next_char in
  x, (next_char, x::snd m)

let rec term_to_string_raw = function 
  | Var x -> string_of_int x
  | Name x -> Printf.sprintf "(Name %d)" x
  | Abs tm -> Printf.sprintf  "(Abs %s)" (term_to_string_raw tm)
  | App(t1, t2) -> Printf.sprintf "(App %s %s)" (term_to_string_raw t1) (term_to_string_raw t2)

let rec clos_to_string = function 
  | Open m -> Printf.sprintf "(Open %d)" m
  | Clos(env, x) -> Printf.sprintf "(Clos %s %s)" (env_to_string env) (term_to_string_raw x)

and env_to_string env = 
  let s = List.map clos_to_string env in 
  Printf.sprintf "[%s]" (String.concat "; " s)

let print_term_raw t = print_string (term_to_string_raw t)

let rec print_term m = function 
  | Var x -> print_char (find (snd m) x)
  | Name x -> print_string "(Name "; print_int x; print_string ")"
  | Abs tm -> let x, m = push m in print_string "(Abs "; print_char x; print_string " "; print_term m tm; print_string ")"
  | App(t1, t2) -> print_string "("; print_term m t1; print_string " "; print_term m t2; print_string ")"

let print_term = print_term (Char.code 'a' - 1, [])

let rec encode (n:int) = 
  if n = 0 then z
  else succ (encode (n - 1))

let test2 = 
  let s = encode 1000 in 
  let x = norm s in 
  print_term x
(*  print_term (norm s) *)
 

  
