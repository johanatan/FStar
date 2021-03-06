module Unit1.WPsAndTriples
inline let as_requires (#a:Type) (wp:pure_wp a) = wp (fun x -> True)
inline let as_ensures  (#a:Type) (wlp:pure_wp a) (x:a) = ~ (wlp (fun y -> ~(y=x)))
assume val as_Pure: #a:Type -> #b:(a -> Type)
          -> #wp:(x:a -> GTot (pure_wp (b x)))
          -> #wlp:(x:a -> GTot (pure_wp (b x)))
          -> $f:(x:a -> PURE (b x) (wp x) (wlp x))
          -> x:a -> Pure (b x) (as_requires (wp x))
                               (as_ensures (wlp x))

val f : x:int -> PURE int (fun 'p -> x > 0 /\ 'p (x + 1)) (fun 'p -> x > 0 ==> 'p (x + 1))
let f x = assert (x > 0); x + 1

val h : #req:(int -> Type) -> #ens:(int -> int -> Type) -> $f:(x:int -> Pure int (req x) (ens x)) -> y:int -> Pure int (req y) (ens y)
let h #req #ens f x = f x

val g : x:int -> Pure int (b2t (x > 0)) (fun y -> y == x + 1)
let g = h (as_Pure f)
