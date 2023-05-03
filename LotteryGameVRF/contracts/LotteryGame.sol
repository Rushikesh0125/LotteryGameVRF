// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract LotteryGame is VRFConsumerBase, Ownable{

    uint256 public gameId;
    bool public gameStarted;
    address[] public players;
    uint public maxPlayers;
    uint256 public entryFee;

    //LINK fee for chainlink purpose
    uint256 public fee;
    bytes32 public keyHash;

    event gameCreated(uint256 gameId, uint256 maxPlayers, uint256 entryFee);
    event playerJoined(address player, uint256 gameId);
    event gameEnded(uint256 gameId, address winner, bytes32 reqId);

    constructor(address vrfCoordAdd, address linkToken, bytes32 vrfkeyHash, uint256 vrfFee) VRFConsumerBase(vrfCoordAdd, linkToken){
        keyHash = vrfkeyHash;
        fee = vrfFee;
        gameStarted = false;
    }

    function startGame(uint256 _maxPlayers, uint256 _entryFee) public onlyOwner {
        require(!gameStarted, "a game is alread running");

        delete players;

        maxPlayers = _maxPlayers;
        entryFee = _entryFee;
        gameId += 1;
        gameStarted = true;

        emit gameCreated(gameId, maxPlayers, entryFee);
    }

    function joinGame() public payable{
        require(gameStarted, "no game to join, game hasn't  started");
        require(players.length < maxPlayers, "wait for another game, this one is full");
        require(msg.value == entryFee, "please pay to get into the game");

        players.push(msg.sender);
        emit playerJoined(msg.sender, gameId);

        if(players.length == maxPlayers){
            getRandomWinner();
        }
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual override{

        uint256 winnerInd = randomness % players.length;

        address winner = players[winnerInd];

        (bool sent,) = winner.call{value : address(this).balance}("");

        require(sent, "failed to send winnings");

        emit gameEnded(gameId, winner, requestId);

        gameStarted = false;
    }


    function getRandomWinner() private returns(bytes32 requestId){
        require(LINK.balanceOf(address(this)) >= fee, "not enough link");

        return requestRandomness(keyHash, fee);
    }

    receive() external payable{}

    fallback() external payable{}
}