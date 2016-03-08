//= require_self

import A from './module';

export default function() {
  let b = new A();

  return b.whatever();
}
