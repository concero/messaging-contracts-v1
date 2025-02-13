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
        const srcJsHashSum = "0xef64cf53063700bbbd8e42b0282d3d8579aac289ea03f826cf16f9bd96c7703a"
        const ethersHashSum = "0x984202f6c36a048a80e993557555488e5ae13ff86f2dfbcde698aacd0a7d4eb4"

        return [srcJsHashSum, ethersHashSum, "0x01", "0x" + (84532).toString(16)]
    },
}
