var Executor = artifacts.require("FlashloanExecutor");

var constants = require("../test/kovan");

module.exports = function(deployer) {
    deployer.deploy(Executor, constants.AAVE_PROVIDER);
}
