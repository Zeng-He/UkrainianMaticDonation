// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWalletWhitelist {
    event ConfirmWallet(address indexed owner, address indexed wallet);
    event RevokeConfirmation(address indexed owner, address indexed wallet);
    event AcceptWalletConfirmation(address indexed owner);

    //address[] public signers; dont want this
    mapping(address => bool) public isSigner;
    uint public numConfirmationsRequired;

    // mapping from wallet => owner => bool
    // holds signers signatures
    mapping(address => mapping(address => bool)) public signs;

    // mapping from wallet => owner => bool
    //holds signers signatures
    mapping(address => uint) public signCount;

    // Candidate Address where funds are collected, needs owner confirmation
    address payable private _destinationWalletCandidate;

    // Confirmed Address where funds are collected
    address payable private _destinationWalletConfirmed;

    modifier onlySigners() {
        require(isSigner[msg.sender], "not a signer");
        _;
    }

    modifier notSignedAlready(address wallet) {
        require(!signs[wallet][msg.sender], "you already signed");
        _;
    }

    modifier notRevokedAlready(address wallet) {
        require(signs[wallet][msg.sender], "you already revoked");
        _;
    }

    constructor(address[] memory _signers, uint _numConfirmationsRequired) {
        require(_signers.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _signers.length,
            "invalid number of required confirmations"
        );

        for (uint i = 0; i < _signers.length; i++) {
            address owner = _signers[i];

            require(owner != address(0), "invalid owner");
            require(!isSigner[owner], "owner not unique");

            isSigner[owner] = true;
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    function signWallet(address wallet)
        public
        onlySigners
        notSignedAlready(wallet)
        /* check status, wallet is not confirmed yet*/
    {
        
        signs[wallet][msg.sender] = true;
        signCount[wallet] += 1; // add safe math

        emit ConfirmWallet(msg.sender, wallet);
        //check for sign count and change state
    }

    function revokeSign(address wallet)
        public
        onlySigners
        notRevokedAlready(wallet)
        /* check status, wallet is not confirmed yet*/
    {
        
        signs[wallet][msg.sender] = false;
        signCount[wallet] -= 1; // add safe math

        emit RevokeConfirmation(msg.sender, wallet);(msg.sender, wallet);
        //check for sign count and change state
    }

    function acceptWalletConfirmation()
        public
        /* check status, wallet is confirmed */
    {
        require(address(msg.sender) == _destinationWalletCandidate, "You are not the wallet owner");
        emit AcceptWalletConfirmation(msg.sender);
        // change state
        // delete signers or something. for that I will need the signers array
    }

}