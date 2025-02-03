pragma solidity 0.8.28;

import {Test} from "forge-std/src/Test.sol";
import {ConceroClient} from "contracts/ConceroClient/ConceroClient.sol";
import {ConceroClientMock} from "../mocks/ConceroClientMock.sol";
import {DeployConceroRouterScript} from "../scripts/DeployConceroRouter.s.sol";
import {IConceroClient} from "contracts/ConceroClient/interfaces/IConceroClient.sol";

contract ConceroClientTest is Test {
    address internal s_conceroRouter = makeAddr("conceroRouter");

    /* REVERTS */

    function test_conceroReceiveInvalidConceroRouter_revert() public {
        vm.createSelectFork(vm.envString("RPC_URL_BASE"));
        DeployConceroRouterScript deployConceroRouterScript = new DeployConceroRouterScript();
        // @dev TODO: move this logic inside DeployConceroRouterScript
        deal(
            deployConceroRouterScript.getLinkAddress(),
            deployConceroRouterScript.getDeployer(),
            10_000 * 1e18
        );
        address conceroRouter = deployConceroRouterScript.run();
        ConceroClientMock conceroClient = new ConceroClientMock(conceroRouter);

        bytes memory revertSelector = abi.encodeWithSelector(
            ConceroClient.InvalidConceroRouter.selector,
            s_conceroRouter
        );

        IConceroClient.Message memory message = IConceroClient.Message({
            id: bytes32(0),
            srcChainSelector: 0,
            sender: address(0),
            data: ""
        });

        vm.startPrank(s_conceroRouter);
        vm.expectRevert(revertSelector);
        conceroClient.conceroReceive(message);
    }

    function test_constructorZeroConceroRouter_revert() public {
        bytes memory revertSelector = abi.encodeWithSelector(
            ConceroClient.InvalidConceroRouter.selector,
            address(0)
        );

        vm.expectRevert(revertSelector);
        new ConceroClientMock(address(0));
    }

    function test_constructorEmptyConceroRouter_revert() public {
        bytes memory revertSelector = abi.encodeWithSelector(
            ConceroClient.InvalidConceroRouter.selector,
            s_conceroRouter
        );

        vm.expectRevert(revertSelector);
        new ConceroClientMock(s_conceroRouter);
    }
}
