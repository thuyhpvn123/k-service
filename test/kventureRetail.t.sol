// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {console} from "forge-std/console.sol";
import {Test} from "forge-std/Test.sol";
import {KventureCode} from "../contracts/GenerateCode.sol";
import {PackageInfoStruct} from "../contracts/AbstractPackage.sol";
import {MasterPool} from "../contracts/MasterPool.sol";
import {USDT} from "../contracts/USDT.sol";
import {BinaryTree} from "../contracts/BinaryTree.sol";
import {KVenture} from "../contracts/kventure.sol";
import {KProductRetail} from "../contracts/ProductRetail.sol";
import {KOrder} from "../contracts/Order.sol";
import {KventureNft} from "../contracts/PackageNFT.sol";
import "../contracts/interfaces/IKventureProduct.sol";
import {PosNFT} from "../contracts/nft.sol";

contract KventureRetailTest is Test {
    MasterPool public MONEY_POOL;
    USDT public USDT_ERC;
    KVenture public PO5;
    KventureCode public CREATE_CODE;
    BinaryTree public TREE;
    KProductRetail public PRODUCT;
    KOrder public ORDER; 
    KOrder public ORDER1; 
    KventureNft public NFT;
    PosNFT public POSNFT;
    address public Deployer = address(0x1510);
    address public Max_out = address(0x1661);
    address public MTN = address(0x1771);
    address public DTBH = address(0x1881);
    address public DAO_DT = address(0x1551);
    uint256 ONE_USDT = 1_000_000;

    // Time Config
    bytes32 codeRef;
    bytes32 codeRef3;
    bytes32 codeRef2;
    bytes32 codeRef4;
    bytes32 codeRef13;
    uint256 public currentTime = 10368001;
    uint256 public timeAfter60Days = 10368001+60*24*60*60; //60*24*60*60= seconds in 60days
    // address[] public delegatesArr;
    constructor() {
        vm.startPrank(Deployer);
        //Deploy
        PO5 = new KVenture();
        USDT_ERC = new USDT();
        MONEY_POOL = new MasterPool(address(USDT_ERC));
        TREE = new BinaryTree(address(PO5));
        CREATE_CODE = new KventureCode();
        PRODUCT = new KProductRetail();
        ORDER = new KOrder();
        ORDER1 = new KOrder();
        NFT = new KventureNft();
        POSNFT = new PosNFT();
        //Call
        //init 
        USDT_ERC.setMinterAddress(Deployer);
        PO5.initialize(address(USDT_ERC), address(MONEY_POOL), address(TREE), Deployer, DAO_DT, DTBH, address(CREATE_CODE), MTN, Max_out,Deployer);
        PRODUCT.initialize(address(USDT_ERC),address(MONEY_POOL),address(CREATE_CODE),address(PO5),address(ORDER1));
        CREATE_CODE.initialize(address(USDT_ERC), address(MONEY_POOL), address(0x01), address(PRODUCT), address(NFT), address(PO5), address(0x02));
        CREATE_CODE.SetProduct(address(PRODUCT));
        NFT.grantRole(keccak256("MINTER_ROLE"), address(CREATE_CODE));
        MONEY_POOL.setController(address(PO5));  
        MONEY_POOL.setPosNft(address(POSNFT));
        PO5.SetProduct(address(PRODUCT));
        ORDER1.initialize(address(PRODUCT));
        POSNFT.setKventure(address(MONEY_POOL));
        vm.stopPrank();
        Register();
    }

    function mintUSDT(address user, uint256 amount) internal {
        vm.startPrank(Deployer);
        USDT_ERC.mintToAddress(user, amount * ONE_USDT);
        USDT_ERC.approve(address(PO5),amount * ONE_USDT);
        vm.stopPrank();
    }

    function Register() public {
        // 7 user need 7 * 160$ to register 12 month
        mintUSDT(Deployer,800*160);
        // Account 1 == A
        vm.startPrank(Deployer);
        bytes32 codeRef1;
        PO5.Register(codeRef1, codeRef1, 1, keccak256(abi.encodePacked(block.timestamp + 1)), address(0x1));
        vm.stopPrank();
        vm.startPrank(address(0x1));
        codeRef1 = PO5.GetCodeRef();
        vm.stopPrank();
    
        // Account 2 == B
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef1, 1, keccak256(abi.encodePacked(block.timestamp + 2)), address(0x2));
        vm.stopPrank();
        vm.startPrank(address(0x2));
        codeRef2 = PO5.GetCodeRef();
        vm.stopPrank();

        // Account 3 == C
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef1, 1, keccak256(abi.encodePacked(block.timestamp + 3)), address(0x3));
        vm.stopPrank();
        vm.startPrank(address(0x3));
        codeRef3 = PO5.GetCodeRef();
        vm.stopPrank();


        // Account 4 == D
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef1, 1, keccak256(abi.encodePacked(block.timestamp + 4)), address(0x4));
        vm.stopPrank();
        vm.startPrank(address(0x4));
        codeRef4 = PO5.GetCodeRef();
        vm.stopPrank();

        // Account 5 == E
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef1, 1, keccak256(abi.encodePacked(block.timestamp + 5)), address(0x5));
        vm.startPrank(address(0x5));
        bytes32 codeRef5 = PO5.GetCodeRef();
        vm.stopPrank();



        // Account 6 == F
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef2, 1, keccak256(abi.encodePacked(block.timestamp + 6)), address(0x6));
        vm.startPrank(address(0x6));
        bytes32 codeRef6 = PO5.GetCodeRef();
        vm.stopPrank();

     

        // Account 7 == G
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef2, 1, keccak256(abi.encodePacked(block.timestamp + 7)), address(0x7));
        vm.stopPrank();
        vm.startPrank(address(0x7));
        // bytes32 codeRef7 = PO5.GetCodeRef();
        vm.stopPrank();

        // Account 8 == H
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef3, 1, keccak256(abi.encodePacked(block.timestamp + 8)), address(0x8));
        vm.stopPrank();
        vm.startPrank(address(0x8));
        // bytes32 codeRef8 = PO5.GetCodeRef();
        vm.stopPrank();

        // Account 9 == I
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef4, 1, keccak256(abi.encodePacked(block.timestamp + 9)), address(0x9));
        vm.stopPrank();
        vm.startPrank(address(0x9));
        bytes32 codeRef9 = PO5.GetCodeRef();
        vm.stopPrank();

        // Account 10 == K
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef5, 1, keccak256(abi.encodePacked(block.timestamp + 10)), address(0x10));
        vm.stopPrank();
        vm.startPrank(address(0x10));
        bytes32 codeRef10 = PO5.GetCodeRef();
        vm.stopPrank();

        // Account 11 == L
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef5, 1, keccak256(abi.encodePacked(block.timestamp + 11)), address(0x11));
        vm.stopPrank();
        vm.startPrank(address(0x11));
        bytes32 codeRef11 = PO5.GetCodeRef();
        vm.stopPrank();

        // Account 12 == M
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef5, 1, keccak256(abi.encodePacked(block.timestamp + 12)), address(0x12));
        vm.stopPrank();
        vm.startPrank(address(0x12));
        // bytes32 codeRef12 = PO5.GetCodeRef();
        vm.stopPrank();

        // Account 13 == N
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef6, 1, keccak256(abi.encodePacked(block.timestamp + 13)), address(0x13));
        vm.stopPrank();
        vm.startPrank(address(0x13));
        codeRef13 = PO5.GetCodeRef();
        vm.stopPrank();

        // Account 14 == O
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef9, 1, keccak256(abi.encodePacked(block.timestamp + 14)), address(0x14));
        vm.stopPrank();
        vm.startPrank(address(0x14));
        bytes32 codeRef14 = PO5.GetCodeRef();
        vm.stopPrank();

        // Account 15 == P
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef10, 1, keccak256(abi.encodePacked(block.timestamp + 15)), address(0x15));
        vm.stopPrank();
        vm.startPrank(address(0x15));
        // bytes32 codeRef15 = PO5.GetCodeRef();
        vm.stopPrank();

        // Account 16 == Q
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef11, 1, keccak256(abi.encodePacked(block.timestamp + 16)), address(0x16));
        vm.stopPrank();
        vm.startPrank(address(0x16));
        // bytes32 codeRef16 = PO5.GetCodeRef();
        vm.stopPrank();

        // Account 17 == R
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef14, 1, keccak256(abi.encodePacked(block.timestamp + 17)), address(0x17));
        vm.stopPrank();
        vm.startPrank(address(0x17));
        bytes32 codeRef17 = PO5.GetCodeRef();
        vm.stopPrank();

        // Account 18 == S
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef14, 1, keccak256(abi.encodePacked(block.timestamp + 18)), address(0x18));
        vm.stopPrank();
        vm.startPrank(address(0x18));
        // bytes32 codeRef18 = PO5.GetCodeRef();
        vm.stopPrank();

        // Account 19 == T
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef14, 1, keccak256(abi.encodePacked(block.timestamp + 19)), address(0x19));
        vm.stopPrank();
        vm.startPrank(address(0x19));
        // bytes32 codeRef19 = PO5.GetCodeRef();
        vm.stopPrank();

        // Account 20 == U
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef17, 1, keccak256(abi.encodePacked(block.timestamp + 20)), address(0x20));
        vm.stopPrank();
        vm.startPrank(address(0x20));
        bytes32 codeRef20 = PO5.GetCodeRef();
        vm.stopPrank();

        // Account 21 == V
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef17, 1, keccak256(abi.encodePacked(block.timestamp + 21)), address(0x21));
        vm.stopPrank();
        vm.startPrank(address(0x21));
        // bytes32 codeRef21 = PO5.GetCodeRef();
        vm.stopPrank();

        // Account 22 == W
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef20, 1, keccak256(abi.encodePacked(block.timestamp + 22)), address(0x22));
        vm.stopPrank();
        vm.startPrank(address(0x22));
        bytes32 codeRef22 = PO5.GetCodeRef();
        vm.stopPrank();

        // Account 23 == Y
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef20, 1, keccak256(abi.encodePacked(block.timestamp + 23)), address(0x23));
        vm.stopPrank();
        vm.startPrank(address(0x23));
        // bytes32 codeRef23 = PO5.GetCodeRef();
        vm.stopPrank();

        // Account 24 == Z
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef22, 1, keccak256(abi.encodePacked(block.timestamp + 24)), address(0x24));
        vm.stopPrank();
        vm.startPrank(address(0x23));
        // bytes32 codeRef24 = PO5.GetCodeRef();
        vm.stopPrank();

        // Account 25 == 1
        vm.startPrank(Deployer);
        PO5.Register(codeRef1, codeRef3, 1, keccak256(abi.encodePacked(block.timestamp + 25)), address(0x25));
        vm.stopPrank();
        vm.startPrank(address(0x25));
        // bytes32 codeRef24 = PO5.GetCodeRef();
        vm.stopPrank();
        console.log("bal U la:",USDT_ERC.balanceOf(address(0x20)));
        console.log("bal Y la:",USDT_ERC.balanceOf(address(0x23)));

    }
    function testOrder()public{
        //admin add product
        vm.startPrank(Deployer);
        PRODUCT.SetAdmin(Deployer);
        // PRODUCT.adminAddProduct("100",100*ONE_USDT,117*ONE_USDT,"ao",true,120);
        PRODUCT.adminAddProduct("100_000",100_000*ONE_USDT,120_077*ONE_USDT,"ao",true,120);
        Product [] memory ProductArr = new Product[](1);
        ProductArr = PRODUCT.adminViewProduct();
        address NSX = address(0x1991);
        PRODUCT.adminUpdateReward(ProductArr[0].id,27_444*ONE_USDT,200_000*ONE_USDT,NSX);
        vm.stopPrank();
        //case1:
        mintUSDT(address(Deployer),1_000_000*ONE_USDT);
        vm.startPrank(address(Deployer));
        USDT_ERC.approve(address(PRODUCT),1_000_000*ONE_USDT);

        bool[] memory lockArr = new bool[](1);
        lockArr[0]=false;
        bytes32[][] memory codeHashes = new bytes32[][](1);
        bool[] memory cloudMinings = new bool[](1);
        cloudMinings[0]=false;
        address[] memory delegates = new address[](1);
        delegates[0]=address(0);
        bytes32[] memory idArr = new bytes32[](1);
        uint256[] memory quaArr = new uint256[](1);

        // address L order 1 products 100_000
        idArr[0] = ProductArr[0].id;
        quaArr[0]=1;
        bytes32[] memory codeHash0L = new bytes32[](1);
        codeHash0L= getCodeHash(1,100_000);      
        codeHashes[0] = codeHash0L;       
        PRODUCT.order(idArr,quaArr,lockArr,codeHashes,delegates,PO5.GetRefCoder(address(0x11)),address(0x25),address(0x23));
        uint256 bal = USDT_ERC.balanceOf(NSX);
        console.log("NSX:",bal);
        uint256 bal1 = USDT_ERC.balanceOf(Max_out);
        console.log("Max_out:",bal1);


        // console.log("totalSaleBonus A:",PO5.GetUserInfo(address(0x1)).totalSaleBonus); //
        // console.log("totalSaleBonus B:",PO5.GetUserInfo(address(0x2)).totalSaleBonus);
        // console.log("totalSaleBonus E:",PO5.GetUserInfo(address(0x5)).totalSaleBonus); //
        // console.log("totalSaleBonus F:",PO5.GetUserInfo(address(0x6)).totalSaleBonus);
        // console.log("totalSaleBonus I:",PO5.GetUserInfo(address(0x9)).totalSaleBonus);
        // console.log("totalSaleBonus K:",PO5.GetUserInfo(address(0x10)).totalSaleBonus);
        // console.log("totalSaleBonus L:",PO5.GetUserInfo(address(0x11)).totalSaleBonus);
        // console.log("totalSaleBonus O:",PO5.GetUserInfo(address(0x14)).totalSaleBonus); //

        // console.log("totalGoodSaleBonus A:",PO5.totalRevenues(address(0x1)));
        // console.log("totalGoodSaleBonus B:",PO5.totalRevenues(address(0x2)));
        // console.log("totalGoodSaleBonus C:",PO5.totalRevenues(address(0x3)));
        // console.log("totalGoodSaleBonus D:",PO5.totalRevenues(address(0x4)));
        // console.log("totalGoodSaleBonus E:",PO5.totalRevenues(address(0x5))); 
        // console.log("totalGoodSaleBonus F:",PO5.totalRevenues(address(0x6))); 
        // console.log("totalGoodSaleBonus G:",PO5.totalRevenues(address(0x7)));
        // console.log("totalGoodSaleBonus H:",PO5.totalRevenues(address(0x8)));
        // console.log("totalGoodSaleBonus I:",PO5.totalRevenues(address(0x9))); 
        // console.log("totalGoodSaleBonus K:",PO5.totalRevenues(address(0x10))); 
        // console.log("totalGoodSaleBonus L:",PO5.totalRevenues(address(0x11))); 
        // console.log("totalGoodSaleBonus E:",PO5.totalRevenues(address(0x12))); 
        // console.log("totalGoodSaleBonus O:",PO5.totalRevenues(address(0x14))); 

        //check sale bonus
        // assertEq(
        //     PO5.GetUserInfo(address(0x1)).totalSaleBonus, 
        //     6231*ONE_USDT + 24924*ONE_USDT/100,  //50%*(12_077-10_000)*6 direct + 2%*(12_077-10_000)*6
        //     "Error balance PB"
        // ); 
        vm.stopPrank();

        
    }
    function getCodeHash(uint256 amount,uint256 price) public pure returns(bytes32[] memory){
        bytes32[] memory codeHashArr = new bytes32[](amount);
        for (uint i=0;i< amount;i++){
            codeHashArr[i]= keccak256(abi.encodePacked(i+amount+price));
        }
        return codeHashArr;
    }
}
