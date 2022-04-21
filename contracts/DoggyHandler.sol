// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./DogGoneBad.sol";

contract DoggyHandler is Ownable {
    address public nftAddress;
    DogGoneBad public nft;

    uint256 public revealAfterSeconds;

    struct ItemMetaData {
        bool upgraded;
        uint256 initTime;
    }

    // a mapping of tokenId and ItemMetaData
    mapping (uint256 => ItemMetaData) private _metadata;

    constructor() {}

    modifier onlyNFT() {
        require(msg.sender == nftAddress || msg.sender == owner());
        _;
    }

    function setNFT(address _nft) public onlyOwner {
        nftAddress = _nft;
        nft = DogGoneBad(_nft);
    }

    function setRevealTime(uint256 time) public onlyOwner {
        revealAfterSeconds = time;
    }

    function setUpgraded(uint256 tokenId, bool upgraded) external onlyNFT {
        _metadata[tokenId].upgraded = upgraded;
    }

    function setMetaData(uint256 tokenId, bool upgraded) external onlyNFT {
        _metadata[tokenId] = ItemMetaData(upgraded, block.timestamp);
    }

    function isUpgraded(uint256 tokenId) external view returns (bool) {
        return _metadata[tokenId].upgraded;
    }

    function isRevealed(uint256 tokenId) external view returns (bool) {
        if (_metadata[tokenId].initTime != 0) {
            return (block.timestamp - _metadata[tokenId].initTime) > revealAfterSeconds;
        } else {
            return false;
        }
    }

    function timePassedAfterInit(uint256 tokenId) external view returns (uint256) {
        return block.timestamp - _metadata[tokenId].initTime;
    }

    function getMetaData(uint256 tokenId) external view returns (ItemMetaData memory) {
        return _metadata[tokenId];
    }

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