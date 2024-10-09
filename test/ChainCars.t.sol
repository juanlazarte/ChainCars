// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/ChainCars.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ChainCarsTest is Test {
    ChainCars public chainCars;
    IERC20 public usdtMock;
    address public owner;
    address public user;

    function setUp() public {
        // Mocking USDT contract
        usdtMock = IERC20(address(new ERC20Mock("Mock USDT", "USDT", 10000 * 10**18, 18)));

        // Deploying ChainCars contract
        chainCars = new ChainCars(address(usdtMock));

        owner = address(this); // Owner of the contract
        user = vm.addr(1); // Mock user address

        // Mint some USDT to the user
        deal(address(usdtMock), user, 1000 * 10**18);
    }

    function testAddCar() public {
        // Call addCar from owner account
        string memory carName = "Car 1";
        string memory carDescription = "Fast car";
        uint256 carPrice = 100 * 10**18; // 100 USDT
        uint256 carAPY = 10;

        chainCars.addCar(carName, carDescription, carPrice, carAPY);

        // Verify that the car was added
        ChainCars.Car memory car = chainCars.getCar(1);
        assertEq(car.name, carName);
        assertEq(car.description, carDescription);
        assertEq(car.price, carPrice);
        assertEq(car.apy, carAPY);
    }

    function testFail_AddCarCallerIsNotOwner() public {
        string memory carName = "Car 1";
        string memory carDescription = "Fast car";
        uint256 carPrice = 100 * 10**18; // 100 USDT
        uint256 carAPY = 10;

        // Call addCar from user account
        vm.expectRevert("Ownable: caller is not the owner");
        vm.startPrank(user);
        chainCars.addCar(carName, carDescription, carPrice, carAPY);
        vm.stopPrank();
    }

    function testEditCar() public {
        // Add a car first
        chainCars.addCar("Car 1", "Fast car", 100 * 10**18, 10);

        // Call editCar from owner account
        string memory carName = "Car 2";
        string memory carDescription = "Fast car red";
        uint256 carPrice = 101 * 10**18; // 100 USDT
        uint256 carAPY = 11;

        chainCars.editCar(1, carName, carDescription, carPrice, carAPY);

        // Verify that the car was edited
        ChainCars.Car memory car = chainCars.getCar(1);
        assertEq(car.name, carName);
        assertEq(car.description, carDescription);
        assertEq(car.price, carPrice);
        assertEq(car.apy, carAPY);
    }

   function testFail_editCarCallerIsNotOwner() public {
        // Add a car first
        chainCars.addCar("Car 1", "Fast car", 100 * 10**18, 10);

        // Call editCar from user account
        vm.expectRevert("Ownable: caller is not the owner");
        vm.startPrank(user);
        chainCars.editCar(1, "Car 2", "Fast car red", 101 * 10**18, 11);
        vm.stopPrank();
   }

    function testBuyCar() public {
        // Add a car first
        chainCars.addCar("Car 1", "Fast car", 100 * 10**18, 10);

        // User tries to buy the car
        vm.startPrank(user);

        // Approve USDT transfer from the user to the contract
        usdtMock.approve(address(chainCars), 100 * 10**18);

        // Buy car
        chainCars.buyCar(1, 1);

        // Verify the user now owns 1 unit of the car
        uint256 userBalance = chainCars.balanceOf(user, 1);
        assertEq(userBalance, 1);

        vm.stopPrank();
    }

    function testFail_BuyCarWithWrongId() public {
        // User tries to buy the car
        vm.startPrank(user);

        // Approve USDT transfer from the user to the contract
        usdtMock.approve(address(chainCars), 100 * 10**18);

        // Buy car 
        chainCars.buyCar(100, 1);

        vm.stopPrank();

        // Verify the user now owns 0 units of the car
        uint256 userBalance = chainCars.balanceOf(user, 1);
        assertEq(userBalance, 0);
    }

    function testWithdrawUSDT() public {
        // Add a car
        chainCars.addCar("Car 1", "Fast car", 100 * 10**18, 10);

        // Buy car to get USDT into the contract
        vm.startPrank(user);
        usdtMock.approve(address(chainCars), 100 * 10**18);
        chainCars.buyCar(1, 1);
        vm.stopPrank();

        // Owner withdraws USDT
        uint256 initialOwnerBalance = usdtMock.balanceOf(owner);
        chainCars.withdrawUSDT(100 * 10**18);
        uint256 finalOwnerBalance = usdtMock.balanceOf(owner);

        assertEq(finalOwnerBalance - initialOwnerBalance, 100 * 10**18);
    }

    function testFail_WithdrawCallerIsNotOwner() public {
        // Add a car
        chainCars.addCar("Car 1", "Fast car", 100 * 10**18, 10);

        // Buy car to get USDT into the contract
        vm.startPrank(user);
        usdtMock.approve(address(chainCars), 100 * 10**18);
        chainCars.buyCar(1, 1);
        vm.stopPrank();

        vm.expectRevert("Ownable: caller is not the owner");
    }
}

// Mock contract for USDT
contract ERC20Mock is IERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply;
        balances[msg.sender] = _initialSupply;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "Not enough balance");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(balances[sender] >= amount, "Not enough balance");
        require(allowance[sender][msg.sender] >= amount, "Allowance exceeded");
        balances[sender] -= amount;
        balances[recipient] += amount;
        allowance[sender][msg.sender] -= amount;
        return true;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
}
