pragma solidity 0.8.28;

import {ConceroRouterStorage} from "./storage/ConceroRouterStorage.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IConceroRouter} from "./interface/IConceroRouter.sol";

contract ConceroRouter is IConceroRouter, ConceroRouterStorage {
    using SafeERC20 for IERC20;

    /* CONSTANT VARIABLES */
    uint32 internal constant MAX_MESSAGE_SIZE = 1024;
    uint32 internal constant MAX_DST_CHAIN_GAS_LIMIT = 1_500_000;

    /* IMMUTABLE VARIABLES */
    address internal immutable i_usdc;
    uint64 internal immutable i_chainSelector;
    address internal immutable i_msgr0;
    address internal immutable i_msgr1;
    address internal immutable i_msgr2;

    constructor(address usdc, uint64 chainSelector, address[3] memory _messengers) {
        i_usdc = usdc;
        i_chainSelector = chainSelector;
        i_msgr0 = _messengers[0];
        i_msgr1 = _messengers[1];
        i_msgr2 = _messengers[2];
    }

    /* EXTERNAL FUNCTIONS */

    function sendMessage(MessageRequest memory messageReq) external {
        _validateMessage(messageReq);

        uint256 fee = _getFee(messageReq);
        IERC20(messageReq.feeToken).safeTransferFrom(msg.sender, address(this), fee);

        bytes32 messageId = keccak256(
            abi.encode(
                block.number,
                ++s_nonceByChain[messageReq.dstChainSelector],
                messageReq.dstChainSelector,
                messageReq.receiver,
                msg.sender
            )
        );

        Message memory message = Message({
            srcChainSelector: i_chainSelector,
            dstChainSelector: messageReq.dstChainSelector,
            receiver: messageReq.receiver,
            sender: msg.sender,
            extraArgs: messageReq.extraArgs,
            data: messageReq.data
        });
    }

    function getFee(MessageRequest memory message) external returns (uint256) {
        _validateMessage(message);
        return _getFee(message);
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

    function _getFee(MessageRequest memory /*message*/) internal pure returns (uint256) {
        return 0.01 * 10e6;
    }
}
