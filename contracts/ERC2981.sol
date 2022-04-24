// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";

abstract contract ERC2981 is IERC2981 {
    struct Royalty {
        address creator;
        uint256 value;
    }

    mapping(uint256 => Royalty) internal _royalties;

    function _setRoyalty(
        uint256 tokenId,
        address creator,
        uint256 value
    ) internal {
        require(value <= 10000, "ERC2981: Royalty too high");
        _royalties[tokenId] = Royalty(creator, value);
    }

    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        override
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        Royalty memory royalty = _royalties[tokenId];
        return (royalty.creator, (value * royalty.value) / 10000);
    }
}
