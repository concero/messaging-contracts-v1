pragma solidity 0.8.28;

interface IConceroRouter {
    /* ERRORS */
    error UnsupportedFeeToken();
    error InvalidReceiver();
    error MessageTooLarge();
    error InvalidDstChainGasLimit();

    /* TYPES */
    struct MessageRequest {
        address feeToken;
        address receiver;
        uint64 dstChainSelector;
        bytes extraArgs;
        bytes data;
    }

    struct Message {
        uint64 srcChainSelector;
        uint64 dstChainSelector;
        address receiver;
        address sender;
        bytes extraArgs;
        bytes data;
    }

    struct EvmArgs {
        uint32 dstChainGasLimit;
    }
}
