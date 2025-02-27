import type { WaitForTransactionReceiptParameters } from "viem/actions/public/waitForTransactionReceipt"
import { parseUnits, WriteContractParameters } from "viem"
import { EnvPrefixes } from "../types/deploymentVariables"
import { getEnvVar } from "../utils/getEnvVar"
import { arbitrum, avalanche, base, optimism, polygon } from "viem/chains"

export const messengers: string[] = [
    getEnvVar("MESSENGER_0_ADDRESS"),
    getEnvVar("MESSENGER_1_ADDRESS"),
    getEnvVar("MESSENGER_2_ADDRESS"),
]

export const viemReceiptConfig: WaitForTransactionReceiptParameters = {
    timeout: 0,
    confirmations: 2,
}

export const writeContractConfig: WriteContractParameters = {
    gas: 3000000n, // 3M
}

export enum ProxyEnum {
    conceroRouterProxy = "conceroRouterProxy",
}

export const envPrefixes: EnvPrefixes = {
    conceroRouterProxy: "CONCERO_ROUTER_PROXY",
    conceroRouter: "CONCERO_ROUTER",
    conceroRouterProxyAdmin: "CONCERO_ROUTER_PROXY_ADMIN",
    create3Factory: "CREATE3_FACTORY",
    pause: "CONCERO_PAUSE",
    poolMessenger0: "POOL_MESSENGER_0_ADDRESS",
    poolMessenger1: "POOL_MESSENGER_1_ADDRESS",
    poolMessenger2: "POOL_MESSENGER_2_ADDRESS",
    infraMessenger0: "MESSENGER_0_ADDRESS",
    infraMessenger1: "MESSENGER_1_ADDRESS",
    infraMessenger2: "MESSENGER_2_ADDRESS",
}

export const CONCERO_ROUTER_CLF_SECRETS_SLOT_ID = 0
export const clfPremiumFeeInUsdc = {
    [base.id]: parseUnits("0.06", 6),
    [avalanche.id]: parseUnits("0.28", 6),
    [optimism.id]: parseUnits("0.09", 6),
    [polygon.id]: parseUnits("0.04", 6),
    [arbitrum.id]: parseUnits("0.075", 6),
}
export const defaultClfPremiumFeeInUsdc = parseUnits("0.06", 6)
