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
        const srcContractAddress = getEnvVar("CONCERO_ROUTER_PROXY_BASE_SEPOLIA")
        const srcChainSelector = "0x" + BigInt(getEnvVar("CL_CCIP_CHAIN_SELECTOR_BASE_SEPOLIA")).toString(16)
        const messageId = "0x61bde6a9d54542f15071a52e53263f3167c5592d5215e4e68da4cdfe774f966d"
        const dstChainSelector = "0x" + BigInt(getEnvVar("CL_CCIP_CHAIN_SELECTOR_FUJI")).toString(16)
        const messageHash = "0x2ecaac5b9a4e68ff15c716ef20768135457dda260aab36101fa6413b49826f3f"

        return ["0x0", "0x0", "0x0", srcContractAddress, srcChainSelector, dstChainSelector, messageId, messageHash]
    },
}
