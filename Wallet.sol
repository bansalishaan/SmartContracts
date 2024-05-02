//SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

// Description: This smart contract deposits and withdraws money from any address
// Purpose: To get familiar and comfortable with solidity, smart contracts and their capabilities
contract SmartWallet {

    uint public totalRecieved = 0;

    function deposit() public payable {
        totalRecieved += msg.value;
    }
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdraw(uint amount) public {
        payable(msg.sender).transfer(amount);
    }

    function withdrawAll() public {
        address payable to = payable(msg.sender);
        to.transfer(getBalance());
    }

    function withdrawToAddress(address payable to) public {
        to.transfer(getBalance());
    }
}
