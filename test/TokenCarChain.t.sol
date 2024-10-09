// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {CarChainToken} from "../contracts/TokenCarChain.sol";

contract UnsTokenTest is Test {
    CarChainToken public token;

    uint256 internal userPrivateKey = 3298374194781094846464646;
    uint256 immutable public TOKEN_PRICE = 0.0001 ether;

    function setUp() public {
        token = new CarChainToken();
    }

    function testBalance() public {
        vm.deal(address(this), 20_000_000);
    }

    function testFail_MintAsNotOwner() public {
        vm.prank(address(0)); 
        token.mint(address(this), 100);
    }

    function testFail_MintAsNotStakeContract() public {
        vm.prank(address(0)); 
        token.mint(100);
    }

    function testBuy() public {
        uint256 amount = 1;
        uint256 price = amount * TOKEN_PRICE;
        address user = vm.addr(userPrivateKey);

        vm.deal(user, price);
        vm.prank(user);

        token.buy{value: price}(amount);

        assertEq(token.balanceOf(user), amount);
    }

    function testBuyInvalidAmount() public {
        uint256 amount = 1;
        uint256 wrongPrice = amount * TOKEN_PRICE - 1;
        address user = vm.addr(userPrivateKey);

        vm.deal(user, wrongPrice);
        vm.prank(user);

        vm.expectRevert("Invalid amount");
        token.buy{value: wrongPrice}(amount);
    }

    function testFuzz_SetStakingContract(address x) public {
        token.setStakingContract(x);
        assertEq(token.s_stakeContract(), x);
    }
}