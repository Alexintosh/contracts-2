const ExecutorFactory = artifacts.require("ExecutorFactory");

const constants = require("./kovan");
const ethers = require("ethers");

const tx = [{"to":"0xcDbE04934d89e97a24BCc07c3562DC8CF17d8167","txData":"0x38ed17390000000000000000000000000000000000000000000000008ac7230489e800000000000000000000000000000000000000000000000000008963dd8c2c5e000000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000038ad9777dc231274553ff927ccb0fd21cd42fb9000000000000000000000000000000000000000000000000000000005ed445000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000ff795577d9ac8bd7d90ee22b6c1703490b6512fd000000000000000000000000aaf64bfcc32d0f15873a02163e7e500671a4ffcd"}]
const legs = tx.map((item) => {
  return { to: item.to,
    input: item.txData,
    value: 0,
    callType: 0, }});

const amount = ethers.utils.parseEther("0.5");

contract("ExecutorFactory", accounts => {
  it("Should deploy an executor contract", async function() {
    const ef = await ExecutorFactory.new();

    await ef.testDeploy(constants.AAVE_PROVIDER, legs);
  });

  it("Should check the transaction legs", async function() {
    const ef = await ExecutorFactory.new();

    await ef.testLegs(constants.AAVE_PROVIDER, legs);
  });

  it("Should check the flash loan", async function() {
    const ef = await ExecutorFactory.new();

    await ef.testFlashLoan(constants.AAVE_PROVIDER, legs, constants.AAVE_ETHEREUM, amount);
  });

  it("Should run a test transaction", async function() {
    const ef = await ExecutorFactory.new();

    await ef.execute(constants.AAVE_PROVIDER, legs, constants.AAVE_ETHEREUM, amount);
  });
});



