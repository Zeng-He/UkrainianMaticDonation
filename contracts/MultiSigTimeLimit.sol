// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

enum TimeLimitConfirmationStatus {
    VALUE_NOT_CONFIRMED,
    VALUE_CONFIRMED 
}

/**
    TimeLimit Multi Signature contract
    This contract is used for controlling the life-span of a contract
    To set a time-limit value do not provide relative amount eg: 1 week
    Instead send the absolute timestamp that block.timestamp 
    should reach to finish contract execution
 */
contract MultiSigTimeLimit {

    // Safety first :)
    using SafeMath for uint256;

    event ConfirmedValue(address indexed signer, uint256 proposedValue);
    event RevokedConfirmation(address indexed signer, uint256 proposedValue);

    mapping(address => bool) public isSigner;
    uint public numConfirmationsRequired;

    // mapping from value => owner => bool
    // holds signers signatures
    mapping(uint256 => mapping(address => bool)) public signs;

    // mapping from value => bool
    // holds signatures count
    mapping(uint256 => uint) public signCount;

    // max cap selected
    uint256 public timeLimit = 0;

    modifier onlySigners() {
        require(isSigner[msg.sender], "not a signer");
        _;
    }

    modifier notSignedAlready(uint256 value) {
        require(!signs[value][msg.sender], "you already signed");
        _;
    }

    modifier notRevokedAlready(uint256 value) {
        require(signs[value][msg.sender], "you already revoked");
        _;
    }

    modifier statusIs(TimeLimitConfirmationStatus _status) {
        require(getStatus() == _status, "this function cannot be called at this time");
        _;
    }

    constructor(address[] memory _signers, uint _numConfirmationsRequired, uint256 initialValue) {
        require(_signers.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 && _numConfirmationsRequired <= _signers.length,
            "invalid number of required confirmations"
        );
        require(initialValue > block.timestamp, "Invalid initial value");

        for (uint i = 0; i < _signers.length; i++) {
            address owner = _signers[i];

            require(owner != address(0), "invalid owner");
            require(!isSigner[owner], "owner not unique");

            isSigner[owner] = true;
        }
        numConfirmationsRequired = _numConfirmationsRequired;
        timeLimit = initialValue;
    }

    function signValue(uint256 proposedTimeLimit)
        public
        onlySigners
        notSignedAlready(proposedTimeLimit)
        statusIs(TimeLimitConfirmationStatus.VALUE_NOT_CONFIRMED)
    {
        require(proposedTimeLimit > block.timestamp, "Invalid initial value");
        signs[proposedTimeLimit][msg.sender] = true;
        signCount[proposedTimeLimit] = signCount[proposedTimeLimit].add(1);

        emit ConfirmedValue(msg.sender, proposedTimeLimit);

        if (signCount[proposedTimeLimit] == numConfirmationsRequired 
        && getStatus() == TimeLimitConfirmationStatus.VALUE_NOT_CONFIRMED) {
            timeLimit = proposedTimeLimit;
        }
    }

    function revokeSign(uint256 proposedTimeLimit)
        public
        onlySigners
        notRevokedAlready(proposedTimeLimit)
    {
        signs[proposedTimeLimit][msg.sender] = false;
        signCount[proposedTimeLimit] = signCount[proposedTimeLimit].sub(1);
        emit RevokedConfirmation(msg.sender, proposedTimeLimit);
    }

    function getStatus() public view returns(TimeLimitConfirmationStatus) {
        if (timeLimit == 0) 
            return TimeLimitConfirmationStatus.VALUE_NOT_CONFIRMED;
        else 
            return TimeLimitConfirmationStatus.VALUE_CONFIRMED;
    }

    function isTimeLimitReached() public 
        statusIs(TimeLimitConfirmationStatus.VALUE_CONFIRMED) 
        view returns(bool) 
    {
        return block.timestamp >= timeLimit;
    }
}