// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./DogGoneBad.sol";

contract DogHandler is Ownable {
    DogGoneBad public nft;

    constructor() {}

    function setNFT(address _nft) public onlyOwner {
        nft = DogGoneBad(_nft);
    }

    function isApproved(address creator) public view returns (bool) {
        // NFT owner has to approve this contract first
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