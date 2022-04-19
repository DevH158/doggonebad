const DoggyVersion = artifacts.require("DoggyVersion");

module.exports = function (deployer) {
    deployer.deploy(DoggyVersion);
};