pragma solidity 0.8.28;

import {Test} from "forge-std/src/Test.sol";
import {DeployConceroRouterHarnessScript} from "../scripts/DeployConceroRouterHarness.s.sol";
import {ConceroRouter} from "contracts/ConceroRouter.sol";
import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";
import {ConceroRouterHarness} from "../harnesses/ConceroRouterHarness.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ConceroRouterTest is Test {
    /* CONSTANTS */
    uint256 internal constant ARB_GAS_PRICE = 10000000; // @dev 0.01 gwei
    uint256 internal constant LINK_NATIVE_RATE = 0.00752868 ether;
    uint256 internal constant LINK_USDC_RATE = 25.04 ether;
    uint256 internal constant NATIVE_USDC_RATE = 3_266.05 ether;
    uint256 internal constant ARB_CLF_FEE_IN_USDC = 0.04 * 1e6;
    uint256 internal constant BASE_CLF_FEE_IN_USDC = 0.06 * 1e6;
    uint256 internal constant USDC_DECIMALS = 1e6;

    /* STORAGE VARS */
    DeployConceroRouterHarnessScript internal s_deployConceroRouterScript =
        new DeployConceroRouterHarnessScript();
    ConceroRouterHarness internal s_conceroRouter;
    uint256 internal s_baseForkId = vm.createFork(vm.envString("RPC_URL_BASE"));
    uint64 internal s_arbChainSelector = uint64(vm.envUint("CL_CCIP_CHAIN_SELECTOR_ARBITRUM"));
    uint64 internal s_baseChainSelector = uint64(vm.envUint("CL_CCIP_CHAIN_SELECTOR_BASE"));
    address internal s_usdcBase = vm.envAddress("USDC_BASE");

    function setUp() public {
        s_conceroRouter = ConceroRouterHarness(s_deployConceroRouterScript.run(s_baseForkId));
        s_conceroRouter.exposed_setLastGasPrice(s_arbChainSelector, ARB_GAS_PRICE);
        s_conceroRouter.exposed_setLatestLinkNativeRate(LINK_NATIVE_RATE);
        s_conceroRouter.exposed_setLatestLinkUsdcRate(LINK_USDC_RATE);
        s_conceroRouter.exposed_setLatestNativeUsdcRate(NATIVE_USDC_RATE);
        s_conceroRouter.exposed_setClfFeesInUsdc(s_arbChainSelector, ARB_CLF_FEE_IN_USDC);
        s_conceroRouter.exposed_setClfFeesInUsdc(s_baseChainSelector, BASE_CLF_FEE_IN_USDC);
    }

    function test_getFee() public {
        vm.pauseGasMetering();
        address client = makeAddr("client");
        deal(s_usdcBase, client, 1_000_000 * USDC_DECIMALS);
        vm.startPrank(client);
        vm.resumeGasMetering();

        IConceroRouter.MessageRequest memory messageReq = IConceroRouter.MessageRequest({
            feeToken: s_usdcBase,
            receiver: client,
            dstChainSelector: s_arbChainSelector,
            dstChainGasLimit: 1_000_000,
            data: new bytes(1)
        });

        uint256 feeInUsdc = s_conceroRouter.getFeeInUsdc(s_arbChainSelector);
        IERC20(s_usdcBase).approve(address(s_conceroRouter), feeInUsdc);
        s_conceroRouter.sendMessage(messageReq);
        vm.stopPrank();
    }
}
