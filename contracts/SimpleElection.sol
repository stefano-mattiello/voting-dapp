// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleElection {
    //Structure of an election
    struct Election {
        bytes32 name;
        string description;
        uint32 id;
        bool requireRegitration;
        uint32 startElection;
        uint32 endElection;
        uint32 startRegistration;
        uint32 endRegistration;
    }

    mapping(bytes32 => uint32) electionsNames; //list of current elections
    uint32[] currentElections;

    //Structure of candidate standing in an election
    struct Candidate {
        bytes32 name; //name of the proposal
        uint256 voteCount; //votes received
        bool votable; //boolean to check if the proposal exists
    }

    //Structure of a voter
    struct Voter {
        uint256 weight; // weight is accumulated by delegation
        bool voted; // if true, that person already voted
    }

    //Mapping of the elections
    mapping(uint32 => Election) elections;

    //Mappings of the proposals for every election
    mapping(uint32 => mapping(bytes32 => Candidate)) public candidates;

    //List of the proposal for every election
    mapping(uint32 => bytes32[]) public candidatesList;

    //Number of proposal for every election
    mapping(uint32 => uint256) public candidatesCount;

    //Mapping of the voters for every election
    mapping(uint32 => mapping(address => Voter)) public voters;

    //A nonce to assign the id to the elections
    uint32 electionNonce = 1;
    uint32 electionCount = 1;

    event ElectionCreated(
        bytes32 name,
        string description,
        uint256 electionId,
        bool requireRegitration,
        uint32 startElection,
        uint32 endElection,
        uint32 startRegistration,
        uint32 endRegistration
    );
    event Voted(address voter, bytes32 _candidate, uint256 _weight);

    //A function that creates an election structure.
    function createElection(
        bytes32 _name, //name of the election
        string memory _description, //a description
        bool _requireRegitration, //true if is required a registration
        bytes32[] memory _candidates, //the list of proposals
        uint32 _startElection, //date of the begin of the election period
        uint32 _endElection, //date of the end of the election period
        uint32 _startRegistration, //date of the begin of the registration period
        uint32 _endRegistration //date of the end of the registration period
    ) public {
        require(_candidates.length > 0, "There should be atleast 1 candidate.");
        uint32 electionId = electionNonce;
        require(
            elections[electionId].id == 0,
            "This election already exists, please select other name"
        );

        elections[electionId] = Election(
            _name,
            _description,
            electionId,
            _requireRegitration,
            _startElection,
            _endElection,
            _startRegistration,
            _endRegistration
        );
        electionsNames[_name] = electionId;
        currentElections.push(electionId);

        for (uint256 i = 0; i < _candidates.length; i++) {
            addCandidate(electionId, _candidates[i]);
        }
        emit ElectionCreated(
            _name,
            _description,
            electionId,
            _requireRegitration,
            _startElection,
            _endElection,
            _startRegistration,
            _endRegistration
        );
        electionNonce++;
        electionCount++;
    }

    //Private function to add a candidate
    function addCandidate(uint32 _electionId, bytes32 _candidateName) private {
        candidates[_electionId][_candidateName] = Candidate(
            _candidateName,
            0,
            true
        );
        candidatesList[_electionId].push(_candidateName);
        candidatesCount[_electionId]++;
    }

    //Public vote function for voting a candidate
    function vote(
        uint32 _electionId, //the election in which vote
        bytes32 _candidate, //the proposal to vote
        uint256 _weight //"how many times" vote
    ) public {
        require(elections[_electionId].id != 0, "The election doesn't exist");
        require(
            elections[_electionId].startElection <= block.timestamp,
            "The election has not started yet"
        );
        require(
            elections[_electionId].endElection >= block.timestamp,
            "Election already ended"
        );
        address voter = msg.sender;
        if (elections[_electionId].requireRegitration) {
            require(
                voters[_electionId][voter].weight != 0,
                "Voter hasn't registered"
            );
        } else {
            voters[_electionId][voter].weight = 1;
        }
        require(
            _weight <= voters[_electionId][voter].weight,
            "Voter do not have so many votes"
        );
        require(!voters[_electionId][voter].voted, "Voter has already Voted!");
        require(
            candidates[_electionId][_candidate].votable,
            "Invalid candidate to Vote!"
        );

        //update the vote count of the voted proposal
        candidates[_electionId][_candidate].voteCount =
            candidates[_electionId][_candidate].voteCount +
            _weight;

        //subtract the votes to the voter Structure
        voters[_electionId][voter].weight =
            voters[_electionId][voter].weight -
            _weight;

        //set the variable voted to true if the voter does not have other votes
        if (voters[_electionId][voter].weight == 0) {
            voters[_electionId][voter].voted = true;
        }

        emit Voted(voter, _candidate, _weight);
    }

    //get list of elections
    function getCurrentElections() public view returns (bytes32[] memory) {
        bytes32[] memory result = new bytes32[](currentElections.length);
        for (uint32 i = 0; i < currentElections.length; i++) {
            result[i] = elections[currentElections[i]].name;
        }
        return result;
    }

    //get list of proposal of an election
    function getCandidatesForElection(uint32 _electionId)
        public
        view
        returns (bytes32[] memory)
    {
        return candidatesList[_electionId];
    }

    //register for an election
    function register(uint32 _electionId) public {
        require(
            elections[_electionId].startRegistration <= block.timestamp,
            "Registration not open"
        );
        require(
            elections[_electionId].endRegistration >= block.timestamp,
            "Registration closed"
        );
        voters[_electionId][msg.sender].weight = 1;
    }
}
