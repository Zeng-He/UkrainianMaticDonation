// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

enum WalletConfirmationStatus {
    AWAITING_ADDRESS_WHITELIST,
    AWAITING_ADDRESS_CONFIRMATION,
    ADDRESS_CONFIRMED 
}

contract MultiSigWalletWhitelist {

    // Safety first :)
    using SafeMath for uint256;

    event ConfirmWallet(address indexed owner, address indexed wallet);
    event RevokeConfirmation(address indexed owner, address indexed wallet);
    event AcceptWalletConfirmation(address indexed owner);
    // event RenounceWalletConfirmation(address indexed owner); Not used :(

    //address[] public signers; dont want this
    mapping(address => bool) public isSigner;
    uint public numConfirmationsRequired;

    // mapping from wallet => owner => bool
    // holds signers signatures
    mapping(address => mapping(address => bool)) public signs;

    // mapping from wallet => bool
    // holds signatures count
    mapping(address => uint) public signCount;

    // Candidate Address where funds are collected, needs owner confirmation
    address payable public destinationWalletCandidate = payable(0);

    // Confirmed Address where funds are collected
    address payable public destinationWalletConfirmed = payable(0);

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

    modifier statusIs(WalletConfirmationStatus _status) {
        require(getStatus() == _status, "this function cannot be called at this time");
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
        statusIs(WalletConfirmationStatus.AWAITING_ADDRESS_WHITELIST)
    {
        
        signs[wallet][msg.sender] = true;
        signCount[wallet] = signCount[wallet].add(1);

        emit ConfirmWallet(msg.sender, wallet);
        if (signCount[wallet] == numConfirmationsRequired 
        && getStatus() == WalletConfirmationStatus.AWAITING_ADDRESS_WHITELIST) {
            destinationWalletCandidate = payable(wallet);
        }
    }

    /**
     * signers can revoke sign even if an address collect all the necessary signs
     */
    function revokeSign(address wallet)
        public
        onlySigners
        notRevokedAlready(wallet)
        statusIs(WalletConfirmationStatus.AWAITING_ADDRESS_WHITELIST)
        statusIs(WalletConfirmationStatus.AWAITING_ADDRESS_CONFIRMATION)
    {
        signs[wallet][msg.sender] = false;
        signCount[wallet] = signCount[wallet].sub(1);
        emit RevokeConfirmation(msg.sender, wallet);

        if (signCount[wallet] < numConfirmationsRequired 
        && getStatus() == WalletConfirmationStatus.AWAITING_ADDRESS_CONFIRMATION) {
            destinationWalletCandidate = payable(0);
        }
    }

    /**
     *  Once an address is confirmed and accepted it cannot be unsigned nor unaccepted
     */
    function acceptWalletConfirmation()
        public
        statusIs(WalletConfirmationStatus.AWAITING_ADDRESS_CONFIRMATION)
    {
        require(address(msg.sender) == destinationWalletCandidate, "You are not the wallet owner");
        destinationWalletConfirmed = payable(msg.sender);
        emit AcceptWalletConfirmation(msg.sender);
    }
    
    /** We could add the possibility to the owner to renonunce
     *  but that could bring unexpected behavior
     */
    // function renounceWalletConfirmation()
    //     public
    //     statusIs(WalletConfirmationStatus.ADDRESS_CONFIRMED)
    // {
    //     require(address(msg.sender) == destinationWalletConfirmed, "You are not the wallet owner");
    //     destinationWalletConfirmed = payable(0);
    //     emit RenounceWalletConfirmation(msg.sender);
    // }

    function getStatus() public view returns(WalletConfirmationStatus){
        if (destinationWalletCandidate == address(0)) 
            return WalletConfirmationStatus.AWAITING_ADDRESS_WHITELIST;
        else if (destinationWalletConfirmed == address(0))
            return WalletConfirmationStatus.AWAITING_ADDRESS_CONFIRMATION;
        else return WalletConfirmationStatus.ADDRESS_CONFIRMED;
    }

}