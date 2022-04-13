// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface Factory {
    function tokenToPool(address, address) external view returns (address);
}

interface Exchange {
    function getCurrentPool() external view returns (uint, uint);
}

contract CustomRandom {

    uint private sealedSeed;

    address private baseToken = 0x5c74070FDeA071359b86082bd9f9b3dEaafbe32b; // KDAI
    address private token1 = 0xC6a2Ad8cC6e4A7E08FC37cC5954be07d499E7654; // KSP
    address private token2 = 0xC6a2Ad8cC6e4A7E08FC37cC5954be07d499E7654; // BORA
    address private token3 = 0x0000000000000000000000000000000000000000; // KLAY

    mapping (address => uint256) private prevUserInput;

    constructor(uint _sealedSeed) {
        sealedSeed = _sealedSeed;
    }

    function resetTokenAddress(address add1, address add2, address add3) public {
        token1 = add1;
        token2 = add2;
        token3 = add3;
    }

    function getExchangeAddress(address tokenA, address tokenB) public view returns (address) {
        Factory ksp = Factory(0xC6a2Ad8cC6e4A7E08FC37cC5954be07d499E7654);
        return ksp.tokenToPool(tokenA, tokenB);
    }

    function getCurrentPool(address tokenA, address tokenB) public view returns (uint, uint) {
        address exchangeContract = getExchangeAddress(tokenA, tokenB);
        Exchange exchange = Exchange(exchangeContract);
        return exchange.getCurrentPool();
    }

    function getRandom(uint userInput) public returns (uint) {
        require(prevUserInput[msg.sender] != userInput, "please provide a different number input");
        prevUserInput[msg.sender] = userInput;

        // KLAY: 0x0000000000000000000000000000000000000000
        (uint num1, uint num2) = getCurrentPool(baseToken, token1);
        (uint num3, uint num4) = getCurrentPool(baseToken, token2);
        (uint num5, uint num6) = getCurrentPool(baseToken, token3);

        uint num = uint(
            keccak256(
                abi.encodePacked(
                    sealedSeed,
                    userInput,
                    num1,
                    num2,
                    num3,
                    num4,
                    num5,
                    num6,
                    block.timestamp,
                    msg.sender,
                    blockhash(block.number - 1)
                )
            )
        );
        return num % 100;
    }

    function getMockRandom(uint userInput) public view returns (uint) {
                uint num = uint(
            keccak256(
                abi.encodePacked(
                    sealedSeed,
                    userInput,
                    block.timestamp,
                    msg.sender,
                    blockhash(block.number - 1)
                )
            )
        );
        return num % 100;
    }
}