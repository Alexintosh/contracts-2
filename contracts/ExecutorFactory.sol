
pragma experimental ABIEncoderV2;
pragma solidity >=0.5.0 <0.7.0;

import "./FlashloanExecutor.sol";

contract ExecutorFactory {
    constructor() public {
    }

    /* Emit appropriate events for scoring */
   function execute (address _provider, FlashloanExecutor.TxnLeg[] memory _legs) public {
       FlashloanExecutor sd = new FlashloanExecutor(_provider, _legs);
       sd.testLegs();
       delete sd;
   }
}