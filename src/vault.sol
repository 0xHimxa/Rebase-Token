//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.19;



import {IRebaseToken} from "./interfaces/IRabseToken.sol";
import {RebaseToken} from "./RebaseToken.sol";
contract Vault{


error Vault__RedeemFailed();


 RebaseToken private immutable i_rebaseTokenAddress;

event Deposit(address indexed user, uint256 amount);
event Redeem(address indexed user, uint256 amount);




constructor(address _rebaseTokenAddress){
    i_rebaseTokenAddress = RebaseToken(_rebaseTokenAddress);
}


receive() external payable{}


function deposit() external payable{
    uint256 userInterestRate =  i_rebaseTokenAddress.getInterestRate();
    i_rebaseTokenAddress.mint(msg.sender, msg.value,userInterestRate);
    emit Deposit(msg.sender, msg.value);
}



function redeem(uint256 _amount) external{


if(_amount ==type(uint256).max){
    _amount = i_rebaseTokenAddress.balanceOf(msg.sender);
}

    i_rebaseTokenAddress.burn(msg.sender, _amount);
    (bool success, ) = msg.sender.call{value: _amount}("");
    if(!success){
        revert Vault__RedeemFailed();
    }
    emit Redeem(msg.sender, _amount);
}




function getRebaseTokenAddress() external view returns(address){
    return address(i_rebaseTokenAddress);
}




}