module ST2
assume val v0 : a:Type -> a -> Tot a
assume val v1 : a:Type -> a -> Tot a

type heap2 = heap * heap

kind STWP (a:Type) = (a -> heap -> Type) -> heap -> Type

type comp (a:Type) (b:Type) (wp0:STWP a) (wp1:STWP b) (p:((a * b) -> heap2 -> Type)) (h2:heap2) =
    wp0 (fun y0 h0 ->
      wp1 (fun y1 h1 -> p (y0, y1) (h0, h1))
      (snd h2))
    (fst h2)

assume val compose2: a0:Type -> b0:Type -> wp0:(a0 -> STWP b0) -> wlp0:(a0 -> STWP b0)
                  -> a1:Type -> b1:Type -> wp1:(a1 -> STWP b1) -> wlp1:(a1 -> STWP b1)
                  -> =c0:(x0:a0 -> STATE b0 (wp0 x0) (wlp0 x0))
                  -> =c1:(x1:a1 -> STATE b1 (wp1 x1) (wlp1 x1))
                  -> x0:a0
                  -> x1:a1
                  -> ST2Core (b0 * b1)
                             (comp b0 b1 (wp0 x0) (wp1 x1))
                             (comp b0 b1 (wlp0 x0) (wlp1 x1))

module Sample
open ST2
open Heap

let f x = x := !x - !x
let g x = x := 0

val equiv1: x:ref int
         -> y:ref int
         -> ST2 (unit * unit)
                (fun _ -> True) //x, y may be high-references
                (fun _ _ h2' -> sel (fst h2') x == sel (snd h2') y) //their contents are equal afterwards
let equiv1 x y = compose2 f g x y