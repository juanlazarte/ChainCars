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
    mapping(address => uint256[]) public carsOwnedByWallet;
    mapping(uint256 => uint256) public totalMinted;
    
    uint256 public totalCars;
    uint256 public MAXSUPPLY = 100;

    constructor(address _USDT) ERC1155("https://ipfs.io/ipfs/QmeCehCLYadg1rSaU8uWsxbgzphjUuZBGDXjmubPvXeVbi/{id}.json") Ownable(msg.sender) {
        name = "ChainCars";
        symbol = "CC";
        USDT = IERC20(_USDT);
        totalCars = 0;
    }

    function uri(uint256 _tokenId) public view override returns(string memory){
        require(exists(_tokenId), "URI: id doesn't exist");
        return string(abi.encodePacked(super.uri(_tokenId), Strings.toString(_tokenId) ,".json"));
    }

    function addCar(string memory _name, string memory _description, uint256 _price, uint256 _category) public onlyOwner {
        totalCars++;
        cars[totalCars] = Car({
            name: _name,
            description: _description,
            price: _price,
            category: _category
        });
    }

    function mintCar(uint256 _carId, uint256 _amount) public {
        require(_carId <= totalCars, "Car ID does not exist");
        require(_carId > 0, "Car ID does not exist");
        require(totalMinted[_carId] + _amount < MAXSUPPLY, "Sale has ended");
        
        Car memory car = cars[_carId];

        totalMinted[_carId]++;

        uint256 totalPrice = car.price * _amount;

        require(USDT.transferFrom(msg.sender, address(this), totalPrice), "USDT transfer failed");

        _mint(msg.sender, _carId, _amount, "");

        for (uint256 i = 0; i < _amount; i++) {
            carsOwnedByWallet[msg.sender].push(_carId);
        }
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

    function getCarsOwnedByWallet(address wallet) public view returns (uint256[] memory) {
        return carsOwnedByWallet[wallet];
    }

    function withdrawUSDT(uint256 amount) public onlyOwner {
        require(USDT.transfer(owner(), amount), "Withdraw failed");
    }
}