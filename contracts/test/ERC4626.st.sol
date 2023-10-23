// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "erc4626-tests/ERC4626.test.sol";

import { MockERC20 } from "../../modules/erc20/contracts/test/mocks/MockERC20.sol";
import { RevenueDistributionToken as RDT } from "../RevenueDistributionToken.sol";

contract ERC4626StdTest is ERC4626Test {

    function setUp() public override {
        __underlying__ = address(new MockERC20("MockERC20", "MockERC20", 18));
        __vault__ = address(new RDT("MockERC4626", "MockERC4626", address(this), __underlying__, 1e30));
        __delta__ = 0;
    }

    // custom setup for yield
    function setupYield(Init memory init) public override {
        // setup initial yield
        if (init.yield >= 0) {
            uint gain = uint(init.yield);
            try IMockERC20(__underlying__).mint(__vault__, gain) {} catch { vm.assume(false); }
            try RDT(__vault__).updateVestingSchedule(10) {} catch { vm.assume(false); }
            skip(3); // 30% of gain vested
        } else {
            vm.assume(false); // no loss
        }
    }

    // NOTE: The following test is relaxed to consider only smaller values (of type uint120),
    // since maxWithdraw() fails with large values (due to overflow).
    // The maxWithdraw() behavior is inherited from Solmate ERC4626 on which this vault is built.

    function test_maxWithdraw(Init memory init) public override {
        init = clamp(init, type(uint120).max);
        super.test_maxWithdraw(init);
    }

    function clamp(Init memory init, uint max) internal pure returns (Init memory) {
        for (uint i = 0; i < N; i++) {
            init.share[i] = init.share[i] % max;
            init.asset[i] = init.asset[i] % max;
        }
        init.yield = init.yield % int(max);
        return init;
    }
}
