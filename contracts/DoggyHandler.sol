// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./DogGoneBad.sol";

contract DoggyHandler is Ownable {
    DogGoneBad public nft;

    uint256 private sealedSeed;

    struct ItemMetaData {
        bool burnable; // burn original after update/change
        uint64 maxUpgradeCnt;
        uint64 currUpgradeCnt;
    }

    // a mapping of tokenId and ItemMetaData
    mapping (uint256 => ItemMetaData) private _metadata;

    constructor(uint256 _sealedSeed) {
        sealedSeed = _sealedSeed;
    }

    function setSealedSeed(uint256 _sealedSeed) public onlyOwner {
        sealedSeed = _sealedSeed;
    }

    function setNFT(address _nft) public onlyOwner {
        nft = DogGoneBad(_nft);
    }

    // function setMetaData(uint256 tokenId) public onlyOwner {

    // }

    function isApproved(address creator) public view returns (bool) {
        // NFT owner has to approve this contract first
        // DogGoneBad.setApprovalForAll(creator, address(this))
        return nft.isApprovedForAll(creator, address(this));
    }

    function transferToContract(uint256 tokenId) public {
        require(isApproved(msg.sender), "approve this contract first");
        address o = nft.ownerOf(tokenId);
        require(o == msg.sender, "is not owned");
        nft.transferFrom(msg.sender, address(this), tokenId);
    }

    function transferBack(address to, uint256 tokenId) public {
        require(isApproved(msg.sender), "approve this contract first");
        address o = nft.ownerOf(tokenId);
        require(o == address(this), "is not owned by this contract, transfer first");
        nft.transferFrom(address(this), to, tokenId);
    }
}