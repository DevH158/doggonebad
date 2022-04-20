// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Strings.sol';

contract DoggyVersion is Ownable {
    address private handler;

    uint256 private currentVersion;

    mapping (uint256 => uint256[2]) private versionInfo;
    mapping (uint256 => uint8[]) private randomArray; // initial random values
    mapping (uint256 => uint256[]) private upgradedArray; // random values after upgrade

    mapping (uint256 => string) private baseUriByVersion;

    constructor() {
        currentVersion = 0;
    }

    modifier onlyHandler() {
        require(msg.sender == handler || msg.sender == owner());
        _;
    }

    function setHandler(address _handler) public onlyHandler {
        handler = _handler;
    }

    function getCurrentVersion() public view onlyHandler returns (uint256) {
        return currentVersion;
    }

    function addVersionInfo(uint256 from, uint256 to) public onlyOwner {
        currentVersion++;
        versionInfo[currentVersion] = [from, to];
    }

    function addBaseURI(uint256 version, string memory uri) public onlyOwner {
        baseUriByVersion[version] = uri;
    }

    function getVersionInfo(uint256 version) public view onlyHandler returns (uint256[2] memory) {
        return versionInfo[version];
    }

    function getTokenVersion(uint256 tokenId) public view onlyHandler returns (uint256) {
        for (uint256 i = 1; i < currentVersion + 1; i++) {
            uint256[2] memory fromTo = getVersionInfo(i);
            if (fromTo[0] < (tokenId + 1) && tokenId < (fromTo[1] + 1)) {
                return i;
            }
        }
        return 0;
    }

    function setRandomArray(uint256 version, uint8[] calldata arr) public onlyOwner {
        randomArray[version] = arr;
    }

    function setUpgradedArray(uint256 version, uint256[] calldata arr) public onlyOwner {
        upgradedArray[version] = arr;
    }

    function getSelection(uint256 tokenId) public view onlyHandler returns (uint8) {
        uint256 version = getTokenVersion(tokenId);
        uint256[2] memory fromTo = getVersionInfo(version); 
        uint256 arrayLength = (fromTo[1] - fromTo[0]);
        uint256 arrayPosition = (fromTo[1] - tokenId);
        return randomArray[version][arrayLength - arrayPosition];
    }

    function getUpgradedSelection(uint256 tokenId) public view onlyHandler returns (uint256) {
        uint256 version = getTokenVersion(tokenId);
        uint256[2] memory fromTo = getVersionInfo(version); 
        uint256 arrayLength = (fromTo[1] - fromTo[0]);
        uint256 arrayPosition = (fromTo[1] - tokenId);
        return upgradedArray[version][arrayLength - arrayPosition];
    }

    function baseURI(uint256 version) public view onlyHandler returns (string memory) {
        return baseUriByVersion[version];
    }

    function tokenURI(uint256 tokenId) external view onlyHandler returns (string memory) {
        uint256 version = getTokenVersion(tokenId);
        uint256 selection = getSelection(tokenId);
        string memory base = baseURI(version);
        return string(abi.encodePacked(base, Strings.toString(selection), ".json"));
    }

    function upgradedTokenURI(uint256 tokenId) public view onlyHandler returns (string memory) {
        uint256 version = getTokenVersion(tokenId);
        uint256 selection = getUpgradedSelection(tokenId);
        string memory base = baseURI(version);
        return string(abi.encodePacked(base, Strings.toString(selection), ".json"));
    }
}