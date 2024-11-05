// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import "../contracts/Staking.sol";
import "../contracts/ChainCars.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockUSDT is IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    function mint(address to, uint256 amount) external {
        _balances[to] += amount;
        _totalSupply += amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(
            _allowances[from][msg.sender] >= amount,
            "Insufficient allowance"
        );
        _allowances[from][msg.sender] -= amount;
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }
}

contract StakingChainCarsTest is Test {
    StakingChainCars public staking;
    ChainCars public chainCars;
    MockUSDT public usdt;

    address public owner;
    address public user1;
    address public user2;

    uint256 public constant INITIAL_USDT_BALANCE = 1000000 * 10 ** 18;
    uint256 public constant TOKEN_ID = 1;
    uint256 public constant TOKENID_FAIL = 2;
    uint256 public constant CATEGORY = 1;
    uint256 public constant APY = 10; // 10%
    uint256 public constant PRICE = 1000 * 10 ** 18; // 1000 USDT
    uint256 public constant STAKE_AMOUNT = 1;

    event Staked(address indexed user, uint256 tokenId, uint256 amount);
    event Unstaked(address indexed user, uint256 tokenId, uint256 amount);
    event RewardClaimed(address indexed user, uint256 tokenId, uint256 amount);

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // Deploy contracts
        usdt = new MockUSDT();
        chainCars = new ChainCars(address(usdt));
        staking = new StakingChainCars(chainCars, IERC20(address(usdt)));

        // Add car to ChainCars
        vm.startPrank(owner);
        chainCars.addCar("Sedan", "Comfortable family car", PRICE, CATEGORY);
        vm.stopPrank();

        // Mint initial USDT balance for user1 and set approval in frontend simulation
        vm.startPrank(owner);
        usdt.mint(user1, INITIAL_USDT_BALANCE);
        vm.stopPrank();

        vm.startPrank(user1);
        usdt.approve(address(chainCars), INITIAL_USDT_BALANCE);
        chainCars.mintCar(TOKEN_ID, 1);
        usdt.approve(address(staking), INITIAL_USDT_BALANCE);
        vm.stopPrank();

        // Mint USDT to staking contract for rewards
        vm.startPrank(owner);
        usdt.mint(address(staking), INITIAL_USDT_BALANCE);
        vm.stopPrank();

        // Set up staking tier
        vm.startPrank(owner);
        staking.addStakingTier(CATEGORY, APY, PRICE);
        vm.stopPrank();

        vm.startPrank(user1);
        chainCars.setApprovalForAll(address(staking), true);
        vm.stopPrank();
    }

    function testAddStakingTier() public {
        uint256 newCategory = 2;
        uint256 newApy = 15;
        uint256 newPrice = 2000 * 10 ** 18;

        staking.addStakingTier(newCategory, newApy, newPrice);

        (uint256 category, uint256 apy, uint256 price) = staking.stakingTiers(
            newCategory
        );
        assertEq(category, newCategory);
        assertEq(apy, newApy);
        assertEq(price, newPrice);
    }

    function testStaking() public {
        vm.startPrank(user1);

        vm.expectEmit(true, true, true, true);
        emit Staked(user1, TOKEN_ID, STAKE_AMOUNT);

        staking.stake(TOKEN_ID, STAKE_AMOUNT);

        StakingChainCars.StakingInfo memory info = staking.getStakingInfo(
            user1,
            0
        );
        assertEq(info.tokenId, TOKEN_ID);
        assertEq(info.amount, STAKE_AMOUNT);
        assertEq(info.apy, APY);
        assertEq(info.price, PRICE);
        assertEq(info.unstaked, false);

        vm.stopPrank();
    }

    function testFail_StakeWithoutApproval() public {
        vm.startPrank(user2);
        vm.expectRevert("ERC1155: caller is not token owner or approved");
        staking.stake(TOKEN_ID, STAKE_AMOUNT);
        vm.stopPrank();
    }

    function testFail_ClaimRewardsTooEarly() public {
        vm.startPrank(user1);
        staking.stake(TOKEN_ID, STAKE_AMOUNT);

        vm.warp(block.timestamp + 2 days);
        vm.expectRevert("Rewards can be claimed once a week");
        staking.claimRewards(1);
        vm.stopPrank();
    }

    function testFail_UnstakeAlreadyUnstaked() public {
        vm.startPrank(user1);
        staking.stake(TOKEN_ID, STAKE_AMOUNT);
        staking.unstake(1);

        vm.expectRevert("Tokens already unstaked");
        staking.unstake(1);
        vm.stopPrank();
    }

    function testWithdrawUSDT() public {
        uint256 withdrawAmount = 1000 * 10 ** 18;
        uint256 initialBalance = usdt.balanceOf(address(staking));

        staking.withdrawUSDT(withdrawAmount);

        assertEq(
            usdt.balanceOf(address(staking)),
            initialBalance - withdrawAmount
        );
        assertEq(usdt.balanceOf(address(this)), withdrawAmount);
    }

    function testFail_WithdrawUSDTInsufficientBalance() public {
        vm.startPrank(user1);
        uint256 withdrawAmount = INITIAL_USDT_BALANCE + 100;
        vm.expectRevert("Insufficient USDT balance");
        staking.withdrawUSDT(withdrawAmount);
        vm.stopPrank();
    }

    function testGetStakingsPerAddress() public {
        vm.startPrank(user1);
        staking.stake(TOKEN_ID, STAKE_AMOUNT);

        StakingChainCars.StakingInfo[] memory stakings = staking
            .getStakingsPerAddress(user1);
        assertEq(stakings.length, 1);
        assertEq(stakings[0].tokenId, TOKEN_ID);
        assertEq(stakings[0].amount, STAKE_AMOUNT);
        vm.stopPrank();
    }
}
