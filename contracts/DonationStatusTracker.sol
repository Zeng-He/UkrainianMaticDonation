//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// TODO rename to StateMachine
contract DonationStatusTracker {

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

    constructor() {
        _status = DonationStatus.AWAITING_ADDRESS_WHITELIST;
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

    function isFundraisingDone() public view returns(bool) {
        // I could use something like _status > DonationStatus.RECEIVING_PAYMENTS
        return _status == DonationStatus.GOAL_REACHED 
            || _status == DonationStatus.TIMELIMIT_REACHED 
            || _status == DonationStatus.EMERGENCY_STOP;
    }
}