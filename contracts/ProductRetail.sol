// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts@v4.9.0/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable@v4.9.0/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable@v4.9.0/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts@v4.9.0/token/ERC721/IERC721.sol";
import "./interfaces/IKventure.sol";
import "./interfaces/IKventureCode.sol";
import "./interfaces/IKventureOrder.sol";

struct OrderParam {
    address buyer;
    address bonus;
    bytes32[]  codeHashes;
    uint quantity;
    address delegate;
    bool lock;
}

contract KProductRetail is Initializable, OwnableUpgradeable{
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
    uint256 public DiscountPercent; // div 1000 0.5% -> 5, 50% -> 500

    mapping(bytes32 => Product) public mIDTOProduct;

    uint8 public returnRIP = 10;
    address[] public BuyerList;
    uint256[] public ActiveProduct;

    mapping(bytes32 => uint256) public mIDTOReward;
    mapping(bytes32 => uint256) public mIDTOFEprice;
    mapping(bytes32 => address) public mIDTONsx;

    event eBuyProduct(address add, uint256[] quantities, uint256[] prices,uint256 totalPrice, uint256 time);
    event eDiscountLink(address add, address link,uint256 percent ,uint256 totalDiscount, uint256 time);

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
        DiscountPercent = 80;
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
        bytes32 codeRef,
        address to,
        address link
    ) external returns (bytes32) {
        // Payment and bonus tree flow

        address bonusUser = SCKven.GetRefCodeOwner(codeRef);
        OrderProduct[] memory orderProducts = new OrderProduct[](quaArr.length);

        require(bonusUser != address(0),"RefCode invalid");
        {
            for(uint i = 0;i < idArr.length;i++){
                bytes32 id = idArr[i];
                {
                    OrderParam memory param;
                    param.codeHashes = codeHashes[i];
                    param.bonus = bonusUser;
                    param.quantity = quaArr[i];
                    param.lock = lockArr[i];
                    param.delegate = delegates[i];
                    param.buyer = to;
                    orderProducts[i] = _order(param, mIDTOProduct[id]);
                }
            }
        }

        {
            uint256 totalPrice;
            uint256 discountPrice;
            uint256[] memory prices = new uint256[](quaArr.length);
            for (uint256 index = 0; index < orderProducts.length; index++) {
                totalPrice += orderProducts[index].price * orderProducts[index].quantity;
                discountPrice += (orderProducts[index].retailPrice - orderProducts[index].price) * orderProducts[index].quantity;
                prices[index] = orderProducts[index].price;
            }
            emit eBuyProduct(to, quaArr, prices, totalPrice, block.timestamp);
            emit eDiscountLink(to, link, DiscountPercent, discountPrice, block.timestamp);
        }
        BuyerList.push(to);
        return SCOrder.CreateOrder(to, orderProducts);
    }

    function _order(OrderParam memory _param, Product memory _product) internal returns(OrderProduct memory orderProduct) {
        // uint256 discountPrice = _product.retailPrice *  DiscountPercent / 1_000;
        // uint256 actualPrice = _product.retailPrice - discountPrice;
        uint256 actualPrice = _product.retailPrice;
        require(actualPrice > _product.memberPrice);

        for (uint256 index = 0; index < _param.quantity; index++) {
            // Sender transfer to master pool
            require(
                SCUsdt.balanceOf(msg.sender) >= actualPrice,
                "Product: Invalid Balance"
            );
            SCUsdt.transferFrom(msg.sender, MasterPool, actualPrice);
            // Pay bonus
            SCKven.TransferRetailBonus(_param.bonus,_product.memberPrice, mIDTOReward[_product.id], _product.retailPrice - _product.memberPrice,mIDTONsx[_product.id] );
        }
        orderProduct.desc = _product.desc;
        orderProduct.imgUrl = _product.imgUrl;
        orderProduct.price = actualPrice;
        orderProduct.boostTime = _product.boostTime;
        orderProduct.quantity = _param.quantity;
        orderProduct.retailPrice = _product.retailPrice;

        if (_product.boostTime > 0) {
            orderProduct.tokens = SCKvenCode.GenerateCode(_param.buyer, _product.memberPrice, _param.quantity, _param.lock, _param.codeHashes, _param.delegate, orderProduct.boostTime);
        }
    }

    function _createCode(address buyer, Product memory _product, uint256 _quantity, bool _lock, bytes32[] calldata _codeHashes, address _delegate) internal returns(uint[] memory) {
        return SCKvenCode.GenerateCode(buyer, _product.memberPrice, _quantity, _lock, _codeHashes, _delegate, _product.boostTime);
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

    function SetDiscountPercent(uint256 _amount)external onlyAdmin returns (bool){
        DiscountPercent = _amount;
        return true;
    }
}
