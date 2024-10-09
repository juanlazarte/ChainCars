// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract StakingNft is Ownable, IERC1155Receiver {
    IERC1155 public s_nftToken;
    IERC20 public s_rewardToken;

    struct Staker {
        mapping(uint256 => uint256) stakedTokens; // tokenId => cantidad de tokens apostados
        uint256 rewardDebt;
        uint256 lastUpdateTime;
    }

    uint256 public s_rewardRate = 100;

    mapping(address => Staker) public s_stakers;

    event Staked(address indexed user, uint256 tokenId, uint256 amount);
    event Unstaked(address indexed user, uint256 tokenId, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    constructor(IERC1155 _nftToken, IERC20 _rewardToken) Ownable(msg.sender) {
        s_nftToken = _nftToken;
        s_rewardToken = _rewardToken;
    }

    function stake(uint256 _tokenId, uint256 _amount) external {
        require(
            s_nftToken.balanceOf(msg.sender, _tokenId) >= _amount,
            "You do not own enough tokens"
        );

        s_nftToken.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            _amount,
            ""
        );
        Staker storage staker = s_stakers[msg.sender];
        _updateReward(msg.sender);

        staker.stakedTokens[_tokenId] += _amount;

        emit Staked(msg.sender, _tokenId, _amount);
    }

    function unstake(uint256 _tokenId, uint256 _amount) external {
        require(
            s_stakers[msg.sender].stakedTokens[_tokenId] >= _amount,
            "You do not have enough staked tokens"
        );

        Staker storage staker = s_stakers[msg.sender];
        _updateReward(msg.sender);

        staker.stakedTokens[_tokenId] -= _amount;

        s_nftToken.safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId,
            _amount,
            ""
        );

        emit Unstaked(msg.sender, _tokenId, _amount);
    }

    function claimRewards() external {
        Staker storage staker = s_stakers[msg.sender];

        _updateReward(msg.sender);

        uint256 reward = staker.rewardDebt;
        staker.rewardDebt = 0;

        // Mint y transferir la recompensa
        s_rewardToken.mint(reward); // Asumiendo que tienes un método mint en el token de recompensa
        s_rewardToken.transfer(msg.sender, reward);

        emit RewardClaimed(msg.sender, reward);
    }

    function _updateReward(address _user) internal {
        Staker storage staker = s_stakers[_user];

        uint256 totalReward = 0;
        uint256 timeDiff = block.timestamp - staker.lastUpdateTime;

        // Suponiendo que conoces los tipos de tokens que existen
        for (uint256 tokenId = 0; tokenId < 10; tokenId++) {
            // Ajusta el límite según tus necesidades
            uint256 amountStaked = staker.stakedTokens[tokenId];
            if (amountStaked > 0) {
                totalReward += amountStaked * s_rewardRate * timeDiff;
            }
        }

        staker.rewardDebt += totalReward;
        staker.lastUpdateTime = block.timestamp;
    }

    function setRewardRate(uint256 _newRewardRate) external onlyOwner {
        s_rewardRate = _newRewardRate;
    }

    function getStakedTokens(
        address _user,
        uint256 _tokenId
    ) external view returns (uint256) {
        return s_stakers[_user].stakedTokens[_tokenId];
    }

    // Required by IERC1155Receiver
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    // Required by IERC1155Receiver for batch transfers
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId;
    }
}
