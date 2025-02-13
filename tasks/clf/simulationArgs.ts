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
        const messageId = "0xcc62224337944f6e5b3d920a48b99f098b3a6551fdff062f44cfe5562ae936bb"
        const dstChainSelector = "0x" + BigInt(getEnvVar("CL_CCIP_CHAIN_SELECTOR_FUJI")).toString(16)
        const messageHash = "0xf4bd91b2c049a31fe31783b41986cf663f8610d19e0b1068b18c4ed3f5a21c9f"

        return ["0x0", "0x0", "0x0", srcContractAddress, srcChainSelector, dstChainSelector, messageId, messageHash]
    },
}

// 1000000

// 0x2b48812e25ff9afb05a9724231c2cab57bb6eb37dddddb8a8e41c194ac6542a0ad7ba663a72741e08f90b8876dee6538 f424000000000010
