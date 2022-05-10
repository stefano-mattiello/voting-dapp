from operator import ne
from brownie import accounts,network,config

LOCAL_BLOCKCHAIN_ENVIRONMENTS=["development","local"]
FORKED_BLOCKCHAIN_ENVIRONMENTS=[]


def get_account(index=None,id=None):
    if index:
        return accounts[index]
    if id:
        return accounts.load(id)
    if(network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS or network.show_active() in FORKED_BLOCKCHAIN_ENVIRONMENTS):
        return accounts[0]
    return accounts.add(config["wallets"]["from_key"])


  



DECIMALS=8
INITIAL_VALUE=200000000000


def fund_with_link(contract_address,account=None,link_token=None,amount=100000000000000000):
    account=account if account else get_account()
    link_token=link_token if link_token else get_contract("linktoken")
    tx=link_token.transfer(contract_address,amount,{"from":account})
    tx.wait(1)
    print("contract funded with link")
    return tx