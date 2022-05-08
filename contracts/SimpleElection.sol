// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleElection {
    //Structure of an election
    struct Election {
        bytes32 name;
        string description;
        uint256 id;
        bool requireRegitration;
        uint32 startElection;
        uint32 endElection;
        uint32 startRegistration;
        uint32 endRegistration;
    }

    bytes32[] currentElections; //list of current elections

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
    mapping(bytes32 => Election) elections;

    //Mappings of the proposals for every election
    mapping(bytes32 => mapping(bytes32 => Candidate)) public candidates;

    //List of the proposal for every election
    mapping(bytes32 => bytes32[]) public candidatesList;

    //Number of proposal for every election
    mapping(bytes32 => uint256) public candidatesCount;

    //Mapping of the voters for every election
    mapping(bytes32 => mapping(address => Voter)) public voters;

    //A nonce to assign the id to the elections
    uint256 electionNonce = 1;

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
        require(
            elections[_name].id == 0,
            "This election already exists, please select other name"
        );

        elections[_name] = Election(
            _name,
            _description,
            electionNonce,
            _requireRegitration,
            _startElection,
            _endElection,
            _startRegistration,
            _endRegistration
        );
        currentElections.push(_name);

        for (uint256 i = 0; i < _candidates.length; i++) {
            addCandidate(_name, _candidates[i]);
        }
        emit ElectionCreated(
            _name,
            _description,
            electionNonce,
            _requireRegitration,
            _startElection,
            _endElection,
            _startRegistration,
            _endRegistration
        );
        electionNonce++;
    }

    //Private function to add a candidate
    function addCandidate(bytes32 _electioName, bytes32 _candidateName)
        private
    {
        candidates[_electioName][_candidateName] = Candidate(
            _candidateName,
            0,
            true
        );
        candidatesList[_electioName].push(_candidateName);
        candidatesCount[_electioName]++;
    }

    //Public vote function for voting a candidate
    function vote(
        bytes32 _electionName, //the election in which vote
        bytes32 _candidate, //the proposal to vote
        uint256 _weight //"how many times" vote
    ) public {
        require(elections[_electionName].id != 0, "The election doesn't exist");
        require(
            elections[_electionName].startElection <= block.timestamp,
            "The election has not started yet"
        );
        require(
            elections[_electionName].endElection >= block.timestamp,
            "Election already ended"
        );
        address voter = msg.sender;
        if (elections[_electionName].requireRegitration) {
            require(
                voters[_electionName][voter].weight != 0,
                "Voter hasn't registered"
            );
        } else {
            voters[_electionName][voter].weight = 1;
        }
        require(
            _weight <= voters[_electionName][voter].weight,
            "Voter do not have so many votes"
        );
        require(
            !voters[_electionName][voter].voted,
            "Voter has already Voted!"
        );
        require(
            candidates[_electionName][_candidate].votable,
            "Invalid candidate to Vote!"
        );

        //update the vote count of the voted proposal
        candidates[_electionName][_candidate].voteCount =
            candidates[_electionName][_candidate].voteCount +
            _weight;

        //subtract the votes to the voter Structure
        voters[_electionName][voter].weight =
            voters[_electionName][voter].weight -
            _weight;

        //set the variable voted to true if the voter does not have other votes
        if (voters[_electionName][voter].weight == 0) {
            voters[_electionName][voter].voted = true;
        }

        emit Voted(voter, _candidate, _weight);
    }

    //get list of elections
    function getCurrentElections() public view returns (bytes32[] memory) {
        return currentElections;
    }

    //get list of proposal of an election
    function getCandidatesForElection(bytes32 _electionName)
        public
        view
        returns (bytes32[] memory)
    {
        return candidatesList[_electionName];
    }

    //register for an election
    function register(bytes32 _electionName) public {
        require(
            elections[_electionName].startRegistration <= block.timestamp,
            "Registration not open"
        );
        require(
            elections[_electionName].endRegistration >= block.timestamp,
            "Registration closed"
        );
        voters[_electionName][msg.sender].weight = 1;
    }
}
