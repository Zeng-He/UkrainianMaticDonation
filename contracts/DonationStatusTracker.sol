//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// TODO rename to StateMachine
// TODO this contract will talk to maxcap, timelimit and wallet whitelisting to update the status
//      so, it has to know them and receive them in the constructor
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
        EMERGENCY_STOP,
        FINISHED
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
            || _status == DonationStatus.EMERGENCY_STOP
            || _status == DonationStatus.FINISHED;
    }
}