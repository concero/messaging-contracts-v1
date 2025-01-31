//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.28;

import {ConceroRouterStorage} from "./storages/ConceroRouterStorage.sol";
import {FunctionsClient as ClfClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IConceroRouter} from "./interfaces/IConceroRouter.sol";
import {IConceroClient} from "./ConceroClient/interfaces/IConceroClient.sol";

contract ConceroRouter is IConceroRouter, ClfClient, ConceroRouterStorage {
    using SafeERC20 for IERC20;
    using FunctionsRequest for FunctionsRequest.Request;

    /* CONSTANT VARIABLES */

    uint24 internal constant MAX_DST_CHAIN_GAS_LIMIT = 1_500_000;
    uint32 internal constant MAX_MESSAGE_SIZE = 949;
    uint32 internal constant CLF_SRC_CALLBACK_GAS_LIMIT = 150_000;
    uint32 internal constant CLF_DST_CALLBACK_GAS_LIMIT = 2_000_000;
    string internal constant CLF_JS_CODE =
        "try{const m='https://raw.githubusercontent.com/';const u=m+'ethers-io/ethers.js/v6.10.0/dist/ethers.umd.min.js';const [t,p]=await Promise.all([ fetch(u),fetch(m+'concero/messaging-contracts-v1/'+'release'+`/clf/dist/${BigInt(bytesArgs[2])===1n ? 'src':'dst'}.min.js`,),]);const [e,c]=await Promise.all([t.text(),p.text()]);const g=async s=>{return('0x'+Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(s)))).map(v=>('0'+v.toString(16)).slice(-2).toLowerCase()).join(''));};const r=await g(c);const x=await g(e);const b=bytesArgs[0].toLowerCase();const o=bytesArgs[1].toLowerCase();if(r===b && x===o){const ethers=new Function(e+';return ethers;')();return await eval(c);}throw new Error(`${r}!=${b}||${x}!=${o}`);}catch(e){throw new Error(e.message.slice(0,255));}";

    /* IMMUTABLE VARIABLES */
    address internal immutable i_usdc;
    uint64 internal immutable i_chainSelector;
    address internal immutable i_msgr0;
    address internal immutable i_msgr1;
    address internal immutable i_msgr2;
    // @dev clf immutables
    uint8 internal immutable i_clfDonHostedSecretsSlotId;
    uint64 internal immutable i_clfDonHostedSecretsVersion;
    uint64 internal immutable i_clfSubId;
    bytes32 internal immutable i_clfDonId;
    bytes32 internal immutable i_clfSrcJsHash;
    bytes32 internal immutable i_clfDstJsHash;
    bytes32 internal immutable i_clfEthersJsHash;

    constructor(
        address usdc,
        uint64 chainSelector,
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
    }

    /* MODIFIERS */

    modifier onlyMessenger() {
        if (msg.sender != i_msgr0 && msg.sender != i_msgr1 && msg.sender != i_msgr2) {
            revert NotMessenger();
        }
        _;
    }

    /* EXTERNAL FUNCTIONS */

    function sendMessage(MessageRequest memory messageReq) external {
        _validateMessageReq(messageReq);

        uint256 fee = _getFee(messageReq);
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
    }

    function getFee(MessageRequest memory message) external view returns (uint256) {
        _validateMessageReq(message);
        return _getFee(message);
    }

    function receiveUnconfirmedMessage(
        bytes32 messageId,
        uint64 srcChainSelector,
        bytes32 messageHash
    ) external onlyMessenger {
        if (s_messageHashById[messageId] != bytes32(0)) {
            revert TxAlreadyExists();
        } else {
            s_messageHashById[messageId] = messageHash;
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

        s_clfRequests[clfReqId].reqType = ClfReqType.ConfirmMessage;
        s_clfRequests[clfReqId].conceroMessageId = messageId;

        s_isClfReqPending[clfReqId] = true;

        emit UnconfirmedMessageReceived(messageId);
    }

    /* INTERNAL FUNCTIONS */

    function _validateMessageReq(MessageRequest memory message) internal view {
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

    function _getFee(MessageRequest memory /*message*/) internal pure returns (uint256) {
        return 0.01 * 10e6;
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

        s_clfRequests[clfReqId].reqType = ClfReqType.SendUnconfirmedMessage;
        s_isClfReqPending[clfReqId] = true;
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
        if (s_isClfReqPending[clfReqId]) {
            s_isClfReqPending[clfReqId] = false;
        } else {
            revert UnexpectedCLFRequestId();
        }

        ClfRequest storage clfRequest = s_clfRequests[clfReqId];

        if (err.length != 0) {
            if (clfRequest.reqType == ClfReqType.SendUnconfirmedMessage) {
                emit SendUnconfirmedMessageClfReqError(clfReqId);
            }

            return;
        }

        ClfReqType clfReqType = clfRequest.reqType;
        if (clfReqType == ClfReqType.SendUnconfirmedMessage) {
            _handleSendUnconfirmedMessageClfResp(response);
        } else if (clfReqType == ClfReqType.ConfirmMessage) {
            _handleConfirmMessageClfResp(clfRequest.conceroMessageId, response);
        } else {
            revert UnknownClfReqType();
        }
    }

    function _handleConfirmMessageClfResp(
        bytes32 conceroMessageId,
        bytes memory response
    ) internal {
        bytes32 conceroMessageHash = s_messageHashById[conceroMessageId];
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
}
