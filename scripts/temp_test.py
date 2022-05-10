from brownie import SimpleElection,config,network
from scripts.helpful_script import get_account,to_bytes,from_bytes

def deploy():
    account=get_account()
    SimpleElection.deploy({"from":account})
    simpleElection=SimpleElection[-1]
    simpleElection.createElection(to_bytes("name"),"description",False,to_bytes(["a","b"]),1,4000000000,1,1,{"from":account})
    simpleElection.createElection(to_bytes("nasme"),"description",False,to_bytes(["a","b"]),1,4000000000,1,1,{"from":account})
    simpleElection.vote(1,1,1,{"from":account})
    currentElections=simpleElection.getCurrentElections({"from":account})
    for election in currentElections:
        print(from_bytes(election))
    candidates=simpleElection.getCandidatesForElection(1)
    for candidate in candidates:
        print(from_bytes(candidate))


def main():
    deploy()