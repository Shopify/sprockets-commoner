module.exports = function () {
  return {
    pre: function pre() {
      this.opts.__commoner_options = true;
    }
  };
};
