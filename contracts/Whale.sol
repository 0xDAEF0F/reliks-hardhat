// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Global Constants
address constant MARKETPLACE_ADDRESS = 0xD8f76d6C907E705E8C66D531f7C3386d33Dc2f2E;
uint256 constant PERCENTAGE_MARKETPLACE_FEE = 10;

contract WhaleStrategy {
    address public immutable creatorWallet;
    uint256 public whaleLimit;
    uint256 public initialLairEntry;

    bool public lairFull;

    Whale[] public whaleArr;
    mapping(address => bool) public isWhale;

    struct Whale {
        address addr;
        uint256 grant;
    }

    event LogNewWhale(uint256 amount, address newWhale);
    event LogDethroneWhale(uint256 amount, address newWhale, address oldWhale);

    constructor(
        address creatorAddress,
        uint256 maxWhaleLimit,
        uint256 initialCost
    ) {
        creatorWallet = creatorAddress;
        whaleLimit = maxWhaleLimit;
        initialLairEntry = initialCost;
    }

    function enterLair() public payable checkMoney(msg.value) {
        if (lairFull == false) {
            _accomodateWhaleWithoutDethrone(msg.value, msg.sender);
            // Calculate Mktplace fee
            uint256 marketPlaceFee = _calculateAppFee(msg.value);
            // Distribute ether
            payable(MARKETPLACE_ADDRESS).transfer(marketPlaceFee);
            payable(creatorWallet).transfer(msg.value - marketPlaceFee);
            return;
        }

        // LAIR FULL
        Whale memory whaleToDethrone = whaleArr[whaleArr.length - 1];
        _accomodateWhaleAndDethrone(msg.value, msg.sender);
        // Refund old whale
        payable(whaleToDethrone.addr).transfer(whaleToDethrone.grant);
    }

    function _accomodateWhaleWithoutDethrone(
        uint256 moneyPaid,
        address newWhaleWallet
    ) private {
        whaleArr.push(Whale(newWhaleWallet, moneyPaid));
        // Define whale in mapping
        isWhale[newWhaleWallet] = true;
        emit LogNewWhale(moneyPaid, newWhaleWallet);
        if (whaleArr.length >= whaleLimit) {
            sort();
            lairFull = true;
        }
    }

    function _accomodateWhaleAndDethrone(uint256 newMoney, address newAddr)
        private
    {
        Whale memory dethronedWhale = whaleArr[whaleArr.length - 1];
        // Remove last element from array since it is sorted
        whaleArr.pop();
        // Remove whale from mapping
        isWhale[dethronedWhale.addr] = false;
        emit LogDethroneWhale(newMoney, newAddr, dethronedWhale.addr);
        whaleArr.push(Whale(newAddr, newMoney));
        sort();
    }

    function _calculateAppFee(uint256 amount) private pure returns (uint256) {
        return (amount * PERCENTAGE_MARKETPLACE_FEE) / 100;
    }

    function sort() internal {
        _quickSort(whaleArr, int256(0), int256(whaleArr.length - 1));
    }

    function _quickSort(
        Whale[] storage arr,
        int256 left,
        int256 right
    ) private {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)].grant;
        while (i <= j) {
            while (arr[uint256(i)].grant > pivot) i++;
            while (pivot > arr[uint256(j)].grant) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) _quickSort(arr, left, j);
        if (i < right) _quickSort(arr, i, right);
    }

    modifier checkMoney(uint256 amount) {
        if (lairFull == false) {
            require(amount >= initialLairEntry, "Not enough money.");
            _;
            return;
        }
        if (lairFull == true) {
            require(
                amount > whaleArr[whaleLimit - 1].grant,
                "Not enough to dethrone whale."
            );
            _;
            return;
        }
    }
}
