// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GroupMentorship {

    struct Session {
        uint256 sessionId;
        address mentor;
        string topic;
        uint256 pricePerParticipant;
        uint256 maxParticipants;
        uint256 participantCount;
        uint256 startTime;
        mapping(address => bool) participants;
    }

    uint256 public sessionCounter;
    mapping(uint256 => Session) public sessions;

    event SessionCreated(
        uint256 sessionId,
        address mentor,
        string topic,
        uint256 pricePerParticipant,
        uint256 maxParticipants,
        uint256 startTime
    );

    event ParticipantJoined(uint256 sessionId, address participant);

    modifier onlyMentor(uint256 sessionId) {
        require(msg.sender == sessions[sessionId].mentor, "Only mentor can call this function");
        _;
    }

    modifier sessionExists(uint256 sessionId) {
        require(sessions[sessionId].startTime != 0, "Session does not exist");
        _;
    }

    function createSession(
        string memory topic,
        uint256 pricePerParticipant,
        uint256 maxParticipants,
        uint256 startTime
    ) public {
        require(startTime > block.timestamp, "Start time must be in the future");
        require(maxParticipants > 0, "Maximum participants must be greater than zero");

        sessionCounter++;
        Session storage newSession = sessions[sessionCounter];
        newSession.sessionId = sessionCounter;
        newSession.mentor = msg.sender;
        newSession.topic = topic;
        newSession.pricePerParticipant = pricePerParticipant;
        newSession.maxParticipants = maxParticipants;
        newSession.startTime = startTime;

        emit SessionCreated(
            sessionCounter,
            msg.sender,
            topic,
            pricePerParticipant,
            maxParticipants,
            startTime
        );
    }

    function joinSession(uint256 sessionId) public payable sessionExists(sessionId) {
        Session storage session = sessions[sessionId];
        require(msg.value == session.pricePerParticipant, "Incorrect payment amount");
        require(session.participantCount < session.maxParticipants, "Session is full");
        require(!session.participants[msg.sender], "Already joined this session");
        require(block.timestamp < session.startTime, "Session has already started");

        session.participants[msg.sender] = true;
        session.participantCount++;

        emit ParticipantJoined(sessionId, msg.sender);
    }

    function withdrawFunds(uint256 sessionId) public sessionExists(sessionId) onlyMentor(sessionId) {
        Session storage session = sessions[sessionId];
        require(block.timestamp > session.startTime, "Session not yet concluded");

        uint256 totalFunds = session.pricePerParticipant * session.participantCount;
        payable(session.mentor).transfer(totalFunds);
    }
}
