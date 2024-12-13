// contracts/GameItem.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts@v4.9.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@v4.9.0/access/Ownable.sol";
import "@openzeppelin/contracts@v4.9.0/token/ERC20/IERC20.sol";
import "./model/struct_models.sol";
import "forge-std/console.sol";
import {IMasterPool} from "./interfaces/IMasterPool.sol";

contract PosNFT is ERC721, Ownable {
    constructor() payable ERC721("PosNFT", "PNFT") {
        usdt = IERC20(0x0000000000000000000000000000000000000002);
    }

    mapping(uint256 => NftInfo) public mNftInfo;
    mapping(bytes32 => uint256[]) public nftList; 

    address public POS;
    address public masterpool;
    IERC20 public usdt;
    uint256 public totalNFT;

    event EMint(
        address indexed to,
        uint256 indexed tokenId,
        uint256 indexed value,
        uint256 atTime
    );

    event EConvert(
        address indexed caller,
        uint256 indexed tokenId,
        uint256 indexed value,
        uint256 atTime
    );

    function setPos(address _newPos) public onlyOwner returns (bool) {
        POS = _newPos;
        return true;
    }

    function setUsdt(address _newUsdt) external onlyOwner returns(bool) {
        usdt = IERC20(_newUsdt);
        return true;
    }

    function setKventure(address _newKventure) public onlyOwner returns(bool) {
        masterpool = _newKventure;
        return true;
    }
    function mint(
        address _to,
        uint256 _price,
        uint256 _lockTime,
        string calldata _nftType,
        bytes32 _paymentId
    ) public returns (uint256) {
        require(msg.sender == POS || msg.sender == masterpool, '{"from": "PosNFT.sol","code": 0}'); // Only POS or masterpool
        totalNFT++;
        uint256 tokenId = totalNFT;
        usdt.transferFrom(msg.sender, address(this), _price);
        super._safeMint(_to, tokenId);
        mNftInfo[tokenId] = NftInfo({
            tokenId: tokenId,
            price: _price,
            lockTime: _lockTime,
            nftType: _nftType,
            paymentId: _paymentId
        });
        nftList[_paymentId].push(tokenId);
        emit EMint(_to, tokenId, _price, block.timestamp);
        return tokenId;
    }

    function convert(uint256 _tokenId) public returns (bool) {
        require(
            msg.sender == ownerOf(_tokenId),
            '{"from": "PosNFT.sol","code": 0}'
        ); // Not NFT Owner
        require(block.timestamp > mNftInfo[_tokenId].lockTime, '{"from": "PosNFT.sol","code": 0}'); // NFT Still Lock
        uint256 convertedValue = mNftInfo[_tokenId].price;
        delete mNftInfo[_tokenId];
        super._burn(_tokenId);
        usdt.transfer(msg.sender, convertedValue);
        emit EConvert(msg.sender, _tokenId, convertedValue, block.timestamp);
        return true;
    }

}
