const DogHandler = artifacts.require("DogHandler");

module.exports = function (deployer) {
    deployer.deploy(DogHandler);
};