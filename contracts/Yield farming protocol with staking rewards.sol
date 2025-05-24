// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title YieldFarm
 * @dev Simple staking and reward distribution contract
 */
contract YieldFarm is Ownable {
    IERC20 public stakingToken;
    IERC20 public rewardToken;
    uint256 public rewardRate; // reward tokens distributed per block
    uint256 public lastUpdateBlock;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /// @dev Default constructor with hardcoded token addresses and reward rate
    constructor() Ownable(msg.sender) {
        // Replace these with real token addresses when deploying on testnet/mainnet
        stakingToken = IERC20(0x000000000000000000000000000000000000dEaD); // Default: Dead address placeholder
        rewardToken = IERC20(0x000000000000000000000000000000000000bEEF); // Default: Dummy reward token
        rewardRate = 1e18; // Default reward rate: 1 token per block

        lastUpdateBlock = block.number;
    }

    /// @dev Parameterized constructor (OPTIONAL)


    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateBlock = block.number;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            ((block.number - lastUpdateBlock) * rewardRate * 1e18) / _totalSupply;
    }

    function earned(address account) public view returns (uint256) {
        return
            (_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18 +
            rewards[account];
    }

    function stake(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Cannot stake zero");
        _totalSupply += amount;
        _balances[msg.sender] += amount;
        require(
            stakingToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw zero");
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        require(stakingToken.transfer(msg.sender, amount), "Transfer failed");
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            require(
                rewardToken.transfer(msg.sender, reward),
                "Reward transfer failed"
            );
        }
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    function setRewardRate(uint256 _rewardRate) external onlyOwner {
        rewardRate = _rewardRate;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        require(
            tokenAddress != address(stakingToken),
            "Cannot recover staking token"
        );
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }
}
