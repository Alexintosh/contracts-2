const AltFlashloanExecutor = artifacts.require("AltFlashloanExecutor");

const constants = require("./kovan");
const ethers = require("ethers");
const UNISWAP_ABI = require("../artifacts/IUniswapV2Router01.json").abi;

const raw_tx = {
  amountIn: ethers.utils.parseUnits("10", "ether"),
  amountOutMin: ethers.utils.parseUnits("9.9", "ether"),
  path: [
    "0xff795577d9ac8bd7d90ee22b6c1703490b6512fd",
    "0xaaf64bfcc32d0f15873a02163e7e500671a4ffcd",
  ],
  to: "0x038AD9777dC231274553ff927CcB0Fd21Cd42fb9",
  deadline: 1590969600,
};
const uniswap = new ethers.utils.Interface(UNISWAP_ABI);
const txData = uniswap.functions.swapExactTokensForTokens.encode([
    raw_tx.amountIn,
    raw_tx.amountOutMin,
    raw_tx.path,
    raw_tx.to,
    raw_tx.deadline]);
const txTo = constants.UNISWAP_ADDRESS;

const tx = [{"to": txTo,"txData": txData}];
const legs = tx.map((item) => {
  return { to: item.to,
    input: item.txData,
    value: 0,
    callType: 0, }});

const amount = ethers.utils.parseEther("0.5");

contract("AltFlashloanExecutor", accounts => {
  it("Should deploy an executor contract", async function() {
    const ef = await AltFlashloanExecutor.new(constants.AAVE_PROVIDER);
  });

  it("Should have valid test data", async function () {
    ;
  });

  it("Should run a test transaction", async function() {
    const ef = await AltFlashloanExecutor.new(constants.AAVE_PROVIDER);

    await ef.run(constants.AAVE_ETHEREUM, amount, legs);
  });
});



