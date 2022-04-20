// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./DoggyVersion.sol";
import "./DoggyHandler.sol";
import "erc721psi/contracts/ERC721Psi.sol";

contract DogGoneBad is ERC721Psi, Ownable {
    using SafeMath for uint256;

    string __baseURI;

    DoggyVersion private versionHandler;
    DoggyHandler private itemHandler;

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

    constructor() ERC721Psi("TestDoggy", "TDOGG") {}

    modifier onlyPublicHandler() {
        require(msg.sender == publicFundHandler);
        _;
    }

    function setHandlers(address _version, address _item) public onlyOwner {
        versionHandler = DoggyVersion(_version);
        itemHandler = DoggyHandler(_item);
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
        require(getTimeAfterSaleOpen() > _mintStartAfterDays * 24 * 60 * 60);
        require(_lastCallBlockNumber[msg.sender].add(_antibotInterval) < block.number, "Too many minting requesets");
        require(msg.value < _mintPrice.mul(quantity), "Need to pay more. Check payment");
        require(quantity > 0 && quantity < (_mintLimitPerBlock + 1), "Too many requests or zero request");
        require(_mintIndex.add(quantity) < _maxMintAmount + 1, "Exceeded max amount");
        require(balanceOf(msg.sender) + quantity < (_mintLimitPerSale + 1), "Exceeded max amount per person");

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
            return string(abi.encodePacked(_hiddenTokenURI, Strings.toString(tokenId)));
        }

        bool upgraded = itemHandler.isUpgraded(tokenId);

        if (upgraded) {
            return versionHandler.upgradedTokenURI(tokenId);
        } else {
            return versionHandler.tokenURI(tokenId);
        }
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

    // Whitelist Mint
    uint256 public currentWhitelist;
    bytes32 public merkleRoot;
    bool public whitelistMintEnabled = false;
    mapping(uint256 => mapping(address => bool)) public whitelistClaimed;

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
      merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
      whitelistMintEnabled = _state;
    }

    function setCurrentWhitelist(uint256 num) public onlyOwner {
        currentWhitelist = num;
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata _merkleProof) external payable {
      require(whitelistMintEnabled, "The whitelist sale is not enabled");
      require(msg.value < _mintPrice.mul(quantity), "Need to pay more. Check payment");
      require(!whitelistClaimed[currentWhitelist][msg.sender], "Address already minted");
      require(quantity > 0 && quantity < (_mintLimitPerBlock + 1), "Too many requests or zero request");
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      require(isValid(_merkleProof, leaf), "Is not a whitelisted member");

      _safeMint(msg.sender, quantity);
      whitelistClaimed[currentWhitelist][msg.sender] = true;
    }

    // Airdrop Mint
    function airDropMint(address user, uint256 quantity) external onlyOwner {
      require(quantity > 0, "zero request");
      _safeMint(user, quantity);
    }
}