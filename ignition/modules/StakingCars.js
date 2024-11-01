const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("StakingChainCars", (m) => {
  const IERC1155CCAdd = 0xe592427a0aece92de3edee1f18e0157c05861564; //Change
  const IERC20USDTAdd = 0xe592427a0aece92de3edee1f18e0157c05861564; //Change

  const staking = m.contract("StakingChainCars", [IERC1155CCAdd, IERC20USDTAdd], {});

  return { staking };
});