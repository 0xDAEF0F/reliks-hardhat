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

        address whaleToDethrone = whaleArr[whaleLimit - 1].addr;
        uint256 amountForRefund = whaleArr[whaleLimit - 1]
            .amountPaidToEnterLair;
        if (lairFull == true) {
            _accomodateWhaleAndDethrone(msg.value, msg.sender);
            return;
        }

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
            lairFull = true;
        }
    }

    function _accomodateWhaleAndDethrone(uint256 newMoney, address newAddr)
        private
    {
        // 1. Remove last element array
        // 2. Emit event.
        // 3. Find Index where to locate
        // 4. Keep array sorted
    }

    function _calculateMarketplaceShare(uint256 amount)
        private
        pure
        returns (uint256)
    {
        return (amount * PERCENTAGE_MARKETPLACE_FEE) / 100;
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
