pragma solidity 0.8.28;

import {Test} from "forge-std/src/Test.sol";
import {DeployConceroRouterHarnessScript} from "../scripts/DeployConceroRouterHarness.s.sol";
import {ConceroRouter} from "contracts/ConceroRouter.sol";
import {IConceroRouter} from "contracts/interfaces/IConceroRouter.sol";
import {IConceroRouterStorage} from "contracts/interfaces/IConceroRouterStorage.sol";
import {ConceroRouterHarness} from "../harnesses/ConceroRouterHarness.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {VmSafe} from "forge-std/src/Vm.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConceroClientMock} from "../mocks/ConceroClientMock.sol";

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
    uint256 internal s_baseForkId = vm.createSelectFork(vm.envString("RPC_URL_BASE"));
    uint64 internal s_arbChainSelector = uint64(vm.envUint("CL_CCIP_CHAIN_SELECTOR_ARBITRUM"));
    uint64 internal s_baseChainSelector = uint64(vm.envUint("CL_CCIP_CHAIN_SELECTOR_BASE"));
    address internal s_usdcBase = vm.envAddress("USDC_BASE");

    function setUp() public {
        deal(
            s_deployConceroRouterScript.getLinkAddress(),
            s_deployConceroRouterScript.getDeployer(),
            10_000 * 1e18
        );

        s_conceroRouter = ConceroRouterHarness(s_deployConceroRouterScript.run());
        s_conceroRouter.exposed_setLastGasPrice(s_arbChainSelector, ARB_GAS_PRICE);
        s_conceroRouter.exposed_setLatestLinkNativeRate(LINK_NATIVE_RATE);
        s_conceroRouter.exposed_setLatestLinkUsdcRate(LINK_USDC_RATE);
        s_conceroRouter.exposed_setLatestNativeUsdcRate(NATIVE_USDC_RATE);
        s_conceroRouter.exposed_setClfFeesInUsdc(s_arbChainSelector, ARB_CLF_FEE_IN_USDC);
        s_conceroRouter.exposed_setClfFeesInUsdc(s_baseChainSelector, BASE_CLF_FEE_IN_USDC);

        vm.prank(s_deployConceroRouterScript.getDeployer());
        // @dev doesnt matter what the value is
        s_conceroRouter.setDstConceroRouterByChain(s_arbChainSelector, makeAddr("arb router"));
    }

    function test_sendMessage() public {
        vm.pauseGasMetering();
        address client = makeAddr("client");
        deal(s_usdcBase, client, 1_000_000 * USDC_DECIMALS);
        uint256 clientBalanceBefore = IERC20(s_usdcBase).balanceOf(client);
        uint32 dstChainGasLimit = 1_000_000;
        bytes memory messageData = new bytes(10);
        vm.startPrank(client);
        vm.resumeGasMetering();

        IConceroRouter.MessageRequest memory messageReq = IConceroRouter.MessageRequest({
            feeToken: s_usdcBase,
            receiver: client,
            dstChainSelector: s_arbChainSelector,
            dstChainGasLimit: dstChainGasLimit,
            data: messageData
        });

        uint256 feeInUsdc = s_conceroRouter.getFeeInUsdc(s_arbChainSelector);
        IERC20(s_usdcBase).approve(address(s_conceroRouter), feeInUsdc);

        //         @dev check only data without indexed id
        vm.pauseGasMetering();
        vm.expectEmit(false, false, false, true, address(s_conceroRouter));
        emit IConceroRouter.ConceroMessageSent(
            bytes32(0),
            client,
            client,
            abi.encode(IConceroRouter.EvmArgs({dstChainGasLimit: dstChainGasLimit})),
            messageData
        );
        vm.resumeGasMetering();

        s_conceroRouter.sendMessage(messageReq);
        vm.stopPrank();
        vm.pauseGasMetering();

        uint256 clientBalanceAfter = IERC20(s_usdcBase).balanceOf(client);
        assertEq(clientBalanceBefore - feeInUsdc, clientBalanceAfter);
        vm.resumeGasMetering();
    }

    function test_receiveUnconfirmedMessage() public {
        bytes32 conceroMessageId = keccak256("concero message id");
        bytes32 conceroMessageHash = keccak256("concero message hash");

        vm.prank(s_conceroRouter.exposed_getMessenger0());
        vm.recordLogs();
        s_conceroRouter.receiveUnconfirmedMessage(
            conceroMessageId,
            s_arbChainSelector,
            conceroMessageHash
        );

        VmSafe.Log[] memory logs = vm.getRecordedLogs();

        bytes32 clfReqId;
        // @dev find clf req id in logs
        for (uint256 i; i < logs.length; ++i) {
            if (logs[i].topics[0] == FunctionsClient.RequestSent.selector) {
                clfReqId = logs[i].topics[1];
                break;
            }
        }

        assertEq(
            uint8(s_conceroRouter.exposed_getClfReqTypeByClfReqId(clfReqId)),
            uint8(IConceroRouterStorage.ClfReqType.ConfirmMessage)
        );
        assertEq(s_conceroRouter.exposed_getConceroMessageIdByClfReqId(clfReqId), conceroMessageId);
    }

    function test_handleOracleFulfillmentWithError() public {
        bytes32 clfReqId = keccak256("clf req id");
        bytes memory response = new bytes(0);
        bytes memory err = new bytes(1);

        s_conceroRouter.exposed_setClfReqTypeByClfReqId(
            clfReqId,
            IConceroRouterStorage.ClfReqType.ConfirmMessage
        );

        vm.prank(s_conceroRouter.exposed_getClfRouter());
        FunctionsClient(address(s_conceroRouter)).handleOracleFulfillment(clfReqId, response, err);

        assertEq(
            uint8(s_conceroRouter.exposed_getClfReqTypeByClfReqId(clfReqId)),
            uint8(IConceroRouterStorage.ClfReqType.Empty)
        );
    }

    function test_handleOracleFulfillmentConfirmMessage() public {
        bytes32 clfReqId = keccak256("clf req id");
        bytes32 conceroMessageId = keccak256("concero message id");
        address receiver = address(new ConceroClientMock(address(s_conceroRouter)));
        address sender = makeAddr("sender");
        uint64 srcChainSelector = s_arbChainSelector;
        uint24 gasLimit = 1000000;
        bytes memory messageData = new bytes(0);
        bytes memory err = new bytes(0);
        bytes memory response = abi.encodePacked(
            receiver,
            sender,
            srcChainSelector,
            gasLimit,
            messageData
        );
        bytes32 conceroMessageHash = keccak256(
            abi.encode(
                conceroMessageId,
                srcChainSelector,
                s_conceroRouter.exposed_getChainSelector(),
                sender,
                receiver,
                keccak256(messageData)
            )
        );

        s_conceroRouter.exposed_setClfReqTypeByClfReqId(
            clfReqId,
            IConceroRouterStorage.ClfReqType.ConfirmMessage
        );
        s_conceroRouter.exposed_setConceroMessageIdByClfReqId(clfReqId, conceroMessageId);
        s_conceroRouter.exposed_setMessageHashByConceroMessageId(
            conceroMessageId,
            conceroMessageHash
        );

        vm.prank(s_conceroRouter.exposed_getClfRouter());
        FunctionsClient(address(s_conceroRouter)).handleOracleFulfillment(clfReqId, response, err);

        assertEq(
            uint8(s_conceroRouter.exposed_getClfReqTypeByClfReqId(clfReqId)),
            uint8(IConceroRouterStorage.ClfReqType.Empty)
        );
    }

    /* REVERT TESTS */

    function test_sendMessageInvalidMessageDataSize_revert() public {
        address client = makeAddr("client");
        uint256 messageSize = s_conceroRouter.exposed_getMaxMessageDataSize() + 1;

        IConceroRouter.MessageRequest memory messageReq = IConceroRouter.MessageRequest({
            feeToken: s_usdcBase,
            receiver: client,
            dstChainSelector: s_arbChainSelector,
            dstChainGasLimit: 1000000,
            data: new bytes(messageSize)
        });

        vm.expectRevert(IConceroRouter.MessageTooLarge.selector);
        s_conceroRouter.sendMessage(messageReq);
    }

    function test_sendMessageUnsupportedFeeToken_revert() public {
        address client = makeAddr("client");
        IConceroRouter.MessageRequest memory messageReq = IConceroRouter.MessageRequest({
            feeToken: makeAddr("invalid token"),
            receiver: client,
            dstChainSelector: s_arbChainSelector,
            dstChainGasLimit: 1000000,
            data: new bytes(1)
        });

        vm.expectRevert(IConceroRouter.UnsupportedFeeToken.selector);
        s_conceroRouter.sendMessage(messageReq);
    }

    function test_sendMessageInvalidReceiver_revert() public {
        IConceroRouter.MessageRequest memory messageReq = IConceroRouter.MessageRequest({
            feeToken: s_usdcBase,
            receiver: address(0),
            dstChainSelector: s_arbChainSelector,
            dstChainGasLimit: 1000000,
            data: new bytes(1)
        });

        vm.expectRevert(IConceroRouter.InvalidReceiver.selector);
        s_conceroRouter.sendMessage(messageReq);
    }

    function test_sendMessageInvalidDstChain_revert() public {
        address client = makeAddr("client");
        IConceroRouter.MessageRequest memory messageReq = IConceroRouter.MessageRequest({
            feeToken: s_usdcBase,
            receiver: client,
            dstChainSelector: 0,
            dstChainGasLimit: 1000000,
            data: new bytes(1)
        });

        deal(s_usdcBase, client, 100 * USDC_DECIMALS);
        vm.startPrank(client);
        uint256 feeInUsdc = s_conceroRouter.getFeeInUsdc(s_arbChainSelector);
        IERC20(s_usdcBase).approve(address(s_conceroRouter), feeInUsdc);

        vm.expectRevert(IConceroRouter.InvalidChainSelector.selector);
        s_conceroRouter.sendMessage(messageReq);
    }

    function test_sendMessageInvalidDstChainGasLimit_revert() public {
        address client = makeAddr("client");

        IConceroRouter.MessageRequest memory messageReq = IConceroRouter.MessageRequest({
            feeToken: s_usdcBase,
            receiver: client,
            dstChainSelector: s_arbChainSelector,
            dstChainGasLimit: 0,
            data: new bytes(1)
        });

        vm.expectRevert(IConceroRouter.InvalidDstChainGasLimit.selector);
        s_conceroRouter.sendMessage(messageReq);

        messageReq.dstChainGasLimit = s_conceroRouter.exposed_getMaxDstChainGasLimit() + 1;

        vm.expectRevert(IConceroRouter.InvalidDstChainGasLimit.selector);
        s_conceroRouter.sendMessage(messageReq);
    }

    function test_receiveUnconfirmedMessageNotMessenger_revert() public {
        vm.startPrank(makeAddr("not messenger"));

        vm.expectRevert(IConceroRouter.NotMessenger.selector);
        s_conceroRouter.receiveUnconfirmedMessage(bytes32(0), uint64(0), bytes32(0));
    }

    function test_setDstConceroRouterByChainNotAdmin_revert() public {
        vm.startPrank(makeAddr("not admin"));
        vm.expectRevert(IConceroRouter.NotAdmin.selector);
        s_conceroRouter.setDstConceroRouterByChain(uint64(2), makeAddr("arb router"));
    }

    function test_setClfFeeInUsdcNotAdmin_revert() public {
        vm.startPrank(makeAddr("not admin"));
        vm.expectRevert(IConceroRouter.NotAdmin.selector);
        s_conceroRouter.setClfFeeInUsdc(uint64(2), 100);
    }

    function test_setDstConceroRouterByChainInvalidConceroRouter_revert() public {
        vm.startPrank(s_conceroRouter.exposed_getAdmin());
        vm.expectRevert(IConceroRouter.InvalidConceroRouter.selector);
        s_conceroRouter.setDstConceroRouterByChain(uint64(2), address(0));
    }

    function test_setDstConceroRouterByChainInvalidChainSelector_revert() public {
        vm.startPrank(s_conceroRouter.exposed_getAdmin());
        vm.expectRevert(IConceroRouter.InvalidChainSelector.selector);
        s_conceroRouter.setDstConceroRouterByChain(uint64(0), makeAddr("some address"));
    }

    function test_setClfFeeInUsdcInvalidChainSelector_revert() public {
        vm.startPrank(s_conceroRouter.exposed_getAdmin());
        vm.expectRevert(IConceroRouter.InvalidChainSelector.selector);
        s_conceroRouter.setClfFeeInUsdc(uint64(0), 100);
    }

    function test_receiveUnconfirmedMessageSecondTime_revert() public {
        bytes32 conceroMessageId = keccak256("concero message id");
        bytes32 conceroMessageHash = keccak256("concero message hash");

        vm.startPrank(s_conceroRouter.exposed_getMessenger0());

        s_conceroRouter.receiveUnconfirmedMessage(
            conceroMessageId,
            s_arbChainSelector,
            conceroMessageHash
        );

        vm.expectRevert(IConceroRouter.MessageAlreadyExists.selector);
        s_conceroRouter.receiveUnconfirmedMessage(
            conceroMessageId,
            s_arbChainSelector,
            conceroMessageHash
        );
    }

    function test_receiveUnconfirmedMessageInvalidSrcChainSelector() public {
        bytes32 conceroMessageId = keccak256("concero message id");
        bytes32 conceroMessageHash = keccak256("concero message hash");

        vm.startPrank(s_conceroRouter.exposed_getMessenger0());
        vm.expectRevert(IConceroRouter.InvalidChainSelector.selector);
        s_conceroRouter.receiveUnconfirmedMessage(conceroMessageId, uint64(0), conceroMessageHash);
    }

    function test_handleOracleFulfillmentUnexpectedReqId_revert() public {
        bytes32 clfReqId = keccak256("clf req id");
        bytes memory response = new bytes(0);
        bytes memory err = new bytes(0);

        vm.startPrank(s_conceroRouter.exposed_getClfRouter());
        vm.expectRevert(IConceroRouter.UnexpectedCLFRequestId.selector);
        FunctionsClient(address(s_conceroRouter)).handleOracleFulfillment(clfReqId, response, err);
    }
}
