//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./DonationStatusTracker.sol";
import "./DonorTracker.sol";

contract UkrainianMaticDonation is Ownable, ReentrancyGuard, DonationStatusTracker, DonorTracker {
    // TODO Add change max cap function (multisig) (event) - new contract
    // TODO Add change timelimit function (multisig) (event) - new contract
    // TODO Add whitelist wallet function (multisig) (event) - new contract
    // TODO determine how timelimit can be executed - new contract - check StateMachine.sol
    // TODO Add some way to check and update status related to external contracts
    //      it could be public function in the DonationStatusTracker contract that..
    //      checks ALL statuses calling the other contracts

    // Address where funds are collected
    address payable private _destinationWallet; // this could go in a different contract

    // Owners required to sign changes
    // mapping (address => bool) private _signers; // this could go in a different contract

    //Contact Balance.. maybe this not needed. address(this).balance is the same
    //uint private _balance;

    uint private _creationTime = block.timestamp;

    /**
     * Event for dontation withdrawal
     * @param beneficiary who receive the donation
     * @param amount total amount of tokens donated
     */
    event DontationWithdrawal(address indexed beneficiary, uint256 amount);

    // TODO receive multisig contracts to read different values
    constructor() 
    {
        
    }

    /**
     * @dev receive function
     * Note that it could be necessary to add an extra function to use
     * the nonReentrant modifier
     */
    receive () external nonReentrant statusIs(DonationStatus.RECEIVING_PAYMENTS) payable {
        // TODO Move this to StatusTracker and convert the ifs to modifiers
        // if(TimeLimit.isTimeLimitReached(_creationTime)) {
        //     setStatus(DonationStatus.TIMELIMIT_REACHED);
        //     //revert("Time limit reached!"); can't revert as this will undo the status change
        // }
        // if(MaxCap.isMaxCapReached(address(this).balance)) {
        //     setStatus(DonationStatus.GOAL_REACHED);
        // }
        registerDonation();
    }

    /**
     * @dev fallback function
     * Note that it could be necessary to add an extra function to use
     * the nonReentrant modifier
     */
    fallback() external nonReentrant statusIs(DonationStatus.RECEIVING_PAYMENTS) payable {
        // if(TimeLimit.isTimeLimitReached(_creationTime)) {
        //     setStatus(DonationStatus.TIMELIMIT_REACHED);
        //     //revert("Time limit reached!"); can't revert as this will undo the status change
        // }
        // else if(MaxCap.isMaxCapReached(address(this).balance)) {
        //     setStatus(DonationStatus.GOAL_REACHED);
        // }
        registerDonation();
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _destinationWallet;
    }

    /**
     * @return the amount of donations raised.
     */
    function donationRaised() public view returns (uint256) {
        return address(this).balance;
    }

    /*
    * Donation withdrawal function
    * Allows donors to withdraw all their funds
    */
    function withdrawMyFunds() isDonor public {
        uint256 amount = getDonorAmount(msg.sender);
        payable(msg.sender).transfer(amount);
        emit DontationWithdrawal(msg.sender, amount);

        //Destroy the contract once the fundraising is done and no money is left
        if(isFundraisingDone() && address(this).balance == 0) {
            selfdestruct(payable(0)); // yeah! burning bby!.. I guess
        }
    }

    /**
    * @dev Emergency stop in case that something goes wrong
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
        emit DontationWithdrawal(_destinationWallet, address(this).balance);
        setStatus(DonationStatus.GOAL_REACHED);
        /*Hardwired to*/selfdestruct(_destinationWallet);
    }
}