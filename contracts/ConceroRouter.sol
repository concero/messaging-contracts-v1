//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.28;

import {ConceroRouterStorage} from "./storages/ConceroRouterStorage.sol";
import {FunctionsClient as ClfClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IConceroRouter} from "./interfaces/IConceroRouter.sol";
import {IConceroClient} from "./ConceroClient/interfaces/IConceroClient.sol";

contract ConceroRouter is ConceroRouterStorage, IConceroRouter, ClfClient {
    using SafeERC20 for IERC20;
    using FunctionsRequest for FunctionsRequest.Request;

    /* CONSTANT VARIABLES */

    uint24 internal constant MAX_DST_CHAIN_GAS_LIMIT = 1_500_000;
    uint32 internal constant MAX_MESSAGE_SIZE = 949;
    uint32 internal constant CLF_SRC_CALLBACK_GAS_LIMIT = 150_000;
    uint32 internal constant CLF_DST_CALLBACK_GAS_LIMIT = 2_000_000;
    uint64 internal constant HALF_DST_GAS = 200_000;
    uint256 internal constant STANDARD_TOKEN_DECIMALS = 1e18;
    uint256 internal constant USDC_DECIMALS = 1e6;
    uint256 internal constant CONCERO_MESSAGE_FEE_IN_USDC = 0.1e6;
    string internal constant CLF_JS_CODE =
        "const m='https://raw.githubusercontent.com/';const u=m+'ethers-io/ethers.js/v6.10.0/dist/ethers.umd.min.js';const [t,p]=await Promise.all([ fetch(u),fetch(m+'concero/messaging-contracts-v1/'+'release'+`/clf/dist/${BigInt(bytesArgs[2])===1n ? 'src':'dst'}.min.js`,),]);const [e,c]=await Promise.all([t.text(),p.text()]);const g=async s=>{return('0x'+Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(s)))).map(v=>('0'+v.toString(16)).slice(-2).toLowerCase()).join(''));};const r=await g(c);const x=await g(e);const b=bytesArgs[0].toLowerCase();const o=bytesArgs[1].toLowerCase();if(r===b && x===o){const ethers=new Function(e+';return ethers;')();return await eval(c);}throw new Error(`${r}!=${b}||${x}!=${o}`.slice(0,255));";

    /* IMMUTABLE VARIABLES */
    uint64 internal immutable i_chainSelector;
    address internal immutable i_usdc;
    address internal immutable i_msgr0;
    address internal immutable i_msgr1;
    address internal immutable i_msgr2;
    address internal immutable i_admin;
    // @dev clf immutables
    uint8 internal immutable i_clfDonHostedSecretsSlotId;
    uint64 internal immutable i_clfDonHostedSecretsVersion;
    uint64 internal immutable i_clfSubId;
    bytes32 internal immutable i_clfDonId;
    bytes32 internal immutable i_clfSrcJsHash;
    bytes32 internal immutable i_clfDstJsHash;
    bytes32 internal immutable i_clfEthersJsHash;

    constructor(
        uint64 chainSelector,
        address usdc,
        address[3] memory _messengers,
        address clfRouter,
        uint8 clfDonHostedSecretsSlotId,
        uint64 clfDonHostedSecretsVersion,
        uint64 clfSubId,
        bytes32 clfDonId,
        bytes32 clfSrcJsHash,
        bytes32 clfDstJsHash,
        bytes32 clfEthersJsHash
    ) ClfClient(clfRouter) {
        i_usdc = usdc;
        i_chainSelector = chainSelector;
        i_msgr0 = _messengers[0];
        i_msgr1 = _messengers[1];
        i_msgr2 = _messengers[2];

        // @dev clf immutables
        i_clfDonHostedSecretsSlotId = clfDonHostedSecretsSlotId;
        i_clfDonHostedSecretsVersion = clfDonHostedSecretsVersion;
        i_clfSubId = clfSubId;
        i_clfDonId = clfDonId;
        i_clfSrcJsHash = clfSrcJsHash;
        i_clfDstJsHash = clfDstJsHash;
        i_clfEthersJsHash = clfEthersJsHash;
        i_admin = msg.sender;
    }

    /* MODIFIERS */

    modifier onlyMessenger() {
        if (msg.sender != i_msgr0 && msg.sender != i_msgr1 && msg.sender != i_msgr2) {
            revert NotMessenger();
        }
        _;
    }

    modifier onlyAdmin() {
        if (msg.sender != i_admin) {
            revert NotAdmin();
        }
        _;
    }

    /* EXTERNAL FUNCTIONS */

    function sendMessage(MessageRequest calldata messageReq) external returns (bytes32) {
        _validateMessageReq(messageReq);

        uint256 fee = _getFeeInUsdc(messageReq.dstChainSelector);
        IERC20(messageReq.feeToken).safeTransferFrom(msg.sender, address(this), fee);

        bytes32 messageId = keccak256(
            abi.encode(
                block.number,
                ++s_nonceByChain[messageReq.dstChainSelector],
                i_chainSelector,
                messageReq.dstChainSelector,
                msg.sender,
                messageReq.receiver
            )
        );

        bytes32 messageHash = keccak256(
            abi.encode(
                messageId,
                i_chainSelector,
                messageReq.dstChainSelector,
                msg.sender,
                messageReq.receiver,
                keccak256(messageReq.data)
            )
        );

        _sendUnconfirmedMessage(messageId, messageHash, messageReq.dstChainSelector);

        emit ConceroMessageSent(
            messageId,
            msg.sender,
            messageReq.receiver,
            abi.encode(EvmArgs({dstChainGasLimit: messageReq.dstChainGasLimit})),
            messageReq.data
        );

        return messageId;
    }

    function getFeeInUsdc(uint64 dstChainSelector) external view returns (uint256) {
        return _getFeeInUsdc(dstChainSelector);
    }

    function receiveUnconfirmedMessage(
        bytes32 messageId,
        uint64 srcChainSelector,
        bytes32 messageHash
    ) external onlyMessenger {
        if (s_messageHashByConceroMessageId[messageId] == bytes32(0)) {
            s_messageHashByConceroMessageId[messageId] = messageHash;
        } else {
            revert MessageAlreadyExists();
        }

        address srcConceroRouter = s_dstConceroRouterByChain[srcChainSelector];
        if (srcConceroRouter == address(0)) {
            revert InvalidChainSelector();
        }

        bytes[] memory clfReqArgs = new bytes[](8);
        clfReqArgs[0] = abi.encodePacked(i_clfDstJsHash);
        clfReqArgs[1] = abi.encodePacked(i_clfEthersJsHash);
        clfReqArgs[2] = abi.encodePacked(ClfReqType.ConfirmMessage);
        clfReqArgs[3] = abi.encodePacked(srcConceroRouter);
        clfReqArgs[4] = abi.encodePacked(srcChainSelector);
        clfReqArgs[5] = abi.encodePacked(i_chainSelector);
        clfReqArgs[6] = abi.encodePacked(messageId);
        clfReqArgs[7] = abi.encodePacked(messageHash);

        bytes32 clfReqId = _initializeAndSendClfRequest(clfReqArgs, CLF_DST_CALLBACK_GAS_LIMIT);

        s_clfReqTypeByClfReqId[clfReqId] = ClfReqType.ConfirmMessage;
        s_conceroMessageIdByClfReqId[clfReqId] = messageId;

        emit UnconfirmedMessageReceived(messageId);
    }

    /* ADMIN FUNCTIONS */

    function setDstConceroRouterByChain(
        uint64 dstChainSelector,
        address conceroRouter
    ) external payable onlyAdmin {
        require(conceroRouter != address(0), InvalidConceroRouter());
        require(
            dstChainSelector != i_chainSelector && dstChainSelector != 0,
            InvalidChainSelector()
        );

        s_dstConceroRouterByChain[dstChainSelector] = conceroRouter;
    }

    function setClfFeeInUsdc(uint64 chainSelector, uint256 feeInUsdc) external payable onlyAdmin {
        require(chainSelector != 0, InvalidChainSelector());

        s_clfFeesInUsdc[chainSelector] = feeInUsdc;
    }

    /* INTERNAL FUNCTIONS */

    function _validateMessageReq(MessageRequest calldata message) internal view {
        if (message.feeToken != i_usdc) {
            revert UnsupportedFeeToken();
        }

        if (message.receiver == address(0)) {
            revert InvalidReceiver();
        }

        if (message.data.length > MAX_MESSAGE_SIZE) {
            revert MessageTooLarge();
        }

        if (message.dstChainGasLimit > MAX_DST_CHAIN_GAS_LIMIT || message.dstChainGasLimit == 0) {
            revert InvalidDstChainGasLimit();
        }
    }

    function _getFeeInUsdc(uint64 dstChainSelector) internal view returns (uint256) {
        uint256 clfFeeInUsdc = s_clfFeesInUsdc[dstChainSelector] + s_clfFeesInUsdc[i_chainSelector];

        uint256 messengerDstGasInNative = HALF_DST_GAS * s_lastGasPrices[dstChainSelector];
        uint256 messengerSrcGasInNative = HALF_DST_GAS * s_lastGasPrices[i_chainSelector];
        uint256 messengerGasFeeInUsdc = _convertToUsdcDecimals(
            ((messengerDstGasInNative + messengerSrcGasInNative) * s_latestNativeUsdcRate) /
                STANDARD_TOKEN_DECIMALS
        );

        return clfFeeInUsdc + messengerGasFeeInUsdc + CONCERO_MESSAGE_FEE_IN_USDC;
    }

    function _sendUnconfirmedMessage(
        bytes32 messageId,
        bytes32 messageHash,
        uint64 dstChainSelector
    ) internal {
        address dstConceroRouter = s_dstConceroRouterByChain[dstChainSelector];

        if (dstConceroRouter == address(0)) {
            revert InvalidChainSelector();
        }

        bytes[] memory clfReqArgs = new bytes[](8);
        clfReqArgs[0] = abi.encodePacked(i_clfSrcJsHash);
        clfReqArgs[1] = abi.encodePacked(i_clfEthersJsHash);
        clfReqArgs[2] = abi.encodePacked(ClfReqType.SendUnconfirmedMessage);
        clfReqArgs[3] = abi.encodePacked(dstConceroRouter);
        clfReqArgs[4] = abi.encodePacked(messageId);
        clfReqArgs[5] = abi.encodePacked(i_chainSelector);
        clfReqArgs[6] = abi.encodePacked(dstChainSelector);
        clfReqArgs[7] = abi.encodePacked(messageHash);

        bytes32 clfReqId = _initializeAndSendClfRequest(clfReqArgs, CLF_SRC_CALLBACK_GAS_LIMIT);

        s_clfReqTypeByClfReqId[clfReqId] = ClfReqType.SendUnconfirmedMessage;
    }

    function _initializeAndSendClfRequest(
        bytes[] memory args,
        uint32 gasLimit
    ) internal returns (bytes32) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(CLF_JS_CODE);
        req.addDONHostedSecrets(i_clfDonHostedSecretsSlotId, i_clfDonHostedSecretsVersion);
        req.setBytesArgs(args);
        return _sendRequest(req.encodeCBOR(), i_clfSubId, gasLimit, i_clfDonId);
    }

    // solhint-disable-next-line chainlink-solidity/prefix-internal-functions-with-underscore
    function fulfillRequest(
        bytes32 clfReqId,
        bytes memory response,
        bytes memory err
    ) internal override {
        ClfReqType clfReqType = s_clfReqTypeByClfReqId[clfReqId];

        if (clfReqType != ClfReqType.Empty) {
            s_clfReqTypeByClfReqId[clfReqId] = ClfReqType.Empty;
        } else {
            revert UnexpectedCLFRequestId();
        }

        if (err.length == 0) {
            if (clfReqType == ClfReqType.SendUnconfirmedMessage) {
                _handleSendUnconfirmedMessageClfResp(response);
            } else if (clfReqType == ClfReqType.ConfirmMessage) {
                _handleConfirmMessageClfResp(s_conceroMessageIdByClfReqId[clfReqId], response);
            } else {
                revert UnknownClfReqType();
            }
        } else {
            emit ClfReqFailed(clfReqId, uint8(clfReqType), err);
        }
    }

    function _handleConfirmMessageClfResp(
        bytes32 conceroMessageId,
        bytes memory response
    ) internal {
        bytes32 conceroMessageHash = s_messageHashByConceroMessageId[conceroMessageId];
        if (conceroMessageHash == bytes32(0)) {
            revert MessageDoesntExist();
        }

        if (!s_isMessageConfirmed[conceroMessageId]) {
            s_isMessageConfirmed[conceroMessageId] = true;
        } else {
            revert MessageAlreadyConfirmed();
        }

        (
            address receiver,
            address sender,
            uint64 srcChainSelector,
            uint24 gasLimit,
            bytes memory messageData
        ) = _decodeConfirmMessageClfResp(response);

        bytes32 recomputedMessageHash = keccak256(
            abi.encode(
                conceroMessageId,
                srcChainSelector,
                i_chainSelector,
                sender,
                receiver,
                keccak256(messageData)
            )
        );

        if (recomputedMessageHash != conceroMessageHash) {
            revert MessageDataHashMismatch();
        }

        IConceroClient(receiver).conceroReceive{gas: gasLimit}(
            IConceroClient.Message({
                id: conceroMessageId,
                srcChainSelector: srcChainSelector,
                sender: sender,
                data: messageData
            })
        );

        emit MessageReceived(conceroMessageId);
    }

    function _handleSendUnconfirmedMessageClfResp(bytes memory response) internal {
        (
            uint256 dstGasPrice,
            uint256 srcGasPrice,
            uint64 dstChainSelector,
            uint256 linkUsdcRate,
            uint256 nativeUsdcRate,
            uint256 linkNativeRate
        ) = abi.decode(response, (uint256, uint256, uint64, uint256, uint256, uint256));

        if (srcGasPrice != 0) {
            s_lastGasPrices[i_chainSelector] = srcGasPrice;
        }

        if (dstGasPrice != 0) {
            s_lastGasPrices[dstChainSelector] = dstGasPrice;
        }

        if (linkUsdcRate != 0) {
            s_latestLinkUsdcRate = linkUsdcRate;
        }

        if (nativeUsdcRate != 0) {
            s_latestNativeUsdcRate = nativeUsdcRate;
        }

        if (linkNativeRate != 0) {
            s_latestLinkNativeRate = linkNativeRate;
        }
    }

    function _decodeConfirmMessageClfResp(
        bytes memory response
    )
        internal
        pure
        returns (
            address receiver,
            address sender,
            uint64 srcChainSelector,
            uint24 gasLimit,
            bytes memory messageData
        )
    {
        assembly {
            receiver := mload(add(response, 20))
            sender := mload(add(response, 40))
            srcChainSelector := mload(add(response, 48))
            gasLimit := mload(add(response, 51))
        }

        if (response.length > 32) {
            uint256 messageDataLength = response.length - 32;
            messageData = new bytes(messageDataLength);

            for (uint256 i; i < messageDataLength; i++) {
                messageData[i] = response[32 + i];
            }
        }
    }

    function _convertToUsdcDecimals(uint256 amount) internal pure returns (uint256) {
        return (amount * USDC_DECIMALS) / STANDARD_TOKEN_DECIMALS;
    }
}
