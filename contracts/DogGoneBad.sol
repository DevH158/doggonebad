// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AOwnersExplicit.sol";
import "./ERC721APausable.sol";
import "./ERC721AQueryable.sol";

contract DogGoneBad is ERC721A, ERC721ABurnable, ERC721AOwnersExplicit, ERC721AQueryable, Ownable {
    using SafeMath for uint256;

    string __baseURI;
    uint256 _mintPrice = 1 * 10 ** 18;

    // all the payments earned through public minting goes here
    uint256 public deposits;
    uint256 public publicFund;

    // contract that can withdraw and use public funds
    address public publicFundHandler;
    uint8 public creatorFee = 10; // in percentage. Only creator fee goes to owner

    event Received(address, uint);

    constructor() ERC721A("TestDoggy", "TDOGG") {}

    modifier onlyPublicHandler() {
        require(msg.sender == publicFundHandler);
        _;
    }

    function setMintPrice(uint256 price) public onlyOwner {
        _mintPrice = price;
    }

    function getMintPrice() public view returns (uint256) {
        return _mintPrice;
    }

    function setPublicFundHandler(address _contract) public onlyOwner {
        publicFundHandler = _contract;
    }

    function mintTo(address to, uint256 quantity) public onlyOwner {
        _safeMint(to, quantity);
    }

    function publicMint(uint256 quantity) external payable {
        require(msg.value == _mintPrice.mul(quantity), "Need to pay more. Check payment");
        deposits += msg.value;
        _safeMint(msg.sender, quantity);
    }

    function setBaseURI(string memory uri) public onlyOwner {
        __baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function withdraw() external payable onlyOwner {
        // withdraw function for the creator/owner
        uint256 toSend = deposits;
        uint256 creatorDeposit = toSend * creatorFee / 100;
        uint256 publicDeposit = toSend * (100 - creatorFee) / 100;
        deposits = 0;
        publicFund += publicDeposit;

        address o = owner();
        (bool success1, ) = payable(o).call{value: creatorDeposit}("");
        require(success1, "fund withdrawal by owner failed");
    }

    function withdrawPublicFund() public onlyPublicHandler {
        uint256 toSend = publicFund;
        publicFund = 0;
        (bool success, ) = payable(publicFundHandler).call{value: toSend}("");
        require(success, "fund withdrawal by public handler failed");
    }
}