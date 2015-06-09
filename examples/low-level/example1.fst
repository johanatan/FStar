(*--build-config
    options:--admit_fsi Set;
    variables:LIB=../../lib;
    other-files:$LIB/ext.fst $LIB/set.fsi $LIB/heap.fst $LIB/st.fst $LIB/list.fst stack.fst listset.fst st3.fst
  --*)
module Example1
open StructuredMem
open Heap
open Stack
open Set
open Prims
open List
open ListSet


(*a good aspect of the current formulation is that the heap/stack difference
only matters at the time of allocation. Functions like increment can be
defined without without bothering about that distinction*)

(*ideally, the refExistsInMem clauses should not be needed in the postcondition*)
val incrementRef : r:(ref int) -> SST unit  (fun m -> (refExistsInMem r m)==true)
(fun m0 a m1 -> (refExistsInMem r m0) /\ (refExistsInMem r m1) /\ (mstail m0 = mstail m1) /\ (loopkupRef r m1 = (loopkupRef r m0) + 1))
let incrementRef r =
  let oldv = memread r in
  memwrite r (oldv + 1)

val pushPopNoChage : unit ->  SST unit  (fun _ -> True) (fun m0 vo m1 -> m0 == m1)
let pushPopNoChage () =
  pushStackFrame (); (* As expected, removing this line results in an error, even for the trivial postcondition*)
  popStackFrame ()


val incrementUsingStack : vi:int -> SST int  (fun _ -> True)
    (fun m0 vo m1 -> m0 = m1 /\ vo=vi+1)
let incrementUsingStack vi =
  pushStackFrame ();
    let r = salloc vi in
    let oldv = memread r in
    memwrite r (oldv + 1);
    let v = (memread r) in
  popStackFrame ();
  v


val incrementRef2 : r:(ref int) -> SST unit
(fun m -> (refExistsInMem r m)
              /\ (isNonEmpty (st m))
              /\ (refLoc r = InStack (topstid m)))
(fun m0 a m1 -> (refExistsInMem r m0) /\ (refExistsInMem r m1)
    /\ (mtail m0 = mtail m1)
    /\ (loopkupRef r m1 = (loopkupRef r m0) + 1))
let incrementRef2 r =
  let oldv = memread r in
  memwrite r (oldv + 1)

(* an example illustrating a typical C idiom :
  caller allocates memory and passes the ref to callee to get some work done *)
val incrementUsingStack2 : vi:int -> SST int  (fun _ -> True)
    (fun m0 vo m1 -> m0 = m1 /\ vo=vi+1)
let incrementUsingStack2 vi =
  pushStackFrame ();
    let r = salloc vi in
    incrementRef2 r; (*why doesn't incrementRef work here?*)
    let v = (memread r) in
  popStackFrame ();
  v

val incrementUsingStack3 : vi:int -> SST int  (fun _ -> True)
    (fun m0 vo m1 ->  m0 =  m1 /\ vo=vi+1)
let incrementUsingStack3 vi =
  pushStackFrame ();
  pushStackFrame ();
    let r = salloc vi in
    let r2 = salloc 0 in
    let oldv = memread r in
    memwrite r (oldv + 1);
    memwrite r2 2; (*a dummy operation bwteen write r and read r*)
    let v = (memread r) in
  popStackFrame ();
  v