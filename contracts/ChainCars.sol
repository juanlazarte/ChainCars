// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ChainCars is ERC1155, Ownable {
    string public name;
    string public symbol;

    struct Car {
        string name;
        string description;
        uint256 price;
        uint256 category;
    }

    IERC20 public USDT;

    mapping(uint256 => Car) public cars;

    uint256 public totalCars;

    event CarAdded(
        uint256 indexed carId,
        string name,
        uint256 price,
        uint256 category
    );

    event CarEdited(
        uint256 indexed carId,
        string name,
        uint256 price,
        uint256 category
    );
    
    event CarMinted(
        address indexed buyer,
        uint256 indexed carId,
        uint256 amount
    );
    event USDTWithdrawn(address indexed owner, uint256 amount);

    constructor(address _USDT) ERC1155("") Ownable(msg.sender) {
        name = "ChainCars";
        symbol = "CC";
        USDT = IERC20(_USDT);
        totalCars = 0;
    }

    function addCar(
        string memory _name,
        string memory _description,
        uint256 _price,
        uint256 _category
    ) public onlyOwner {
        totalCars++;
        cars[totalCars] = Car({
            name: _name,
            description: _description,
            price: _price,
            category: _category
        });

        emit CarAdded(totalCars, _name, _price, _category);
    }

    function editCar(
        uint256 carId,
        string memory _name,
        string memory _description,
        uint256 _price,
        uint256 _category
    ) public onlyOwner {
        require(carId <= totalCars, "Car ID does not exist");

        cars[carId] = Car({
            name: _name,
            description: _description,
            price: _price,
            category: _category
        });

        emit CarEdited(carId, _name, _price, _category);
    }

    function mintCar(uint256 carId, uint256 amount) public {
        require(carId <= totalCars, "Car ID does not exist");
        Car memory car = cars[carId];

        uint256 totalPrice = car.price * amount;

        require(USDT.balanceOf(msg.sender) >= totalPrice, "Not enough USDT");
        require(
            USDT.approve(address(this), totalPrice),
            "USDT approval failed"
        );

        require(
            USDT.transferFrom(msg.sender, address(this), totalPrice),
            "USDT transfer failed"
        );

        _mint(msg.sender, carId, amount, "");

        emit CarMinted(msg.sender, carId, amount);
    }

    function getAllCars() public view returns (Car[] memory) {
        Car[] memory allCars = new Car[](totalCars);
        for (uint256 i = 1; i <= totalCars; i++) {
            allCars[i - 1] = cars[i];
        }
        return allCars;
    }

    function getCarCategory(uint256 _tokenId) public view returns (uint256) {
        return cars[_tokenId].category;
    }

    function withdrawUSDT(uint256 amount) public onlyOwner {
        require(USDT.transfer(owner(), amount), "Withdraw failed");

        emit USDTWithdrawn(owner(), amount);
    }
}
