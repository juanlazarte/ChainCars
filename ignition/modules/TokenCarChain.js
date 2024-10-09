const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("CarChainToken", (m) => {
  const token = m.contract("CarChainToken", [IERC1155Add, IERC20Add], {});

  return { token };
});