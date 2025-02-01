//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.28;

import {IConceroRouterStorage} from "../interfaces/IConceroRouterStorage.sol";

abstract contract ConceroRouterStorage is IConceroRouterStorage {
    // @dev price feed vars
    uint256 internal s_latestLinkUsdcRate;
    uint256 internal s_latestNativeUsdcRate;
    uint256 internal s_latestLinkNativeRate;

    mapping(uint64 dstChainSelector => uint256 nonce) internal s_nonceByChain;
    mapping(uint64 dstChainSelector => address conceroRouter) internal s_dstConceroRouterByChain;
    mapping(uint64 => uint256) internal s_clfFeesInUsdc;
    mapping(bytes32 messageId => bool isConfirmed) internal s_isMessageConfirmed;
    mapping(bytes32 messageId => bytes32 messageHash) internal s_messageHashById;

    // @dev clf mappings
    mapping(bytes32 clfReqId => ClfRequest clfRequest) internal s_clfRequests;
    mapping(bytes32 clfReqId => bool isPending) internal s_isClfReqPending;

    // @dev price feed mappings
    mapping(uint64 chainSelector => uint256 gasPrice) internal s_lastGasPrices;
}
