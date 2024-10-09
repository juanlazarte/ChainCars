const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("StakingNft", (m) => {
  const IERC1155Add = 0xe592427a0aece92de3edee1f18e0157c05861564; //Change
  const IERC20Add = 0xe592427a0aece92de3edee1f18e0157c05861564; //Change

  const staking = m.contract("StakingNft", [IERC1155Add, IERC20Add], {});

  return { staking };
});