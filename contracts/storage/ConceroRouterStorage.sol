pragma solidity 0.8.28;

import {IConceroRouter} from "../interface/IConceroRouter.sol";

contract ConceroRouterStorage {
    // @dev price feed vars
    uint256 internal s_latestLinkUsdcRate;
    uint256 internal s_latestNativeUsdcRate;
    uint256 internal s_latestLinkNativeRate;

    mapping(uint64 dstChainSelector => uint256 nonce) internal s_nonceByChain;
    mapping(uint64 dstChainSelector => address conceroRouter) internal s_dstConceroRouterByChain;

    // @dev clf mappings
    mapping(bytes32 clfReqId => IConceroRouter.ClfRequest clfRequest) internal s_clfRequests;
    mapping(bytes32 clfReqId => bool isPending) internal s_isClfReqPending;

    // @dev price feed mappings
    mapping(uint64 chainSelector => uint256 gasPrice) internal s_lastGasPrices;
}
