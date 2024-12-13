// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts@v4.9.0/utils/math/Math.sol";
import "./interfaces/IBinaryTree.sol";

contract BinaryTree is IBinaryTree {
    using Math for uint256;

    mapping(uint256 => address) public mAddressOfIndex;
    mapping(address => Node) public mNode;

    Node[] public nodeList;
    address public CONTROLLER_ADDRESS; 

    constructor(address _controller) payable {
        CONTROLLER_ADDRESS = _controller;
    }

    function init(address _address, uint256 _index) external returns (bool) {
        return _createNode(_address, _index);
    }

    function _createNode(
        address _address,
        uint256 _index
    ) internal onlyController returns (bool) {
        require(_index > 0, "Binary tree: Invalid index");
        Node memory newNode = Node({
            _address: _address,
            left: 0,
            right: 0,
            index: _index
        });

        mNode[_address] = newNode;
        mAddressOfIndex[_index] = _address;
        nodeList.push(newNode);
        return true;
    }

    function addNode(
        address pAddress,
        address _address
    ) external onlyController returns (address mParent) {
        require(
            mNode[pAddress]._address != address(0),
            "Binary tree: Parent does not exist"
        );
        require(mNode[_address]._address == address(0), "Address exist");

        Node memory _node = mNode[pAddress];
        uint256 depth = Math.log2(_node.index + 1);
        uint256 order = _node.index - 2 ** (depth - 1);
        uint256 currentLevel = 1;

        while (_node._address != address(0)) {
            uint256 start = (2 ** depth) + order * (2 ** currentLevel);
            for (uint index = 0; index < 2 ** currentLevel; index += 2) {
                mParent = executeInsertNode(start, currentLevel, order, index, depth, _address);
                if (mParent != address(0)) {
                    return mParent;
                }
            }
            for (uint index = 1; index < 2 ** currentLevel; index += 2) {
                mParent = executeInsertNode(start, currentLevel, order, index, depth, _address);
                if (mParent != address(0)) {
                    return mParent;
                }
            }
            depth++;
            currentLevel++;
        }
        revert("Binary tree: Fail addNode");
    }

    function executeInsertNode(
        uint256 start,
        uint256 currentLevel,
        uint256 order,
        uint256 index,
        uint256 depth,
        address nodeAddress
    ) internal onlyController returns (address) {
        uint256 newNodeIndex = start + index;
        if (mAddressOfIndex[newNodeIndex] == address(0)) {
            Node memory mParent = mNode[
                mAddressOfIndex[
                    2 ** (depth - 1) +
                        2 ** (currentLevel - 1) *
                        order +
                        index /
                        2
                ]
            ];
            if (index % 2 == 0) {
                mParent.left = newNodeIndex;
            } else {
                mParent.right = newNodeIndex;
            }
            _createNode(nodeAddress, newNodeIndex);
            return mParent._address;
        }
        return address(0);
    }

    modifier onlyController {
        require(CONTROLLER_ADDRESS == msg.sender, "Binary tree: Only Controller");
        _;
    }
}
