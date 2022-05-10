// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleElection {
    //Structure of an election
    struct Election {
        bytes32 name;
        string description;
        bool requireRegistration;
        uint32 id;
        uint32 startElection;
        uint32 endElection;
        uint32 startRegistration;
        uint32 endRegistration;
    }

    mapping(bytes32 => uint32) electionsIds;

    uint32[] currentElections; //list of current elections

    //Structure of candidate standing in an election
    struct Candidate {
        bytes32 name; //name of the proposal
        uint256 voteCount; //votes received
    }

    //Structure of a voter
    struct Voter {
        uint256 weight; // weight is accumulated by delegation
        bool voted; // if true, that person already voted
    }

    //Mapping of the elections
    mapping(uint32 => Election) elections;

    //Mappings of the proposals for every election
    mapping(uint32 => mapping(uint8 => Candidate)) public candidates;

    mapping(uint32 => mapping(bytes32 => uint8)) public candidatesIds;

    //List of the proposal for every election
    mapping(uint32 => uint8[]) public candidatesList;

    //Mapping of the voters for every election
    mapping(uint32 => mapping(address => Voter)) public voters;

    uint32 electionNonce;
    uint32 electionCount;

    event ElectionCreated(
        bytes32 name,
        string description,
        uint256 electionId,
        bool requireRegistration,
        uint32 startElection,
        uint32 endElection,
        uint32 startRegistration,
        uint32 endRegistration
    );
    event Voted(
        uint32 electionId,
        address voter,
        uint8 candidateId,
        uint256 weight
    );
    event Delegate(address delegator, address delegate, uint256 weight);

    constructor() {
        electionNonce = 1;
        electionCount = 1;
    }

    //A function that creates an election structure.
    function createElection(
        bytes32 _name, //name of the election
        string memory _description, //a description
        bool _requireRegistration, //true if is required a registration
        bytes32[] memory _candidates, //the list of proposals
        uint32 _startElection, //date of the begin of the election period
        uint32 _endElection, //date of the end of the election period
        uint32 _startRegistration, //date of the begin of the registration period
        uint32 _endRegistration //date of the end of the registration period
    ) public {
        require(_candidates.length > 0, "There should be atleast 1 candidate.");
        require(
            !electionExists(_name),
            "This election already exists, please select other name"
        );
        uint32 electionId = electionNonce;
        elections[electionId] = Election(
            _name,
            _description,
            _requireRegistration,
            electionId,
            _startElection,
            _endElection,
            _startRegistration,
            _endRegistration
        );
        electionsIds[_name] = electionId;
        currentElections.push(electionId);

        for (uint8 i = 0; i < _candidates.length; i++) {
            addCandidate(electionId, _candidates[i], i + 1);
        }
        emit ElectionCreated(
            _name,
            _description,
            electionId,
            _requireRegistration,
            _startElection,
            _endElection,
            _startRegistration,
            _endRegistration
        );
        electionNonce++;
        electionCount++;
    }

    //Private function to add a candidate
    function addCandidate(
        uint32 _electionId,
        bytes32 _candidateName,
        uint8 _candidateId
    ) private {
        candidates[_electionId][_candidateId] = Candidate(_candidateName, 0);
        candidatesIds[_electionId][_candidateName] = _candidateId;
        candidatesList[_electionId].push(_candidateId);
    }

    //Private vote function for voting a candidate
    function voterVote(
        uint32 _electionId, //the election in which vote
        address _voter, //the voter
        uint8 _candidateId, //the proposal to vote
        uint256 _weight //"how many times" vote
    ) private {
        require(electionExists(_electionId), "The election doesn't exist");
        require(checkElectionOpen(_electionId), "The election is closed");
        if (elections[_electionId].requireRegistration) {
            require(
                voterHasRegistred(_electionId, _voter),
                "Voter hasn't registered"
            );
        } else {
            registerVoter(_electionId, _voter);
        }
        require(
            !voterHasVoted(_electionId, _voter),
            "Voter has already Voted!"
        );
        require(
            _weight <= voters[_electionId][_voter].weight,
            "Voter do not have so many votes"
        );
        require(
            candidateExists(_electionId, _candidateId),
            "Invalid candidate to Vote!"
        );

        //update the vote count of the voted proposal
        candidates[_electionId][_candidateId].voteCount =
            candidates[_electionId][_candidateId].voteCount +
            _weight;

        //subtract the votes to the voter Structure
        voters[_electionId][_voter].weight =
            voters[_electionId][_voter].weight -
            _weight;

        //set the variable voted to true if the voter does not have other votes
        if (voters[_electionId][_voter].weight == 0) {
            voters[_electionId][_voter].voted = true;
        }

        emit Voted(_electionId, _voter, _candidateId, _weight);
    }

    //Public function to vote
    function vote(
        uint32 _electionId, //the election in which vote
        uint8 _candidateId, //the proposal to vote
        uint256 _weight //"how many times" vote
    ) public {
        voterVote(_electionId, msg.sender, _candidateId, _weight);
    }

    //register for an election
    function registerVoter(uint32 _electionId, address voter) private {
        voters[_electionId][voter].weight = 1;
    }

    function register(uint32 _electionId, address _voter) public {
        require(checkRegistrationOpen(_electionId), "Registration not open");
        registerVoter(_electionId, _voter);
    }

    function delegateVote(
        uint32 _electionId,
        address _delegate,
        uint256 _weight
    ) public {
        require(electionExists(_electionId), "The election doesn't exist");
        address delegator = msg.sender;
        require(
            _weight <= voters[_electionId][delegator].weight,
            "Voter do not have so many votes"
        );
        if (!voterHasRegistred(_electionId, _delegate)) {
            register(_electionId, _delegate);
        }
        voters[_electionId][delegator].weight -= _weight;
        if (voters[_electionId][delegator].weight == 0) {
            voters[_electionId][delegator].voted = true;
        }
        voters[_electionId][_delegate].weight += _weight;
        emit Delegate(delegator, _delegate, _weight);
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
        require(electionExists(_electionId), "The election doesn't exist");
        bytes32[] memory result = new bytes32[](
            candidatesList[_electionId].length
        );
        for (uint8 i = 0; i < candidatesList[_electionId].length; i++)
            result[i] = candidates[_electionId][candidatesList[_electionId][i]]
                .name;
        return result;
    }

    function checkRegistrationOpen(uint32 _electionId)
        public
        view
        returns (bool)
    {
        return ((elections[_electionId].startRegistration <= block.timestamp) &&
            (elections[_electionId].endRegistration >= block.timestamp));
    }

    function checkElectionOpen(uint32 _electionId) public view returns (bool) {
        return ((elections[_electionId].startElection <= block.timestamp) &&
            (elections[_electionId].endElection >= block.timestamp));
    }

    function voterHasRegistred(uint32 _electionId, address voter)
        public
        view
        returns (bool)
    {
        return ((voters[_electionId][voter].weight != 0) ||
            (voters[_electionId][voter].voted == true));
    }

    function voterHasVoted(uint32 _electionId, address voter)
        public
        view
        returns (bool)
    {
        return voters[_electionId][voter].voted;
    }

    function electionExists(bytes32 _electionName) public view returns (bool) {
        return electionsIds[_electionName] != 0;
    }

    function electionExists(uint32 _electionId) public view returns (bool) {
        return elections[_electionId].id != 0;
    }

    function candidateExists(uint32 _electionId, uint8 _candidateId)
        public
        view
        returns (bool)
    {
        return (candidates[_electionId][_candidateId].name != 0);
    }

    function getCandidateId(uint32 _electionId, bytes32 _candidatename)
        public
        view
        returns (uint8)
    {
        return candidatesIds[_electionId][_candidatename];
    }
}
