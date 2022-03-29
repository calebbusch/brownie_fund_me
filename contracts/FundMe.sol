// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

// Retrieve the latest ETH/USD price from chainlink price feed
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

/*
 * Smart contract that allows anyone to deposit ETH into the contract
 * Only the owner of the contract can withdraw the ETH
 */
contract FundMe {
    using SafeMathChainlink for uint256;
    // State variables
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    // Set the owner as the account that deployed the contract
    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    /*
     * Updates addressToAmountFunded and funders state variables with the
     * sender's account and amount of eth sent if it meets a minimum USD
     * value; else throws exception
     */
    function fund() public payable {
        // 18 digit number
        uint256 minimumUSD = 50 * 10**18;
        // If minimum amount of eth is not sent, throw exception and revert state
        require(
            getConvertedUSDValue(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );
        // Else add to map and funders state variables
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    // Gets the version of the chainlink pricefeed
    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    // Returns the ETH/USD rate with 18 digits
    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    // Returns the USD value of an ether amount
    function getConvertedUSDValue(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    // Returns minimum amount required to donate in terms of ether
    function getEntranceFee() public view returns (uint256) {
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return ((minimumUSD * precision) / price) + 1;
    }

    // Is the message sender the owner of the contract?
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Withdraws funds sent to this contract account; only the owner can withdraw
    function withdraw() public payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
        // Iterate through and nullify all of the mappings
        // since the entire deposited amount has been withdrawn
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        // Nullify funders array by initializing to 0
        funders = new address[](0);
    }
}
