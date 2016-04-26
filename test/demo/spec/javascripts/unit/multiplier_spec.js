import Multiplier from 'multiplier';

describe('Multiplier', () => {
  let multiplier = new Multiplier();
  describe('#multiply', () => {
    it('multiplies two numbers', () => {
      expect(multiplier.multiply(2, 5)).toEqual(10);
    });

    it('multiplies three numbers', () => {
      expect(multiplier.multiply(2, 3, 5)).toEqual(30);
    });
  });
});
