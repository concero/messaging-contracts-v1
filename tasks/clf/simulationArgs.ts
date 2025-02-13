import { getEnvVar } from "../../utils"
import getHashSum from "../../utils/getHashSum"

type ArgBuilder = () => Promise<string[]>

export const getSimulationArgs: { [functionName: string]: ArgBuilder } = {
    src: async () => {
        const dstContractAddress = getEnvVar("CONCERO_ROUTER_PROXY_BASE_SEPOLIA")
        const conceroMessageId = getHashSum("concero message id")
        const srcChainSelector = "0x" + BigInt(getEnvVar("CL_CCIP_CHAIN_SELECTOR_ARBITRUM_SEPOLIA")).toString(16)
        const dstChainSelector = "0x" + BigInt(getEnvVar("CL_CCIP_CHAIN_SELECTOR_BASE_SEPOLIA")).toString(16)
        const txDataHash = getHashSum("tx data")

        return [
            "0x0",
            "0x0",
            "0x0",
            dstContractAddress,
            conceroMessageId,
            srcChainSelector,
            dstChainSelector,
            txDataHash,
        ]
    },
    dst: async () => {
        const srcContractAddress = getEnvVar("CONCERO_ROUTER_PROXY_ARBITRUM_SEPOLIA")
        const srcChainSelector = "0x" + BigInt(getEnvVar("CL_CCIP_CHAIN_SELECTOR_ARBITRUM_SEPOLIA")).toString(16)
        const messageId = "0x338c379ecd4e277ebf92b23f98e2108dbf58aaea6d75dd9627bc014fa874a23a"
        const dstChainSelector = "0x" + BigInt(getEnvVar("CL_CCIP_CHAIN_SELECTOR_BASE_SEPOLIA")).toString(16)
        const messageHash = "0x1b55bf64fff9bd0328c3973fde85be22bc2f082d78fa7ff25b244d1d8121ae2d"

        return ["0x0", "0x0", "0x0", srcContractAddress, srcChainSelector, dstChainSelector, messageId, messageHash]
    },
}
