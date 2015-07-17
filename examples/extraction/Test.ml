
type nnat =
| O
| S of nnat

let idnat = (Obj.magic(fun _1_3 -> _1_3))

type ('a, 'b) prod =
| Pair of 'a * 'b

type 'a list =
| Nil
| Cons of 'a * 'a list

type ('a, 'b) list2 =
| Nil2
| Cons2 of 'a * 'b * ('a, 'b) list2

type any =
| Any of unit * Obj.t

type distr_pair =
(unit  ->  Obj.t  ->  Obj.t)  ->  (nnat, nnat list) prod

type 'a list2p =
| Nil2p
| Cons2p of 'a * ('a, 'a) prod list2p

type 'dummyV1 list3 =
| Nil3 of unit
| Cons3 of unit * Obj.t * Obj.t list3

type 'x poly =
| Poly of nnat * 'x

type 'x poly2 =
| Poly2 of unit * 'x

type 'x sch =
'x  ->  'x

type sch1 =
Obj.t  ->  Obj.t

type sch3 =
Obj.t  ->  Obj.t

type 'x sch3param =
'x  ->  'x

type idt =
unit  ->  Obj.t  ->  Obj.t

type ('a, 'dummyV1) vec =
| Nill
| Conss of nnat * 'a * ('a, unit) vec

type vecn1 =
(nnat, unit) vec

type ('t, 'n) naryTree =
| Leaf
| Node of (('t, unit) naryTree, unit) vec

type 't binaryTree =
('t, unit) naryTree

type polyvec =
(nnat, unit) vec poly

type polylist =
Obj.t list poly2

type 'a listalias =
'a list

type polylistalias =
Obj.t listalias poly2



