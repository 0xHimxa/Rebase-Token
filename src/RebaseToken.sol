//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.19;


import {ERC20Burnable,ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract RebaseToken is ERC20{
 
error RebaseToken__IntrestRateCanOnlyBeDecreased(uint256 currentRate, uint256 newRate);

 uint256 private interestRate = 5e10;
  mapping(address user => uint256 interestRate) private s_userInterestRate;
 mapping(address user => uint256 lastUpdate) private s_userLastUpdateTimeStamp;
 uint256 private constant PRECISION_FACTOR = 1e18;




event InterestRateSet(uint256 newInterestRate);






constructor() ERC20("RebaseToken","RBT"){
   
}
function increaseIntrestRate(uint256 _newInterestRate) external {

 if(_newInterestRate > interestRate){
    revert RebaseToken__IntrestRateCanOnlyBeDecreased(interestRate, _newInterestRate);
 }

    interestRate = _newInterestRate;
    emit InterestRateSet(_newInterestRate);
}   


function mint(address _to, uint256 _amount) external{
    _mintAccruedInterest(_to);
    s_userInterestRate[_to] = interestRate;
   // s_userLastUpdateTimeStamp[_to] = block.timestamp;
    _mint(_to, _amount);
} 

function balance0f(address _user) public view returns(uint256){

    return (super.balanceOf(_user) * _calculateUserAccumulatedInterest(_user)) / PRECISION_FACTOR;
}
function _calculateUserAccumulatedInterest(address _user) internal view returns(uint256){
    uint256 userRate = s_userInterestRate[_user];
    // if(userRate == 0){
    //     return 1e18;
    // }
    uint256 timeDiff = block.timestamp - s_userLastUpdateTimeStamp[_user];
    uint256 accumulatedInterest = (userRate * timeDiff);
    return PRECISION_FACTOR + accumulatedInterest;
}


function _mintAccruedInterest(address _user) internal {
  
    s_userLastUpdateTimeStamp[_user] = block.timestamp;
}

function getUserInterestRate(address _user) external view returns(uint256){
    return s_userInterestRate[_user];
}





}