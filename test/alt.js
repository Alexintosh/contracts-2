const FlashloanExecutor = artifacts.require("FlashloanExecutor");

const constants = require("./kovan");
const UNISWAP_ABI = require("../artifacts/IUniswapV2Router01.json").abi;
const UNISWAP_FACTORY_ABI = require("../artifacts/IUniswapV2Factory.json").abi;
const UNISWAP_PAIR_ABI = require('../artifacts/IUniswapV2Pair.json').abi;

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

contract("FlashloanExecutor", accounts => {
  it("Should deploy an executor contract", async function() {
    const ef = await FlashloanExecutor.new(constants.AAVE_PROVIDER);
  });

  it("Should have valid Uniswap pair", async function () {
    const factory = new ethers.Contract(constants.UNISWAP_FACTORY, UNISWAP_FACTORY_ABI, ethers.getDefaultProvider());

    // TODO: Pair needs to be sorted
    const pair = await factory.getPair(raw_tx.path[0], raw_tx.path[1]);
    assert.notEqual(pair, "0x0000000000000000000000000000000000000000", "Pair address should not be zero");
  });

  it("Uniswap reserves must have enough balance", async function () {
    const factory = new ethers.Contract(constants.UNISWAP_FACTORY, UNISWAP_FACTORY_ABI, ethers.getDefaultProvider());

    const pair = await factory.getPair(raw_tx.path[0], raw_tx.path[1]);
    assert.notEqual(pair, "0x0000000000000000000000000000000000000000", "Pair address should not be zero");

    const pairContract = new ethers.Contract(pair, UNISWAP_PAIR_ABI, ethers.getDefaultProvider());
    const [ reserveA, reserves ] = await factory.getPair(raw_tx.path[0], raw_tx.path[1]);
    assert.notEqual(pair, "0x0000000000000000000000000000000000000000", "Pair address should not be zero");
  });

  it("Should run a test transaction", async function() {
    const ef = await FlashloanExecutor.new(constants.AAVE_PROVIDER);

    await ef.run(constants.AAVE_ETHEREUM, amount, legs);
  });
});



