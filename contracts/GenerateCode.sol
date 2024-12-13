// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {ICodePool} from "./interfaces/ICodePool.sol";
import "@openzeppelin/contracts@v4.9.0/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable@v4.9.0/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable@v4.9.0/proxy/utils/Initializable.sol";
import "./AbstractPackage.sol";
import "./interfaces/ICode.sol";
import "./interfaces/IMining.sol";
import "./interfaces/IKventureNFT.sol";
import "./interfaces/IDiscount.sol";

contract KventureCode is Initializable, OwnableUpgradeable, PackageInfoStruct {
    uint public RateBoost;
    uint256 public usdtDecimal = 10 ** 6;
    uint256 public boostSpeedDecimal = 10 ** 2;
    uint256 public KCodePrice = usdtDecimal * 30;
    uint256 public CLoudPrice = usdtDecimal * 5000;
    uint32 public returnRIP = 10;
    mapping(bytes32 => Code) mPackageInfo;
    mapping(uint256 => uint256) public mValidMiningTime;

    uint public deployedDate;

    address public usdt;
    ICodePool public codePool;
    IMining public mining;
    address public masterPool;
    address public nft;
    address public kventure;
    address public product;
    address public CloudMining;
    mapping(uint => Product) public mIdToPro;
    
    mapping(address => bool) public mIsProduct;
    uint256 public MulBoostingTime;
    uint256 public MulBoostingRate;
    // uint256 public multiplePrice; ??? Chi Thuy viet cai j vay troi
    uint256 public BeginRequireActivateDate;
    uint256 public EndRequireActivateDate;
    uint256 public BeginBuyTime;
    uint256 public EndBuyTime;

    IDiscount public CodeDiscount;
    constructor() payable {}

    function initialize(
        address _trustedUSDT,
        address _masterPool,
        address _codePool,
        address _product,
        address _trustedNFT,
        address _kventure,
        address _mining
    ) public initializer {
        usdt = _trustedUSDT;
        masterPool = _masterPool;
        codePool = ICodePool(_codePool);
        kventure = _kventure;
        mIsProduct[_product] = true;
        nft = _trustedNFT;
        mining = IMining(_mining);
        __Ownable_init();

        // returnRIP = 10;
        usdtDecimal = 10 ** 6;
        boostSpeedDecimal = 10 ** 2;
        RateBoost = 1 * usdtDecimal / 10; // 1$ = 1%
        deployedDate = block.timestamp;
    }

    modifier onlyKventure() {
        require(msg.sender == kventure, "KventureCode: Only kventure");
        _;
    }
    
    modifier onlyProduct() {
        require(mIsProduct[msg.sender], "KventureCode: Only product");
        _;
    }
    function SetNFT(address _nft) external onlyOwner {
        nft = _nft;
    }

    function SetUsdt(address _usdt) external onlyOwner {
        usdt = _usdt;
    } 
    function SetMasterPool(address _masterPool) external onlyOwner {
        masterPool = _masterPool;
    }
    function SetProduct(address _product) external onlyOwner {
        mIsProduct[_product] = true;
    }
    function SetCLoudPrice(uint256 _price) external onlyOwner {
        CLoudPrice = _price;
    }
    function SetRateBoost(uint256 _price) external onlyOwner {
        RateBoost = _price;
    }
    function SetCodePool(address _codePool) external onlyOwner {
        codePool = ICodePool(_codePool);
    }
    function SetMining(address _mining) external onlyOwner {
        mining = IMining(_mining);
    }
    function SetDiscount(address _address) external onlyOwner {
        CodeDiscount = IDiscount(_address);
    }

    function SetCloudMiningAddress(address _cloudMining) external onlyOwner {
        CloudMining = _cloudMining;
    }
    function SetMultiBoost(
        uint256 _multipleBoostingTime, 
        uint256 _multipleBoostingRate, 
        uint256 _beginRequireActivateDate, 
        uint256 _endRequireActivateDate,
        uint256 _beginBuyTime,
        uint256 _endBuyTime
    ) external onlyOwner{
        require(
            _multipleBoostingRate > 0
            && _multipleBoostingTime > 0,
            "KventureCode: Input invalid"
        );
        MulBoostingTime = _multipleBoostingTime;
        MulBoostingRate = _multipleBoostingRate;
        BeginRequireActivateDate = _beginRequireActivateDate; 
        EndRequireActivateDate = _endRequireActivateDate;
        BeginBuyTime = _beginBuyTime;
        EndBuyTime = _endBuyTime;
    }
    
    function GenerateCode(
        address buyer,
        uint planPrice,
        uint quantity,
        bool lock,
        bytes32[] calldata codeHashes,
        address _delegate,
        uint256 _boostTime
    ) external onlyProduct returns (uint[] memory) {
        require(
            codeHashes.length == quantity && quantity > 0,
            "Kventure: Code Hash Not Equal To Quantity or Quantity Smaller Than 1"
        );

        uint [] memory codes = new uint[](quantity); 
        for (uint i = 0; i < quantity; i++) {
            uint code = _generateCode(
                buyer,
                codeHashes[i],
                lock,
                planPrice,
                RateBoost,
                _delegate,
                _boostTime
            );
            codes[i]=code;
        }

        return codes;
    }


    function KGenerateCode(
        address buyer,
        bytes32 codeHash
    ) external onlyKventure returns (bool) {
        _generateCode(
            buyer,
            codeHash,
            false,
            KCodePrice,
            RateBoost,
            CloudMining,
            45 days
        );
        return true;
    }

    function _generateCode(
        address buyer,
        bytes32 codeHash,
        bool _lock,
        uint _planPrice,
        uint _rateBoost,
        address _delegate,
        uint256 _boostTime
    ) internal returns(uint){
        require(
            mPackageInfo[codeHash].owner == address(0),
            "MetaNode: Duplicate Code Hash"
        );
        // require(
        //     mining.isCloudMining(_delegate),
        //     "MetaNode: Not set cloud mining"
        // );
        uint code = uint(codeHash);
        if(_planPrice < CLoudPrice){
            _delegate = address(0);
        }
        
        mPackageInfo[codeHash] = Code({
            owner: buyer,
            codeHash: codeHash,
            activeTime: 0,
            expirationActiveTime: block.timestamp + 90 days,
            boostSpeed: (_planPrice * boostSpeedDecimal) / _rateBoost,
            boostTime: _boostTime,
            rateBoost: _rateBoost,
            delegate: _delegate,
            status: _isBlock(_lock),
            origin:"KVENTURE",
            mintedAmount: 0,
            releasePercentage:100,
            lockTime:0,
            keyHash:bytes32(0),
            currentDeposit:0,
            lastestClaim:0
        });
        INFT(nft).safeMint(buyer,code);
        // codePool.addCode(mPackageInfo[codeHash]);
        if (block.timestamp <= EndBuyTime && block.timestamp >= BeginBuyTime){ 
            CodeDiscount.AddInfoDiscount(codeHash, MulBoostingTime, MulBoostingRate, BeginRequireActivateDate, EndRequireActivateDate, buyer);
        }
        return code;
    }
 function GenerateCodeLock(
        address buyer,
        uint planPrice,
        uint quantity,
        bool lock,
        bytes32[] calldata codeHashes,
        address _delegate,
        uint256 _boostTime
    ) external onlyProduct returns (uint[] memory) {
        require(
            codeHashes.length == quantity && quantity > 0,
            "Kventure: Code Hash Not Equal To Quantity or Quantity Smaller Than 1"
        );

        uint [] memory codes = new uint[](quantity); 
        for (uint i = 0; i < quantity; i++) {
            uint code = _generateCodeLock(
                buyer,
                codeHashes[i],
                lock,
                planPrice,
                RateBoost,
                _delegate,
                _boostTime
            );
            codes[i]=code;
        }

        return codes;
    }
    function _generateCodeLock(
        address buyer,
        bytes32 codeHash,
        bool _lock,
        uint _planPrice,
        uint _rateBoost,
        address _delegate,
        uint256 _boostTime
    ) internal returns(uint){
        require(
            mPackageInfo[codeHash].owner == address(0),
            "MetaNode: Duplicate Code Hash"
        );
        // require(
        //     mining.isCloudMining(_delegate),
        //     "MetaNode: Not set cloud mining"
        // );
        uint code = uint(codeHash);
        if(_planPrice < CLoudPrice){
            _delegate = address(0);
        }
        
        mPackageInfo[codeHash] = Code({
            owner: buyer,
            codeHash: codeHash,
            activeTime: 0,
            expirationActiveTime: block.timestamp + 90 days,
            boostSpeed: (_planPrice * boostSpeedDecimal) / _rateBoost,
            boostTime: _boostTime,
            rateBoost: _rateBoost,
            delegate: _delegate,
            status: _isBlock(_lock),
            origin:"KVENTURE",
            mintedAmount: 0,
            releasePercentage:0,
            lockTime:block.timestamp + 60 days,
            keyHash:bytes32(0),
            currentDeposit:0,
            lastestClaim:0
        });
        INFT(nft).safeMint(buyer,code);
        // codePool.addCode(mPackageInfo[codeHash]);
        if (block.timestamp <= EndBuyTime && block.timestamp >= BeginBuyTime){ 
            CodeDiscount.AddInfoDiscount(codeHash, MulBoostingTime, MulBoostingRate, BeginRequireActivateDate, EndRequireActivateDate, buyer); 
        }
        return code;
    }
    function AddCodePool(bytes32 codeHash) public  {
        codePool.addCode(mPackageInfo[codeHash]);
    }

    function UnblockManyCode(
        string[] calldata codeFEs
    ) external returns (bool[] memory) {
        bool[] memory success = new bool[](codeFEs.length);
        bytes32 codeHash;
        for (uint index = 0; index < codeFEs.length; index++) {
            codeHash = keccak256(abi.encodePacked(codeFEs[index]));
            if (
                msg.sender != mPackageInfo[codeHash].owner ||
                mPackageInfo[codeHash].status == Status.Unblock
            ) {
                continue;
            }
            mPackageInfo[codeHash].status = Status.Unblock;
            success[index] = true;
        }
        return success;
    }

    function BlockManyCode(
        string[] calldata codeFEs
    ) external returns (bool[] memory) {
        bool[] memory success = new bool[](codeFEs.length);
        bytes32 codeHash;
        for (uint8 index = 0; index < codeFEs.length; index++) {
            codeHash = keccak256(abi.encodePacked(codeFEs[index]));
            if (
                msg.sender != mPackageInfo[codeHash].owner ||
                mPackageInfo[codeHash].status == Status.Block
            ) {
                continue;
            }
            mPackageInfo[codeHash].status = Status.Block;
            success[index] = true;
        }
        return success;
    }

    function _isBlock(bool lock) internal pure returns (Status) {
        return lock ? Status.Block : Status.Unblock;
    }

    function getCodeInfoSmC(
        bytes32 codeHash
    ) external view returns (Code memory) {
        return mPackageInfo[codeHash];
    }


    function GetMyCode(uint32 _page) 
    external 
    returns(bool isMore, Code[] memory arrayPack) {
        uint length = INFT(nft).balanceOf(msg.sender);
        if (_page * returnRIP > length + returnRIP) { 
            return(false, arrayPack);
        } else {
            if (_page*returnRIP < length ) {
                isMore = true;
                arrayPack = new Code[](returnRIP);
            } else {
                isMore = false;
                arrayPack = new Code[](returnRIP -(_page*returnRIP - length));
            }
            for (uint i = 0; i < arrayPack.length; i++) {
                arrayPack[i] = codePool.getCodeInfo(bytes32(INFT(nft).tokenOfOwnerByIndex(msg.sender,_page*returnRIP - returnRIP +i)));
            }
            return (isMore, arrayPack);
        }
    }

    function GetUserCode(uint32 _page, address _user) 
    external onlyOwner
    returns(bool isMore, Code[] memory arrayPack) {
        uint length = INFT(nft).balanceOf(_user);
        if (_page * returnRIP > length + returnRIP) { 
            return(false, arrayPack);
        } else {
            if (_page*returnRIP < length ) {
                isMore = true;
                arrayPack = new Code[](returnRIP);
            } else {
                isMore = false;
                arrayPack = new Code[](returnRIP -(_page*returnRIP - length));
            }
            for (uint i = 0; i < arrayPack.length; i++) {
                arrayPack[i] = codePool.getCodeInfo(bytes32(INFT(nft).tokenOfOwnerByIndex(_user,_page*returnRIP - returnRIP +i)));
            }
            return (isMore, arrayPack);
        }
    }

    function GetTotalMyCode() external view returns(uint) {
        return INFT(nft).balanceOf(msg.sender);
    }
}