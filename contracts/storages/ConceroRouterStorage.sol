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
    mapping(bytes32 messageId => bytes32 messageHash) internal s_messageHashById;

    // @dev clf mappings
    mapping(bytes32 clfReqId => ClfReqType reqType) internal s_clfReqTypeById;
    mapping(bytes32 clfReqId => bytes32 conceroMessageId) internal s_conceroMessageIdByClfReqId;

    // @dev price feed mappings
    mapping(uint64 chainSelector => uint256 gasPrice) internal s_lastGasPrices;
}
