// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

struct PackageType {
    bytes32 PackageId;
    uint256 FiveMinuteTxnLimit;
    uint256 HourTxnLimit;
    uint256 DayTxnLimit;
    uint256 WeekTxnLimit;
    uint256 AmountLimit;
    uint256 DayAmountLimit;
    uint256 TransactionFee; // a * 10^3 => Divide for 10^3 when calculation
    uint256 AnnualFee;
}

struct PaymentInfo {
    address payer;
    address to;
    bytes32 packageId;
    uint256 yearNumber;
    bool isPending;
    uint256 createdAt;
    string[] countryList;
    uint8 paymentType;
}

struct MerchantInfo {
    // Merchant Info
    address merchant;
    bytes32 packageId;
    uint256 startTime;
    uint256 expiredTime;
    string[] countryList;

    // History 
    uint32 fiveMinuteEndTime; 
    uint32 hourEndTime;
    uint32 dayEndTime;
    uint32 weekEndTime;
    uint256 fiveMinuteTxnCount;
    uint256 hourTxnCount;
    uint256 dayTxnCount;
    uint256 weekTxnCount;
    uint256 dayTxnAmount;
}

struct Store {
    bytes32 storeId;
    string storeCode; // storeId on UI
    string name;
    string phoneNumber;
    string storeAddr;
    string email;
    address owner;
    address[] admin;
    address[] accountant;
    address[] cashier;
}       

struct OrderInfo {
    bytes32 orderId;
    bytes32 storeId;
    address requestMerchant;
    uint256 amount;
    address user;
    address scAddress;
    bytes dataAction;
    uint8 orderType;
    uint256 txnFee;
    bool isExecuted;
}

struct MmInfo {
    address user;
    uint256 balance;
}

struct MemberInfo {
    address user;
    bytes32 storeId;
    bool active;
    string name;
    uint8 role;
}

// USD Ratio on MTD Ratio
// Ex: 100% USD & 0% MTD => Ratio = 100
struct MerchantRatio {
    address user;
    uint256 ratio;
    uint256 amountUSD;
    uint256 amountMTD;
    uint256 maxUSD;  
    uint256 maxMTD;
}

struct NftInfo {
    uint256 tokenId;
    string nftType;
    uint256 price;
    uint256 lockTime;
    bytes32 paymentId;
}

struct CreateOrderInfo {
    address requestMerchant;
    bytes32 storeId;
    uint256 amountUsdt;
    address scAddress;
    address user;
    uint8 orderType;
}