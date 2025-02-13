//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.28;

import {IConceroRouterStorage} from "../interfaces/IConceroRouterStorage.sol";

abstract contract ConceroRouterStorage is IConceroRouterStorage {
    // @dev price feed vars
    uint256 internal s_latestLinkUsdcRate;
    uint256 internal s_latestNativeUsdcRate;
    uint256 internal s_latestLinkNativeRate;

    // @dev src chain mappings
    mapping(uint64 dstChainSelector => uint256 nonce) internal s_nonceByChain;
    mapping(uint64 dstChainSelector => address conceroRouter) internal s_dstConceroRouterByChain;
    mapping(uint64 => uint256) internal s_clfFeesInUsdc;

    // @dev dst chain mappings
    mapping(bytes32 messageId => bool isConfirmed) internal s_isMessageConfirmed;
    mapping(bytes32 conceroMessageId => bytes32 messageHash)
        internal s_messageHashByConceroMessageId;

    // @dev clf mappings
    mapping(bytes32 clfReqId => ClfReqType reqType) internal s_clfReqTypeByClfReqId;
    mapping(bytes32 clfReqId => bytes32 conceroMessageId) internal s_conceroMessageIdByClfReqId;

    // @dev price feed mappings
    mapping(uint64 chainSelector => uint256 gasPrice) internal s_lastGasPrices;

    /* GETTERS */

    function getMessageHashById(bytes32 conceroMessageId) external view returns (bytes32) {
        return s_messageHashByConceroMessageId[conceroMessageId];
    }

    function getDstConceroRouterByChain(uint64 dstChainSelector) external view returns (address) {
        return s_dstConceroRouterByChain[dstChainSelector];
    }
}
