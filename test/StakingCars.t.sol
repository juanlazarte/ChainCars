// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/StakingCars.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {IERC20} from "../contracts/IERC20.sol";
import {CarChainToken} from "../contracts/TokenCarChain.sol";

contract StakingNftTest is Test {
    StakingNft public stakingNft;
    ERC1155Mock public nftToken;
    CarChainToken public rewardToken;
    address public owner;
    address public user;

    function setUp() public {
        owner = address(this);
        user = vm.addr(1); 

        nftToken = new ERC1155Mock();
        rewardToken = new CarChainToken();

        // Deploy the staking contract
        stakingNft = new StakingNft(
            IERC1155(address(nftToken)),
            IERC20(address(rewardToken))
        );
        rewardToken.setStakingContract(address(stakingNft)); 

        
        nftToken.mint(user, 1, 5); 
        rewardToken.mint(owner, 10000 * 10 ** 18); 
    }

    function testStakeTokens() public {
        vm.startPrank(user); 

        // Approve and stake NFT tokens
        nftToken.setApprovalForAll(address(stakingNft), true);
        stakingNft.stake(1, 5); // Stake 5 NFTs of tokenId 1

        // Check that the contract now holds the tokens
        assertEq(nftToken.balanceOf(address(stakingNft), 1), 5);
        assertEq(stakingNft.getStakedTokens(user, 1), 5);

        vm.stopPrank();
    }

    function testUnstakeTokens() public {
        vm.startPrank(user);

        // Stake tokens first
        nftToken.setApprovalForAll(address(stakingNft), true);
        stakingNft.stake(1, 5);

        // Check initial balances
        assertEq(nftToken.balanceOf(address(stakingNft), 1), 5);

        // Unstake the tokens
        stakingNft.unstake(1, 3); // Unstake 3 NFTs

        // Check balances after unstaking
        assertEq(nftToken.balanceOf(user, 1), 3); // User should get 3 NFTs back
        assertEq(nftToken.balanceOf(address(stakingNft), 1), 2); // Contract should hold 2 NFTs

        vm.stopPrank();
    }

    function testClaimRewards() public {
        vm.startPrank(user);

        // Stake tokens first
        nftToken.setApprovalForAll(address(stakingNft), true);
        stakingNft.stake(1, 5);

        // Simulate passage of time (1 day)
        skip(1 days);

        // Claim rewards
        stakingNft.claimRewards();

        // Check reward balance of user
        uint256 expectedReward = 5 * 100 * 1 days; // 5 NFTs * rewardRate (100) * 1 day
        assertEq(rewardToken.balanceOf(user), expectedReward);

        vm.stopPrank();
    }

    function testSetRewardRate() public {
        uint256 newRate = 200;
        stakingNft.setRewardRate(newRate);

        // Check that the reward rate was updated
        assertEq(stakingNft.s_rewardRate(), newRate);
    }
}

// Mock ERC1155 token contract for testing
contract ERC1155Mock is ERC1155, ERC1155Supply {
    constructor() ERC1155("MockNFT") {}

    function mint(address account, uint256 id, uint256 amount) public {
        _mint(account, id, amount, "");
    }
    
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal override(ERC1155, ERC1155Supply) {
        super._update(from, to, ids, amounts);
    }
}
