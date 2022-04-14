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

    // all the payments earned through public minting goes here
    uint256 public deposits;
    uint256 public publicFund;

    // contract that can withdraw and use public funds
    address public publicFundHandler;
    uint8 public creatorFee = 10; // in percentage. Only creator fee goes to owner

    // Minting information
    uint256 public publicSaleCount; // total number of public sale events
    bool public publicSaleEnabled = false;

    mapping (address => uint256) private _lastCallBlockNumber;
    uint256 private _mintIndex;
    uint256 private _maxMintAmount;
    uint256 private _antibotInterval;
    uint256 private _mintLimitPerBlock;
    uint256 private _mintLimitPerSale;
    uint256 private _mintStartAfterDays;
    uint256 private _mintStartTimestamp;
    uint256 private _mintPrice = 1 * 10 ** 18;  // start from 1 KLAY

    // Reveal information
    // assumes there are multiple public sales each of which hides tokenURI
    // for a set period of time
    bool public reveal = false;
    string private _hiddenTokenURI;
    uint256 private _hideFrom;
    uint256 private _hideTo;

    constructor() ERC721A("TestDoggy", "TDOGG") {}

    modifier onlyPublicHandler() {
        require(msg.sender == publicFundHandler);
        _;
    }

    function setPublicFundHandler(address _contract) public onlyOwner {
        // public fund handler can manage all the public fund in this contract (balance)
        publicFundHandler = _contract;
    }

    function setMintPrice(uint256 price) public onlyOwner {
        _mintPrice = price;
    }

    function getMintPrice() public view returns (uint256) {
        return _mintPrice;
    }

    function setPublicSale(
        uint256 maxMintAmount,
        uint256 antibotInterval,
        uint256 mintLimitPerBlock,
        uint256 mintLimitPerSale,
        uint256 mintStartAfterDays
    ) public onlyOwner {
        _mintIndex = 0;
        _maxMintAmount = maxMintAmount;
        _antibotInterval = antibotInterval;
        _mintLimitPerBlock = mintLimitPerBlock;
        _mintLimitPerSale = mintLimitPerSale;
        _mintStartAfterDays = mintStartAfterDays;
    }

    function getPublicSale() public view returns (uint256[7] memory) {
        return [
            _maxMintAmount,
            _antibotInterval,
            _mintLimitPerBlock,
            _mintLimitPerSale,
            _mintStartAfterDays,
            _mintStartTimestamp,
            _mintPrice
        ];
    }

    function openPublicSale() public onlyOwner {
        publicSaleEnabled = true;
        publicSaleCount++;
        _mintStartTimestamp = block.timestamp;
    }

    function closePublicSale() public onlyOwner {
        publicSaleEnabled = false;
    }

    function getTimeAfterSaleOpen() public view returns (uint256) {
        require(publicSaleEnabled, "Public minting has not started yet");
        return block.timestamp - _mintStartTimestamp;
    }

    function publicMint(uint256 quantity) external payable {
        require(publicSaleEnabled, "Public minting has not started yet");
        require(_lastCallBlockNumber[msg.sender].add(_antibotInterval) < block.number, "Too many minting requesets");
        require(getTimeAfterSaleOpen() >= _mintStartAfterDays * 24 * 60 * 60);
        require(quantity > 0 && quantity <= _mintLimitPerBlock, "Too many requests or zero request");
        require(msg.value == _mintPrice.mul(quantity), "Need to pay more. Check payment");
        require(_mintIndex.add(requestedCount) <= _maxMintAmount + 1, "Exceeded max amount");
        require(balanceOf(msg.sender) + requestedCount <= _mintLimitPerSale, "Exceeded max amount per person");

        deposits += msg.value;
        _lastCallBlockNumber[msg.sender] = block.number;
        _safeMint(msg.sender, quantity);
    }

    function mintTo(address to, uint256 quantity) public onlyOwner {
        _safeMint(to, quantity);
    }

    function setBaseURI(string memory uri) public onlyOwner {
        __baseURI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return __baseURI;
    }

    function hideTokens(uint256 from, uint256 to, string memory uri) public onlyOwner {
        reveal = false;
        _hideFrom = from;
        _hideTo = to;
        _hiddenTokenURI = uri;
    }

    function revealTokens() public onlyOwner {
        reveal = true;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!reveal && tokenId >= _hideFrom && tokenId <= _hideTo) {
            return string(abi.encodePacked(_hiddenTokenURI, tokenId.toString()));
        }

        return super.tokenURI();
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