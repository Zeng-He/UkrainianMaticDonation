// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWalletWhitelist {
    event ConfirmWallet(address indexed owner);
    event RevokeConfirmation(address indexed owner);
    event AcceptWalletConfirmation(address indexed owner);

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationsRequired;

    // mapping from wallet => owner => bool
    mapping(address => mapping(address => bool)) public isConfirmed;

    address[] private _wallets;

    // Confirmed Address where funds are collected
    address payable private _confirmedDestinationWallet;

    modifier onlyOwners() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier walletExists(address wallet) {
        //require(_wallets., "wallet does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

}