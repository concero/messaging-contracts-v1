import { HardhatRuntimeEnvironment } from "hardhat/types"
import { conceroChains } from "../../constants/liveChains"
import { conceroNetworks, networkEnvKeys } from "../../constants"
import { CNetworkNames } from "../../types/CNetwork"
import { getClients } from "../../utils/getViemClients"
import { getEnvVar } from "../../utils"
import { Address } from "viem"
import log from "../../utils/log"
import { clfPremiumFeeInUsdc, defaultClfPremiumFeeInUsdc, viemReceiptConfig } from "../../constants/deploymentVariables"

async function setConceroDstRouters() {
    const hre: HardhatRuntimeEnvironment = require("hardhat")
    const currentChainName = hre.network.name as CNetworkNames
    const isTestnet = conceroNetworks[currentChainName].type === "testnet"
    const liveChains = conceroChains[isTestnet ? "testnet" : "mainnet"].infra
    const { publicClient, walletClient } = getClients(conceroNetworks[currentChainName].viemChain)
    const currentChainConceroRouter = getEnvVar(`CONCERO_ROUTER_PROXY_${networkEnvKeys[currentChainName]}`) as Address
    const { abi: conceroRouterAbi } = await import("../../artifacts/contracts/ConceroRouter.sol/ConceroRouter.json")

    for (const dstChain of liveChains) {
        if (currentChainName === dstChain.name) continue

        const currentDstConceroRouter = (await publicClient.readContract({
            address: currentChainConceroRouter,
            abi: conceroRouterAbi,
            functionName: "getDstConceroRouterByChain",
            args: [BigInt(dstChain.chainSelector)],
        })) as Address
        const expectedDstConceroRouter = getEnvVar(`CONCERO_ROUTER_PROXY_${networkEnvKeys[dstChain.name]}`) as Address

        if (currentDstConceroRouter.toLowerCase() === expectedDstConceroRouter.toLowerCase()) {
            const logMessage = `[Skip] ${currentChainConceroRouter}.dstRouter${currentDstConceroRouter}. Already set`
            log(logMessage, "setDstConceroRouter", currentChainName)
            continue
        }

        const setDstConceroRouterReq = (
            await publicClient.simulateContract({
                account: walletClient.account,
                address: currentChainConceroRouter,
                abi: conceroRouterAbi,
                functionName: "setDstConceroRouterByChain",
                args: [dstChain.chainSelector, expectedDstConceroRouter],
            })
        ).request

        const setDstConceroRouterHash = await walletClient.writeContract(setDstConceroRouterReq)
        const setDstConceroRouterStatus = (
            await publicClient.waitForTransactionReceipt({ ...viemReceiptConfig, hash: setDstConceroRouterHash })
        ).status

        if (setDstConceroRouterStatus === "success") {
            log(
                `[Success] ${currentChainConceroRouter}.dstRouter${expectedDstConceroRouter}. Set`,
                "setDstConceroRouter",
                currentChainName,
            )
        } else {
            log(
                `[Error] ${currentChainConceroRouter}.dstRouter${expectedDstConceroRouter}. Failed`,
                "setDstConceroRouter",
                currentChainName,
            )
        }
    }
}

async function setClfPremiumFee() {
    const hre: HardhatRuntimeEnvironment = require("hardhat")
    const currentChainName = hre.network.name as CNetworkNames
    const isTestnet = conceroNetworks[currentChainName].type === "testnet"
    const liveChains = conceroChains[isTestnet ? "testnet" : "mainnet"].infra
    const { publicClient, walletClient } = getClients(conceroNetworks[currentChainName].viemChain)
    const currentChainConceroRouter = getEnvVar(`CONCERO_ROUTER_PROXY_${networkEnvKeys[currentChainName]}`) as Address
    const { abi: conceroRouterAbi } = await import("../../artifacts/contracts/ConceroRouter.sol/ConceroRouter.json")

    for (const dstChain of liveChains) {
        const currentClfFee = (await publicClient.readContract({
            address: currentChainConceroRouter,
            abi: conceroRouterAbi,
            functionName: "getClfPremiumFeeInUsdcByChain",
            args: [BigInt(dstChain.chainSelector)],
        })) as BigInt

        const expectedFee = clfPremiumFeeInUsdc[dstChain.chainId] ?? defaultClfPremiumFeeInUsdc

        if (expectedFee === currentClfFee) {
            const logMessage = `[Skip] ${currentChainConceroRouter}.clfPremiumFee${expectedFee}. Already set`
            log(logMessage, "setClfPremiumFee", currentChainName)
            continue
        }

        const setClfPremiumFeeReq = (
            await publicClient.simulateContract({
                account: walletClient.account,
                address: currentChainConceroRouter,
                abi: conceroRouterAbi,
                functionName: "setClfFeeInUsdc",
                args: [dstChain.chainSelector, expectedFee],
            })
        ).request
        const setClfPremiumFeeHash = await walletClient.writeContract(setClfPremiumFeeReq)
        const setClfPremiumFeeStatus = (
            await publicClient.waitForTransactionReceipt({ ...viemReceiptConfig, hash: setClfPremiumFeeHash })
        ).status

        if (setClfPremiumFeeStatus === "success") {
            log(
                `[Success] ${currentChainConceroRouter}.clfPremiumFee${expectedFee}. Set`,
                "setClfPremiumFee",
                currentChainName,
            )
        } else {
            log(
                `[Error] ${currentChainConceroRouter}.clfPremiumFee${expectedFee}. Failed`,
                "setClfPremiumFee",
                currentChainName,
            )
        }
    }
}

export async function setConceroRouterVars() {
    await setConceroDstRouters()
    await setClfPremiumFee()
}
