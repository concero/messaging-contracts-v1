//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.28;

interface IConceroRouter {
    /* ERRORS */
    error UnsupportedFeeToken();
    error InvalidReceiver();
    error MessageTooLarge();
    error InvalidDstChainGasLimit();
    error InvalidChainSelector();

    /* TYPES */
    struct MessageRequest {
        address feeToken;
        address receiver;
        uint64 dstChainSelector;
        uint32 dstChainGasLimit;
        bytes data;
    }

    function getFee(
        uint64 dstChainSelector,
        address feeToken,
        uint32 dstChainGasLimit
    ) external view returns (uint256);

    function sendMessage(MessageRequest calldata messageRequest) external returns (bytes32);

    function getLinkUsdcRate() external view returns (uint256);
}
