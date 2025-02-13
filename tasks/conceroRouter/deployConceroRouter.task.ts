import { task } from "hardhat/config"
import { HardhatRuntimeEnvironment } from "hardhat/types"
import deployProxyAdmin from "../../deploy/TransparentProxyAdmin"
import deployTransparentProxy from "../../deploy/TransparentProxy"
import { CONCERO_ROUTER_CLF_SECRETS_SLOT_ID, ProxyEnum } from "../../constants/deploymentVariables"
import { conceroNetworks } from "../../constants"
import { getEnvAddress } from "../../utils"
import deployConceroRouterImplementation from "../../deploy/ConceroRouter"
import { upgradeProxyImplementation } from "../transparentProxy/upgradeProxyImplementation.task"
import { addClfConsumer } from "../clf/addClfConsumer.task"
import { CNetwork, CNetworkNames, NetworkType } from "../../types/CNetwork"
import { networkTypes } from "../../constants/conceroNetworks"
import { verifyContractVariables } from "../../utils/verifyContractVariables.task"
import { CLF_SECRETS_MAINNET_EXPIRATION, CLF_SECRETS_TESTNET_EXPIRATION } from "../../constants/clfSecrets"
import { conceroChains } from "../../constants/liveChains"
import { uploadClfSecrets } from "../clf/uploadSecrets.task"
import { compileContracts } from "../../utils/compileContracts"
import { setConceroRouterVars } from "./setConceroRouterVars"

interface DeployInfraParams {
    hre: any
    liveChains: CNetwork[]
    deployableChains: CNetwork[]
    networkType: NetworkType
    deployProxy: boolean
    deployImplementation: boolean
    setVars: boolean
    uploadSecrets: boolean
    slotId: number
}

async function deployConceroRouter(params: DeployInfraParams) {
    const { hre, deployableChains, deployProxy, deployImplementation, setVars, uploadSecrets, slotId } = params
    const name = hre.network.name as CNetworkNames
    const isTestnet = deployableChains[0].type === "testnet"

    if (deployProxy) {
        await deployProxyAdmin(hre, ProxyEnum.conceroRouterProxy)
        await deployTransparentProxy(hre, ProxyEnum.conceroRouterProxy)
        const [proxyAddress] = getEnvAddress(ProxyEnum.conceroRouterProxy, name)
        const { functionsSubIds } = conceroNetworks[name]
        if (!functionsSubIds) throw new Error(`No functionsSubIds found for ${name}`)
        await addClfConsumer(conceroNetworks[name], [proxyAddress], Number(functionsSubIds[0]))
    }

    if (uploadSecrets) {
        await uploadClfSecrets(
            deployableChains,
            slotId,
            isTestnet ? CLF_SECRETS_TESTNET_EXPIRATION : CLF_SECRETS_MAINNET_EXPIRATION,
        )
    }

    if (deployImplementation) {
        await deployConceroRouterImplementation(hre, params)
        await upgradeProxyImplementation(hre, false)
    }

    if (setVars) {
        await setConceroRouterVars()
    }
}

task("deploy-concero-router", "Deploy the concero router")
    .addFlag("proxy", "Deploy the proxy")
    .addFlag("implementation", "Deploy the implementation")
    .addFlag("setvars", "Set the contract variables")
    .addFlag("uploadsecrets", "Upload DON-hosted secrets")
    .setAction(async taskArgs => {
        compileContracts({ quiet: true })

        const hre: HardhatRuntimeEnvironment = require("hardhat")
        const { live } = hre.network
        const name = hre.network.name as CNetworkNames
        const networkType = conceroNetworks[name].type
        let deployableChains: CNetwork[] = []
        if (live) deployableChains = [conceroNetworks[name]]

        let liveChains: CNetwork[] = []
        if (networkType == networkTypes.mainnet) {
            liveChains = conceroChains.mainnet.infra
            await verifyContractVariables()
        } else {
            liveChains = conceroChains.testnet.infra
        }

        await deployConceroRouter({
            hre,
            deployableChains,
            liveChains,
            networkType,
            deployProxy: taskArgs.proxy,
            deployImplementation: taskArgs.implementation,
            setVars: taskArgs.setvars,
            uploadSecrets: taskArgs.uploadsecrets,
            slotId: CONCERO_ROUTER_CLF_SECRETS_SLOT_ID,
        })
    })

export default {}
