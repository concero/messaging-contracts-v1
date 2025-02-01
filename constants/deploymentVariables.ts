import type { WaitForTransactionReceiptParameters } from "viem/actions/public/waitForTransactionReceipt";
import { WriteContractParameters } from "viem";
import { EnvPrefixes } from "../types/deploymentVariables";
import { getEnvVar } from "../utils/getEnvVar";

export const messengers: string[] = [
    getEnvVar("MESSENGER_0_ADDRESS"),
    getEnvVar("MESSENGER_1_ADDRESS"),
    getEnvVar("MESSENGER_2_ADDRESS"),
];

export const viemReceiptConfig: WaitForTransactionReceiptParameters = {
    timeout: 0,
    confirmations: 2,
};

export const writeContractConfig: WriteContractParameters = {
    gas: 3000000n, // 3M
};

export enum ProxyEnum {
    conceroRouterProxy = "conceroRouterProxy",
}

export const envPrefixes: EnvPrefixes = {
    conceroRouterProxy: "CONCERO_ROUTER_PROXY",
    conceroRouterProxyAdmin: "CONCERO_ROUTER_PROXY_ADMIN",
    create3Factory: "CREATE3_FACTORY",
    pause: "CONCERO_PAUSE",
    poolMessenger0: "POOL_MESSENGER_0_ADDRESS",
    poolMessenger1: "POOL_MESSENGER_1_ADDRESS",
    poolMessenger2: "POOL_MESSENGER_2_ADDRESS",
    infraMessenger0: "MESSENGER_0_ADDRESS",
    infraMessenger1: "MESSENGER_1_ADDRESS",
    infraMessenger2: "MESSENGER_2_ADDRESS",
};
