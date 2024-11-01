const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("USDT", (m) => {
  const initialOwner = 0xe592427a0aece92de3edee1f18e0157c05861564; //Change
  
  const token = m.contract("USDT", [initialOwner], {});

  return { token };
});