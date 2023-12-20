// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract BlocAuction {

    address public deployer;
    address payable public beneficiary;
    
    address public highestBidder;
    uint public highestBid;
    
    mapping (address => uint) public pendingReturns;
    
    bool public ended;
    
    event HighestBidIncreased(address indexed bidder, uint amount);
    event AuctionEnded(address indexed winner, uint amount);
    event BidWithdrawn(address indexed bidder, uint amount);

    modifier onlyDeployer() {
    require(msg.sender == deployer, "You are not the auction deployer!");
    _;
}

    modifier notEnded() {
    require(!ended, "Auction has already ended.");
    _;
}



    constructor(address payable _beneficiary) {
        deployer = msg.sender;
        beneficiary = _beneficiary;
    }

    function bid() external payable notEnded {
        require(msg.value > highestBid, "Bid must be higher than the current highest bid.");

        if (highestBid != 0) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function withdraw() external returns (bool) {
        uint amount = pendingReturns[msg.sender];
        require(amount > 0, "No funds to withdraw.");

        pendingReturns[msg.sender] = 0;

        if (!payable(msg.sender).send(amount)) {
            pendingReturns[msg.sender] = amount;
            emit BidWithdrawn(msg.sender, amount);
            return false;
        }

        emit BidWithdrawn(msg.sender, amount);
        return true;
    }

    function getPendingReturn() external view returns (uint) {
        return pendingReturns[msg.sender];
    }

    function auctionEnd() external onlyDeployer notEnded {
        ended = true;
        emit AuctionEnded(highestBidder, highestBid);

        beneficiary.transfer(highestBid);
    }
}
