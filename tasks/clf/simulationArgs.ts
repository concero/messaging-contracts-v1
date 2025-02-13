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
        const messageId = "0x463e37b9af1bca4078a100f717fb76bbc78d051e483331e82cde9f37ac086dbc"
        const dstChainSelector = "0x" + BigInt(getEnvVar("CL_CCIP_CHAIN_SELECTOR_BASE_SEPOLIA")).toString(16)
        const messageHash = "0xb0378cbddcf299adbdfe0724170282235bf8d7952cff085342cba8bc64de54dd"

        return ["0x0", "0x0", "0x0", srcContractAddress, srcChainSelector, dstChainSelector, messageId, messageHash]
    },
}
