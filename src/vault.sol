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
    i_rebaseTokenAddress.mint(msg.sender, msg.value,i_rebaseTokenAddress.getInterestRate());
    emit Deposit(msg.sender, msg.value);
}



function redeem(uint256 _amount) external{
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