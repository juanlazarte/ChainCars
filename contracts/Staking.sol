// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../contracts/ChainCars.sol";

contract StakingChainCars is Ownable {
    ChainCars public CC;
    IERC20 public USDT;

    struct StakingInfo {
        uint256 tokenId;
        uint256 amount;
        uint256 timestamp;
        uint256 lastClaim;
        uint256 apy;
        uint256 price;    
        bool unstaked;
    }

    struct StakingTier {
        uint256 category;
        uint256 apy; 
        uint256 price;     
    }

    mapping(uint256 => StakingTier) public stakingTiers;
    mapping(address => StakingInfo[]) public stakingBalances;

    event Staked(address indexed user, uint256 tokenId, uint256 amount);
    event Unstaked(address indexed user, uint256 tokenId, uint256 amount);
    event RewardClaimed(address indexed user, uint256 tokenId, uint256 amount);
    event StakingTierAdded(uint256 tokenId, uint256 rewardRate, uint256 price);

    constructor(ChainCars _CC, IERC20 _USDT) Ownable(msg.sender) {
        CC = _CC;
        USDT = _USDT;
    }

    function addStakingTier(uint256 _category, uint256 _apy, uint256 _price) external onlyOwner {
        stakingTiers[_category] = StakingTier({
            category: _category,
            apy: _apy,
            price: _price
        });

        emit StakingTierAdded(_category, _apy, _price);
    }

    function stake(uint256 _tokenId, uint256 _amount) external {
        require(stakingTiers[_tokenId].apy > 0, "Staking tier not found");
        require(CC.balanceOf(msg.sender, _tokenId) >= _amount, "Not enough tokens");

        CC.safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");

        uint256 category = CC.getCarCategory(_tokenId);

        StakingTier memory tier = stakingTiers[category];

        stakingBalances[msg.sender].push(StakingInfo({
            tokenId: _tokenId,
            amount: _amount,
            timestamp: block.timestamp,
            lastClaim: block.timestamp,
            apy: tier.apy,
            price: tier.price,
            unstaked: false
        }));

        emit Staked(msg.sender, _tokenId, _amount);
    }

    function claimRewards(uint256 _index) external {
        StakingInfo storage info = stakingBalances[msg.sender][_index];
        require(!info.unstaked, "Tokens unstaked");
        require(block.timestamp >= info.lastClaim + 7 days, "Rewards can be claimed once a week");

        uint256 rewards = calculateRewards(msg.sender, _index);
        require(rewards > 0, "No rewards available");

        info.lastClaim = block.timestamp;

        require(USDT.balanceOf(address(this)) >= rewards, "Insufficient USDT in contract");
        require(USDT.transfer(msg.sender, rewards), "Reward transfer failed");

        emit RewardClaimed(msg.sender, info.tokenId, rewards);
    }

    function unstake(uint256 _index) external {
        StakingInfo storage info = stakingBalances[msg.sender][_index];
        require(!info.unstaked, "Tokens already unstaked");

        info.unstaked = true;

        uint256 rewards = calculateRewards(msg.sender, _index);
        uint256 amount = info.amount;

        CC.safeTransferFrom(address(this), msg.sender, info.tokenId, amount, "");

        if (rewards > 0) {
            require(USDT.balanceOf(address(this)) >= rewards, "Insufficient USDT in contract");
            require(USDT.transfer(msg.sender, rewards), "Reward transfer failed");
        }

        emit Unstaked(msg.sender, info.tokenId, amount);
    }

    function calculateRewards(address _user, uint256 _index) public view returns (uint256) {
        StakingInfo storage info = stakingBalances[_user][_index];

        uint256 timeElapsed = block.timestamp - info.lastClaim;

        uint256 rewards = (info.price * info.amount * info.apy * timeElapsed) / (100 * 365 days);

        return rewards;
    }

    function getStakingsPerAddress(address _address) external view returns (StakingInfo[] memory) {
        return stakingBalances[_address];
    }

    function getStakingInfo(
        address _user,
        uint256 _index
    ) external view returns (StakingInfo memory) {
        return stakingBalances[_user][_index];
    }

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function withdrawUSDT(uint256 _amount) external onlyOwner {
        require(USDT.balanceOf(address(this)) >= _amount, "Insufficient USDT balance");
        require(USDT.transfer(msg.sender, _amount), "Transfer failed");
    }
}