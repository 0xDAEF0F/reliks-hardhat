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

    Whale[] whaleArr;

    struct Whale {
        address addr;
        uint256 amountPaidToEnterLair;
    }

    event LogNewWhale(uint256 amount, address newWhale);
    event LogDethroneWhale(uint256 amount, address newWhale, address oldWhale);

    constructor(
        address name,
        uint256 maxWhaleLimit,
        uint256 initialCost
    ) {
        creatorWallet = name;
        whaleLimit = maxWhaleLimit;
        initialLairEntry = initialCost;
    }

    function enterLair() public payable checkMoney(msg.value) {
        // Values apply both scenarios
        uint256 mktPlaceFee = _calculateMarketplaceShare(msg.value);
        uint256 creatorProfit = msg.value - mktPlaceFee;

        // Distribute payments
        payable(MARKETPLACE_ADDRESS).transfer(mktPlaceFee);
        payable(creatorWallet).transfer(creatorProfit);

        if (lairFull == false) {
            _accomodateWhaleWithoutDethrone(msg.value, msg.sender);
            return;
        }

        // LAIR FULL
        address whaleToDethrone = whaleArr[whaleLimit - 1].addr;
        uint256 amountForRefund = whaleArr[whaleLimit - 1]
            .amountPaidToEnterLair;
        _accomodateWhaleAndDethrone(msg.value, msg.sender);

        // Refund old whale
        payable(whaleToDethrone).transfer(amountForRefund);
    }

    function _accomodateWhaleWithoutDethrone(
        uint256 moneyPaid,
        address newWhaleWallet
    ) private {
        whaleArr.push(Whale(newWhaleWallet, moneyPaid));
        emit LogNewWhale(moneyPaid, newWhaleWallet);
        if (whaleArr.length >= whaleLimit) {
            // Sort array
            sort();
            // mark lair as full
            lairFull = true;
        }
    }

    function _accomodateWhaleAndDethrone(uint256 newMoney, address newAddr)
        private
    {
        // 1. Remove last element array
        Whale memory dethronedWhale = whaleArr[whaleArr.length - 1];
        whaleArr.pop();
        // 2. Emit event.
        emit LogDethroneWhale(newMoney, newAddr, dethronedWhale.addr);
        // 3. Push new whale.
        whaleArr.push(Whale(newAddr, newMoney));
        // 4. Re-sort the array (can improve)
        sort();
    }

    function _calculateMarketplaceShare(uint256 amount)
        private
        pure
        returns (uint256)
    {
        return (amount * PERCENTAGE_MARKETPLACE_FEE) / 100;
    }

    function sort() internal {
        quickSort(whaleArr, int256(0), int256(whaleArr.length - 1));
    }

    function quickSort(
        Whale[] storage arr,
        int256 left,
        int256 right
    ) private {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)]
            .amountPaidToEnterLair;
        while (i <= j) {
            while (arr[uint256(i)].amountPaidToEnterLair > pivot) i++;
            while (pivot > arr[uint256(j)].amountPaidToEnterLair) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }

    modifier checkMoney(uint256 amount) {
        if (lairFull == false) {
            require(amount >= initialLairEntry, "Not enough money.");
            _;
        }
        require(
            amount > whaleArr[whaleLimit - 1].amountPaidToEnterLair,
            "Not enough to dethrone whale."
        );
        _;
    }
}
