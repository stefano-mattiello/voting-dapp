from brownie import SimpleElection
from scripts.helpful_script import get_account,config,network

def deploy():
    account=get_account()
    SimpleElection.deploy({"from":account})
    simpleElection=SimpleElection[-1]
    simpleElection.createElection("name".encode('utf-8'),"description",False,["a".encode('utf-8'),"b".encode('utf-8')],1,4000000000,1,1,{"from":account})
    simpleElection.createElection("nasme".encode('utf-8'),"description",False,["a".encode('utf-8'),"b".encode('utf-8')],1,4000000000,1,1,{"from":account})
    simpleElection.vote(1,1,1,{"from":account})
    currentElections=simpleElection.getCurrentElections({"from":account})
    for election in currentElections:
        print(election.decode('utf-8'))
    candidates=simpleElection.getCandidatesForElection(1)
    for candidate in candidates:
        print(candidate.decode('utf-8'))


def main():
    deploy()