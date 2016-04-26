import Adder from 'adder';

describe('Adder', () => {
  let adder = new Adder();
  describe('#add', () => {
    it('adds two numbers', () => {
      expect(adder.add(2, 5)).toEqual(7);
    });

    it('adds three numbers', () => {
      expect(adder.add(2, 3, 5)).toEqual(10);
    });
  });
});
