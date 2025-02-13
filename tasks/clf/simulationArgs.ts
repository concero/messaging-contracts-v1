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
        const messageId = "0xb3b6cda30b381669fb96b9abadfdd9caac0ffd721dfb8d84214ba1ca064c2961"
        const dstChainSelector = "0x" + BigInt(getEnvVar("CL_CCIP_CHAIN_SELECTOR_BASE_SEPOLIA")).toString(16)
        const messageHash = "0x94b871315f9930f014723c1fb04ea05b6340cb89bf642ce3853b662c0b2a93b6"

        return ["0x0", "0x0", "0x0", srcContractAddress, srcChainSelector, dstChainSelector, messageId, messageHash]
    },
}
