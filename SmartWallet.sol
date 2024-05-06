//SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

// Implementing a smart wallet with many different capabilities
contract Wallet {
    address payable public owner;

    // Owner can grant people to use funds in wallet up to a certain declared amount
    mapping(address => uint) allowance;
    mapping(address => bool) isAllowedToSend;

    // Guardians are to be used as a backup in case owner loses their account
    // With 3 out of guardians approval, a new owner can be declared
    uint public constant confirmationsFromGuardiansForReset = 3;
    mapping(address => bool) guardians;
    address payable nextOwner;
    mapping(address => mapping(address => bool)) nextOwnerGuardianVotedBool;
    uint guardiansResetCount;

    constructor() {
        owner = payable(msg.sender);
    }

    // Method to add a guardian to the wallet
    // Requires:
    //   - The address interacting with the function is the owner's
    function addGuardian(address guardian) public {
        require(msg.sender == owner, "You are not the owner, aborting");
        guardians[guardian] = true;
    }

    // Method to change the owner
    // Requires:
    //   - Address interacting with the function is a guardian
    //   - Haven't previously voted for the new owner that they are recommending
    function proposeNewOwner(address payable newOwner) public {
        require(guardians[msg.sender], "You are not the guardian of this wallet, aborting");
        require(nextOwnerGuardianVotedBool[newOwner][msg.sender] == false, "You already voted, aborting");
        if(newOwner != nextOwner) {
            nextOwner = newOwner;
            guardiansResetCount = 0;
        }

        guardiansResetCount++;
        nextOwnerGuardianVotedBool[newOwner][msg.sender] = true;

        if(guardiansResetCount >= confirmationsFromGuardiansForReset) {
            owner = nextOwner;
            nextOwner = payable(address(0));
        }
    }

    // Transfer certain amount of funds from the smart wallet to the address (optional payload)
    // If the address interacting with the contract is that of the owner, it trusts that they are 
    // transferring an amount less than or equal to the total balance of the account
    // Requires:
    //   - Address interacting with the function is either the owner or has been granted an allowance to a certain amount of funds
    //   - The amount being requested to transfer is less than their allowane
    function transfer(address payable to, uint amount, bytes memory payload) public returns(bytes memory) {
        if(msg.sender != owner) {
            require(isAllowedToSend[msg.sender], "You are not allowed to send anything from this smart contract, aborting");
            require(allowance[msg.sender] >= amount, "You are trying to send more than you are allowed to, aborting");
        
            allowance[msg.sender] -= amount;
        }
        
        (bool success, bytes memory returnData) = to.call{value: amount}(payload);
        require(success, "Aborting, call was not successful");
        return returnData;
    }

    // Granting an address a certain allowance of the smart wallet's funds
    // Requires:
    //   - Address interacting with the function is the owner
    function setAllowance(address allowedUser, uint amount) public {
        require(msg.sender == owner, "You are not the owner, aborting");
        allowance[allowedUser] = amount;

        if(amount > 0) {
            isAllowedToSend[allowedUser] = true;
        } else {
            isAllowedToSend[allowedUser] = false;
        }
    }

    // Fallback function to receive funds without calldata
    receive() external payable { }
}
