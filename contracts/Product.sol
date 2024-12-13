// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts@v4.9.0/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable@v4.9.0/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable@v4.9.0/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts@v4.9.0/token/ERC721/IERC721.sol";
import "./interfaces/IKventure.sol";
import "./interfaces/IKventureCode.sol";
import "./interfaces/IKventureOrder.sol";

contract KProduct is Initializable, OwnableUpgradeable{
    Product[] public products;
    address[] public Admins;
    mapping(address => bool) public isAdmin;
    // Address smc
    IERC20 public SCUsdt;
    IKventure public SCKven;
    IKventureCode public SCKvenCode;
    IOrder public SCOrder;

    address public MasterPool;
    uint256 public totalProduct;

    mapping(bytes32 => Product) public mIDTOProduct;

    uint8 public returnRIP = 10;
    address[] public BuyerList;
    uint256[] public ActiveProduct;

    mapping(bytes32 => uint256) public mIDTOReward;
    mapping(bytes32 => uint256) public mIDTOFEprice;
    mapping(bytes32 => address) public mIDTONsx;
    event SaleOrder(address buyer,bytes32 orderId,bytes32[] productIds, uint256[] quantities);
    event eBuyProduct(address add, uint256[] quantities, uint256[] prices,uint256 totalPrice, uint256 time);
    event OrderInfo(OrderProduct order,uint256 createAt,string typ);
    constructor() payable {}

    modifier onlyAdmin() {
        require(isAdmin[msg.sender]==true , "Invalid caller-Only Admin");
        _;
    }

    function initialize(
        address _trustedUSDT,
        address _masterPool,
        address _kventureCode,
        address _kventure,
        address _order
    ) public initializer {
        SCUsdt = IERC20(_trustedUSDT);
        MasterPool = _masterPool;
        SCKven = IKventure(_kventure);
        SCKvenCode = IKventureCode(_kventureCode);
        SCOrder = IOrder(_order);
        __Ownable_init();
    }

    function SetKventureCode(address _kventureCode) external onlyOwner {
        SCKvenCode = IKventureCode(_kventureCode);
    }

    function SetOrder(address _order) external onlyOwner {
        SCOrder = IOrder(_order);
    }

    function SetRef(address _kventure) external onlyOwner {
        SCKven = IKventure(_kventure);
    }

    function SetUsdt(address _usdt) external onlyOwner {
        SCUsdt = IERC20(_usdt);
    }

    function SetAdmin(address _admin) external onlyOwner {
        isAdmin[_admin] = true;
        Admins.push(_admin);
    }

    function RemoveAdmin(address _admin) external onlyOwner returns(bool) {
        isAdmin[_admin] = false;
        for (uint256 i = 0; i < Admins.length; i++) {
            if (Admins[i] == _admin) {
                if (i < Admins.length - 1) {
                    Admins[i] = Admins[Admins.length - 1];
                }
                Admins.pop(); 
                return true;
            }
        }
        return true;
    }

    function SetMasterPool(address _masterPool) external onlyOwner {
        MasterPool = _masterPool;
    }

    function order(
        bytes32[] memory idArr, 
        uint256[] memory quaArr,
        bool[] memory lockArr,
        bytes32[][] calldata codeHashes,
        address[] memory delegates,
        bytes32 codeRef, // Support FE version old 
        address to
    ) external returns(bytes32){
        // Payment and bonus tree flow
        require(SCKven.CheckActiveMember(to),"Non member can not order");
        OrderProduct[] memory orderProducts = new OrderProduct[](quaArr.length);
        uint256[] memory prices = new uint256[](quaArr.length);
        uint256 totalPrice;
        for(uint i = 0;i < idArr.length;i++){
            bytes32 id = idArr[i];
            require(mIDTOProduct[id].memberPrice > 0," product id does not exist ");
            // This is link price or member price
            prices[i] = mIDTOProduct[id].memberPrice;
            // Loop because good sale pay in each product
            for (uint256 index = 0; index < quaArr[i]; index++) {
                // Sender transfer to master pool
                require(
                    SCUsdt.balanceOf(msg.sender) >= mIDTOProduct[id].memberPrice,
                    "Product: Invalid Balance"
                );
                SCUsdt.transferFrom(msg.sender, MasterPool, mIDTOProduct[id].memberPrice);
                // Pay bonus
                SCKven.TransferCommssion(to, mIDTOProduct[id].memberPrice,mIDTOReward[id], mIDTOProduct[id].retailPrice - mIDTOProduct[id].memberPrice,mIDTONsx[id]);
                SCKven.AddDiamondShare(to, mIDTOProduct[id].memberPrice);
                // Total price to buy product
                totalPrice += mIDTOProduct[id].memberPrice;
            }    
            orderProducts[i] = OrderProduct({
                desc: mIDTOProduct[id].desc,
                imgUrl: mIDTOProduct[id].imgUrl, 
                price: mIDTOProduct[id].memberPrice,    
                boostTime: mIDTOProduct[id].boostTime,    
                quantity: quaArr[i],  
                retailPrice: mIDTOProduct[id].retailPrice,
                tokens: new uint[](quaArr[i])  
            });
            // Create code if boost time > 0
            if (mIDTOProduct[id].boostTime > 0) {
                orderProducts[i].tokens = _createCode(to, mIDTOProduct[id], quaArr[i], lockArr[i], codeHashes[i], delegates[i]); 
            }
            emit OrderInfo(orderProducts[i],block.timestamp,"USDT");
        }
        emit eBuyProduct(to, quaArr, prices, totalPrice, block.timestamp);
        BuyerList.push(to);

        return SCOrder.CreateOrder(to, orderProducts);
    }

    function _createCode(address buyer, Product memory _product, uint256 _quantity, bool _lock, bytes32[] calldata _codeHashes, address _delegate) internal returns(uint[] memory) {
        return SCKvenCode.GenerateCode(buyer, _product.memberPrice, _quantity, _lock, _codeHashes, _delegate, _product.boostTime);
    }
function orderLock(
        OrderLockInput[] calldata orderLockInputs,
        bytes32 idPayment,
        address to
    ) external returns(bytes32){
        // Payment and bonus tree flow
        require(SCKven.CheckActiveMember(to),"Non member can not order");
        OrderProduct[] memory orderProducts = new OrderProduct[](orderLockInputs.length);
        uint256[] memory prices = new uint256[](orderLockInputs.length);
        uint256 totalPrice;
        uint256[] memory quaArr= new uint256[](orderLockInputs.length);
        for(uint i = 0;i < orderLockInputs.length;i++){
            bytes32 id = orderLockInputs[i].id;
            require(mIDTOProduct[id].memberPrice > 0," product id does not exist ");
            // This is link price or member price
            prices[i] = mIDTOProduct[id].memberPrice;
            // Loop because good sale pay in each product
            for (uint256 index = 0; index < orderLockInputs[i].quantity; index++) {
                // Sender transfer to master pool
                require(
                    SCUsdt.balanceOf(msg.sender) >= mIDTOProduct[id].memberPrice,
                    "Product: Invalid Balance"
                );
                SCUsdt.transferFrom(msg.sender, MasterPool, mIDTOProduct[id].memberPrice);
                // Pay bonus
                // uint256 locktime = block.timestamp + 60 days;
                SCKven.TransferCommssionSave(to, mIDTOProduct[id].memberPrice,mIDTOReward[id], mIDTOProduct[id].retailPrice - mIDTOProduct[id].memberPrice,idPayment,block.timestamp + 60 days,mIDTONsx[id]);
                SCKven.AddDiamondShare(to, mIDTOProduct[id].memberPrice);
                // Total price to buy product
                totalPrice += mIDTOProduct[id].memberPrice;
            }    
            quaArr[i] = orderLockInputs[i].quantity;
            orderProducts[i] = OrderProduct({
                desc: mIDTOProduct[id].desc,
                imgUrl: mIDTOProduct[id].imgUrl, 
                price: mIDTOProduct[id].memberPrice,    
                boostTime: mIDTOProduct[id].boostTime,    
                quantity: orderLockInputs[i].quantity,  
                retailPrice: mIDTOProduct[id].retailPrice,
                tokens: new uint[](orderLockInputs[i].quantity)  
            });
            // Create code if boost time > 0
            if (mIDTOProduct[id].boostTime > 0) {
                orderProducts[i].tokens = _createCodeLock(to, mIDTOProduct[id], orderLockInputs[i]); 
            }
            emit OrderInfo(orderProducts[i],block.timestamp,"VISA");
        }
        emit eBuyProduct(to, quaArr, prices, totalPrice, block.timestamp);
        BuyerList.push(to);

        return SCOrder.CreateOrder(to, orderProducts);
    }
    function _createCodeLock(
        address buyer, 
        Product memory _product,         
        OrderLockInput calldata orderLockInput
    ) internal returns(uint[] memory){
        return SCKvenCode.GenerateCodeLock(buyer, _product.memberPrice, orderLockInput.quantity, orderLockInput.lock, orderLockInput.codeHashes, orderLockInput.delegate, _product.boostTime);
    }
    function adminAddProduct(
        string memory _imgUrl,
        uint256 _memberPrice,
        uint256 _retailPrice,
        string memory _desc,
        bool  _status,
        uint256 _boostTime
    ) external onlyAdmin   {
        bytes32 idPro =keccak256(abi.encodePacked(_imgUrl,_memberPrice,_retailPrice,_desc));
        Product memory product = Product({
            index: products.length,
            id: idPro,
            imgUrl: bytes(_imgUrl),
            memberPrice: _memberPrice,
            retailPrice: _retailPrice,
            desc: bytes(_desc),
            active: _status,
            boostTime: _boostTime
        });
        
        if (_status == true) {
            ActiveProduct.push(products.length);
        }

        products.push(product);
        mIDTOProduct[idPro] = product;
        totalProduct++;
    }
    function AdminActiveProduct(uint256 _index) external onlyAdmin returns (bool) {
        products[_index].active = true;
        for (uint256 i = 0; i < ActiveProduct.length; i++) {
            if (ActiveProduct[i] == _index) {
                return true;
            }
        }
        ActiveProduct.push(_index);
        return true;
    }

    function AdminDeactiveProduct(uint256 _index) external onlyAdmin returns (bool) {
        products[_index].active = false;
        for (uint256 i = 0; i < ActiveProduct.length; i++) {
            if (ActiveProduct[i] == _index) {
                if (i < ActiveProduct.length - 1) {
                    ActiveProduct[i] = ActiveProduct[ActiveProduct.length - 1];
                }
                ActiveProduct.pop(); 
                return true;
            }
        }
        return true;
    }

    function getProductById(bytes32 _id) public view returns(Product memory){
        return mIDTOProduct[_id];
    }

    function adminUpdateProduct(
        uint256 _index,
        string memory _imgUrl,
        string memory _desc,
        uint256 _boostTime
    )external onlyAdmin returns (bool){
        products[_index].imgUrl = bytes(_imgUrl);
        products[_index].desc = bytes(_desc);
        products[_index].boostTime = _boostTime;
        return true;
    }
    function adminUpdateReward(bytes32 id,uint256 _newReward,uint256 _fePrice,address _nsx)external onlyAdmin returns(bool){
        require(_newReward <= (( mIDTOProduct[id].memberPrice * 50 - 20 * (mIDTOProduct[id].retailPrice - mIDTOProduct[id].memberPrice)) * 10**3 /(130*825)),"reward too big");
        mIDTOReward[id] = _newReward;
        mIDTOFEprice[id] = _fePrice;
        mIDTONsx[id] = _nsx;
        return true;
    }
    function getReward(bytes32 id) external view returns(uint256){
        return mIDTOReward[id];
    }

    function adminViewProduct()external view onlyAdmin returns (Product[] memory){
        return products;
    }

    function userViewProduct()external view returns(Product[] memory _products) {
        _products = new Product[](ActiveProduct.length);
        for (uint i=0;i < ActiveProduct.length;i++){
            _products[i] = products[ActiveProduct[i]];
        }
        return _products;
    }
    
}
