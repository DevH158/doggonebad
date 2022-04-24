// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "erc721psi/contracts/BitMaps.sol";

import "./DoggyVersion.sol";
import "./DoggyHandler.sol";
import "./ERC721Psi.sol";
import "./ERC2981.sol";

contract DogGoneBad is ERC721, ERC2981, Ownable {
    using SafeMath for uint256;

    DoggyVersion private versionHandler;
    address private itemHandler; // DoggyHandler

    // all the payments earned through public minting goes here
    uint256 public deposits;
    uint256 public publicFund;

    // contract that can withdraw and use public funds
    address public publicFundHandler;
    uint256 public creatorFee = 1000; // 1000 is 10%
    uint256 public royaltyFee = 250; // 250 is 2.5%;

    // Minting information
    uint256 public mintPrice = 1 * 10 ** 18;  // start from 1 KLAY

    string private _hiddenTokenURI;

    struct ItemMetaData {
        bool publicMinted; // is held by owner other than creator
        bool upgraded;
        bool burned;
    }

    // a mapping of tokenId and ItemMetaData
    mapping (uint256 => ItemMetaData) private _metadata;
    uint256 private _burned;

    constructor() ERC721("TestDoggies", "DGB") {}

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
        mintPrice = price;
    }

    function setRoyaltyFee(uint256 fee) public onlyOwner {
        royaltyFee = fee;
    }

    function setHiddenTokenURI(string memory uri) public onlyOwner {
        _hiddenTokenURI = uri;
    }

    function setMetaData(uint256 tokenId, bool publicMinted, bool upgraded, bool burned) internal {
        _metadata[tokenId] = ItemMetaData(publicMinted, upgraded, burned);
    }

    function setUpgraded(uint256 tokenId, bool upgraded) external onlyItemHandler {
        _metadata[tokenId].upgraded = upgraded;
    }

    function getMetaData(uint256 tokenId) public view returns (ItemMetaData memory) {
        return _metadata[tokenId];
    }

    function _exists(uint256 tokenId) internal view virtual override returns (bool) {
        return (tokenId < _minted) && (!_metadata[tokenId].burned);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Psi: URI query for nonexistent token");

        ItemMetaData memory metadata = _metadata[tokenId];

        if (!metadata.publicMinted) {
            return _hiddenTokenURI;
        } else {
            if (metadata.upgraded) {
                return versionHandler.upgradedTokenURI(tokenId);
            } else {
                return versionHandler.tokenURI(tokenId);
            }
        }
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _minted - _burned;
    }

    function _burn(uint256 tokenId) internal virtual {
        _metadata[tokenId].burned = true;
        _burned++;

        address from = ownerOf(tokenId);
        emit Transfer(from, address(0), tokenId);
    }

    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Has to be approved to burn token");
        _burn(tokenId);
    }

    function withdraw() external payable onlyOwner {
        // withdraw function for the creator/owner
        uint256 toSend = deposits;
        uint256 creatorDeposit = toSend * creatorFee / 10000;
        uint256 publicDeposit = toSend * (10000 - creatorFee) / 10000;
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

    uint256 private _mintLimitPerBlock;

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
      merkleRoot = _merkleRoot;
    }

    function setWhitelistMintEnabled(bool _state) public onlyOwner {
      whitelistMintEnabled = _state;
    }

    function setCurrentWhitelist(uint256 num) public onlyOwner {
        currentWhitelist = num;
    }

    function setWhitelistLimit(uint256 mintLimitPerBlock) public onlyOwner {
        _mintLimitPerBlock = mintLimitPerBlock;
    }

    function isValid(bytes32[] memory proof, bytes32 leaf) public view returns (bool) {
        return MerkleProof.verify(proof, merkleRoot, leaf);
    }

    function whitelistMint(uint256 quantity, bytes32[] calldata _merkleProof) external payable {
      require(whitelistMintEnabled, "The whitelist sale is not enabled");
      require(msg.value >= mintPrice.mul(quantity), "Need to pay more. Check payment");
      require(!whitelistClaimed[currentWhitelist][msg.sender], "Address already minted");
      require(quantity > 0 && quantity < (_mintLimitPerBlock + 1), "Too many requests or zero request");
      bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
      require(isValid(_merkleProof, leaf), "Is not a whitelisted member");

      deposits += msg.value;
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
                setMetaData(tokenId, false, false, false);
                _setRoyalty(tokenId, owner(), royaltyFee);
            } 
        } else {
            // public/opensea sale
            if (from == owner()) {
                setMetaData(startTokenId, true, false, false);
            }
        }
    }
}