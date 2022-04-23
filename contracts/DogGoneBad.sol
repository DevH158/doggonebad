// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./DoggyVersion.sol";
import "./DoggyHandler.sol";
import "./ERC721Psi.sol";

contract DogGoneBad is ERC721Psi, Ownable {
    using SafeMath for uint256;

    DoggyVersion private versionHandler;
    address private itemHandler; // DoggyHandler

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

    // uint256 public revealAfterSeconds;
    string private _hiddenTokenURI;

    struct ItemMetaData {
        bool publicMinted; // is held by owner other than creator
        bool upgraded;
    }

    // a mapping of tokenId and ItemMetaData
    mapping (uint256 => ItemMetaData) private _metadata;

    constructor() ERC721Psi("DogGoneBad", "DGB") {}

    modifier onlyPublicHandler() {
        require(msg.sender == publicFundHandler);
        _;
    }

    modifier onlyItemHandler() {
        require(msg.sender == itemHandler || msg.sender == owner());
        _;
    }

    function setPublicFundHandler(address _contract) public onlyOwner {
        // public fund handler can manage all the public fund in this contract (balance)
        publicFundHandler = _contract;
    }

    function setHandler(address _version, address _item) public onlyOwner {
        versionHandler = DoggyVersion(_version);
        itemHandler = _item;
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
        require(msg.value >= _mintPrice.mul(quantity), "Need to pay more. Check payment");
        require(quantity > 0 && quantity < (_mintLimitPerBlock + 1), "Too many requests or zero request");
        require(_mintIndex.add(quantity) < _maxMintAmount + 1, "Exceeded max amount");
        require(balanceOf(msg.sender) + quantity < (_mintLimitPerSale + 1), "Exceeded max amount per person");

        deposits += msg.value;
        _lastCallBlockNumber[msg.sender] = block.number;
        _safeMint(msg.sender, quantity);
    }

    // function setRevealTime(uint256 time) public onlyOwner {
    //     revealAfterSeconds = time;
    // }

    // function isRevealed(uint256 tokenId) public view returns (bool) {
    //     if (_metadata[tokenId].initTime != 0) {
    //         return (block.timestamp - _metadata[tokenId].initTime) > revealAfterSeconds;
    //     } else {
    //         return false;
    //     }
    // }

    // function timePassedAfterInit(uint256 tokenId) public view returns (uint256) {
    //     return block.timestamp - _metadata[tokenId].initTime;
    // }

    function setHiddenTokenURI(string memory uri) public onlyOwner {
        _hiddenTokenURI = uri;
    }

    function setMetaData(uint256 tokenId, bool publicMinted, bool upgraded) internal {
        _metadata[tokenId] = ItemMetaData(publicMinted, upgraded);
    }

    function setUpgraded(uint256 tokenId, bool upgraded) external onlyItemHandler {
        _metadata[tokenId].upgraded = upgraded;
    }

    function isPublicMinted(uint256 tokenId) public view returns (bool) {
        return _metadata[tokenId].publicMinted;
    }

    function isUpgraded(uint256 tokenId) public view returns (bool) {
        return _metadata[tokenId].upgraded;
    }

    function getMetaData(uint256 tokenId) public view returns (ItemMetaData memory) {
        return _metadata[tokenId];
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Psi: URI query for nonexistent token");

        bool publicMinted = isPublicMinted(tokenId);

        if (!publicMinted) {
            return _hiddenTokenURI;
        } else {
            bool upgraded = isUpgraded(tokenId);

            if (upgraded) {
                return versionHandler.upgradedTokenURI(tokenId);
            } else {
                return versionHandler.tokenURI(tokenId);
            }
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
      require(msg.value >= _mintPrice.mul(quantity), "Need to pay more. Check payment");
      require(!whitelistClaimed[currentWhitelist][msg.sender], "Address already minted");
      require(quantity > 0 && quantity < (_mintLimitPerBlock + 1), "Too many requests or zero request");
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      require(isValid(_merkleProof, leaf), "Is not a whitelisted member");

      _safeMint(msg.sender, quantity);
      whitelistClaimed[currentWhitelist][msg.sender] = true;
    }

    // Airdrop Mint
    function mintTo(address user, uint256 quantity) external onlyOwner {
      require(quantity > 0, "zero request");
      _safeMint(user, quantity);
    }

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if (from == address(0)) {
            // bulk mint
            for (uint256 tokenId = startTokenId; tokenId < startTokenId + quantity; tokenId++) {
                setMetaData(tokenId, false, false);
            } 
        } else {
            // public/opensea sale
            if (from == owner()) {
                setMetaData(startTokenId, true, false);
            }
        }
    }
}