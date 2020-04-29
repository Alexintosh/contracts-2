pragma solidity >=0.5.0 <0.7.0;
import "./Enum.sol";
import "./interfaces/aave-protocol/FlashLoanReceiverBase.sol";
import "./interfaces/aave-protocol/ILendingPool.sol";
import "./interfaces/aave-protocol/ILendingPoolAddressesProvider.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/// @title FlashloanExecutor - A contract that can execute transactions after receiving a flashloan from aave
/// This was inspired from Gnosis safe and has been modified to integrate aave flashloan interfaces
contract FlashloanExecutor is FlashLoanReceiverBase {
    using SafeMath for uint256;
    uint256 private gas;

    constructor(address _provider) FlashLoanReceiverBase(_provider) public {}

    function execute(address to, uint256 value, bytes memory data, Enum.Operation operation, uint256 txGas)
        public
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

    /**
    * @dev flashloan Allows specified _receiver to borrow(**Without Collateral**) from the _reserve pool(lender), and calls executeOperation() on the _receiver contract.
    * @param amt Total amount to be borrowed for flash loan.
    * @param asset Address of the asset to be borrowed ex: Dai, Usdc etc.
    * @param data bytes-encoded extra parameters to use inside the executeOperation() function
    * @param _txGas ...
    * @notice onlyOwner This function can only be called by the contract owner.
    */
    function flashloan(uint256 amt, address asset,bytes memory data,uint256 _txGas) public onlyOwner {
        // ILendingPool lendingPool = ILendingPool(provider.getLendingPool());
        // token = IERC20(asset);
        // lendingPool.flashLoan(address(this),asset,amt,data);
        // gas = _txGas;
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
        //Perform the actual operation
        executeDelegateCall(this.owner(),_params,gas);
        //return the loan back to the pool
        uint totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }
}