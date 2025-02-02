pragma solidity 0.8.28;

import {ConceroRouter} from "contracts/ConceroRouter.sol";

contract ConceroRouterHarness is ConceroRouter {
    constructor(
        uint64 chainSelector,
        address usdc,
        address[3] memory _messengers,
        address clfRouter,
        uint8 clfDonHostedSecretsSlotId,
        uint64 clfDonHostedSecretsVersion,
        uint64 clfSubId,
        bytes32 clfDonId,
        bytes32 clfSrcJsHash,
        bytes32 clfDstJsHash,
        bytes32 clfEthersJsHash
    )
        ConceroRouter(
            chainSelector,
            usdc,
            _messengers,
            clfRouter,
            clfDonHostedSecretsSlotId,
            clfDonHostedSecretsVersion,
            clfSubId,
            clfDonId,
            clfSrcJsHash,
            clfDstJsHash,
            clfEthersJsHash
        )
    {}

    function exposed_setLastGasPrice(uint64 dstChainSelector, uint256 gasPrice) external {
        s_lastGasPrices[dstChainSelector] = gasPrice;
    }

    function exposed_setLatestLinkUsdcRate(uint256 rate) external {
        s_latestLinkUsdcRate = rate;
    }

    function exposed_setLatestNativeUsdcRate(uint256 rate) external {
        s_latestNativeUsdcRate = rate;
    }

    function exposed_setLatestLinkNativeRate(uint256 rate) external {
        s_latestLinkNativeRate = rate;
    }

    function exposed_setClfFeesInUsdc(uint64 chainSelector, uint256 fee) external {
        s_clfFeesInUsdc[chainSelector] = fee;
    }

    function exposed_getMaxMessageDataSize() external pure returns (uint256) {
        return MAX_MESSAGE_SIZE;
    }
}
