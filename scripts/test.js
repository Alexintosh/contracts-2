// We require the Buidler Runtime Environment explicitly here. This is optional
// when running the script with `buidler run <script>`: you'll find the Buidler
// Runtime Environment's members available as global variable in that case.

const ethers = require('ethers');
require('dotenv').config()
const ERC20_ABI = require('./erc20.abi.json');
const FL_EXECUTOR_ABI = require("../artifacts/FlashloanExecutor.json").abi;
const UNISWAP_ABI = require("../artifacts/IUniswapV2Router01.json").abi;
const UNISWAP_FACTORY_ABI = require("../artifacts/IUniswapV2Factory.json").abi;
const UNISWAP_PAIR_ABI = require('../artifacts/IUniswapV2Pair.json').abi;
const constants = require("../test/kovan");
let wallet = new ethers.Wallet(process.env.PRIVATE_KEY, ethers.getDefaultProvider('kovan'));

async function main() {
    // const weiValue = web3.utils.toWei('10', 'ether');
    // const minValue = web3.utils.toWei('9.99', 'ether');
    // // console.log(web3.eth.abi.encodeFunctionCall({
    // //     name: 'transfer',
    // //     type: 'function',
    // //     inputs: [{
    // //         type: 'address',
    // //         name: 'to'
    // //     }, {
    // //         type: 'uint',
    // //         name: 'value'
    // //     }]
    // // }, ['0x038AD9777dC231274553ff927CcB0Fd21Cd42fb9', weiValue]));

    // const daiInterface = new ethers.utils.Interface(ERC20_ABI);
    // //const txData = daiInterface.functions.transfer.encode(['0x038AD9777dC231274553ff927CcB0Fd21Cd42fb9', weiValue]);
    // const txData = daiInterface.functions.balanceOf.encode(['0xe3818504c1b32bf1557b16c238b2e01fd3149c17']);
    // console.log('txData', txData);

    // console.log(uniswap_abi);
    // const uniSwap = new ethers.utils.Interface(uniswap_abi.abi);
    // const input = uniSwap.functions.swapExactTokensForTokens.encode([weiValue, minValue, ['0xff795577d9ac8bd7d90ee22b6c1703490b6512fd', '0xaaf64bfcc32d0f15873a02163e7e500671a4ffcd'], '0x038AD9777dC231274553ff927CcB0Fd21Cd42fb9', 1590969600]);
    // console.log(input);

    const raw_tx = {
        amountIn: ethers.utils.parseUnits("10", "ether"),
        amountOutMin: ethers.utils.parseUnits("9.9", "ether"),
        path: [
            "0xd0A1E359811322d97991E03f863a0C30C2cF029C", // First must always be WETH
            "0xff795577d9ac8bd7d90ee22b6c1703490b6512fd", // Aave DAI
            "0xe22da380ee6B445bb8273C81944ADEB6E8450422" // Aave USDC
        ],
        to: "0x038AD9777dC231274553ff927CcB0Fd21Cd42fb9",
        deadline: 1590969600,
    };
    const uniswap = new ethers.utils.Interface(UNISWAP_ABI);
    const txData = uniswap.functions.swapETHForExactTokens.encode([
        raw_tx.amountOutMin,
        raw_tx.path,
        raw_tx.to,
        raw_tx.deadline,
    ]);
    const txTo = constants.UNISWAP_ADDRESS;

    const txLegs = [
        [txTo, txData, 0, 0]
    ];

    let flashLoanContract = new ethers.Contract(constants.FL_EXECUTOR, FL_EXECUTOR_ABI, ethers.getDefaultProvider("kovan"));
    let overrides = {
        value: ethers.utils.parseEther('0.5'),
    };
    let flashLoanSigner = flashLoanContract.connect(wallet);
    const txn = await flashLoanSigner.run(constants.AAVE_ETHEREUM, raw_tx.amountIn, txLegs, overrides);
    console.log(txn)
}
main();