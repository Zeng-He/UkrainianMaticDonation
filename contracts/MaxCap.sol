// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract MultiSigMacCap {

    // Safety first :)
    using SafeMath for uint256;

    event ConfirmValue(address indexed owner, address indexed wallet);
    event RevokeConfirmation(address indexed owner, address indexed wallet);

    mapping(address => bool) public isSigner;
    uint public numConfirmationsRequired;

    // mapping from value => owner => bool
    // holds signers signatures
    mapping(uint256 => mapping(address => bool)) public signs;

    // mapping from value => bool
    // holds signatures count
    mapping(uint256 => uint) public signCount;

    // max cap selected
    uint256 public selectedValue = 0;

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


    constructor(address[] memory _signers, uint _numConfirmationsRequired, uint256 initialValue) {
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
        selectedValue = initialValue;
    }

    /** CONTINUE ADDING FUNCTIONS FROM MULTISIGWALLET */

}