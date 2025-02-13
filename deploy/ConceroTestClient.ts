import { Deployment } from "hardhat-deploy/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"
import { conceroNetworks, networkEnvKeys } from "../constants/conceroNetworks"
import updateEnvVariable from "../utils/updateEnvVariable"
import log from "../utils/log"
import { getGasParameters } from "../utils/getGasPrice"

interface ConstructorArgs {
    conceroProxyAddress?: string
    parentProxyAddress?: string
    childProxyAddress?: string
    linkToken?: string
    ccipRouter?: string
    chainSelector?: number
    usdc?: string
    owner?: string
    messengers?: string[]
}

const deployConceroTestClient: (hre: HardhatRuntimeEnvironment, constructorArgs?: ConstructorArgs) => Promise<void> =
    async function (hre: HardhatRuntimeEnvironment, constructorArgs: ConstructorArgs = {}) {
        const { deployer } = await hre.getNamedAccounts()
        const { deploy } = hre.deployments
        const { name, live } = hre.network
        const { maxFeePerGas, maxPriorityFeePerGas } = await getGasParameters(conceroNetworks[name])

        log("Deploying...", "deployConceroTestClient", name)

        const deployConceroTestClient = (await deploy("ConceroTestClient", {
            from: deployer,
            args: [],
            log: true,
            autoMine: true,
            maxFeePerGas: maxFeePerGas.toString(),
            maxPriorityFeePerGas: maxPriorityFeePerGas.toString(),
        })) as Deployment

        if (live) {
            log(`Deployed at: ${deployConceroTestClient.address}`, "deployConceroTestClient", name)
            updateEnvVariable(
                `CONCERO_TEST_CLIENT_${networkEnvKeys[name]}`,
                deployConceroTestClient.address,
                `deployments.${type}`,
            )
        }
    }

export default deployConceroTestClient
deployConceroTestClient.tags = ["ConceroTestClient"]
