pragma solidity 0.8.28;

import {ConceroRouter} from "contracts/ConceroRouter.sol";

contract ConceroRouterHarness is ConceroRouter {
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
    )
        ConceroRouter(
            chainSelector,
            usdc,
            _messengers,
            clfRouter,
            clfDonHostedSecretsSlotId,
            clfDonHostedSecretsVersion,
            clfSubId,
            clfDonId,
            clfSrcJsHash,
            clfDstJsHash,
            clfEthersJsHash
        )
    {}

    /* SETTERS */

    function exposed_setLastGasPrice(uint64 dstChainSelector, uint256 gasPrice) external {
        s_lastGasPrices[dstChainSelector] = gasPrice;
    }

    function exposed_setLatestLinkUsdcRate(uint256 rate) external {
        s_latestLinkUsdcRate = rate;
    }

    function exposed_setLatestNativeUsdcRate(uint256 rate) external {
        s_latestNativeUsdcRate = rate;
    }

    function exposed_setLatestLinkNativeRate(uint256 rate) external {
        s_latestLinkNativeRate = rate;
    }

    function exposed_setClfFeesInUsdc(uint64 chainSelector, uint256 fee) external {
        s_clfFeesInUsdc[chainSelector] = fee;
    }

    function exposed_setClfReqTypeByClfReqId(bytes32 reqId, ClfReqType reqType) external {
        s_clfReqTypeByClfReqId[reqId] = reqType;
    }

    function exposed_setConceroMessageIdByClfReqId(
        bytes32 reqId,
        bytes32 conceroMessageId
    ) external {
        s_conceroMessageIdByClfReqId[reqId] = conceroMessageId;
    }

    /* GETTERS */

    function exposed_getMaxMessageDataSize() external pure returns (uint256) {
        return MAX_MESSAGE_SIZE;
    }

    function exposed_getMaxDstChainGasLimit() external pure returns (uint32) {
        return MAX_DST_CHAIN_GAS_LIMIT;
    }

    function exposed_getAdmin() external view returns (address) {
        return i_admin;
    }

    function exposed_getMessenger0() external view returns (address) {
        return i_msgr0;
    }

    function exposed_getMessenger1() external view returns (address) {
        return i_msgr1;
    }

    function exposed_getMessenger2() external view returns (address) {
        return i_msgr2;
    }

    function exposed_getClfReqTypeByClfReqId(bytes32 reqId) external view returns (ClfReqType) {
        return s_clfReqTypeByClfReqId[reqId];
    }

    function exposed_getConceroMessageIdByClfReqId(bytes32 reqId) external view returns (bytes32) {
        return s_conceroMessageIdByClfReqId[reqId];
    }

    function exposed_getMessageHashByConceroMessageId(
        bytes32 conceroMessageId
    ) external view returns (bytes32) {
        return s_messageHashByConceroMessageId[conceroMessageId];
    }

    function exposed_getClfRouter() external view returns (address) {
        return address(i_router);
    }
}
