# Import FundMe and MockV3Aggregator as contract proxy objects
from brownie import FundMe, MockV3Aggregator, network, config
from scripts.helper_scripts import (
    get_account,
    deploy_mocks,
    LOCAL_BLOCKCHAIN_ENVIRONMENTS,
)


def deploy_fund_me():
    account = get_account()
    print(f"The active network is {network.show_active()}")
    # Make this script development-live network agnostic
    # If not development or ganache-local then get live price feed address
    # from config file
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        price_feed_address = config["networks"][network.show_active()][
            "eth_usd_price_feed"
        ]
    # Else deploy mock price feed
    else:
        deploy_mocks()
        # Get address of most recently deployed mock aggregator
        price_feed_address = MockV3Aggregator[-1].address

    # Pass contract constructor arguments as first arguments in brownie's .deploy
    # proxy function. Automatically verify and publish the source code using
    # etherscan API
    # Returns ProjectContract proxy object
    fund_me = FundMe.deploy(
        price_feed_address,
        {"from": account},
        publish_source=config["networks"][network.show_active()].get("verify"),
    )
    print(f"Contract deployed to {fund_me.address}")
    return fund_me


# Execution begins here
def main():
    deploy_fund_me()
