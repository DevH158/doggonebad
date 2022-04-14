// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DogGoneBad is ERC721, Ownable {
    uint256 public publicSaleCount;
    bool public publicSaleEnabled = false;

    mapping (address => uint256) private _lastCallBlockNumber;

    uint256 private _mintIndex;
    uint256 private _maxMintAmount;
    uint256 private _antibotInterval;
    uint256 private _mintLimitPerBlock;
    uint256 private _mintLimitPerSale;
    uint256 private _mintStartAfterDays;
    uint256 private _mintStartTimestamp;
    uint256 private _mintPrice = 1 * 10 ** 18;

    constructor() ERC721("TestDogGoneBad", "TDGB") {}

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
}