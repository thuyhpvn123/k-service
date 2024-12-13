// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable@v4.9.0/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable@v4.9.0/proxy/utils/Initializable.sol";
import "./interfaces/IKventure.sol";
import "./interfaces/IKventureOrder.sol";

contract KOrder is Initializable, OwnableUpgradeable{
    address public AddressProduct;
    mapping(bytes32 => Order) public mIDTOOrder;
    mapping(address => bytes32[]) public mAddressTOOrderID;

    bytes32[] public OrderIDs;
    address[] public Users;
    constructor() payable {}

    modifier onlyProduct() {
        require(msg.sender == AddressProduct , "Invalid caller-Only Product");
        _;
    }

    function initialize(
        address _product
    ) public initializer {
        AddressProduct = _product;
        __Ownable_init();
    }

    function SetProduct(address _product) external onlyOwner {
        AddressProduct = _product;
    }

    function CreateOrder(address _buyer, OrderProduct[] memory _products) onlyProduct() external returns (bytes32){
        bytes32 orderId = keccak256(abi.encodePacked(msg.sender, _buyer, _products.length, block.timestamp));
        for (uint256 index = 0; index < _products.length; index++) {
            mIDTOOrder[orderId].products.push(_products[0]); 
        }

        mIDTOOrder[orderId].id = orderId;
        mIDTOOrder[orderId].buyer = _buyer; 
        mIDTOOrder[orderId].createdAt = block.timestamp; 
        OrderIDs.push(orderId);
        if (mAddressTOOrderID[_buyer].length == 0 ) {
            Users.push(_buyer);
        }
        mAddressTOOrderID[_buyer].push(orderId);
       
        return orderId;
    }

    function UserViewOrder() external view returns (Order[] memory orders){
        orders = new Order[](mAddressTOOrderID[msg.sender].length);
        for (uint256 index = 0; index < mAddressTOOrderID[msg.sender].length; index++) {
            orders[index] = mIDTOOrder[mAddressTOOrderID[msg.sender][index]];
        }
    }

    function UserViewTotalOrder() external view returns (uint){
        return mAddressTOOrderID[msg.sender].length;
    }
    function shippingInfo(
        bytes32 _orderId,
        string memory _firstName,
        string memory _lastName,
        string memory _phoneNumber,
        string memory _country,
        string memory _state,
        string memory _city,
        string memory _streetAddress,
        string memory _zipCode,
        string memory _mail
    )external{
        require(mIDTOOrder[_orderId].buyer == msg.sender,"only owner of order can call");
        ShippingInfo memory shipInfo = ShippingInfo({
            firstName: _firstName,
            lastName :_lastName,
            phoneNumber: _phoneNumber,
            country: _country,
            state:_state,
            city:_city,
            streetAddress: _streetAddress,
            zipCode:_zipCode,
            mail:_mail
        });
        mIDTOOrder[_orderId].shipInfo = shipInfo;
    }
    function getShippingInfo(bytes32 _orderId)external view returns(ShippingInfo memory){
        return mIDTOOrder[_orderId].shipInfo;
    }
    function GetMyOrder(uint32 _page,uint returnRIP) 
    external 
    view 
    returns(bool isMore, Order[] memory arrayOrder) {
        
        bytes32[] memory idArr = new bytes32[](mAddressTOOrderID[msg.sender].length);
        idArr = mAddressTOOrderID[msg.sender];
        // uint256 length = idArr.length;
        if (_page * returnRIP > idArr.length + returnRIP) { 
            return(false, arrayOrder);
        } else {
            if (_page*returnRIP < idArr.length ) {
                isMore = true;
                arrayOrder = new Order[](returnRIP);
                for (uint i = 0; i < arrayOrder.length; i++) {
                    arrayOrder[i] = mIDTOOrder[idArr[_page*returnRIP - returnRIP +i]];
                }
                return (isMore, arrayOrder);
            } else {
                isMore = false;
                arrayOrder = new Order[](returnRIP -(_page*returnRIP - idArr.length));
                for (uint i = 0; i < arrayOrder.length; i++) {
                    arrayOrder[i] = mIDTOOrder[idArr[_page*returnRIP - returnRIP +i]];
                }
                return (isMore, arrayOrder);
            }
        }
    }
    function getmIDTOOrder(bytes32 idOrder)external view returns(Order memory){
        return mIDTOOrder[idOrder];
    }
    function getOrderIds(address add)external view returns(bytes32[] memory){
        return mAddressTOOrderID[add];
    }


}
