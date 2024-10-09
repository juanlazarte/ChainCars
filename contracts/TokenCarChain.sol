// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CarChainToken is ERC20, Ownable {
    uint256 public immutable TOKEN_PRICE = 0.0001 ether;

    address public s_stakeContract;

    event TokensMinted(address indexed to, uint256 amount);
    event TokensBought(address indexed buyer, uint256 amount, uint256 totalCost);
    event StakingContractSet(address indexed stakingContract);

    constructor() ERC20("CarChainToken", "CCT") Ownable(msg.sender) {
        _mint(owner(), 20_000_000 * 10 ** 18);
    }

    modifier onlyStakingContract() {
        require(msg.sender == s_stakeContract, "You can't mint");
        _;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);

        emit TokensMinted(to, amount);
    }

    function mint(uint256 amount) external onlyStakingContract {
        _mint(s_stakeContract, amount);
    }

    function buy(uint256 amount) public payable {
        require(msg.value == amount * TOKEN_PRICE, "Invalid amount");
        _mint(msg.sender, amount);

        emit TokensBought(msg.sender, amount, msg.value);
    }

    function setStakingContract(address _contract) external onlyOwner {
        s_stakeContract = _contract;

        emit StakingContractSet(_contract);
    }
}
