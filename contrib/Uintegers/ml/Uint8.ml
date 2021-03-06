let zero = Stdint.Uint8.zero
let one = Stdint.Uint8.one
let max_int = Stdint.Uint8.max_int
let min_int = Stdint.Uint8.min_int
let bits = Stdint.Uint8.bits

let add x y = Stdint.Uint8.add x y
let sub x y = Stdint.Uint8.sub x y
let mul x y = Stdint.Uint8.mul x y
let div x y = Stdint.Uint8.div x y
let rem x y = Stdint.Uint8.rem x y
let succ x = Stdint.Uint8.succ x
let pred x = Stdint.Uint8.pred x
let abs x = Stdint.Uint8.abs x
let neg x = Stdint.Uint8.neg x
let logand x y = Stdint.Uint8.logand x y
let logor x y = Stdint.Uint8.logor x y
let logxor x y = Stdint.Uint8.logxor x y
let lognot x = Stdint.Uint8.lognot x
let shift_left x n = Stdint.Uint8.shift_left x n
let shift_right x n = Stdint.Uint8.shift_right x n
let shift_right_logical x n = Stdint.Uint8.shift_right_logical x n
let of_int n = Stdint.Uint8.of_int n
let to_int n = Stdint.Uint8.to_int n
let of_string s = Stdint.Uint8.of_string s
let to_string x = Stdint.Uint8.to_string x
let compare x y = Stdint.Uint8.compare x y

let rotate_left x n =
  logor (shift_left x n)
        (shift_right_logical x (8 - n))
let rotate_right x n =
  logor (shift_right_logical x n)
        (shift_left x (8 - n))
