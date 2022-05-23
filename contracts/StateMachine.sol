//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MultiSigWalletWhitelist.sol";
import "./MultiSigMaxCap.sol";
import "./MultiSigTimeLimit.sol";

contract StateMachine {

    /**
     * Event for dontation withdrawal
     * @param newStatus the new status
     */
    event SatusChange(DonationStatus newStatus);

    enum DonationStatus {
        AWAITING_ADDRESS_WHITELIST,
        AWAITING_ADDRESS_CONFIRMATION,
        RECEIVING_PAYMENTS,
        GOAL_REACHED,
        TIMELIMIT_REACHED,
        EMERGENCY_STOP
    }

    DonationStatus internal _status;

    MultiSigWalletWhitelist private _multisigWallet;
    MultiSigMaxCap private _multiSigMaxCap;
    MultiSigTimeLimit private _multiSigTimeLimit;

    //receive the addresses of TL and MC contracts
    constructor(MultiSigWalletWhitelist multisigWallet, MultiSigMaxCap multiSigMaxCap, MultiSigTimeLimit multiSigTimeLimit) {
        _status = DonationStatus.AWAITING_ADDRESS_WHITELIST;
        _multisigWallet = multisigWallet;
        _multiSigMaxCap = multiSigMaxCap;
        _multiSigTimeLimit = multiSigTimeLimit;
    }

    modifier statusIs(DonationStatus status) {
        require(status == _status, "This function cannot be called at this moment");
        _;
    }

    function getStatus() public view returns(DonationStatus) {
        return _status;
    }

    function setStatus(DonationStatus newStatus) internal {
        _status = newStatus;
        emit SatusChange(newStatus);
    }

    function checkStatus(uint256 balance) internal {
        if(_status == DonationStatus.AWAITING_ADDRESS_WHITELIST &&
            _multisigWallet.getStatus() == WalletConfirmationStatus.AWAITING_ADDRESS_CONFIRMATION)
           setStatus(DonationStatus.AWAITING_ADDRESS_CONFIRMATION);
        
        else if(_status == DonationStatus.AWAITING_ADDRESS_CONFIRMATION &&
                _multisigWallet.getStatus() == WalletConfirmationStatus.ADDRESS_CONFIRMED)
           setStatus(DonationStatus.RECEIVING_PAYMENTS);

        else if(_status == DonationStatus.RECEIVING_PAYMENTS &&
                _multiSigMaxCap.isMaxCapReached(balance))
           setStatus(DonationStatus.GOAL_REACHED);

        else if(_status == DonationStatus.RECEIVING_PAYMENTS &&
                _multiSigTimeLimit.isTimeLimitReached())
           setStatus(DonationStatus.TIMELIMIT_REACHED);
    }

    modifier isTimeLimitReached() {
        if(_multiSigTimeLimit.isTimeLimitReached()) {
            setStatus(DonationStatus.TIMELIMIT_REACHED);
        }
        _;
    }

    modifier isMaxCapReached(uint256 balance) {
        if(_multiSigMaxCap.isMaxCapReached(balance)) {
            setStatus(DonationStatus.GOAL_REACHED);
        }
        _;
    }

    function isFundraisingDone() public view returns(bool) {
        // I could use something like _status > DonationStatus.RECEIVING_PAYMENTS
        return _status == DonationStatus.GOAL_REACHED 
            || _status == DonationStatus.TIMELIMIT_REACHED 
            || _status == DonationStatus.EMERGENCY_STOP;
    }
}