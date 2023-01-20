//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Token.sol";

contract Exchange {
	address public feeAccount;
	uint256 public feePercent;
	address public blueGemAddress;
	mapping(address => mapping(address => uint256)) public tokens;

	mapping(address => bool) public hasBalance;
	mapping(address => bool) public isLockedUp;
	mapping(address => uint256) public lockUpEnd;
	
	event tokenLockUp(

		)

	event Deposit(
		address token,
		address user,
		uint256 amount,
		uint256 balance
	); 

	event Withdraw(
		address token,
		address user,
		uint256 amount,
		uint256 balance
	);	

	constructor(address _feeAccount, uint256 _feePercent){
		feeAccount = _feeAccount;
		feePercent = _feePercent;
	}

	function depositToken(address _token, uint256 _amount) public {
		//Transfer Tokens to exchange
		require(Token(_token).transferFrom(msg.sender, address(this), _amount));
		//Make Sure it's BlueGem Token Deposited
		require(_token.address() == blueGemAddress, "Can't deposit tokens that aren't BlueGem")
		//Update Balance
		tokens[_token][msg.sender] = tokens[_token][msg.sender] + _amount;
		//Emit Event
		emit Deposit(_token, msg.sender, _amount, tokens[_token][msg.sender]);
	}

	function withdrawTokens(address _token, uint256 _amount) public {
		require(_amount <= tokens[_token][msg.sender], "not enough tokens");
		require(isLockedUp[msg.sender] == false, "Your tokens are locked up, you can't withdraw right now");

		tokens[_token][msg.sender] = tokens[_token][msg.sender] - _amount;

		Token(_token).transfer(msg.sender, _amount);

		//emit
		emit Withdraw(_token, msg.sender, _amount, tokens[_token][msg.sender]);
	}

	function balanceOf(address _token, address _user)
		public
		view
		returns (uint256) 
		{
			return tokens[_token][_user];
		}

	//Function to set the BlueGem Address in case you need to change it, available only to the owner to set
	function setBlueGemAddress(address bgAddress) public onlyOwner {
		blueGemAddress = bgAddress;
	}

	function startLockUpPeriod(address locker, uint256 lockUpPeriod) public external {
		require(msg.sender == locker, "You can't spend or lockup someone else's tokens")
		//lockup peroid is in weeks
		uint256 lockUpWeeks = lockUpPeriod * 604800;
		uint256 now = block.timestamp;
		isLockedUp[locker] = true;
		lockUpEnd[locker] = now + lockUpWeeks;
	}

	function endLockUpPeriod(address unlocker) public external {
		require(lockUpEnd[unlocker] <= block.timestamp, "Your lockup period is not over yet");
		isLockedUp[unlocker] = false;
		lockUpEnd[unlocker] = 0;
	}

}
