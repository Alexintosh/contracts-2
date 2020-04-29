pragma experimental ABIEncoderV2;
pragma solidity >=0.5.0 <0.7.0;

import "./interfaces/aave-protocol/FlashLoanReceiverBase.sol";
import "./interfaces/aave-protocol/ILendingPool.sol";
import "./Enum.sol";

contract FlashloanExecutor is FlashLoanReceiverBase {
    using SafeMath for uint256;

    event CallSuccessful(address indexed to, bytes input);
    event CallFailed(address indexed to, bytes input);

    constructor(address _provider) FlashLoanReceiverBase(_provider) public {}

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
   
    function testProxy(address asset,bytes memory data,Enum.Operation operation) public onlyOwner returns (bool) {
        return execute(asset,0,data,operation,gaslimit());
    }
    
    /**
    * @dev testFlashLoan Allows specified _receiver to borrow(**Without Collateral**) from the _reserve pool(lender), and calls executeOperation() on the _receiver contract.
    * @param amt Total amount to be borrowed for flash loan.
    * @param asset Address of the asset to be borrowed ex: Dai, Usdc etc.
    * @param data bytes-encoded extra parameters to use inside the executeOperation() function
    * @notice onlyOwner This function can only be called by the contract owner.
    */
    function testFlashLoan(uint256 amt,address asset, bytes memory data) public onlyOwner {
        ILendingPool lendingPool = ILendingPool(addressesProvider.getLendingPool());
        lendingPool.flashLoan(address(this),asset,amt,data);
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
        require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance, was the flashLoan successful?");
        //return the loan back to the pool
        bool success = execute(_reserve,0,_params,Enum.Operation.Call,gaslimit());
        if(success) {
            emit CallSuccessful(_reserve,_params);
        } else {
            emit CallFailed(_reserve,_params);
        }
        uint totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }
}
