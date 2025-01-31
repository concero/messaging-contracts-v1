import { task, types } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import deployProxyAdmin from "../../deploy/TransparentProxyAdmin";
import deployTransparentProxy from "../../deploy/TransparentProxy";
import { ProxyEnum } from "../../constants/deploymentVariables";
import { conceroNetworks } from "../../constants";
import { getEnvAddress } from "../../utils/getEnvVar";
import deployConceroRouterImplementation from "../../deploy/ConceroRouter";
import { upgradeProxyImplementation } from "../transparentProxy/upgradeProxyImplementation.task";

async function deployConceroRouter(params: DeployInfraParams) {
    const { hre, deployableChains, deployProxy, deployImplementation, setVars, uploadSecrets, slotId } = params;
    const { name } = hre.network;
    const isTestnet = deployableChains[0].type === "testnet";

    if (deployProxy) {
        await deployProxyAdmin(hre, ProxyEnum.infraProxy);
        await deployTransparentProxy(hre, ProxyEnum.infraProxy);
        const [proxyAddress] = getEnvAddress(ProxyEnum.infraProxy, name);
        const { functionsSubIds } = conceroNetworks[name];
        await addCLFConsumer(conceroNetworks[name], [proxyAddress], functionsSubIds[0]);
    }

    if (deployImplementation) {
        await deployConceroRouterImplementation(hre, params);
        await upgradeProxyImplementation(hre, ProxyEnum.infraProxy, false);
    }

    if (uploadSecrets) {
        // await uploadDonSecrets(
        //     deployableChains,
        //     slotId,
        //     isTestnet ? CLF_SECRETS_TESTNET_EXPIRATION : CLF_SECRETS_MAINNET_EXPIRATION,
        // );
    }

    if (setVars) {
    }
}

task("deploy-concero-router", "Deploy the concero router")
    .addFlag("deployproxy", "Deploy the proxy")
    .addFlag("deployimplementation", "Deploy the implementation")
    .addFlag("setvars", "Set the contract variables")
    .addFlag("uploadsecrets", "Upload DON-hosted secrets")
    .addOptionalParam("slotid", "DON-Hosted secrets slot id", 0, types.int)
    .setAction(async taskArgs => {
        compileContracts({ quiet: true });

        const hre: HardhatRuntimeEnvironment = require("hardhat");
        const { live, name } = hre.network;
        const networkType = conceroNetworks[name].type;
        let deployableChains: CNetwork[] = [];
        if (live) deployableChains = [conceroNetworks[hre.network.name]];

        let liveChains: CNetwork[] = [];
        if (networkType == networkTypes.mainnet) {
            liveChains = conceroChains.mainnet.infra;
            await verifyVariables();
        } else {
            liveChains = conceroChains.testnet.infra;
        }

        await deployConceroRouter({
            hre,
            deployableChains,
            liveChains,
            networkType,
            deployProxy: taskArgs.deployproxy,
            deployImplementation: taskArgs.deployimplementation,
            setVars: taskArgs.setvars,
            uploadSecrets: taskArgs.uploadsecrets,
            slotId: parseInt(taskArgs.slotid),
        });
    });

export default {};
