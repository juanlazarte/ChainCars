// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract ChainCars is ERC1155, Ownable, ERC1155Supply {
    string public name;
    string public symbol;

    struct Car {
        
        string name;
        string description;
        uint256 price;
        uint256 apy;
    }

    IERC20 public USDT;

    mapping(uint256 id => Car) public cars;
    
    uint256 public totalCars;

    event CarAdded(uint256 indexed carId, string name, string description, uint256 price, uint256 apy);
    event CarEdited(uint256 indexed carId, string name, string description, uint256 price, uint256 apy);
    event CarBought(address indexed buyer, uint256 indexed carId, uint256 amount, uint256 totalPrice);
    event USDTWithdrawn(address indexed owner, uint256 amount);


    constructor(address _USDT) ERC1155("https://ipfs.io/ipfs/QmSCXFTa5bvyiBB8gb8uYu3YNhyFNvhycpJ7vNdUxjqLXP/{id}.json") Ownable(msg.sender) {
        name = "ChainCars";
        symbol = "CC";
        USDT = IERC20(_USDT);
        totalCars = 0;
    }

/*     //URI
    function uri(uint256 _carId) public view override returns(string memory){
        require(exists(_carId), "URI: id doesn't exist");
        return string(abi.encodePacked(super.uri(_carId), Strings.toString(_carId) ,".json"));
    } */

    function addCar(string memory _name, string memory _description, uint256 _price, uint256 _apy) public onlyOwner {
        totalCars++;
        cars[totalCars] = Car({
            name: _name,
            description: _description,
            price: _price,
            apy: _apy
        });

        emit CarAdded(totalCars, _name, _description, _price, _apy);
    }

    function editCar(uint256 _carId, string memory _name, string memory _description, uint256 _price, uint256 _apy) public onlyOwner {
        require(_carId <= totalCars, "Car ID does not exist");
        cars[_carId] = Car({
            name: _name,
            description: _description,
            price: _price,
            apy: _apy
        });

        emit CarEdited(_carId, _name, _description, _price, _apy);
    }

    function buyCar(uint256 _carId, uint256 amount) public {
        require(_carId <= totalCars, "Car ID does not exist");
        require(_carId > 0, "Car ID cannot be 0");
        Car memory car = cars[_carId];

        uint256 totalPrice = car.price * amount;

        require(USDT.transferFrom(msg.sender, address(this), totalPrice), "USDT transfer failed");

        _mint(msg.sender, _carId, amount, "");

        emit CarBought(msg.sender, _carId, amount, totalPrice);
    }

    function getAllCars() public view returns (Car[] memory) {
        Car[] memory allCars = new Car[](totalCars);
        for (uint256 i = 0; i < totalCars; i++) {
            allCars[i] = cars[i];
        }
        return allCars;
    }

    function getCar(uint256 _carId) public view returns (Car memory) {
        require(_carId <= totalCars, "Car ID does not exist");
        return cars[_carId];
    }

    function withdrawUSDT(uint256 amount) public onlyOwner {
        require(USDT.transfer(owner(), amount), "Withdraw failed");

        emit USDTWithdrawn(owner(), amount);
    }

        // The following functions are overrides required by Solidity.
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._update(from, to, ids, values);
    }
}
