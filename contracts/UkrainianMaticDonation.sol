//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./StateMachine.sol";
import "./DonorTracker.sol";

contract UkrainianMaticDonation is Ownable, ReentrancyGuard, StateMachine, DonorTracker {
    // TODO Add change max cap function (multisig) (event) - new contract
    // TODO Add change timelimit function (multisig) (event) - new contract
    // TODO Add whitelist wallet function (multisig) (event) - new contract
    // TODO determine how timelimit can be executed - new contract - check StateMachine.sol
    // TODO Add some way to check and update status related to external contracts
    //      it could be public function in the StateMachine contract that..
    //      checks ALL statuses calling the other contracts

    // Address where funds are collected
    address payable private _destinationWallet; // this could go in a different contract

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
    receive () external 
        nonReentrant 
        statusIs(DonationStatus.RECEIVING_PAYMENTS) 
        isMaxCapReached(_creationTime)
        isTimeLimitReached(address(this).balance)
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
        isMaxCapReached(_creationTime)
        isTimeLimitReached(address(this).balance)
        payable
    {
        // Probably just call receive.. but have to check the nonReentrant validation
        registerDonation();
        if(isFundraisingDone()) { //timelimit or maxcap
            _deliverTokens();
        }
    }

    function checkStatus() public {
        super.checkStatus(address(this).balance, _creationTime);
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
    function donationsRaised() public view returns (uint256) {
        return address(this).balance;
    }

    /*
    * Donation withdrawal function
    * Allows donors to withdraw all their funds
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
        /*Hardwired to*/selfdestruct(_destinationWallet);
    }
}