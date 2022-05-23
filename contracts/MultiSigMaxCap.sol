// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

enum MaxCapConfirmationStatus {
    VALUE_NOT_CONFIRMED,
    VALUE_CONFIRMED 
}

contract MultiSigMaxCap {

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
    uint256 public maxCap = 0;

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

    modifier statusIs(MaxCapConfirmationStatus _status) {
        require(getStatus() == _status, "this function cannot be called at this time");
        _;
    }

    constructor(address[] memory _signers, uint _numConfirmationsRequired, uint256 initialValue) {
        require(_signers.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 && _numConfirmationsRequired <= _signers.length,
            "invalid number of required confirmations"
        );

        for (uint i = 0; i < _signers.length; i++) {
            address owner = _signers[i];

            require(owner != address(0), "invalid owner");
            require(!isSigner[owner], "owner not unique");

            isSigner[owner] = true;
        }
        numConfirmationsRequired = _numConfirmationsRequired;
        maxCap = initialValue;
    }

    function signValue(uint256 proposedMaxCap)
        public
        onlySigners
        notSignedAlready(proposedMaxCap)
        statusIs(MaxCapConfirmationStatus.VALUE_NOT_CONFIRMED)
    {
        signs[proposedMaxCap][msg.sender] = true;
        signCount[proposedMaxCap] = signCount[proposedMaxCap].add(1);

        emit ConfirmedValue(msg.sender, proposedMaxCap);

        if (signCount[proposedMaxCap] == numConfirmationsRequired 
        && getStatus() == MaxCapConfirmationStatus.VALUE_NOT_CONFIRMED) {
            maxCap = proposedMaxCap;
        }
    }

    /**
     * signers can revoke sign only if the value is not confirmed
     */
    function revokeSign(uint256 proposedMaxCap)
        public
        onlySigners
        notRevokedAlready(proposedMaxCap)
        statusIs(MaxCapConfirmationStatus.VALUE_NOT_CONFIRMED)
    {
        signs[proposedMaxCap][msg.sender] = false;
        signCount[proposedMaxCap] = signCount[proposedMaxCap].sub(1);
        emit RevokedConfirmation(msg.sender, proposedMaxCap);
    }

    function getStatus() public view returns(MaxCapConfirmationStatus) {
        if (maxCap == 0) 
            return MaxCapConfirmationStatus.VALUE_NOT_CONFIRMED;
        else 
            return MaxCapConfirmationStatus.VALUE_CONFIRMED;
    }

    function isMaxCapReached(uint256 balance) public 
        statusIs(MaxCapConfirmationStatus.VALUE_CONFIRMED) 
        view returns(bool) 
    {
        return balance >= maxCap;
    }
}