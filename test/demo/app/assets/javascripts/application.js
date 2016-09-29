import Adder from 'adder';
import Multiplier from 'multiplier';

let a = new Adder();
let m = new Multiplier();

console.log(a.add(m.multiply(2, 3, 4), 1));
