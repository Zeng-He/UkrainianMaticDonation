//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DonorTracker {

    // Safety first :)
    using SafeMath for uint256;

    /**
     * Event for donation logging
     * @param donor who sent the money
     * @param amount amount of tokens sent
     */
    event Donation(address indexed donor, uint256 amount, uint256 balance);

    // Donors who send money
    mapping (address => uint256) private _donors;

    modifier isDonor() {
        require(_donors[msg.sender] != 0, "not donor");
        _;
    }

    function getDonorAmount(address donorAddress) internal view returns(uint256) {
        return _donors[donorAddress];
    }

    function liquidateDonorFunds(address donorAddress) internal returns(uint256) {
        uint256 amount = _donors[donorAddress];
        _donors[donorAddress] = 0;
        return amount;
    }

    function registerDonation () internal {
        _donors[address(msg.sender)] = _donors[address(msg.sender)].add(msg.value);
        emit Donation(address(msg.sender), msg.value, address(this).balance);
    }
}