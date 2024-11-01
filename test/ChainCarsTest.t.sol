// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../contracts/ChainCars.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Mock de USDT para pruebas
contract MockUSDT is ERC20 {
    constructor() ERC20("Mock USDT", "mUSDT") {
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }
}

contract ChainCarsTest is Test {
    ChainCars public chainCars;
    MockUSDT public usdt;
    address public owner;
    address public user;

    function setUp() public {
        // Configurar contratos y fondos iniciales
        usdt = new MockUSDT();
        chainCars = new ChainCars(address(usdt));
        owner = address(this); // Owner of the contract
        user = vm.addr(1); // Mock user address

        // Proveer fondos iniciales al usuario
        usdt.transfer(user, 1_000 * 10 ** usdt.decimals());
    }

    function testAddCar() public {
        vm.prank(owner);
        chainCars.addCar(
            "Sedan",
            "Comfortable family car",
            100 * 10 ** usdt.decimals(),
            1
        );
        (
            string memory name,
            string memory description,
            uint256 price,
            uint256 category
        ) = chainCars.cars(1);

        assertEq(name, "Sedan");
        assertEq(description, "Comfortable family car");
        assertEq(price, 100 * 10 ** usdt.decimals());
        assertEq(category, 1);
        assertEq(chainCars.totalCars(), 1);
    }

    function testFail_AddCarAsNonOwner() public {
        vm.expectRevert("Ownable: caller is not the owner"); // Esperar que se revierta la transacción con el mensaje de error
        vm.startPrank(user);

        chainCars.addCar(
            "SUV",
            "Sport Utility Vehicle",
            200 * 10 ** usdt.decimals(),
            2
        );
        vm.stopPrank();
    }

    function testEditCar() public {
        vm.prank(owner);
        chainCars.addCar("Agile", "Negro", 100, 1);
        // Editar el auto
        chainCars.editCar(1, "Agile 1.4", "Negro 5 puertas", 150, 2);

        (
            string memory name,
            string memory description,
            uint256 price,
            uint256 category
        ) = chainCars.cars(1);

        // Verificar los cambios
        assertEq(name, "Agile 1.4");
        assertEq(description, "Negro 5 puertas");
        assertEq(price, 150);
        assertEq(category, 2);
    }

    function testFail_EditCarNonOwner() public {
        vm.prank(owner);
        // Agregar un auto
        chainCars.addCar("Car2", "Description2", 200, 1);

        vm.expectRevert("Ownable: caller is not the owner"); // Esperar que se revierta la transacción con el mensaje de error
        vm.startPrank(user);
        chainCars.editCar(1, "Car2 Edited", "Description2 Edited", 250, 2);
        vm.stopPrank();
    }

    function testMintCar() public {
        // Agregar un auto antes de hacer mint
        vm.prank(owner);
        chainCars.addCar(
            "SUV",
            "Sport Utility Vehicle",
            200 * 10 ** usdt.decimals(),
            2
        );

        // Simular que el contrato ya tiene suficiente autorización
        vm.prank(user);
        usdt.approve(address(chainCars), type(uint256).max); // Dar aprobación máxima

        // Ejecutar el mint de un auto
        vm.prank(user);
        chainCars.mintCar(1, 1);

        // Verificar el balance de tokens del usuario
        assertEq(chainCars.balanceOf(user, 1), 1);
    }

    function testGetAllCars() public {
        // Agregar autos
        vm.prank(owner);
        chainCars.addCar(
            "Sedan",
            "Comfortable family car",
            100 * 10 ** usdt.decimals(),
            1
        );
        vm.prank(owner);
        chainCars.addCar(
            "Truck",
            "Heavy duty truck",
            150 * 10 ** usdt.decimals(),
            2
        );

        // Obtener todos los autos
        ChainCars.Car[] memory allCars = chainCars.getAllCars();

        assertEq(allCars.length, 2);
        assertEq(allCars[0].name, "Sedan");
        assertEq(allCars[1].name, "Truck");
    }

    function testGetCarCategory() public {
        vm.prank(owner);
        chainCars.addCar(
            "Coupe",
            "Sporty coupe car",
            120 * 10 ** usdt.decimals(),
            3
        );

        uint256 category = chainCars.getCarCategory(1);
        assertEq(category, 3);
    }

    function testWithdrawUSDT() public {
        // Agregar un auto y realizar minting
        vm.prank(owner);
        chainCars.addCar(
            "Convertible",
            "Luxury convertible car",
            250 * 10 ** usdt.decimals(),
            4
        );

        vm.prank(user);
        usdt.approve(address(chainCars), type(uint256).max); // Dar aprobación máxima
        vm.prank(user);
        chainCars.mintCar(1, 1);

        // Retirar fondos
        uint256 balanceBefore = usdt.balanceOf(owner);
        vm.prank(owner);
        chainCars.withdrawUSDT(250 * 10 ** usdt.decimals());
        uint256 balanceAfter = usdt.balanceOf(owner);

        assertEq(balanceAfter, balanceBefore + 250 * 10 ** usdt.decimals());
    }

    function testFail_WithdrawUSDTAsNonOwner() public {
        // Agregar un auto y realizar minting
        vm.prank(owner);
        chainCars.addCar(
            "Convertible",
            "Luxury convertible car",
            250 * 10 ** usdt.decimals(),
            4
        );
        // Intentar retirar USDT como un usuario que no es el owner
        uint256 amountToWithdraw = 250 * 10 ** usdt.decimals();

        // Asegurarse de que el owner tenga suficiente USDT antes de la prueba
        vm.prank(owner);
        usdt.approve(address(chainCars), type(uint256).max); // Aprobar cantidad máxima
        vm.prank(owner);
        chainCars.mintCar(1, 1); // Mintear un auto para que el owner tenga USDT

        // Intentar retirar USDT como usuario no propietario
        vm.prank(user); // Cambia a la dirección del usuario
        vm.expectRevert("Ownable: caller is not the owner"); // Esperar que se revierta la transacción
        chainCars.withdrawUSDT(amountToWithdraw);
    }
}
