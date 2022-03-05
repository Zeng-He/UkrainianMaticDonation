//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DonationStatusTracker {

    // TODO Add events for all status change

    // Donation status
    enum DonationStatus {
        AWAITING_ADDRESS_WHITELIST,
        AWAITING_ADDRESS_CONFIRMATION,
        RECEIVING_PAYMENTS,
        DONATION_CONCLUDE,
        TIMELIMIT_REACHED
    }

    DonationStatus internal _status;

    constructor() {
        _status = DonationStatus.AWAITING_ADDRESS_WHITELIST;
    }

    function getCurrentStatus() public view returns(DonationStatus) {
        return _status;
    }
}