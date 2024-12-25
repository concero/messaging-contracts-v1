pragma solidity 0.8.28;

contract ConceroRouter {
    error UnsupportedFeeToken();
    error InvalidReceiver();
    error MessageTooLarge();
    error InvalidDstChainGasLimit();

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

    uint32 internal constant MAX_MESSAGE_SIZE = 1024;
    uint32 internal constant MAX_DST_CHAIN_GAS_LIMIT = 1_500_000;
    address internal immutable i_usdc;

    constructor(address usdc) {
        i_usdc = usdc;
    }

    /* EXTERNAL FUNCTIONS */

    function sendMessage(MessageRequest memory message) external {
        _validateMessage(message);
    }

    function estimateFee(MessageRequest memory message) external returns (uint256) {
        _validateMessage(message);
        return _estimateFee(message);
    }

    /* INTERNAL FUNCTIONS */
    function _validateMessage(MessageRequest memory message) internal view {
        if (message.feeToken != i_usdc) {
            revert UnsupportedFeeToken();
        }

        if (message.receiver == address(0)) {
            revert InvalidReceiver();
        }

        if (message.data.length > MAX_MESSAGE_SIZE) {
            revert MessageTooLarge();
        }

        EvmArgs memory evmArgs = abi.decode(message.extraArgs, (EvmArgs));
        if (evmArgs.dstChainGasLimit > MAX_DST_CHAIN_GAS_LIMIT || evmArgs.dstChainGasLimit == 0) {
            revert InvalidDstChainGasLimit();
        }
    }

    function _estimateFee(MessageRequest memory /*message*/) internal pure returns (uint256) {
        return 0.01 * 10e6;
    }
}
