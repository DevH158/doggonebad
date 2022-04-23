const DoggyHandler = artifacts.require("DoggyHandler");

module.exports = function (deployer) {
    deployer.deploy(DoggyHandler);
};