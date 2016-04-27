import {reduce} from 'lodash';

export default class Multiplier {
  multiply(...args) {
    return reduce(args, (a, b) => a * b);
  }
}
