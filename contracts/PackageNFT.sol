// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts@v4.9.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@v4.9.0/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@v4.9.0/security/Pausable.sol";
import "@openzeppelin/contracts@v4.9.0/access/AccessControl.sol";
import "@openzeppelin/contracts@v4.9.0/token/ERC721/extensions/ERC721Burnable.sol";

// import "./Product.sol";

contract KventureNft is ERC721, ERC721Enumerable, Pausable, AccessControl, ERC721Burnable {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    
    // address public product;
    // mapping(uint => Product) public mIdToPro;
    constructor() ERC721("Kventure", "KVT") payable {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        // _grantRole(PAUSER_ROLE, msg.sender);
        // _grantRole(MINTER_ROLE, msg.sender);
    }
    // function setProduct(address _product) external onlyRole(DEFAULT_ADMIN_ROLE){
    //     product = _product;
    // }
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function burnByController(uint tokenId) external onlyRole(BURNER_ROLE) {
        _burn(tokenId);
    }

    //  onlyRole(MINTER_ROLE)
    function safeMint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}