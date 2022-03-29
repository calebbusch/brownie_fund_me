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
        uint256 minimumUSD = 50 * 10**18;
        // If minimum amount of eth is not sent, throw exception and revert state
        require(
            getConvertedUSDValue(msg.value) >= minimumUSD,
            "You need to spend more ETH."
        );
        // Else add to map and funders state variables
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    // Gets the version of the chainlink pricefeed
    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    // Returns the ETH/USD rate * 10^18
    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // Convert 10^8 to 10^18
        return uint256(answer * 10**10);
    }

    // Returns the USD value of a wei amount
    function getConvertedUSDValue(uint256 weiAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        // (10^18 * 10^18) / 10^18
        uint256 ethAmountInUsd = (ethPrice * weiAmount) / 10**18;
        return ethAmountInUsd;
    }

    // Returns minimum amount required to donate in terms of wei
    function getEntranceFee() public view returns (uint256) {
        uint256 minimumUSD = 50 * (10**18);
        uint256 ethPrice = getPrice();
        // (10^18 * 10^18) / 10^18
        return (minimumUSD * 10**18) / ethPrice;
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
