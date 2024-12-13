// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts@v4.9.0/access/Ownable.sol";
import "@openzeppelin/contracts@v4.9.0/token/ERC20/IERC20.sol";
import {IPosNFT} from "./interfaces/IPosNFT.sol";
import "forge-std/console.sol";
contract MasterPool is Ownable  {
    address public usdt;
    mapping(address => bool) public isController;
    address public posNft;
    mapping(address => uint256) public mAddressToLockTime;
    mapping(address => bytes32) public mIdPayment;
    constructor(address _usdt) payable {
        usdt = _usdt;
    }
    function setPosNft(address _posNft) external onlyOwner {
        posNft = _posNft;
    }
    function setController(address _address) external onlyOwner {
        isController[_address] = true;
    }

    function SetUsdt(address _usdt) external onlyOwner {
        usdt = _usdt;
    }
    modifier onlyController {
        require(isController[msg.sender] == true, "Only Controller");
        _;
    }

    function widthdraw(uint256 amount) external onlyOwner {
        require(usdt != address(0), "Invalid usdt");
        IERC20(usdt).transfer(msg.sender, amount);
    }   

    // Only Controller
    function transferCommission(address _to, uint256 _amount, string calldata _nftType) external onlyController returns(bool) {
        if(mAddressToLockTime[_to] < block.timestamp && mAddressToLockTime[_to] > 0){
            IPosNFT(posNft).mint(_to, _amount,mAddressToLockTime[_to],_nftType,mIdPayment[_to]);
        }
        return IERC20(usdt).transfer(_to, _amount);
    }

    function setLock(address _to,uint256 _locktime,bytes32 _idPayment) external onlyController {
        mAddressToLockTime[_to] = _locktime;
        mIdPayment[_to] = _idPayment;
    }

    function transferCommissionUseNft(
        address _to,
        uint256 _price,
        uint256 _lockTime,
        string calldata _nftType,
        bytes32 _paymentId
    ) external onlyController {
        IERC20(usdt).approve(posNft,_price);
        uint256 id = IPosNFT(posNft).mint(_to, _price,_lockTime,_nftType,_paymentId);
    }
}
