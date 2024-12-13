//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

abstract contract PackageInfoStruct {
    struct Product{
        bytes32 id;
        bytes imgUrl;
        uint256 memberPrice;
        uint256 retailPrice;
        bytes desc;
        bool active;
    }
    struct Order{
        bytes32 id;
        address buyer;
        bytes32[] productIds;
        uint256[] quantities;
        uint256 creatAt;
        uint256 []tokenIds;
        ShippingInfo shipInfo;
        address paymentAdd;
    }
    struct ShippingInfo{
        // bytes32 orderId;
        string fullname;
        string add;
        string phone;
        string zipcode;
        string email;
        uint256 receivingTime;
    }

}