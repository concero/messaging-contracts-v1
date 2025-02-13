import { task } from "hardhat/config"
import { compileContracts } from "../utils/compileContracts"
import { HardhatRuntimeEnvironment } from "hardhat/types"
import { CNetwork, CNetworkNames } from "../types/CNetwork"
import { conceroNetworks } from "../constants"
import { networkTypes } from "../constants/conceroNetworks"
import { conceroChains } from "../constants/liveChains"
import { verifyContractVariables } from "../utils/verifyContractVariables.task"
import deployConceroTestClient from "../deploy/ConceroTestClient"

task("deploy-concero-test-client", "").setAction(async taskArgs => {
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

    await deployConceroTestClient(hre)
})

export default {}
