pragma solidity 0.8.28;

interface IConceroRouter {
    /* ERRORS */
    error UnsupportedFeeToken();
    error InvalidReceiver();
    error MessageTooLarge();
    error InvalidDstChainGasLimit();
    error InvalidDstChainSelector();
    error UnexpectedCLFRequestId();
    error UnknownClfReqType();

    /* TYPES */
    struct MessageRequest {
        address feeToken;
        address receiver;
        uint64 dstChainSelector;
        bytes extraArgs;
        bytes data;
    }

    struct EvmArgs {
        uint32 dstChainGasLimit;
    }

    enum ClfReqType {
        Empty,
        SendUnconfirmedMessage
    }

    struct ClfRequest {
        ClfReqType reqType;
        bytes32 conceroMessageId;
    }

    /* EVENTS */
    event ConceroMessageSent();
    event ConfirmMessageClfReqError(bytes32 indexed conceroMessageId);
    event SendUnconfirmedMessageClfReqError(bytes32 indexed clfReqid);
}
