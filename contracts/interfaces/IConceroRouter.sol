pragma solidity 0.8.28;

interface IConceroRouter {
    /* ERRORS */
    error UnsupportedFeeToken();
    error InvalidReceiver();
    error MessageTooLarge();
    error InvalidDstChainGasLimit();
    error InvalidChainSelector();
    error UnexpectedCLFRequestId();
    error UnknownClfReqType();
    error NotMessenger();
    error TxAlreadyExists();
    error MessageDoesntExist();
    error MessageAlreadyConfirmed();
    error MessageDataHashMismatch();

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

    /* EVENTS */
    event ConceroMessageSent();
    event ConfirmMessageClfReqError(bytes32 indexed conceroMessageId);
    event SendUnconfirmedMessageClfReqError(bytes32 indexed clfReqid);
    event UnconfirmedMessageReceived(bytes32 indexed conceroMessageId);
    event MessageReceived(bytes32 indexed conceroMessageId);
}
