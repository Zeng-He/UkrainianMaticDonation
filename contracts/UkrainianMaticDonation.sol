//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./DonationStatusTracker.sol";

contract UkrainianMaticDonation is Ownable, ReentrancyGuard, DonationStatusTracker {
    // TODO Add change max cap function (multisig) (event) - new contract
    // TODO Add change timelimit function (multisig) (event) - new contract
    // TODO Add whitelist wallet function (multisig) (event) - new contract
    // TODO Add renounce ownership after fundraising started
    // TODO Add way to send money back to donors - probably let them withdraw themselves
    // TODO determine how timelimit can be executed - new contract
    // TODO Add some way to check and update status related to external contracts
    // TODO Add DonorTracker contract

    // Safety first :)
    using SafeMath for uint256;

    // Address where funds are collected
    address payable private _destinationWallet;

    // Owners required to sign changes
    mapping (address => bool) private _signers; // this could go in a different contract

    // Donors who send tokens
    mapping (address => uint256) private _donors; // this could go in a different contract

    //Contact Balance.. maybe this not needed. address(this).balance is the same
    //uint private _balance;

    /**
     * Event for donation logging
     * @param donor who sent the tokens
     * @param amount amount of tokens sent
     */
    event TokensDonated(address indexed donor, uint256 amount);

    /**
     * Event for dontation withdrawal
     * @param beneficiary who receive the donation
     * @param amount total amount of tokens donated
     */
    event DontationWithdrawal(address indexed beneficiary, uint256 amount);

    //TODO receive a list of addresses to sign
    constructor() 
    {
        //TODO allocate list of addresses to _signers
    }

    /**
     * @dev receive function
     * Note that it could be necessary to add an extra function to use
     * the nonReentrant modifier
     */
    receive () external nonReentrant payable {
        require(_status == DonationStatus.RECEIVING_PAYMENTS, "This contract is not acepting payments atm");
        //_balance = _balance.add(msg.value);
        _donors[address(msg.sender)] = _donors[address(msg.sender)].add(msg.value);
        emit TokensDonated(address(msg.sender), msg.value);
    }

    //TODO add fallback function

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

    /**
     * @dev Source of tokens.
     * Call this for token delivery. It could be:
     * Fundraising completed: Deliver all the token amount to one address.
     * Fundraising failed: Send back all the respective tokens to its owners.
     */
    function _deliverTokens() private {
        // if(address(this).balance >= _maxCap)
        if(true){
            //_destinationWallet.transfer(address(this).balance);
            selfdestruct(_destinationWallet);
            _status = DonationStatus.DONATION_CONCLUDE;
            //emit event
        } else {
            //send funds or allow them to withdraw?
            _status = DonationStatus.TIMELIMIT_REACHED;
            selfdestruct(_destinationWallet); // should send zero
            //emit event
        }
    }
}