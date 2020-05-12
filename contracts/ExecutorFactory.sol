
pragma experimental ABIEncoderV2;
pragma solidity >=0.5.0 <0.7.0;

import "./FlashloanExecutor.sol";

contract ExecutorFactory {
    constructor() public {
    }

    function testDeploy (address _provider, FlashloanExecutor.TxnLeg[] memory _legs ) public {
        FlashloanExecutor sd = new FlashloanExecutor(_provider, _legs);

        delete sd;
    }

    function testLegs (address _provider, FlashloanExecutor.TxnLeg[] memory _legs ) public {
        FlashloanExecutor sd = new FlashloanExecutor(_provider, _legs);

        require(sd.testLegs(), "Test must succedd");

        delete sd;
    }

    function testFlashLoan (address _provider,
     FlashloanExecutor.TxnLeg[] memory _legs,
     address _asset,
     uint256 _amount ) public {
        FlashloanExecutor sd = new FlashloanExecutor(_provider, _legs);

        sd.testFlashLoan(_asset, _amount);

        delete sd;
    }

    /* TODO: Emit appropriate events for scoring */
   function execute (address _provider,
    FlashloanExecutor.TxnLeg[] memory _legs,
    address asset,
    uint256 amount) public {
       FlashloanExecutor sd = new FlashloanExecutor(_provider, _legs);

       sd.testFlashLoan(asset, amount);

       delete sd;
   }
}