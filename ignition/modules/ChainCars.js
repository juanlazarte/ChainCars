const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("ChainCars", (m) => {
  const usdtAdd = 0xe592427a0aece92de3edee1f18e0157c05861564; //Change

  const chainCars = m.contract("ChainCars", [usdtAdd], {});

  return { chainCars };
});
