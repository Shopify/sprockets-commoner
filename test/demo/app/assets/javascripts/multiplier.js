import {reduce} from 'lodash';

export default class Multiplier {
  multiply(...args) {
    debugger;
    return reduce(args, (a, b) => a * b);
  }
}
