module.exports = function() {
  return {
    pre() {
      this.opts.__commoner_options = true;
    }
  }
}
