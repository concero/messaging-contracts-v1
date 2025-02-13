import { Deployment } from "hardhat-deploy/types"
import { HardhatRuntimeEnvironment } from "hardhat/types"
import { conceroNetworks, networkEnvKeys } from "../constants/conceroNetworks"
import updateEnvVariable from "../utils/updateEnvVariable"
import log from "../utils/log"
import { getEnvVar } from "../utils"
import { messengers } from "../constants/deploymentVariables"
import { getGasParameters } from "../utils/getGasPrice"
import getHashSum from "../utils/getHashSum"
import { ClfJsCodeType, getClfJsCode } from "../utils/getClfJsCode"

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

const deployConceroRouterImplementation: (
    hre: HardhatRuntimeEnvironment,
    constructorArgs?: ConstructorArgs,
) => Promise<void> = async function (hre: HardhatRuntimeEnvironment, constructorArgs: ConstructorArgs = {}) {
    if (constructorArgs.slotId === undefined) {
        throw new Error("slotid is required for deployConceroRouter")
    }

    const { deployer } = await hre.getNamedAccounts()
    const { deploy } = hre.deployments
    const { name, live } = hre.network
    const clfSrcCode = await getClfJsCode(ClfJsCodeType.Src)
    const clfDstCode = await getClfJsCode(ClfJsCodeType.Dst)
    const clfEthersCode = await getClfJsCode(ClfJsCodeType.EthersV6)
    const {
        type,
        chainSelector,
        functionsRouter: clfRouter,
        donHostedSecretsVersion: clfDonHostedSecretsVersion,
        functionsSubIds,
        functionsDonId,
    } = conceroNetworks[name]
    const defaultArgs = {
        chainSelector,
        usdc: getEnvVar(`USDC_${networkEnvKeys[name]}`),
        owner: deployer,
        messengers,
        clfRouter,
        clfDonHostedSecretsSlotId: constructorArgs.slotId,
        clfDonHostedSecretsVersion,
        clfSubId: functionsSubIds[0],
        clfDonId: functionsDonId,
        clfSrcJsHash: getHashSum(clfSrcCode),
        clfDstJsHash: getHashSum(clfDstCode),
        clfEthersJsHash: getHashSum(clfEthersCode),
    }
    const args = { ...defaultArgs, ...constructorArgs }
    const { maxFeePerGas, maxPriorityFeePerGas } = await getGasParameters(conceroNetworks[name])

    console.log(args)

    log("Deploying...", "deployConceroRouter", name)

    const deployChildPool = (await deploy("ConceroRouter", {
        from: deployer,
        args: [
            args.chainSelector,
            args.usdc,
            args.messengers,
            args.clfRouter,
            args.clfDonHostedSecretsSlotId,
            args.clfDonHostedSecretsVersion,
            args.clfSubId,
            args.clfDonId,
            args.clfSrcJsHash,
            args.clfDstJsHash,
            args.clfEthersJsHash,
        ],
        log: true,
        autoMine: true,
        maxFeePerGas: maxFeePerGas.toString(),
        maxPriorityFeePerGas: maxPriorityFeePerGas.toString(),
    })) as Deployment

    if (live) {
        log(`Deployed at: ${deployChildPool.address}`, "deployConceroRouter", name)
        updateEnvVariable(`CONCERO_ROUTER_${networkEnvKeys[name]}`, deployChildPool.address, `deployments.${type}`)
    }
}

export default deployConceroRouterImplementation
deployConceroRouterImplementation.tags = ["ConceroRouter"]
