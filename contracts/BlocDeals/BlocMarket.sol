// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol';


contract BlocMarket is ERC721URIStorage, Ownable(msg.sender) {

    using Counters for Counters.Counter;

    Counters.Counter private token_ids;

    address payable public foundation_address;

    mapping(uint => Auction) public auctions;
    mapping(uint256 => address) private _owners;


    enum AuctionStatus { NotStarted, Open, Ended }

    struct Auction {
        address payable highestBidder;
        uint highestBid;
        AuctionStatus status;
    }

    modifier landRegistered(uint token_id) {
    require(_exists(token_id), "Land not registered!");
    _;
}


    constructor() ERC721("BlocMarket", "DEAL") {
        foundation_address = payable(msg.sender);
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
    return _owners[tokenId] != address(0);
}

    function createAuction(uint token_id) public onlyOwner landRegistered(token_id) {
        require(auctions[token_id].status == AuctionStatus.NotStarted, "Auction already started");
        auctions[token_id].status = AuctionStatus.Open;
    }

    function registerLand(string memory uri) public payable onlyOwner {
        token_ids.increment();
        uint token_id = token_ids.current();
        _mint(foundation_address, token_id);
        _setTokenURI(token_id, uri);
        createAuction(token_id);
    }

    function endAuction(uint token_id) public onlyOwner landRegistered(token_id) {
        Auction storage auction = auctions[token_id];
        require(auction.status == AuctionStatus.Open, "Auction not open");

        auction.status = AuctionStatus.Ended;
        safeTransferFrom(owner(), auction.highestBidder, token_id);
    }

    function auctionEnded(uint token_id) public view landRegistered(token_id) returns(bool) {
        return auctions[token_id].status == AuctionStatus.Ended;
    }

    function highestBid(uint token_id) public view landRegistered(token_id) returns(uint) {
        return auctions[token_id].highestBid;
    }

    function pendingReturn(uint token_id, address sender) public view landRegistered(token_id) returns(uint) {
        Auction storage auction = auctions[token_id];
        return sender == auction.highestBidder ? 0 : auction.highestBid;
    }

    function bid(uint token_id) public payable landRegistered(token_id) {
        Auction storage auction = auctions[token_id];
        require(auction.status == AuctionStatus.Open, "Auction not open");
        require(msg.value > auction.highestBid, "Bid amount is too low");

        if (auction.highestBidder != address(0)) {
            // Refund the previous highest bidder
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBidder = payable(msg.sender);
        auction.highestBid = msg.value;
    }
}
