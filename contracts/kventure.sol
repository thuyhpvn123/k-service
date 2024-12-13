// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "@openzeppelin/contracts-upgradeable@v4.9.0/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts@v4.9.0/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable@v4.9.0/proxy/utils/Initializable.sol";
import {IMasterPool} from "./interfaces/IMasterPool.sol";
import "@openzeppelin/contracts@v4.9.0/utils/math/Math.sol";
import {IBinaryTree} from "./interfaces/IBinaryTree.sol";
import {IKventureCode} from "./interfaces/IKventureCode.sol";
import "./AbstractPackage.sol";
import "./library/ConvertTime.sol";
import "forge-std/console.sol";

contract KVenture is Initializable, OwnableUpgradeable,PackageInfoStruct {
    using DateTimeLibrary for uint;

    struct SubcribeInfo {
        bytes32 codeRef;
        bytes32 phone;
    } 
    struct Generation{
        uint64 Silver;
        uint64 Gold;
        uint64 Platinum;
        uint64 Diamond; 
    }

    struct NumberChild{
        uint64 Bronze;
        uint64 Silver;
        uint64 Gold;
        uint64 Platinum;
    }

    address public usdt;
    address public masterPool;
    IBinaryTree public binaryTree;
    IKventureCode public kCode;
     
    address public packageController;
    address public root;
    // address public product;

    uint public totalUser;
    enum Rank {Unranked, Bronze, Silver,Gold,Platinum,Diamond,crownDiamond}
    mapping(address => Generation) public mGenerations;
    mapping(address => uint8)public ranks; //0-6
    mapping(bytes32 => address) public mRefCode;
    mapping(address => SubcribeInfo) public mSubInfo;
    mapping(address => address[]) public childrens;
    mapping(address => address[]) public childrensMatrix;
    mapping(address => address) public line; //parent
    mapping(address => address) public lineMatrix; //parent matrix    //nhớ xoá public
    mapping(address => bool) public isActive;
    mapping(address => uint256) firstTimePay;
    mapping(address => uint256) nextTimePay;
    mapping(address => bool) public mSub;
    mapping(address => bytes32) public mphone;
    mapping(address => uint256) public mtotalMember;
    mapping(address => bytes32) public mUUID;
    mapping(address => NumberChild) public mNumberChild;
    uint256[] public totalMemberRequiredToRankUps ;  
    uint256[] public totalMemberF1RequiredToRankUps ;         
    uint256 public RankUpdateBranchRequired ;
    uint256[] public totalMaxMembers1BranchToRankUp;
    address[] public addressList;

    uint256[] public comDirectRate; //0.5% => (5% / 10) = 5/(10^3) 
    uint256 public adDirectRate;
    uint256 comMatrixRate;
    uint256[] public comMatchingRate;
    uint256 public usdtDecimal; 
    uint registerFee;
    uint subcriptionFee;
    uint32 public day; 

    event Subcribed(address subcriber,uint256 amount,address parentDirect, address parentMatrix,uint256 time,bytes32 phone);
    event PayBonus(address add, uint256 rank,uint256 index,uint256 rate ,uint256 commission,uint256 time, string typ,bytes32 idPayment);
    event UserData(address add,bytes32 phone, string name);
    event TeamData(address add, uint256 rank, uint256 IsActive);
    uint256 public totalSubscriptionPayment; 
    uint256 public totalMatrixPayment; 
    uint256 public totalMatchingPayment; 
    uint256 maxDirectRateBonus;
    uint256 maxMatrixRateBonus;
    uint256 matrixCompanyRateBonus;

    uint256 public maxLineForMatrixBonus ;

    uint256[] public saleRateMatrix; //0.5% => (5% / 10) = 5/(10^3) 
    uint256[] public saleRateDirect;
    uint256[] public levelCareerBonus;   
    uint256 public totalSalePayment;
    uint256 public totalCareerPayment;
    uint256 public totalExtraDiamondPayment;
    uint256 public totalExtraCrownDiamondPayment;

    uint256 totalSaleRevenue;
    mapping(address => uint256) public totalSubcriptionBonus;
    mapping(address => uint256) public totalMatrixBonus;
    mapping(address => uint256) public totalMatchingBonus;
    mapping(address => uint256) public totalSaleBonus;
    mapping(address => uint256) public totalGoodSaleBonus;
    mapping(address => uint256) public totalExtraDiamondBonus;
    mapping(address => uint256) public totalExtraCrownDiamondBonus;

    mapping(address => uint256) public totalRevenues;
    mapping(address => uint256) public totalSale;

    mapping(address => mapping(uint8 => bool)) public mIsPaiedCareerBonus; // parent address => level => isClaimed Commission Bonus
    mapping(address => uint256) public currentRevenueForGoodSaleBonus;
    uint256 additionalCom ;
    mapping(address => bool) public isAdmin;
    address [] diamondArr;
    address [] crownDiamondArr;
    uint256 diamondRate;
    uint256 crownDiamondRate;
    uint256 SaleBonusRate;
    struct UserInfo{
        address add;
        bool IsActive;
        uint256 FirstTimePay;
        uint256 NextTimePay;
        bytes32 Mphone;
        address[] Childrens;
        address[] ChildrensMatrix;
        address Line; //parent
        address LineMatrix;
        uint256 MtotalMember;
        uint256 Rank;
        uint256 totalSubcriptionBonus;
        uint256 totalMatrixBonus;
        uint256 totalMatchingBonus;
        uint256 totalSaleBonus;
        uint256 totalGoodSaleBonus;
        uint256 totalExtraDiamondBonus;
        uint256 totalExtraCrownDiamondBonus;
        uint256 totalSale;
        bytes32 UUID;
        string Username;
    }
    // UserInfo userinfo;
    address public DAO_DT; // Corporation Wallet (IBe)
    uint256 timeInActive;
    address public DTBH;
    uint256 public DTBH_RATE;
    uint256 public DT_BALANCE;
    uint256 public DT_DEBT;
    uint256 public DT_RATE;
    address public MTN;
    uint256 public MTN_RATE;
    uint256 public DAODIFF_RATE;
    address public MAX_OUT;
    bytes32 public INIT_CODE_REF;
    address public DTBL;
    struct DiamondShare{
        uint8 rank;
        uint256 times;
    }
    mapping(address => uint256) public AddressToExpiredDiamondShareTime;
    mapping(uint256 => DiamondShare) public PriceToDiamondShare;
    address[] public UserDiamondShare;
    address[] public UserCrownDiamondShare;
    mapping(address => bool) public mIsProduct;
    mapping(address => string) public mAddressToUsername;
    struct RequiredUpRank{
        uint256 NowChild;
        uint256 NowF1;
        uint256 NowBranchValid;
        uint256 NowChildWithCondition;
        uint256 ChildRequired;
        uint256 F1Required;
        uint256 BranchValidRequired;
        uint256 ChildWithConditionRequired;
    }
    bool DisableCode30;
    uint256 public F0DIFF_RATE;
    uint256 public REWARD_RATE;
    event Buysub(address payer,address to,uint256 amount, string typ );
    constructor() payable {}
    function initialize(address _usdt, address _masterPool,address _binaryTree,address _root, address _wallet, address _partnerWallet, address _kCode, address _mtn, address _maxOut, address _dtbl) public initializer {
        usdt = _usdt;
        masterPool = _masterPool;
        binaryTree = IBinaryTree(_binaryTree);
        kCode = IKventureCode(_kCode);
        root = _root;
        __Ownable_init();

        totalMemberRequiredToRankUps =[0,2,20,100,500,2_500,50_000];
        totalMemberF1RequiredToRankUps = [0,2,10,30,100];
        totalMaxMembers1BranchToRankUp = [0,0,0,30,150,500,10_000];
        RankUpdateBranchRequired = 3;
        comDirectRate = [500,100, 50, 50, 30, 20, 20, 10, 10, 10]; //0.5% => (5% / 10) = 5/(10^3) 
        adDirectRate = 175;
        comMatrixRate = 25;
        maxDirectRateBonus = 800;
        maxMatrixRateBonus = 825;
        matrixCompanyRateBonus = 150;
        comMatchingRate = [500, 100, 50, 50, 30];

        usdtDecimal = 10**6; 
        registerFee = 40 * usdtDecimal;
        subcriptionFee =10 * usdtDecimal;
        day = 1;
        maxLineForMatrixBonus = 15;
        //sale bonus
        saleRateMatrix = [20,10,10,10,10,10,10,10,10];
        saleRateDirect = [500,100,50,30,20];
        levelCareerBonus = [600, 1_200, 2_400, 6_000, 12_000];
        additionalCom = 100;
        diamondRate = 20;
        crownDiamondRate = 5;
        SaleBonusRate = 270;
        isAdmin[msg.sender] = true;
        timeInActive = 30 days;

        DAO_DT = _wallet; // Set Corporation Wallet
        DTBH = _partnerWallet; 
        DTBH_RATE = 25;
        DT_RATE = 180;
        MTN_RATE = 500;
        MTN = _mtn;
        MAX_OUT = _maxOut;
        DTBL = _dtbl;
        DAODIFF_RATE = 175;
        F0DIFF_RATE = 800;
        REWARD_RATE = 825;
    }

    modifier onlyProduct() {
        require(mIsProduct[msg.sender], "Kventure: Only product");
        _;
    }

    modifier onlySub() {
        require(mSub[msg.sender] == true, 'MetaNode: Please Subcribe First');
        _;
    }
    modifier onlyAdmin() {
        require(isAdmin[msg.sender]==true , "Invalid caller-Only Admin");
        _;
    }
    function SetKventureCode(address _kvenCode) external onlyOwner {
        kCode = IKventureCode(_kvenCode);
    }
    function SetWallet(address _wallet) external onlyOwner {
        DAO_DT = _wallet;
    } 
    function SetTimeInActive(uint256 _time) external onlyOwner {
        timeInActive = _time;
    } 
    function SetAdmin(address _admin) external onlyOwner {
        isAdmin[_admin] = true;
    } 
    function SetBinaryTree(address _binaryTree) external onlyOwner {
        binaryTree = IBinaryTree(_binaryTree);
    } 
    function SetUsdt(address _usdt) external onlyOwner {
        usdt = _usdt;
    } 
    function SetDtbl(address _dtbl) external onlyOwner {
        DTBL = _dtbl;
    } 
    function SetMasterPool(address _masterPool) external onlyOwner {
        masterPool = _masterPool;
    }
    function SetSubFee(uint _subFee) external onlyOwner {
        subcriptionFee = _subFee;
    }
    function SetRegisterFee(uint _registerFee) external onlyOwner {
        registerFee = _registerFee;
    }
    
    function SetProduct(address _product) external onlyOwner {
        mIsProduct[_product] = true;
    }

    function setMTNWallet(address _newMTN) external onlyOwner {
        MTN = _newMTN;
    }

    function setNewPartnerWallet(address _newParnerWallet) external onlyOwner {
        DTBH = _newParnerWallet;
    }

    function setMaxOutWallet(address _newMaxOut) external onlyOwner {
        MAX_OUT = _newMaxOut;
    }

    function setF0DIFF(uint256 _newRate) external onlyOwner {
        F0DIFF_RATE = _newRate;
    }
    function setDAODIFF_RATE(uint256 _newRate) external onlyOwner {
        DAODIFF_RATE = _newRate;
    }

    // function SetProduct(address _product) external onlyOwner {
    //     product = _product;
    // }
    
    event eAddHeadRef(address user, bytes32 codeRef);
    function _addHeadRef(address sender, bytes32 codeRef)  internal   {
        // require(mSub[sender] == false, "MetaNode: Only for non-subscribers");
        require(mRefCode[codeRef] != address(0), 'MetaNode: Invalid Refferal Code');
        line[sender] = mRefCode[codeRef];
        emit eAddHeadRef(sender, codeRef);
    }
    function Register(bytes32 phone, bytes32 codeRef, uint256 month, bytes32 codeHash, address to) external returns(bool) {
        uint256 firstFee = registerFee + subcriptionFee;
        uint256 transferredAmount = month * subcriptionFee;
        uint256 totalPayment = firstFee + transferredAmount; 
        require(mSub[to] == false, "Registered");
        if (totalUser == 0 ){
            require(codeRef == INIT_CODE_REF, "Registered");
            require(IERC20(usdt).balanceOf(msg.sender) >= totalPayment, "Invalid Balance");
            IERC20(usdt).transferFrom(msg.sender,masterPool,totalPayment);
            root = to;
            totalUser++;
            mSub[root] = true;
            isActive[root] = true;
            mSubInfo[root] = SubcribeInfo({
                codeRef: keccak256(abi.encodePacked(root,block.timestamp, block.prevrandao,totalUser)),
                phone: bytes32(0)
            });
            mRefCode[mSubInfo[root].codeRef] = root;
            ranks[root] = 0;

            binaryTree.init(root,1);
        } else {
            _addHeadRef(to,codeRef);
           
            require(IERC20(usdt).balanceOf(msg.sender) >= totalPayment, "Invalid Balance");
            IERC20(usdt).transferFrom(msg.sender,masterPool,totalPayment);
            _addBinaryTree(to);
            _createSubscription(to,firstFee,phone);

            if (transferredAmount > 0){
                _transferMatrixBonus(to,transferredAmount);
                _bonusForDiamond(transferredAmount);
                _bonusForCrownDiamond(transferredAmount);
            }

        }

        if (month>10 && DisableCode30 == false) {
            DT_DEBT += 30 * usdtDecimal;
            kCode.KGenerateCode(to, codeHash);
        }

        firstTimePay[to] = block.timestamp;
        nextTimePay[to] = DateTimeLibrary.addMonths(firstTimePay[to], month + 1); 
        mUUID[to] = keccak256(abi.encodePacked(to, nextTimePay[to], block.prevrandao,totalUser));
        addressList.push(to);
        emit Subcribed(to, totalPayment, line[to], lineMatrix[to], block.timestamp,phone);
        emit TeamData(to,ranks[to],1);
        emit Buysub(msg.sender,to,totalPayment,"USDT");
        return true;
    }

    function MigrateRegister(bytes32 phone,address _parent, uint256 month, bytes32 codeHash,address _buyer, uint256 _nextTimePay) external onlyAdmin() returns(bool) {
        uint256 firstFee = registerFee + subcriptionFee;
        uint256 transferredAmount = month * subcriptionFee;
        uint256 totalPayment = firstFee + transferredAmount; 
        require(mSub[_buyer] == false, "Registered");
        require(IERC20(usdt).balanceOf(msg.sender) >= totalPayment, "Invalid Balance");
        IERC20(usdt).transferFrom(msg.sender,masterPool,totalPayment);
        if (totalUser == 0 ){
            root = _buyer;
            totalUser++;
            mSub[root] = true;
            isActive[root] = true;
            mSubInfo[root] = SubcribeInfo({
                codeRef: keccak256(abi.encodePacked(root,block.timestamp, block.prevrandao,totalUser)),
                phone: bytes32(0)
            });
            mRefCode[mSubInfo[root].codeRef] = root;
            ranks[root] = 0;

            binaryTree.init(root,1);
        } else {
            line[_buyer] = _parent;
            _addBinaryTree(_buyer);
            _createSubscription(_buyer,firstFee,phone);

            if (transferredAmount > 0){
                _transferMatrixBonus(_buyer,transferredAmount);
                _bonusForDiamond(transferredAmount);
                _bonusForCrownDiamond(transferredAmount);
            }

        }
        if (month>10) {
            DT_DEBT += 30 * usdtDecimal;
        }
        firstTimePay[_buyer] = _nextTimePay - timeInActive * (month + 1);
        nextTimePay[_buyer] = _nextTimePay;
        addressList.push(_buyer);
        mUUID[_buyer] = keccak256(abi.encodePacked(_buyer, nextTimePay[_buyer], block.prevrandao,totalUser));
        emit Subcribed(_buyer, totalPayment, line[_buyer], lineMatrix[_buyer], block.timestamp,phone);
        emit TeamData(_buyer,ranks[_buyer],1);
        emit Buysub(msg.sender,_buyer,totalPayment,"USDT");
        return true;
    }

    function _createSubscription(address subscriber,uint transferredAmount,bytes32 phone) internal {
        totalUser++;
        mSub[subscriber] = true;
        mphone[subscriber] = phone;
        mSubInfo[subscriber] = SubcribeInfo({
            codeRef: keccak256(abi.encodePacked(subscriber,block.timestamp, block.prevrandao,totalUser)),
            phone: phone
        });
        mRefCode[mSubInfo[subscriber].codeRef] = subscriber;

        address parent = line[subscriber];
        if (parent != address(0)) {
            childrens[parent].push(subscriber);
            line[subscriber] = parent;
            _transferDirectCommission(subscriber,transferredAmount);
        }
        ranks[subscriber] = 0;
        isActive[subscriber] = true;
        _addMemberLevels(subscriber);
        _bonusForDiamond(transferredAmount);
        _bonusForCrownDiamond(transferredAmount);
    }
    function _addMemberLevels(address subscriber)internal{
        address parentAddress = line[subscriber];
        // address parentAddressMatrix = lineMatrix[subscriber];
        while(parentAddress != address(0))
        {
            mtotalMember[parentAddress] += 1;
            // mtotalMemberMatrix[parentAddressMatrix] += 1;
            _upRank(parentAddress);
            parentAddress = line[parentAddress];
            // parentAddress = lineMatrix[parentAddressMatrix];
        }
    }
    function _deactivateMember(address _address)internal{
        isActive[_address] = false;
        address _parent = line[_address];
        address _parentMatrix = lineMatrix[_address];
        while(_parent != address(0))
        {
            mtotalMember[_parent] -= 1;
            // mtotalMemberMatrix[_parentMatrix] -= 1;
            if (ranks[_address] >= uint8(Rank.Bronze)){
                if(mNumberChild[_parent].Bronze > 0){
                    mNumberChild[_parent].Bronze--;
                }
            }

            if (ranks[_address] >= uint8(Rank.Silver)){
                if(mNumberChild[_parent].Silver > 0){
                    mNumberChild[_parent].Silver--;
                }
            }

            if (ranks[_address] >= uint8(Rank.Gold)){
                if(mNumberChild[_parent].Gold > 0){
                    mNumberChild[_parent].Gold--;
                }
            }

            if (ranks[_address] >= uint8(Rank.Platinum)){
                if(mNumberChild[_parent].Platinum > 0){
                    mNumberChild[_parent].Platinum--;
                }
            }
            _downRank(_parent);
            _parent = line[_parent];
            _parentMatrix = lineMatrix[_parentMatrix];
        }
        emit TeamData(_address,ranks[_address],0);
    }

    function _addBinaryTree(address to) internal {
        address pAddress = binaryTree.addNode(line[to], to);
        childrensMatrix[pAddress].push(to);
        lineMatrix[to] = pAddress;
    }

    function _transferDirectCommission(address buyer,uint256 _firstFee) internal {
        address parentMatrix = lineMatrix[buyer];
        address parentDirect = line[buyer];
        uint commAmount;
        uint commAmountFA;
        //pay to company
        uint256 amount = (adDirectRate*_firstFee) / 10**3;
        uint256 maxAmountBonus = (maxDirectRateBonus*_firstFee) / 10**3;

        uint totalAmountTransfer = 0;
        IMasterPool(masterPool).transferCommission(DAO_DT, amount,"PO5-Direct");
        
        //pay 50% for F1
        commAmountFA = (comDirectRate[0]*_firstFee) / 10**3;
        if(isActive[parentDirect] == false){
            IMasterPool(masterPool).transferCommission(MAX_OUT, commAmountFA,"PO5-Direct");
        } else {
            IMasterPool(masterPool).transferCommission(parentDirect, commAmountFA,"PO5-Direct");
            totalSubcriptionBonus[parentDirect] += commAmountFA;
            emit PayBonus(parentDirect,ranks[parentDirect],0,comDirectRate[0] ,commAmountFA,block.timestamp,"Direct",bytes32(0));            
        }
        totalAmountTransfer += commAmountFA;
        totalSubscriptionPayment += commAmountFA;

        //pay to users in system
        for (uint index = 1; index < comDirectRate.length; index++) 
        {   
            if (parentMatrix == address(0)) {
                IMasterPool(masterPool).transferCommission(MAX_OUT, maxAmountBonus - totalAmountTransfer,"PO5-Direct");
                break;
            }

            // 9 level from 1 to 10
            commAmount = (comDirectRate[index]*_firstFee) / 10**3;
            if (_isValidLevel(parentMatrix,index+1) && isActive[parentMatrix] == true) {   
                // Pay commission by subscription
                IMasterPool(masterPool).transferCommission(parentMatrix, commAmount,"PO5-Direct");
                emit PayBonus(parentMatrix,ranks[parentMatrix],index,comDirectRate[index],commAmount,block.timestamp,"Direct",bytes32(0));            
                totalSubcriptionBonus[parentMatrix] += commAmount;
            } else {
                IMasterPool(masterPool).transferCommission(MAX_OUT, commAmount,"PO5-Direct");
            }
            totalAmountTransfer += commAmount;
            totalSubscriptionPayment += commAmount;

            // next iteration
            parentMatrix = lineMatrix[parentMatrix];
        }
    }
    
    function PaySub (uint256 monthsNum,address to) external returns (bool) {
        require(isActive[to]==true,"this address is not active anymore");
        require(monthsNum>=1 && monthsNum<=36,"invalid number of month");
        require(mSub[to] == true, "Need to register first");
        require(IERC20(usdt).balanceOf(msg.sender) >= subcriptionFee, "Invalid Balance");
        uint256 transferredAmount = subcriptionFee*monthsNum;
        IERC20(usdt).transferFrom(msg.sender,masterPool,transferredAmount);
        _transferMatrixBonus(to,transferredAmount);
        // firstTimePay[to] = block.timestamp;
        nextTimePay[to] = DateTimeLibrary.addMonths(nextTimePay[to], monthsNum); 
        _bonusForDiamond(transferredAmount);
        _bonusForCrownDiamond(transferredAmount);
        emit Buysub(msg.sender,to,transferredAmount,"USDT");
        return true;
    }
    function _transferMatchingBonus(address buyer,uint256 amount) internal returns (uint) {
        address parent = line[buyer];
        address child = buyer; 
        uint commAmount;
        uint totalAmountTransfer = 0;
        bool success; 
        Generation memory gen = Generation(0,0,0,0);
        uint count=0;
        while(parent != address(0))
        {   
            if (gen.Diamond == 5) {
                return totalAmountTransfer;
                // break;
            }          
            uint256 rank= ranks[parent];
            uint256 matchingRate =0;
            if (rank < 2 && count !=0 ){             
                child = parent;
                parent = line[parent];
                count++;
                continue;
            }
            if (rank> 1){              //Silver
                gen.Silver +=1;
            }
            if(rank >2){          //Gold
                gen.Gold +=1; 
            }
            if(rank>3){         //Platinum
                gen.Platinum +=1;
            }
            if(rank>4){  //Diamond
                gen.Diamond +=1;
            }
            mGenerations[parent] = gen;
            if(count==0){matchingRate += comMatchingRate[0];}
            if(gen.Silver<=2 && rank >= 2){matchingRate += comMatchingRate[1];}
            if(gen.Gold<=3 && rank >= 3){matchingRate += comMatchingRate[2];}        
            if(gen.Platinum<=4 && rank >= 4){matchingRate += comMatchingRate[3];}
            if(gen.Diamond<=5 &&  rank >= 5){matchingRate += comMatchingRate[4];}
            // Pay matching commission 
            
            commAmount = (matchingRate*amount) / 10**3;  
            if(matchingRate>0){
                if(isActive[parent] == false){
                    success = IMasterPool(masterPool).transferCommission(MAX_OUT, commAmount,"PO5-Matching");
                    require(success, "Failed transfer matching commission"); 

                }else{
                    totalMatchingBonus[parent] += commAmount;
                }
                totalAmountTransfer += commAmount;
                totalMatchingPayment += commAmount;
            }           

            // next iteration
            child = parent;
            parent = line[parent];
            count++;
        }
        return totalAmountTransfer;
    }
    function _transferMatrixBonus(address buyer,uint256 amount) internal {
        address parent = lineMatrix[buyer];
        address child = buyer; 
        uint commAmount;
        bool success; 
        uint totalAmountTransfer = 0;
        uint maxMatrixBonus = maxMatrixRateBonus * amount / 10**3;
        // Company
        success = IMasterPool(masterPool).transferCommission(MAX_OUT, matrixCompanyRateBonus * amount / 10**3,"PO5-Matrix");
        require(success, "Failed transfer matrix commission"); 

        for (uint index = 0; index < maxLineForMatrixBonus; index++) 
        {   
            if (parent == address(0)) {
                success = IMasterPool(masterPool).transferCommission(MAX_OUT, maxMatrixBonus - totalAmountTransfer,"PO5-Matrix");
                require(success, "Failed transfer matrix commission"); 
                break;
            }
            if (_isValidLevelForMatrix(parent,index+1)) {   
                // Pay matrix commission 
                commAmount = (comMatrixRate*amount) / 10**3;             

                if(isActive[parent] == false){
                    success = IMasterPool(masterPool).transferCommission(MAX_OUT, commAmount,"PO5-Matrix");
                    require(success, "Failed transfer matrix commission"); 
                }else{
                    totalAmountTransfer += _transferMatchingBonus(parent,commAmount);
                    IMasterPool(masterPool).transferCommission(parent, commAmount,"PO5-Matrix");
                    emit PayBonus(parent, ranks[parent], index + 1, comMatrixRate, commAmount, block.timestamp, "Matrix",bytes32(0));            
                }
                totalAmountTransfer += commAmount;
                totalMatrixBonus[parent] += commAmount;
                totalMatrixPayment += commAmount;
            }

            // next iteration
            child = parent;
            parent = lineMatrix[parent];
        }
    }

    //enum Rank {Unranked, Bronze, Silver,Gold,Platinum,Diamond,CrownDiamond}
        // Check condition of upLine with level
    function _isValidLevel(address receiver, uint atUpLine) internal view returns(bool) { //for Direct tree for sale bonus
 
    if (Rank(ranks[receiver]) == Rank.Unranked && atUpLine <= 1) {
            return true;
        } else if (Rank(ranks[receiver]) == Rank.Bronze && atUpLine <= 2) {
            return true;
        } else if (Rank(ranks[receiver]) == Rank.Silver && atUpLine <= 3) {
            return true;
        } else if (Rank(ranks[receiver]) == Rank.Gold && atUpLine <= 4) {
            return true;
        } else if (Rank(ranks[receiver]) == Rank.Platinum && atUpLine <= 5) {
            return true;
        } else if (Rank(ranks[receiver]) == Rank.Diamond || Rank(ranks[receiver]) == Rank.crownDiamond && atUpLine <= 5) {
            return true;   
        } else {
            return false;
    }
    }
    function _isValidLevelForMatrix(address receiver, uint atUpLine) internal view returns(bool) {
 
        if (Rank(ranks[receiver]) == Rank.Unranked && atUpLine <= 12) {
            return true;
        } else if ((Rank(ranks[receiver]) == Rank.Bronze || Rank(ranks[receiver]) == Rank.Silver) && atUpLine <= 13) {
            return true;
        } else if ((Rank(ranks[receiver]) == Rank.Gold || Rank(ranks[receiver]) == Rank.Platinum) && atUpLine <= 14) {
            return true;
        } else if (Rank(ranks[receiver]) == Rank.Diamond || Rank(ranks[receiver]) == Rank.crownDiamond && atUpLine <= 15) {
            return true;   
        } else {
            return false;
        }
    }
    function _isValidLevelForBinary(address receiver, uint atUpLine) internal view returns(bool) { //for binary trê for sale bonus
 
        // if (Rank(ranks[receiver]) == Rank.Unranked && atUpLine <= 1) {
        //     return true;
        if (Rank(ranks[receiver]) == Rank.Bronze && atUpLine <= 1) {
            return true;
        } else if (Rank(ranks[receiver]) == Rank.Silver && atUpLine <= 3) {
            return true;
        } else if (Rank(ranks[receiver]) == Rank.Gold && atUpLine <= 5) {
            return true;
        } else if (Rank(ranks[receiver]) == Rank.Platinum && atUpLine <= 7) {
            return true;
        } else if (Rank(ranks[receiver]) == Rank.Diamond || Rank(ranks[receiver]) == Rank.crownDiamond && atUpLine <= 9) {
            return true;   
        } else {
            return false;
        }
    }

    function _upRank(address _address) internal {
        (uint8[] memory totalBranchValid,uint256 totalMembersF1ForUpdateLevel) = _totalBranchValidChildWithRankRequired(_address);
        
        // If unrank check can up rank brozen
        if (ranks[_address] == uint8(Rank.Unranked)){
            if (_calculateTotalMemberForUpdateLevel(_address) >= totalMemberRequiredToRankUps[uint8(Rank.Bronze)] && totalMembersF1ForUpdateLevel >= totalMemberF1RequiredToRankUps[uint8(Rank.Bronze)]){
                ranks[_address] = uint8(Rank.Bronze);
                emit TeamData(_address,ranks[_address],2);
                _upChildRank(line[_address],Rank.Bronze);
            }
            return;
        }

        if (ranks[_address] == uint8(Rank.Bronze)){
            if (_calculateTotalMemberForUpdateLevel(_address) >= totalMemberRequiredToRankUps[uint8(Rank.Silver)] 
                && (totalMembersF1ForUpdateLevel >= totalMemberF1RequiredToRankUps[uint8(Rank.Silver)] 
                || totalBranchValid[uint8(uint8(Rank.Bronze))] >= RankUpdateBranchRequired)){
                ranks[_address] = uint8(Rank.Silver);
                emit TeamData(_address,ranks[_address],2);
                _upChildRank(line[_address],Rank.Silver);
            }
            return;
        }

        if (ranks[_address] == uint8(Rank.Silver)){
            if (_calculateTotalMemberForUpdateLevel(_address) >= totalMemberRequiredToRankUps[uint8(Rank.Gold)] 
                && (totalMembersF1ForUpdateLevel >= totalMemberF1RequiredToRankUps[uint8(Rank.Gold)]
                || totalBranchValid[uint8(Rank.Silver)] >= RankUpdateBranchRequired
                || _calculateTotalMaxMember1BranchForUpdateLevel(_address, uint8(Rank.Gold)) >= totalMemberRequiredToRankUps[uint8(Rank.Gold)])){
                ranks[_address] = uint8(Rank.Gold);
                emit TeamData(_address,ranks[_address],2);
                _upChildRank(line[_address],Rank.Gold);
            }
            return;
        }

        if (ranks[_address] == uint8(Rank.Gold)){   
            if (_calculateTotalMemberForUpdateLevel(_address) >= totalMemberRequiredToRankUps[uint8(Rank.Platinum)] 
                && (totalMembersF1ForUpdateLevel >= totalMemberF1RequiredToRankUps[uint8(Rank.Platinum)]
                || totalBranchValid[uint8(uint8(Rank.Gold))] >= RankUpdateBranchRequired
                || _calculateTotalMaxMember1BranchForUpdateLevel(_address, uint8(Rank.Platinum)) >= totalMemberRequiredToRankUps[uint8(Rank.Platinum)])){
                ranks[_address] = uint8(Rank.Platinum);
                emit TeamData(_address,ranks[_address],2);
                _upChildRank(line[_address],Rank.Platinum);
            }
            return;
        }

        if (ranks[_address] != uint8(Rank.crownDiamond)){
            if (_calculateTotalMaxMember1BranchForUpdateLevel(_address, uint8(Rank.crownDiamond)) >= totalMemberRequiredToRankUps[uint8(Rank.crownDiamond)]){
                addDiamond(_address);
                addCrownDiamond(_address);
                ranks[_address] = uint8(Rank.crownDiamond);
                emit TeamData(_address,ranks[_address],2);
                return;
            }
        }

        if (ranks[_address] == uint8(Rank.Platinum)){
            if (_calculateTotalMemberForUpdateLevel(_address) >= totalMemberRequiredToRankUps[uint8(Rank.Diamond)] 
                && (totalBranchValid[uint8(Rank.Platinum)] >= RankUpdateBranchRequired
                ||_calculateTotalMaxMember1BranchForUpdateLevel(_address, uint8(Rank.Diamond)) >= totalMemberRequiredToRankUps[uint8(Rank.Diamond)])){
                addDiamond(_address);
                ranks[_address] = uint8(Rank.Diamond);
                emit TeamData(_address,ranks[_address],2);
            }
        }
    }

    function _downRank(address _address) internal {
        if (ranks[_address] == uint8(Rank.Unranked)){
            return;
        }

        (uint8[] memory totalBranchValid,uint256 totalMembersF1ForUpdateLevel) = _totalBranchValidChildWithRankRequired(_address);

        if (ranks[_address] == uint8(Rank.crownDiamond)){
            if (_calculateTotalMaxMember1BranchForUpdateLevel(_address, uint8(Rank.crownDiamond)) < totalMemberRequiredToRankUps[uint8(Rank.crownDiamond)]){
                removeCrownDiamond(_address);
                ranks[_address] = uint8(Rank.Diamond);
                emit TeamData(_address,ranks[_address],2);
            }
        }

        if (ranks[_address] == uint8(Rank.Diamond)){
            if (_calculateTotalMemberForUpdateLevel(_address) < totalMemberRequiredToRankUps[uint8(Rank.Diamond)] 
                || (totalBranchValid[uint8(Rank.Platinum)] < RankUpdateBranchRequired
                && _calculateTotalMaxMember1BranchForUpdateLevel(_address, uint8(Rank.Diamond)) < totalMemberRequiredToRankUps[uint8(Rank.Diamond)])){
                removeDiamond(_address);
                ranks[_address] = uint8(Rank.Platinum);
                emit TeamData(_address,ranks[_address],2);
            }
        }

        if (ranks[_address] == uint8(Rank.Platinum)){
            if (_calculateTotalMemberForUpdateLevel(_address) < totalMemberRequiredToRankUps[uint8(Rank.Platinum)] 
                || (totalMembersF1ForUpdateLevel < totalMemberF1RequiredToRankUps[uint8(Rank.Platinum)]
                && totalBranchValid[uint8(uint8(Rank.Gold))] < RankUpdateBranchRequired
                && _calculateTotalMaxMember1BranchForUpdateLevel(_address, uint8(Rank.Platinum)) < totalMemberRequiredToRankUps[uint8(Rank.Platinum)])){
                ranks[_address] = uint8(Rank.Gold);
                emit TeamData(_address,ranks[_address],2);
            }
        }

        if (ranks[_address] == uint8(Rank.Gold)){
            if (_calculateTotalMaxMember1BranchForUpdateLevel(_address, uint8(Rank.Gold)) < totalMemberRequiredToRankUps[uint8(Rank.Gold)] 
                || (totalMembersF1ForUpdateLevel < totalMemberF1RequiredToRankUps[uint8(Rank.Gold)]
                && totalBranchValid[uint8(uint8(Rank.Silver))] < RankUpdateBranchRequired)){
                ranks[_address] = uint8(Rank.Silver);
                emit TeamData(_address,ranks[_address],2);
            }
        }

        if (ranks[_address] == uint8(Rank.Silver)){
            if (_calculateTotalMemberForUpdateLevel(_address) < totalMemberRequiredToRankUps[uint8(Rank.Silver)] 
                && (totalMembersF1ForUpdateLevel < totalMemberF1RequiredToRankUps[uint8(Rank.Silver)] 
                || totalBranchValid[uint8(uint8(Rank.Bronze))] < RankUpdateBranchRequired)){
                ranks[_address] = uint8(Rank.Bronze);
                emit TeamData(_address,ranks[_address],2);
            }
            return;
        }

        if (ranks[_address] == uint8(Rank.Bronze)){
            if (_calculateTotalMemberForUpdateLevel(_address) < totalMemberRequiredToRankUps[uint8(Rank.Bronze)] 
                || totalMembersF1ForUpdateLevel < totalMemberF1RequiredToRankUps[uint8(Rank.Bronze)]){
                ranks[_address] = uint8(Rank.Unranked);
                emit TeamData(_address,ranks[_address],2);
            }
        }
    }

    function _upChildRank(address _address, Rank rank) public{
        if(_address != address(0)){
            if (rank == Rank.Bronze){
                mNumberChild[_address].Bronze++;
            }

            if (rank == Rank.Silver){
                mNumberChild[_address].Silver++;
            }

            if(rank == Rank.Gold){
                mNumberChild[_address].Gold++;
            }

            if(rank == Rank.Platinum){
                mNumberChild[_address].Platinum++;
            }
            _upChildRank(line[_address], rank);
        }
    }

    function _downChildRank(address _address, Rank rank) public{
        if(_address != address(0)){
            if (rank == Rank.Bronze && mNumberChild[_address].Bronze > 0){
                mNumberChild[_address].Bronze--;
            }

            if (rank == Rank.Silver && mNumberChild[_address].Silver > 0){
                mNumberChild[_address].Silver--;
            }

            if(rank == Rank.Gold && mNumberChild[_address].Gold > 0){
                mNumberChild[_address].Gold--;
            }

            if(rank == Rank.Platinum && mNumberChild[_address].Platinum > 0){
                mNumberChild[_address].Platinum--;
            }

            _downChildRank(line[_address], rank);
        }
    }
    
    function _calculateTotalMemberForUpdateLevel(address _address) public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < childrens[_address].length; i++) {
            total += mtotalMember[childrens[_address][i]];
            if (isActive[childrens[_address][i]]){
                total++;
            }
        }

        return total;
    }

    function _totalBranchValidChildWithRankRequired(address _address) public view returns (uint8[] memory _totalRankBranch, uint32 _totalF1) {
        _totalRankBranch = new uint8[](5);
        for (uint256 i = 0; i < childrens[_address].length; i++) {
            if (isActive[childrens[_address][i]]){
                _totalF1++;
            }

            if(mNumberChild[childrens[_address][i]].Bronze > 0 || (isActive[childrens[_address][i]] && ranks[childrens[_address][i]] >= uint8(Rank.Bronze))){
                _totalRankBranch[uint8(Rank.Bronze)]++;
            }

            if(mNumberChild[childrens[_address][i]].Silver > 0 || (isActive[childrens[_address][i]] && ranks[childrens[_address][i]] >= uint8(Rank.Silver))){
                _totalRankBranch[uint8(Rank.Silver)]++;
            }

            if(mNumberChild[childrens[_address][i]].Gold > 0 || (isActive[childrens[_address][i]] && ranks[childrens[_address][i]] >= uint8(Rank.Gold))){
                _totalRankBranch[uint8(Rank.Gold)]++;
            }

            if(mNumberChild[childrens[_address][i]].Platinum > 0 || (isActive[childrens[_address][i]] && ranks[childrens[_address][i]] >= uint8(Rank.Platinum))){
                _totalRankBranch[uint8(Rank.Platinum)]++;
            }
        }
    }

    function TotalRankUpdateBranch(address _address) public view returns (uint8[] memory _totalRankBranch) {
        _totalRankBranch = new uint8[](5);
        for (uint256 i = 0; i < childrens[_address].length; i++) {
            uint8[] memory _bIsValid = ValidChildWithRank(childrens[_address][i]);
            for (uint8 _rank = uint8(Rank.Bronze); _rank <= uint8(Rank.Platinum); _rank++) 
            {
                _totalRankBranch[_rank] += _bIsValid[_rank];
            }
        }
    }

    function ValidChildWithRank(address _address) public view returns (uint8[] memory _isValid) {
        _isValid = new uint8[](5);
        
        for (uint8 _rank = uint8(Rank.Bronze); _rank <= uint8(Rank.Platinum); _rank++) 
        {
            if(ranks[_address] >= _rank) {
                _isValid[_rank] = 1;
            }
        }

        uint256 count = GetTotalChildren(_address);
        address[] memory queue = new address[](count);
        uint256 front = 0;
        uint256 back = 0;
        
        for (uint256 i = 0; i < childrens[_address].length; i++) {
            queue[back] = childrens[_address][i];
            for (uint8 _rank = uint8(Rank.Bronze); _rank <= uint8(Rank.Platinum); _rank++) 
            {
                if(ranks[childrens[_address][i]] >= _rank) {
                    _isValid[_rank] = 1;
                }
            }
            back++;
        }

        while (front < back) {
            address current = queue[front];
            front++;      
            if(childrens[current].length>0){
                for (uint256 i = 0; i < childrens[current].length; i++) {
                    queue[back] = childrens[current][i];
                    for (uint8 _rank = uint8(Rank.Bronze); _rank <= uint8(Rank.Platinum); _rank++) 
                    {
                        if(ranks[childrens[current][i]] >= _rank) {
                            _isValid[_rank] = 1;
                        }
                    }
                    back++;
                }
            }         
        }
    }

    function _calculateTotalMaxMember1BranchForUpdateLevel(address _address, uint8 level) public view returns (uint256) {        
        uint256 total = 0;

        for (uint256 i = 0; i < childrens[_address].length; i++) {
            if (isActive[childrens[_address][i]]){
                total++;
            }
            if (mtotalMember[childrens[_address][i]] > totalMaxMembers1BranchToRankUp[level]) {
                total += totalMaxMembers1BranchToRankUp[level];
            } else {
                total += mtotalMember[childrens[_address][i]];
            }
        }
        
        return total;
    }

    function GetCodeRef() external onlySub view returns(bytes32) {
        return mSubInfo[msg.sender].codeRef;
    }
    function GetSubInfo() external onlySub view returns(SubcribeInfo memory) {
        return mSubInfo[msg.sender];
    }
    
    function CheckActiveMember(address user) public view returns(bool) {
        return isActive[user];
    }

    function CheckExistMember(address _address) public view returns(bool) {
        return firstTimePay[_address] == 0;
    }

    function GetRefCodeOwner(bytes32 refCode) public view returns(address) {
        return mRefCode[refCode];
    }

    function GetRefCoder(address _address) public onlyOwner() view returns(bytes32) {
        return mSubInfo[_address].codeRef;
    }

    function GetHeadRef(address caller) external view returns(address) {
        return line[caller];
    }

    function TransferCommssion(address buyer, uint256 price, uint256 reward, uint256 diff,address _NSX) external onlyProduct {
        totalSale[buyer] += price;
        uint256 mtnCom = price * MTN_RATE / 10**3;
        // 50% price to mtn
        IMasterPool(masterPool).transferCommission(MTN, mtnCom,"PO5-Sale");
        // 50% price to bonus, because bonus max is 130% diffPrice then if diffPrice >= 22.692..% price we will suffer a loss
        // The price difference is decided by the BD (func adminAddProduct)      
        uint256 totalAmountTransfer = _transferSaleCommission(buyer, reward * REWARD_RATE / 10**3);
        totalSaleRevenue += price;
        //17.5% diff to Dao 
        IMasterPool(masterPool).transferCommission(DAO_DT, diff * DAODIFF_RATE / 10**3,"PO5-Sale");
        // 2% diff to diamond
        _bonusForDiamond(diff);
        // 0.5% diff to crown diamond

        _bonusForCrownDiamond(diff);  

        // difference of 50% price and bonus-commission to NSX 
        uint256 total = mtnCom + totalAmountTransfer + diff * (diamondRate +  crownDiamondRate + DAODIFF_RATE ) / 10**3 ;
        if(price > total){
            IMasterPool(masterPool).transferCommission(_NSX, price - total,"PO5-Sale");
        }

    }
    function TransferRetailBonus(address coderefer,uint256 price, uint256 reward, uint256 diff,address _NSX) external onlyProduct{
        totalSale[coderefer] += price;
        uint256 mtnCom = price * MTN_RATE / 10**3;
        // 50% price to mtn
        IMasterPool(masterPool).transferCommission(MTN, mtnCom,"PO5-SaleRetail");
        console.log("mtnCom la",mtnCom);
        // 50% price to bonus, because bonus max is 130% diffPrice then if diffPrice >= 22.692..% price we will suffer a loss
        // The price difference is decided by the BD (func adminAddProduct)      
        uint256 totalAmountTransfer = _transferSaleCommission(coderefer, reward * REWARD_RATE / 10**3);

        //80% diff to F0
        uint256 bonus = diff * F0DIFF_RATE / 10**3;
        IMasterPool(masterPool).transferCommission(coderefer, diff * F0DIFF_RATE / 10**3,"PO5-SaleRetail");
        emit PayBonus(coderefer, ranks[coderefer], 0, F0DIFF_RATE, bonus, block.timestamp, "SaleRetail",bytes32(0));  
        totalSaleBonus[coderefer] += bonus;
        totalSalePayment += bonus;
        //17.5% diff to Dao 
        IMasterPool(masterPool).transferCommission(DAO_DT, diff * DAODIFF_RATE / 10**3,"PO5-SaleRetail");
        // 2% diff to diamond
        _bonusForDiamond(diff);
        // 0.5% diff to crown diamond
        _bonusForCrownDiamond(diff);
        // difference of 50% price and bonus-commission to NSX 
        if(price > (mtnCom+totalAmountTransfer)){
            require(
                IMasterPool(masterPool).transferCommission(_NSX, price - mtnCom-totalAmountTransfer,"PO5-SaleRetail"),
                "Failed transfer TransferRetailBonus"
            ); 
        }
    }

    function AddDiamondShare(address buyer, uint256 price) external onlyProduct {
        if (AddressToExpiredDiamondShareTime[buyer] == 0 && PriceToDiamondShare[price].times > 0){
            AddressToExpiredDiamondShareTime[buyer] = DateTimeLibrary.addMonths(block.timestamp, PriceToDiamondShare[price].times); 

            if (PriceToDiamondShare[price].rank == uint8(Rank.Diamond)){
                addDiamondShare(buyer);
            }

            if (PriceToDiamondShare[price].rank == uint8(Rank.crownDiamond)){
                addDiamondShare(buyer);
                addCrownDiamondShare(buyer);
            }
        }
    }
     
    function _transferSaleCommission(address buyer, uint256 reward) internal returns(uint256) {
        address parentMatrix = lineMatrix[buyer];
        address parentDirect = line[buyer];
        uint commAmount;
        uint256 rate;
        uint256 totalAmountTransfer;
        uint256 saleGoodAmount;

        // 10% bonus in binary tree (matrix)
        for (uint index = 0; index < saleRateMatrix.length; index++) 
        {   
            if (parentMatrix == address(0)) {
                break;
            }
            if (_isValidLevelForBinary(parentMatrix,index+1)) {   
                // Pay commission by subscription
                commAmount = saleRateMatrix[index]*reward/10**3;
                if(commAmount > 0){
                    if(isActive[parentMatrix] == true){
                        IMasterPool(masterPool).transferCommission(parentMatrix, commAmount,"PO5-Sale");
                        totalAmountTransfer += commAmount;
                        emit PayBonus(parentMatrix, ranks[parentMatrix], index + 1, saleRateMatrix[index], commAmount, block.timestamp, "Sale",bytes32(0));       
                    }
                    totalSaleBonus[parentMatrix] += commAmount;
                    console.log("parentMatrix la:",parentMatrix);
                    console.log("10 la:",commAmount);
                    totalSalePayment += commAmount;
                }
            }
    
            // next iteration
            parentMatrix = lineMatrix[parentMatrix];
        }
        // 20% bonus in direct tree + 50% diff price for F1 + 50% diff price for good sale
        for (uint index = 0; index < saleRateDirect.length; index++) 
        {   
            if (parentDirect == address(0)) {
                break;
            }

            if (_isValidLevel(parentDirect,index+1)) {   
                commAmount = saleRateDirect[index]*reward/10**3;
                if(commAmount > 0){
                    if(isActive[parentDirect] == true){
                        IMasterPool(masterPool).transferCommission(parentDirect, commAmount,"PO5-Sale");
                        totalAmountTransfer += commAmount;
                        console.log("20 la:",commAmount);
                        if (index == 0){
                            rate = 0;
                            for (uint256 j = 0; j < levelCareerBonus.length; j++) {
                                if (commAmount < levelCareerBonus[j]*usdtDecimal) {
                                    break;
                                } else {
                                    rate += additionalCom;
                                }
                            }
                            if (rate > 0) {
                                saleGoodAmount = rate * reward / 10**3;
                                totalRevenues[parentDirect] += saleGoodAmount;
                                totalAmountTransfer += saleGoodAmount;
                                console.log("good sale la:",saleGoodAmount);
                                console.log("rate la:",rate);
                                console.log("reward la:",reward);
                                emit PayBonus(parentDirect, ranks[parentDirect], index, rate, saleGoodAmount, block.timestamp, "PendingGoodSale",bytes32(0));       

                            }
                        }
                        emit PayBonus(parentDirect, ranks[parentDirect], index, saleRateDirect[index], commAmount, block.timestamp, "Sale",bytes32(0));       
                    }
                    totalSaleBonus[parentDirect] += commAmount;
                    totalSalePayment += commAmount;
                }
            }
    
            // next iteration
            parentDirect = line[parentDirect];
        }
        // Total 130% to bonus
        // Transfer remaining amount to MAX_OUT
        uint256 fullReward = reward * 10**3 / REWARD_RATE;
        console.log("fullReward la:",reward * 10**3 / REWARD_RATE);
        if (fullReward > totalAmountTransfer){
            require(
                IMasterPool(masterPool).transferCommission(MAX_OUT, fullReward - totalAmountTransfer,"PO5-Sale"), 
                "Failed transfer matrix commission"
            ); 
            return fullReward;
        }
        return totalAmountTransfer;
    }

    function PayGoodSaleBonusWeekly(uint256 _index, uint256 _end) external onlyAdmin returns (bool) {
        require(_end <= totalUser,"Invalid end");
        for (_index; _index <= _end; _index++) {
            if(totalRevenues[addressList[_index]] >0){
                // Pay commission good sale
                if(isActive[addressList[_index]] == true){
                    IMasterPool(masterPool).transferCommission(addressList[_index], totalRevenues[addressList[_index]],"PO5-GoodSale");
                    emit PayBonus(addressList[_index], ranks[addressList[_index]], 0, 0, totalRevenues[addressList[_index]], block.timestamp, "GoodSale",bytes32(0));            
                    totalGoodSaleBonus[addressList[_index]] += totalRevenues[addressList[_index]];
                } else {
                    IMasterPool(masterPool).transferCommission(MAX_OUT, totalRevenues[addressList[_index]],"PO5-GoodSale");
                }

                totalCareerPayment += totalRevenues[addressList[_index]];
                // Reset revenue for the current node
                totalRevenues[addressList[_index]] = 0;
            }

            if(totalMatchingBonus[addressList[_index]] >0){
                // Pay commission good sale
                if(isActive[addressList[_index]] == true){
                    IMasterPool(masterPool).transferCommission(addressList[_index], totalMatchingBonus[addressList[_index]],"PO5-Matching");
                    emit PayBonus(addressList[_index], ranks[addressList[_index]], 0, 0, totalMatchingBonus[addressList[_index]], block.timestamp, "Matching",bytes32(0));            
                } else {
                    IMasterPool(masterPool).transferCommission(MAX_OUT, totalMatchingBonus[addressList[_index]],"PO5-Matching");
                }
                
                // Reset revenue for the current node
                totalMatchingBonus[addressList[_index]] = 0;
            }
        }
        
        return true;
    }

    function _bonusForDiamond(uint revenue) internal{
        for(uint i = 0; i < UserDiamondShare.length; i++){
            if (AddressToExpiredDiamondShareTime[UserDiamondShare[i]] < block.timestamp){
                removeDiamondShare(UserDiamondShare[i]);
            }
        }
        uint256 len = diamondArr.length + UserDiamondShare.length;
        bool success;
        if(len > 0){
            for(uint i = 0; i < diamondArr.length; i++){
                uint transferredAmount = revenue * diamondRate / len / 10**3;
                if (isActive[diamondArr[i]] == false) {
                    success = IMasterPool(masterPool).transferCommission(MAX_OUT, transferredAmount,"PO5-Diamond");
                    require(success, "Failed transfer extra Diamond bonus"); 
                } else {
                    success = IMasterPool(masterPool).transferCommission(diamondArr[i], transferredAmount,"PO5-Diamond");
                    emit PayBonus(diamondArr[i],ranks[diamondArr[i]],0,diamondRate / len, transferredAmount, block.timestamp,"Diamond",bytes32(0));            
                    require(success, "Failed transfer extra Diamond bonus");
                }
                totalExtraDiamondBonus[diamondArr[i]] += transferredAmount;
                totalExtraDiamondPayment += transferredAmount;
            }

            for(uint i = 0; i < UserDiamondShare.length; i++){
                uint transferredAmount = revenue * diamondRate / len / 10**3;
                if (isActive[UserDiamondShare[i]] == false) {
                    success = IMasterPool(masterPool).transferCommission(MAX_OUT, transferredAmount,"PO5-Diamond");
                    require(success, "Failed transfer extra Diamond bonus"); 
                } else {
                    success = IMasterPool(masterPool).transferCommission(UserDiamondShare[i], transferredAmount,"PO5-Diamond");
                    emit PayBonus(UserDiamondShare[i],ranks[UserDiamondShare[i]],0,diamondRate / len, transferredAmount, block.timestamp,"DiamondShare",bytes32(0));            
                    require(success, "Failed transfer extra Diamond bonus");
                }
                totalExtraDiamondBonus[UserDiamondShare[i]] += transferredAmount;
                totalExtraDiamondPayment += transferredAmount;
            }
        } else {
            success = IMasterPool(masterPool).transferCommission(MAX_OUT, revenue * diamondRate / 10**3,"PO5-Diamond");
            require(success, "Failed transfer extra Diamond bonus to company");
        }
    }
    function _bonusForCrownDiamond(uint revenue) internal{
        for(uint i = 0; i < UserCrownDiamondShare.length; i++){
            if (AddressToExpiredDiamondShareTime[UserCrownDiamondShare[i]] < block.timestamp){
                removeCrownDiamondShare(UserCrownDiamondShare[i]);
            }
        }
        uint256 len = crownDiamondArr.length + UserCrownDiamondShare.length;
        bool success;
        if(len > 0){
            for(uint i = 0; i < crownDiamondArr.length; i++){
                uint transferredAmount = revenue * crownDiamondRate / len / 10**3;
                if (isActive[crownDiamondArr[i]] == false) {
                    success = IMasterPool(masterPool).transferCommission(MAX_OUT, transferredAmount,"PO5-CrownDiamond");
                    require(success, "Failed transfer extra Crown Diamond bonus"); 
                } else {
                    success = IMasterPool(masterPool).transferCommission(crownDiamondArr[i], transferredAmount,"PO5-CrownDiamond");
                    emit PayBonus(crownDiamondArr[i],ranks[crownDiamondArr[i]],0,crownDiamondRate / len, transferredAmount, block.timestamp,"CrownDiamond",bytes32(0));            
                    require(success, "Failed transfer extra Crown Diamond bonus");
                }
                totalExtraCrownDiamondBonus[crownDiamondArr[i]] += transferredAmount;
                totalExtraCrownDiamondPayment += transferredAmount;
            }

            for(uint i = 0; i < UserCrownDiamondShare.length; i++){
                uint transferredAmount = revenue * crownDiamondRate / len / 10**3;
                if (isActive[UserCrownDiamondShare[i]] == false) {
                    success = IMasterPool(masterPool).transferCommission(MAX_OUT, transferredAmount,"PO5-CrownDiamond");
                    require(success, "Failed transfer extra Crown Diamond bonus"); 
                } else {
                    success = IMasterPool(masterPool).transferCommission(UserCrownDiamondShare[i], transferredAmount,"PO5-CrownDiamond");
                    emit PayBonus(UserCrownDiamondShare[i],ranks[UserCrownDiamondShare[i]],0,crownDiamondRate / len, transferredAmount, block.timestamp,"CrownDiamondShare",bytes32(0));            
                    require(success, "Failed transfer extra Crown Diamond bonus");
                }
                totalExtraCrownDiamondBonus[UserCrownDiamondShare[i]] += transferredAmount;
                totalExtraCrownDiamondPayment += transferredAmount;
            }
        } else {
            success = IMasterPool(masterPool).transferCommission(MAX_OUT, revenue * crownDiamondRate / 10**3,"PO5-CrownDiamond");
            require(success, "Failed transfer extra Crown Diamond bonus to company"); 
        }
    }

    function GetInfoForBinaryTree(address user) external  view returns(
        uint8 rank,bytes32 phone, address[]memory children,
        uint256 _totalSubcriptionBonus,
        uint256 _totalMatrixBonus,
        uint256 _totalMatchingBonus,
        uint256 _totalSaleBonus,
        uint256 _totalGoodSaleBonus,
        uint256 _totalExtraDiamondBonus,
        uint256 _totalExtraCrownDiamondBonus
        ){
        rank = ranks[user];
        phone = mphone[user];
        children = childrens[user];
        _totalSubcriptionBonus = totalSubcriptionBonus[user];
        _totalMatrixBonus = totalMatrixBonus[user];
        _totalMatchingBonus =totalMatchingBonus[user];
        _totalSaleBonus = totalSaleBonus[user];
        _totalGoodSaleBonus = totalGoodSaleBonus[user];
        _totalExtraDiamondBonus= totalExtraDiamondBonus[user];
        _totalExtraCrownDiamondBonus = totalExtraCrownDiamondBonus[user];
        return(
            rank,phone,children,
            _totalSubcriptionBonus,
            _totalMatrixBonus,
            _totalMatchingBonus,
            _totalSaleBonus,
            _totalGoodSaleBonus,
            _totalExtraDiamondBonus,
            _totalExtraCrownDiamondBonus
            );
    }
    function GetUserInfo(address user) public  view returns(UserInfo memory userinfo){
        userinfo.add = user;
        userinfo.IsActive = isActive[user];
        userinfo.FirstTimePay = firstTimePay[user];
        userinfo.NextTimePay =nextTimePay[user];
        userinfo.Mphone = mphone[user];
        userinfo.Childrens = childrens[user];
        userinfo.ChildrensMatrix = childrensMatrix[user];
        userinfo.Line = line[user];
        userinfo.LineMatrix = lineMatrix[user];
        userinfo.MtotalMember = mtotalMember[user];
        userinfo.Rank =ranks[user];
        userinfo.totalSubcriptionBonus = totalSubcriptionBonus[user];
        userinfo.totalMatrixBonus = totalMatrixBonus[user];
        userinfo.totalMatchingBonus =totalMatchingBonus[user];
        userinfo.totalSaleBonus = totalSaleBonus[user];
        userinfo.totalGoodSaleBonus = totalGoodSaleBonus[user];
        userinfo.totalExtraDiamondBonus= totalExtraDiamondBonus[user];
        userinfo.totalExtraCrownDiamondBonus = totalExtraCrownDiamondBonus[user];
        userinfo.totalSale = totalSale[user];
        userinfo.UUID = mUUID[user];
        userinfo.Username = mAddressToUsername[user];
    }

    function GetTotalChildren(address user) public view returns(uint256){
        uint256 count =0;
        count += childrens[user].length;
        for (uint256 i=0;i<childrens[user].length;i++){
            count += GetTotalChildren(childrens[user][i]);
            
        }
        return count;
    }

    function GetTotalChildrenMatrix(address user) public view returns(uint256){
        uint256 count =0;
        count += childrensMatrix[user].length;
        for (uint256 i=0;i<childrensMatrix[user].length;i++){
            count += GetTotalChildrenMatrix(childrensMatrix[user][i]);
            
        }
        return count;
    }

    function UpdateRankDaily(uint256 _index, uint256 _end) external onlyAdmin returns(bool){
        require(_end <= totalUser,"Invalid end");
        for (_index; _index <= _end; _index++) {
            if(nextTimePay[addressList[_index]] < block.timestamp && isActive[addressList[_index]] == true){
                _deactivateMember(addressList[_index]);
            }
        }
        
        return true;
    }

    function addDiamond(address _address) internal {
        for (uint256 i = 0; i < diamondArr.length; i++) {
            if (diamondArr[i] == _address) {
                return;
            }
        }
        diamondArr.push(_address);
    }

    function addCrownDiamond(address _address) internal {
        for (uint256 i = 0; i < crownDiamondArr.length; i++) {
            if (crownDiamondArr[i] == _address) {
                return;
            }
        }
        crownDiamondArr.push(_address);
    }

    function removeDiamond(address value) internal {
        for (uint256 i = 0; i < diamondArr.length; i++) {
            if (diamondArr[i] == value) {
                if (i < diamondArr.length - 1) {
                    diamondArr[i] = diamondArr[diamondArr.length - 1]; // Swap with the last element
                }
                diamondArr.pop(); // Remove the last element
                return; // Exit the function after removing the element
            }
        }
    }

    function removeCrownDiamond(address value) internal {
        for (uint256 i = 0; i < crownDiamondArr.length; i++) {
            if (crownDiamondArr[i] == value) {
                if (i < crownDiamondArr.length - 1) {
                    crownDiamondArr[i] = crownDiamondArr[crownDiamondArr.length - 1]; // Swap with the last element
                }
                crownDiamondArr.pop(); // Remove the last element
                return; // Exit the function after removing the element
            }
        }
        // If the value is not found in the array, you can handle it accordingly (e.g., revert or emit an event)
    }

    function addDiamondShare(address _address) internal {
        for (uint256 i = 0; i < UserDiamondShare.length; i++) {
            if (UserDiamondShare[i] == _address) {
                return;
            }
        }
        UserDiamondShare.push(_address);
    }

    function removeDiamondShare(address _address) internal {
        for (uint256 i = 0; i < UserDiamondShare.length; i++) {
            if (UserDiamondShare[i] == _address) {
                if (i < UserDiamondShare.length - 1) {
                    UserDiamondShare[i] = UserDiamondShare[UserDiamondShare.length - 1]; 
                }
                UserDiamondShare.pop(); 
                return;
            }
        }
    }

    function addCrownDiamondShare(address _address) internal {
        for (uint256 i = 0; i < UserCrownDiamondShare.length; i++) {
            if (UserCrownDiamondShare[i] == _address) {
                return;
            }
        }
        UserCrownDiamondShare.push(_address);
    }

    function removeCrownDiamondShare(address _address) internal {
        for (uint256 i = 0; i < UserCrownDiamondShare.length; i++) {
            if (UserCrownDiamondShare[i] == _address) {
                if (i < UserCrownDiamondShare.length - 1) {
                    UserCrownDiamondShare[i] = UserCrownDiamondShare[UserCrownDiamondShare.length - 1]; 
                }
                UserCrownDiamondShare.pop(); 
                return;
            }
        }
    }

    function viewtree(address add) public view returns (address[] memory) {
        uint256 count = GetTotalChildren(add);
        address[] memory queue = new address[](count);
        uint256 front = 0;
        uint256 back = 0;
        
        // Enqueue root's children
        for (uint256 i = 0; i < childrens[add].length; i++) {
            queue[back] = childrens[add][i];
            back++;
        }
        while (front < back) {
            address current = queue[front];
            front++;      
            // Enqueue current node's children
            if(childrens[current].length>0){
                for (uint256 i = 0; i < childrens[current].length; i++) {
                    queue[back] = childrens[current][i];
                    back++;
                }
            }         
        }
        return queue;
    }

    function viewtreeMatrix(address add) public view returns (address[] memory) {
        uint256 count = GetTotalChildrenMatrix(add);
        address[] memory queue = new address[](count);
        uint256 front = 0;
        uint256 back = 0;
        
        // Enqueue root's children
        for (uint256 i = 0; i < childrensMatrix[add].length; i++) {
            queue[back] = childrensMatrix[add][i];
            back++;
        }
        while (front < back) {
            address current = queue[front];
            front++;      
            // Enqueue current node's children
            if(childrensMatrix[current].length>0){
                for (uint256 i = 0; i < childrensMatrix[current].length; i++) {
                    queue[back] = childrensMatrix[current][i];
                    back++;
                }
            }         
        }
        return queue;
    }

      function viewTreeInfo(address _address) public view returns(UserInfo [] memory ){
        UserInfo [] memory userInfoArr = new UserInfo[](childrens[_address].length);
        for(uint256 i=0;i<childrens[_address].length;i++){
            UserInfo memory user = GetUserInfo(childrens[_address][i]);
            userInfoArr[i] = user;
        }
        return userInfoArr;
    }

    function viewTreeMatrixInfo(address add) public view returns(UserInfo [] memory ){
        UserInfo [] memory userInfoArr = new UserInfo [](6);
        uint256 index;
        for(uint256 i = 0; i < childrensMatrix[add].length; i++){
            userInfoArr[index] = GetUserInfo(childrensMatrix[add][i]);
            index++;
        }

        for(uint256 i = 0; i < childrensMatrix[add].length; i++){
            address f1Address = childrensMatrix[add][i];
            for(uint256 j = 0; j < childrensMatrix[f1Address].length; j++){
                userInfoArr[index] = GetUserInfo(childrensMatrix[f1Address][j]);
                index++;
            }    
        }
        return userInfoArr;
    }
   
    function CountTotalChildren(
        address user,
        uint generation
    ) public view returns (uint256) {
        uint256 count = 0;
        if (generation == 0) {
            return count;
        }
        count += childrens[user].length;
        for (uint256 i = 0; i < childrens[user].length; i++) {
            count += CountTotalChildren(childrens[user][i], generation - 1);
        }
        return count;
    }

    function TransferCommissionByProduct(address to, uint256 amount) external onlyProduct returns(bool) {
        return IMasterPool(masterPool).transferCommission(to, amount,"");
    }

    function PartnerPaymentDebt(uint256 amount) internal returns(bool) {
        if (amount >= DT_DEBT) {
            DT_DEBT = 0;
            DT_BALANCE += amount - DT_DEBT;
        } else {
            DT_DEBT -= amount;
        }
        return true;
    }

    function WithdrawForDT(uint256 amount, address receiveWallet) onlyOwner() external {
        require(amount <= DT_BALANCE, "Kventure: Exceed Balance");
        require(!isContract(receiveWallet), "Kventure: Receive Wallet Is Smart Contract");
        DT_BALANCE -= amount;
        IMasterPool(masterPool).transferCommission(receiveWallet, amount,"");
    }

    function isContract(address _addr) public view returns (bool) {
        return _addr.code.length > 0;
    }

    function UpdatePhone(bytes32 newPhone) external returns(bool) {
        require(newPhone != bytes32(0), "Kventure: Invalid Phone Number");
        require(mSubInfo[msg.sender].codeRef != bytes32(0), "Kventure: Not Sub");
        mSubInfo[msg.sender].phone = newPhone;
        mphone[msg.sender] = newPhone;
        emit UserData(msg.sender,newPhone,"");
        return true;
    }

    function UpdateUsername(string memory newUsername) external returns(bool) {
        require(bytes(newUsername).length != 0, "Kventure: Invalid User Name");
        require(mSubInfo[msg.sender].codeRef != bytes32(0), "Kventure: Not Sub");
        mAddressToUsername[msg.sender] = newUsername;
        emit UserData(msg.sender,bytes32(0),newUsername);
        return true;
    }

    function SetRefInfo(bytes32 _refCode, address _address) external onlyAdmin returns(bool){
        mRefCode[mSubInfo[_address].codeRef] = address(0);
        mSubInfo[_address].codeRef = _refCode;
        mRefCode[_refCode] = _address;
        return true;
    }

    function SetUserInfo(address _address,uint8 _rank, uint256 _subBonus, uint256 _matrixBonus, uint256 _matchingBonus, uint256 _saleBonus, uint256 _totalRevenues) external  onlyAdmin returns(bool){
        ranks[_address] = _rank;
        totalSubcriptionBonus[_address] = _subBonus;
        totalMatrixBonus[_address] = _matrixBonus;
        totalMatchingBonus[_address] = _matrixBonus;
        totalSaleBonus[_address] = _matchingBonus;
        totalSale[_address] = _saleBonus;
        totalRevenues[_address] = _totalRevenues;
        return true;
    }

    function SetDiamondShare(uint256 _price, uint256 _times,uint8 _rank) public onlyAdmin() returns(bool){
        require(_rank == uint8(Rank.Diamond) || _rank == uint8(Rank.crownDiamond), "Rank is not valid");
        PriceToDiamondShare[_price] = DiamondShare({
            times:_times,
            rank:_rank
        });
        return true;
    }

    function DeleteDiamondShare(uint256 _price) public onlyAdmin() returns(bool){
        delete PriceToDiamondShare[_price];
        return true;
    }

    function ViewRequiredRank(address _address,uint8 _rank) public view returns(RequiredUpRank memory ouput) {
        (uint8[] memory totalBranchValid,uint256 totalMembersF1ForUpdateLevel) = _totalBranchValidChildWithRankRequired(_address);
       
        ouput.NowChild = _calculateTotalMemberForUpdateLevel(_address);
        ouput.NowF1 = totalMembersF1ForUpdateLevel;
        ouput.ChildRequired = totalMemberRequiredToRankUps[_rank];
        
        if (_rank > uint8(Rank.Unranked) && _rank < uint8(Rank.Diamond)) {
            ouput.F1Required = totalMemberF1RequiredToRankUps[_rank];
        }

        if (_rank > uint8(Rank.Bronze) && _rank < uint8(Rank.crownDiamond)) {
            ouput.NowBranchValid = totalBranchValid[_rank - 1];
            ouput.BranchValidRequired = RankUpdateBranchRequired;
        }

        if (_rank > uint8(Rank.Silver) && _rank <= uint8(Rank.crownDiamond)) {
            ouput.NowChildWithCondition= _calculateTotalMaxMember1BranchForUpdateLevel(_address, _rank);
            ouput.ChildWithConditionRequired = totalMemberRequiredToRankUps[_rank];
        }
    }

    function SetDisableCode30(bool _status) public returns (bool){
        DisableCode30 = _status;
        return _status;
    }

    function UpdateRank(uint256 _index, uint256 _end) public onlyAdmin() returns (bool){
        for (_index; _index <= _end; _index++) {
            _upRank(addressList[_index]);
        }
        
        return true;
    }

     function RegisterLock(bytes32 phone, bytes32 codeRef, uint256 month, address to,bytes32 idPayment) external returns(bool) {
        uint256 firstFee = registerFee + subcriptionFee;
        uint256 transferredAmount = month * subcriptionFee;
        uint256 totalPayment = firstFee + transferredAmount; 
        require(mSub[to] == false, "Registered");
        uint256 locktime =  block.timestamp + 60 days;
        if (totalUser == 0 ){
            require(codeRef == INIT_CODE_REF, "Registered");
            require(IERC20(usdt).balanceOf(msg.sender) >= totalPayment, "Invalid Balance");
            IERC20(usdt).transferFrom(msg.sender,masterPool,totalPayment);
            root = to;
            totalUser++;
            mSub[root] = true;
            isActive[root] = true;
            mSubInfo[root] = SubcribeInfo({
                codeRef: keccak256(abi.encodePacked(root,block.timestamp, block.prevrandao,totalUser)),
                phone: bytes32(0)
            });
            mRefCode[mSubInfo[root].codeRef] = root;
            ranks[root] = 0;

            binaryTree.init(root,1);
        } else {
            _addHeadRef(to,codeRef);
           
            require(IERC20(usdt).balanceOf(msg.sender) >= totalPayment, "Invalid Balance");
            IERC20(usdt).transferFrom(msg.sender,masterPool,totalPayment);
            _addBinaryTree(to);
            _createSubscriptionSave(to,firstFee,phone,idPayment,locktime);

            if (transferredAmount > 0){
                _transferMatrixBonusSave(to,transferredAmount,idPayment,locktime);
                _bonusForDiamondSave(transferredAmount,idPayment,locktime);
                _bonusForCrownDiamondSave(transferredAmount,idPayment,locktime);
            }

        }
        firstTimePay[to] = block.timestamp;
        nextTimePay[to] = DateTimeLibrary.addMonths(firstTimePay[to], month + 1); 
        mUUID[to] = keccak256(abi.encodePacked(to, nextTimePay[to], block.prevrandao,totalUser));
        addressList.push(to);
        IMasterPool(masterPool).setLock(to,locktime,idPayment);
        emit Subcribed(to, totalPayment, line[to], lineMatrix[to], block.timestamp,phone);
        emit TeamData(to,ranks[to],1);
        emit Buysub(msg.sender,to,totalPayment,"VIsA");
        return true;
    }

    function _transferMatrixBonusSave(address buyer,uint256 amount, bytes32 idPayment,uint256 locktime) internal {
        address parent = lineMatrix[buyer];
        address child = buyer; 
        uint commAmount;
        uint totalAmountTransfer = 0;
        uint maxMatrixBonus = maxMatrixRateBonus * amount / 10**3;
        // Company
        IMasterPool(masterPool).transferCommissionUseNft(MAX_OUT, matrixCompanyRateBonus * amount / 10**3,locktime,"PO5-Matrix",idPayment);

        for (uint index = 0; index < maxLineForMatrixBonus; index++) 
        {   
            if (parent == address(0)) {
                IMasterPool(masterPool).transferCommissionUseNft(MAX_OUT, maxMatrixBonus - totalAmountTransfer,locktime,"PO5-Matrix",idPayment);
                break;
            }
            if (_isValidLevelForMatrix(parent,index+1)) {   
                // Pay matrix commission 
                commAmount = (comMatrixRate*amount) / 10**3;             

                if(isActive[parent] == false){
                    IMasterPool(masterPool).transferCommissionUseNft(MAX_OUT, commAmount,locktime,"PO5-Matrix",idPayment);
                }else{
                    totalAmountTransfer += _transferMatchingBonusSave(parent,commAmount,idPayment,locktime);
                    IMasterPool(masterPool).transferCommissionUseNft(parent, commAmount,locktime,"PO5-Matrix",idPayment);
                    emit PayBonus(parent, ranks[parent], index + 1, comMatrixRate, commAmount, block.timestamp, "Matrix",idPayment);            
                }
                totalAmountTransfer += commAmount;
                totalMatrixBonus[parent] += commAmount;
                totalMatrixPayment += commAmount;
            }

            // next iteration
            child = parent;
            parent = lineMatrix[parent];
        }
    }
    function _transferMatchingBonusSave(address buyer,uint256 amount,bytes32 idPayment,uint256 locktime) internal returns (uint) {
        address parent = line[buyer];
        address child = buyer; 
        uint commAmount;
        uint totalAmountTransfer = 0;
        Generation memory gen = Generation(0,0,0,0);
        uint count=0;
        while(parent != address(0))
        {   
            if (gen.Diamond == 5) {
                return totalAmountTransfer;
                // break;
            }          
            uint256 rank= ranks[parent];
            uint256 matchingRate =0;
            if (rank < 2 && count !=0 ){             
                child = parent;
                parent = line[parent];
                count++;
                continue;
            }
            if (rank> 1){              //Silver
                gen.Silver +=1;
            }
            if(rank >2){          //Gold
                gen.Gold +=1; 
            }
            if(rank>3){         //Platinum
                gen.Platinum +=1;
            }
            if(rank>4){  //Diamond
                gen.Diamond +=1;
            }
            mGenerations[parent] = gen;
            if(count==0){matchingRate += comMatchingRate[0];}
            if(gen.Silver<=2 && rank >= 2){matchingRate += comMatchingRate[1];}
            if(gen.Gold<=3 && rank >= 3){matchingRate += comMatchingRate[2];}        
            if(gen.Platinum<=4 && rank >= 4){matchingRate += comMatchingRate[3];}
            if(gen.Diamond<=5 &&  rank >= 5){matchingRate += comMatchingRate[4];}
            // Pay matching commission 
            
            commAmount = (matchingRate*amount) / 10**3;  
            if(matchingRate>0){
                if(isActive[parent] == false){
                   IMasterPool(masterPool).transferCommissionUseNft(MAX_OUT, commAmount,locktime,"PO5-Matching",idPayment);

                }else{
                    // totalMatchingBonusSave[parent] += commAmount;
                    IMasterPool(masterPool).transferCommissionUseNft(parent, commAmount,locktime,"PO5-Matching",idPayment);

                }
                totalAmountTransfer += commAmount;
                totalMatchingPayment += commAmount;
            }           

            // next iteration
            child = parent;
            parent = line[parent];
            count++;
        }
        return totalAmountTransfer;
    }
    function _bonusForDiamondSave(uint revenue, bytes32 idPayment,uint256 locktime) internal{
        for(uint i = 0; i < UserDiamondShare.length; i++){
            if (AddressToExpiredDiamondShareTime[UserDiamondShare[i]] < block.timestamp){
                removeDiamondShare(UserDiamondShare[i]);
            }
        }
        uint256 len = diamondArr.length + UserDiamondShare.length;
        if(len > 0){
            for(uint i = 0; i < diamondArr.length; i++){
                uint transferredAmount = revenue * diamondRate / len / 10**3;
                if (isActive[diamondArr[i]] == false) {
                    IMasterPool(masterPool).transferCommissionUseNft(MAX_OUT, transferredAmount,locktime,"PO5-Diamond",idPayment);
                } else {
                    IMasterPool(masterPool).transferCommissionUseNft(diamondArr[i], transferredAmount,locktime,"PO5-Diamond",idPayment);
                    emit PayBonus(diamondArr[i],ranks[diamondArr[i]],0,diamondRate / len, transferredAmount, block.timestamp,"Diamond",idPayment);            
                }
                totalExtraDiamondBonus[diamondArr[i]] += transferredAmount;
                totalExtraDiamondPayment += transferredAmount;
            }

            for(uint i = 0; i < UserDiamondShare.length; i++){
                uint transferredAmount = revenue * diamondRate / len / 10**3;
                if (isActive[UserDiamondShare[i]] == false) {
                    IMasterPool(masterPool).transferCommissionUseNft(MAX_OUT, transferredAmount,locktime,"PO5-Diamond",idPayment);
                } else {
                    IMasterPool(masterPool).transferCommissionUseNft(UserDiamondShare[i], transferredAmount,locktime,"PO5-Diamond",idPayment);
                    emit PayBonus(UserDiamondShare[i],ranks[UserDiamondShare[i]],0,diamondRate / len, transferredAmount, block.timestamp,"DiamondShare",idPayment);            
                }
                totalExtraDiamondBonus[UserDiamondShare[i]] += transferredAmount;
                totalExtraDiamondPayment += transferredAmount;
            }
        } else {
            IMasterPool(masterPool).transferCommissionUseNft(MAX_OUT, revenue * diamondRate / 10**3,locktime,"PO5-Diamond",idPayment);
        }
    }
    function _bonusForCrownDiamondSave(uint revenue, bytes32 idPayment,uint256 locktime) internal{
        for(uint i = 0; i < UserCrownDiamondShare.length; i++){
            if (AddressToExpiredDiamondShareTime[UserCrownDiamondShare[i]] < block.timestamp){
                removeCrownDiamondShare(UserCrownDiamondShare[i]);
            }
        }
        uint256 len = crownDiamondArr.length + UserCrownDiamondShare.length;
        if(len > 0){
            for(uint i = 0; i < crownDiamondArr.length; i++){
                uint transferredAmount = revenue * crownDiamondRate / len / 10**3;
                if (isActive[crownDiamondArr[i]] == false) {
                    IMasterPool(masterPool).transferCommissionUseNft(MAX_OUT, transferredAmount,locktime,"PO5-CrownDiamond",idPayment);
                } else {
                    IMasterPool(masterPool).transferCommissionUseNft(crownDiamondArr[i], transferredAmount,locktime,"PO5-CrownDiamond",idPayment);
                    emit PayBonus(crownDiamondArr[i],ranks[crownDiamondArr[i]],0,crownDiamondRate / len, transferredAmount, block.timestamp,"CrownDiamond",idPayment);            
                }
                totalExtraCrownDiamondBonus[crownDiamondArr[i]] += transferredAmount;
                totalExtraCrownDiamondPayment += transferredAmount;
            }

            for(uint i = 0; i < UserCrownDiamondShare.length; i++){
                uint transferredAmount = revenue * crownDiamondRate / len / 10**3;
                if (isActive[UserCrownDiamondShare[i]] == false) {
                    IMasterPool(masterPool).transferCommissionUseNft(MAX_OUT, transferredAmount,locktime,"PO5-CrownDiamond",idPayment);
                } else {
                    IMasterPool(masterPool).transferCommissionUseNft(UserCrownDiamondShare[i], transferredAmount,locktime,"PO5-CrownDiamond",idPayment);
                    emit PayBonus(UserCrownDiamondShare[i],ranks[UserCrownDiamondShare[i]],0,crownDiamondRate / len, transferredAmount, block.timestamp,"CrownDiamondShare",idPayment);            
                }
                totalExtraCrownDiamondBonus[UserCrownDiamondShare[i]] += transferredAmount;
                totalExtraCrownDiamondPayment += transferredAmount;
            }
        } else {
            IMasterPool(masterPool).transferCommissionUseNft(MAX_OUT, revenue * crownDiamondRate / 10**3,locktime,"PO5-CrownDiamond",idPayment);
        }
    }
    function _createSubscriptionSave(address subscriber,uint transferredAmount,bytes32 phone,bytes32 idPayment,uint256 locktime) internal {
        totalUser++;
        mSub[subscriber] = true;
        mphone[subscriber] = phone;
        mSubInfo[subscriber] = SubcribeInfo({
            codeRef: keccak256(abi.encodePacked(subscriber,block.timestamp, block.prevrandao,totalUser)),
            phone: phone
        });
        mRefCode[mSubInfo[subscriber].codeRef] = subscriber;

        address parent = line[subscriber];
        if (parent != address(0)) {
            childrens[parent].push(subscriber);
            line[subscriber] = parent;
            _transferDirectCommissionSave(subscriber,transferredAmount,idPayment,locktime);
        }
        ranks[subscriber] = 0;
        isActive[subscriber] = true;
        _addMemberLevels(subscriber);
        _bonusForDiamondSave(transferredAmount,idPayment,locktime);
        _bonusForCrownDiamondSave(transferredAmount,idPayment,locktime);
    }
    function _transferDirectCommissionSave(address buyer,uint256 _firstFee,bytes32 idPayment,uint256 locktime) internal {
        address parentMatrix = lineMatrix[buyer];
        address parentDirect = line[buyer];
        uint commAmount;
        uint commAmountFA;
        //pay to company
        // uint256 amount = (adDirectRate*_firstFee) / 10**3;
        uint256 maxAmountBonus = (maxDirectRateBonus*_firstFee) / 10**3;

        uint totalAmountTransfer = 0;
        IMasterPool(masterPool).transferCommissionUseNft(DAO_DT, (adDirectRate*_firstFee) / 10**3,locktime,"PO5-Direct",idPayment);
        //pay 50% for F1
        commAmountFA = (comDirectRate[0]*_firstFee) / 10**3;
        if(isActive[parentDirect] == false){
            IMasterPool(masterPool).transferCommissionUseNft(MAX_OUT, commAmountFA,locktime,"PO5-Direct",idPayment);
        } else {
            IMasterPool(masterPool).transferCommissionUseNft(parentDirect, commAmountFA,locktime,"PO5-Direct",idPayment);
            emit PayBonus(parentDirect,ranks[parentDirect],0,comDirectRate[0] ,commAmountFA,block.timestamp,"Direct",idPayment);            
        }
        totalAmountTransfer += commAmountFA;
        totalSubscriptionPayment += commAmountFA;

        //pay to users in system
        for (uint index = 1; index < comDirectRate.length; index++) 
        {   
            if (parentMatrix == address(0)) {
                IMasterPool(masterPool).transferCommissionUseNft(MAX_OUT, maxAmountBonus - totalAmountTransfer,locktime,"PO5-Direct",idPayment);
                break;
            }

            // 9 level from 1 to 10
            commAmount = (comDirectRate[index]*_firstFee) / 10**3;
            if (_isValidLevel(parentMatrix,index+1) && isActive[parentMatrix] == true) {   
                // Pay commission by subscription
                IMasterPool(masterPool).transferCommissionUseNft(parentMatrix, commAmount,locktime,"PO5-Direct",idPayment);
                emit PayBonus(parentMatrix,ranks[parentMatrix],index,comDirectRate[index],commAmount,block.timestamp,"Direct",idPayment);            
                totalSubcriptionBonus[parentMatrix] += commAmount;

            } else {
                IMasterPool(masterPool).transferCommissionUseNft(MAX_OUT, commAmount,locktime,"PO5-Direct",idPayment);
            }
            totalAmountTransfer += commAmount;
            totalSubscriptionPayment += commAmount;

            // next iteration
            parentMatrix = lineMatrix[parentMatrix];
        }
    }
    function PaySubLock (uint256 monthsNum,address to,bytes32 idPayment) external returns (bool) {
        require(isActive[to]==true,"this address is not active anymore");
        require(monthsNum>=1 && monthsNum<=36,"invalid number of month");
        require(mSub[to] == true, "Need to register first");
        require(IERC20(usdt).balanceOf(msg.sender) >= subcriptionFee, "Invalid Balance");
        uint256 transferredAmount = subcriptionFee*monthsNum;
        IERC20(usdt).transferFrom(msg.sender,masterPool,transferredAmount);
        uint256 locktime =  block.timestamp + 60 days;
        _transferMatrixBonusSave(to,transferredAmount,idPayment,locktime);
        // firstTimePay[to] = block.timestamp;
        nextTimePay[to] = DateTimeLibrary.addMonths(nextTimePay[to], monthsNum); 
        _bonusForDiamondSave(transferredAmount,idPayment,locktime);
        _bonusForCrownDiamondSave(transferredAmount,idPayment,locktime);
        IMasterPool(masterPool).setLock(to,locktime,idPayment);
        emit Buysub(msg.sender,to,transferredAmount,"VISA");
        return true;
    }

    function TransferCommssionSave(address buyer, uint256 price, uint256 reward, uint256 diff,bytes32 idPayment,uint256 locktime,address _NSX) external onlyProduct {
        totalSale[buyer] += price;
        uint256 mtnCom = price * MTN_RATE / 10**3;
        // 50% price to mtn
        IMasterPool(masterPool).transferCommission(MTN, mtnCom,"PO5-Sale");
        // 50% price to bonus, because bonus max is 130% diffPrice then if diffPrice >= 22.692..% price we will suffer a loss
        // The price difference is decided by the BD (func adminAddProduct)  
        uint256 totalAmountTransfer = _transferSaleCommissionSave(buyer, reward * REWARD_RATE / 10**3,idPayment,locktime);
        totalSaleRevenue += price;
        //17.5% diff to Dao 
        IMasterPool(masterPool).transferCommissionUseNft(DAO_DT, diff * DAODIFF_RATE / 10**3,locktime,"PO5-Sale",idPayment);
        // 2% diff to diamond
        _bonusForDiamond(diff);
        // 0.5% diff to crown diamond

        _bonusForCrownDiamond(diff);  

        // difference of 50% price and bonus-commission to NSX 
        uint256 total = mtnCom + totalAmountTransfer + diff * (diamondRate +  crownDiamondRate + DAODIFF_RATE ) / 10**3 ;
        if(price > total){
            IMasterPool(masterPool).transferCommissionUseNft(_NSX, price - total,locktime,"PO5-Sale",idPayment);
        }

    }
    function _transferSaleCommissionSave(address buyer, uint256 reward, bytes32 idPayment,uint256 locktime) internal returns(uint256){
        address parentMatrix = lineMatrix[buyer];
        address parentDirect = line[buyer];
        uint commAmount;
        uint256 rate;
        uint256 totalAmountTransfer;
        // uint256 saleGoodAmount;

        // 10% bonus in binary tree (matrix)
        for (uint index = 0; index < saleRateMatrix.length; index++) 
        {   
            if (parentMatrix == address(0)) {
                break;
            }

            if (_isValidLevelForBinary(parentMatrix,index+1)) {   
                // Pay commission by subscription
                commAmount = saleRateMatrix[index]*reward/10**3;
                if(commAmount > 0){
                    if(isActive[parentMatrix] == true){
                        IMasterPool(masterPool).transferCommissionUseNft(parentMatrix, commAmount,locktime,"PO5-Sale",idPayment);
                        totalAmountTransfer += commAmount;
                        emit PayBonus(parentMatrix, ranks[parentMatrix], index + 1, saleRateMatrix[index], commAmount, block.timestamp, "Sale",idPayment);       
                    }
                    totalSaleBonus[parentMatrix] += commAmount;
                    totalSalePayment += commAmount;
                }
            }
    
            // next iteration
            parentMatrix = lineMatrix[parentMatrix];
        }
        // 20% bonus in direct tree + 50% diff price for F1 + 50% diff price for good sale
        for (uint index = 0; index < saleRateDirect.length; index++) 
        {   
            if (parentDirect == address(0)) {
                break;
            }

            if (_isValidLevel(parentDirect,index+1)) {   
                commAmount = saleRateDirect[index]*reward/10**3;
                if(commAmount > 0){
                    if(isActive[parentDirect] == true){
                        IMasterPool(masterPool).transferCommissionUseNft(parentDirect, commAmount,locktime,"PO5-Sale",idPayment);
                        totalAmountTransfer += commAmount;
                        if (index == 0){
                            rate = 0;
                            for (uint256 j = 0; j < levelCareerBonus.length; j++) {
                                if (commAmount < levelCareerBonus[j]*usdtDecimal) {
                                    break;
                                } else {
                                    rate += additionalCom;
                                }
                            }
                            if (rate > 0) {
                                // saleGoodAmount = rate * reward / 10**3;
                                IMasterPool(masterPool).transferCommissionUseNft(parentDirect, rate * reward / 10**3,locktime,"PO5-PendingGoodSale",idPayment);
                                totalAmountTransfer += rate * reward / 10**3;
                                emit PayBonus(parentDirect, ranks[parentDirect], index, rate, rate * reward / 10**3, block.timestamp, "PendingGoodSale",idPayment);       

                            }
                        }
                        emit PayBonus(parentDirect, ranks[parentDirect], index, saleRateDirect[index], commAmount, block.timestamp, "Sale",idPayment);       
                    }
                    totalSaleBonus[parentDirect] += commAmount;
                    totalSalePayment += commAmount;
                }
            }
    
            // next iteration
            parentDirect = line[parentDirect];
        }
        // Total 130% to bonus
        // Transfer remaining amount to MAX_OUT
        uint256 fullReward = reward * 10**3 / REWARD_RATE;
        if (fullReward > totalAmountTransfer){
            IMasterPool(masterPool).transferCommissionUseNft(MAX_OUT, fullReward - totalAmountTransfer,locktime,"PO5-Sale",idPayment); 
            return fullReward;
        }
        return totalAmountTransfer;
    }

}