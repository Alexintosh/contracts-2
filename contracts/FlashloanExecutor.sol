pragma experimental ABIEncoderV2;
pragma solidity >=0.5.0 <0.7.0;

import "./interfaces/aave-protocol/FlashLoanReceiverBase.sol";
import "./interfaces/aave-protocol/ILendingPool.sol";
import "./Enum.sol";

contract FlashloanExecutor is FlashLoanReceiverBase {
    using SafeMath for uint256;

    uint256 private constant FLASHLOAN_FEE_TOTAL = 35;

    struct TxnLeg {
        address to;
        bytes input;
        uint256 value;
        Enum.Operation callType;
    }

    event OperationExecuted(address indexed to, uint256 amount);

    constructor(address _provider) FlashLoanReceiverBase(_provider) public {
    }

    function execute(address to, uint256 value, bytes memory data, Enum.Operation operation, uint256 txGas)
        internal
        returns (bool success)
    {
        if (operation == Enum.Operation.Call)
            success = executeCall(to, value, data, txGas);
        else if (operation == Enum.Operation.DelegateCall)
            success = executeDelegateCall(to, data, txGas);
        else
            success = false;
    }

    function executeCall(address to, uint256 value, bytes memory data, uint256 txGas)
        internal
        returns (bool success)
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    function executeDelegateCall(address to, bytes memory data, uint256 txGas)
        internal
        returns (bool success)
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
        }
    }

    function estimateFee(uint256 amount) pure public returns (uint256 fee) {
        //calculate amount fee
        uint256 amountFee = amount.mul(FLASHLOAN_FEE_TOTAL).div(10000);

        return amountFee;
    }

    /**
    * @dev run Allows specified _receiver to borrow(**Without Collateral**) from the _reserve pool(lender), and calls executeOperation() on the _receiver contract.
    * @param asset Address of the asset to be borrowed ex: Dai, Usdc etc.
    * @param amt Total amount to be borrowed for flash loan.
    * @notice onlyOwner This function can only be called by the contract owner.
    */
    function run(address asset, uint256 amt, TxnLeg[] memory legs) payable public {
        bytes memory data = abi.encode(legs);
        ILendingPool lendingPool = ILendingPool(addressesProvider.getLendingPool());
        lendingPool.flashLoan(address(this), asset, amt, data);
    }

    /**
    * @dev executeOperation This function is called after your contract has received the flash loaned amount
    * @param _reserve Address of the reserve from which loan is borrowed.
    * @param _amount Total amount borrowed for flash loan.
    * @param _fee Total fee for flash loan.
    * @param _params these calldata bytes are from abi encoded params of flashloan() function.
    * @notice override As executeOperation is overriden.
    */
    function executeOperation(address _reserve, uint256 _amount, uint256 _fee, bytes calldata _params) override external {
        //Check if the flash loan was successful
        uint256 balance0 = getBalanceInternal(address(this), _reserve);
        require(_amount <= balance0, "Invalid balance, was the flashLoan successful?");

        TxnLeg[] memory legs = abi.decode(_params, (TxnLeg[]));
        for(uint i = 0; i < legs.length; i++) {
            TxnLeg memory leg = legs[i];

            execute(leg.to, leg.value, leg.input, leg.callType, gasleft());
        }

        //calculate profit and emit event
        uint256 balance1 = getBalanceInternal(address(this), _reserve);
        uint256 pl = balance1.sub(balance0);
        emit OperationExecuted(tx.origin, pl);

        if(pl > 0 && _reserve == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            tx.origin.transfer(pl);
        }

        //return the loan back to the pool
        uint totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }
}
