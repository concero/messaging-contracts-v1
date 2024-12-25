pragma solidity 0.8.28;

contract ConceroRouterStorage {
    mapping(uint64 dstChainSelector => uint256 nonce) internal s_nonceByChain;
}
