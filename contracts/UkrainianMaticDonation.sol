//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./StateMachine.sol";
import "./DonorTracker.sol";
import "./MultiSigWalletWhitelist.sol";
import "./MultiSigMaxCap.sol";
import "./MultiSigTimeLimit.sol";

contract UkrainianMaticDonation is Ownable, ReentrancyGuard, StateMachine, DonorTracker {
    //uint private _creationTime = block.timestamp; Not using this anymore

    MultiSigWalletWhitelist private _multisigWallet;
    MultiSigMaxCap private _multiSigMaxCap;
    MultiSigTimeLimit private _multiSigTimeLimit;

    /**
     * Event for dontation withdrawal
     * @param beneficiary who receive the donation
     * @param amount total amount of tokens donated
     */
    event DontationWithdrawal(address indexed beneficiary, uint256 amount);

    constructor(MultiSigWalletWhitelist multiSigWallet, MultiSigMaxCap multiSigMaxCap, MultiSigTimeLimit multiSigTimeLimit) 
    StateMachine(multiSigWallet, multiSigMaxCap, multiSigTimeLimit)
    {
        _multisigWallet = multiSigWallet;
        _multiSigMaxCap = multiSigMaxCap;
        _multiSigTimeLimit = multiSigTimeLimit;
    }

    /**
     * @dev receive function
     * Note that it could be necessary to add an extra function to use
     * the nonReentrant modifier
     */
    receive () external 
        nonReentrant 
        statusIs(DonationStatus.RECEIVING_PAYMENTS) 
        isMaxCapReached(address(this).balance)
        isTimeLimitReached()
        payable
    {
        registerDonation();
        if(isFundraisingDone()) { //timelimit or maxcap
            _deliverTokens();
        }
    }

    /**
     * @dev fallback function
     * Note that it could be necessary to add an extra function to use
     * the nonReentrant modifier
     */
    fallback() external 
        nonReentrant 
        statusIs(DonationStatus.RECEIVING_PAYMENTS) 
        isMaxCapReached(address(this).balance)
        isTimeLimitReached()
        payable
    {
        // Probably just call receive.. but have to check the nonReentrant validation
        registerDonation();
        if(isFundraisingDone()) { //timelimit or maxcap
            _deliverTokens();
        }
    }

    /** Used to update status through state machine */
    function checkStatus() public {
        super.checkStatus(address(this).balance);
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address) {
        return _multisigWallet.destinationWalletConfirmed();
    }

    /**
     * @return the amount of donations raised.
     */
    function donationsRaised() public view returns (uint256) {
        return address(this).balance;
    }

    /*
    * Donation withdrawal function
    * Allows donors to withdraw all their funds
    * Reentrancy and Cross-Reentrancy safe :)
    */
    function withdrawMyFunds() isDonor nonReentrant public {
        uint256 amount = liquidateDonorFunds(msg.sender);
        payable(msg.sender).transfer(amount);
        emit DontationWithdrawal(msg.sender, amount);

        //Destroy the contract once the fundraising is done and no money is left
        if(isFundraisingDone() && address(this).balance == 0) {
            /*Hardwired to*/selfdestruct(payable(0)); // yeah! burning bby!.. I guess
        }
    }

    /**
    * Allows donors to check their funds
    */
    function getMyFunds() public isDonor view returns(uint256) {
        return getDonorAmount(msg.sender);
    }

    /**
    * Emergency stop in case that something goes wrong
    */
    function emergencyStop() onlyOwner statusIs(DonationStatus.RECEIVING_PAYMENTS) public {
        setStatus(DonationStatus.EMERGENCY_STOP);
        renounceOwnership(); // :(
    }

    /**
     * @dev Source of funds.
     * Call this for token delivery when the fundraising is completed
     * Deliver all the funds to the beneficiary address.
     */
    function _deliverTokens() private {
        require(wallet() != address(0), "The destination wallet is not set"); // Should not happen
        emit DontationWithdrawal(wallet(), address(this).balance);
        /*Hardwired to*/selfdestruct(payable(wallet()));
    }
}