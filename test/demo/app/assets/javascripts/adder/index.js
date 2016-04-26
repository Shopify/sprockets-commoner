import {add, reduce} from 'lodash';

export default class Adder {
  add(...args) {
    return reduce(args, add);
  }
}
