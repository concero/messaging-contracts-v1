import { task } from "hardhat/config"
import { HardhatRuntimeEnvironment } from "hardhat/types"
import { compileContracts } from "../../utils/compileContracts"
import { CNetworkNames } from "../../types/CNetwork"
import { getEnvAddress, getEnvVar } from "../../utils"
import { getFallbackClients } from "../../utils/getViemClients"
import { conceroNetworks, networkEnvKeys } from "../../constants"

export async function withdrawRouterFeeByNetworkName(networkName: CNetworkNames) {
    const [routerAddress] = getEnvAddress("conceroRouterProxy", networkName)
    const usdcAddress = getEnvVar(`USDC_${networkEnvKeys[networkName]}`)
    const { publicClient, walletClient } = getFallbackClients(conceroNetworks[networkName])
    const { abi: conceroRouterAbi } = await import("../../artifacts/contracts/ConceroRouter.sol/ConceroRouter.json")

    const { request } = await publicClient.simulateContract({
        account: walletClient.account,
        address: routerAddress,
        abi: conceroRouterAbi,
        functionName: "withdrawFee",
        args: [usdcAddress],
    })

    const hash = await walletClient.writeContract(request)

    const { status } = await publicClient.waitForTransactionReceipt({ hash })

    console.log("hash", hash)
    console.log("status", status)
}

task("withdraw-fee", "").setAction(async taskArgs => {
    compileContracts({ quiet: true })
    const hre: HardhatRuntimeEnvironment = require("hardhat")

    await withdrawRouterFeeByNetworkName(hre.network.name as CNetworkNames)
})

export default {}
