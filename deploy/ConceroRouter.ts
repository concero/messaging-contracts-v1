import { Deployment } from "hardhat-deploy/types";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { conceroNetworks, networkEnvKeys } from "../constants/conceroNetworks";
import updateEnvVariable from "../utils/updateEnvVariable";
import log from "../utils/log";
import { getEnvVar } from "../utils";
import { poolMessengers } from "../constants/deploymentVariables";
import { getGasParameters } from "../utils/getGasPrice";
import getHashSum from "../utils/getHashSum";
import { ethersV6CodeUrl, infraDstJsCodeUrl, infraSrcJsCodeUrl } from "../constants/functionsJsCodeUrls";

interface ConstructorArgs {
    conceroProxyAddress?: string;
    parentProxyAddress?: string;
    childProxyAddress?: string;
    linkToken?: string;
    ccipRouter?: string;
    chainSelector?: number;
    usdc?: string;
    owner?: string;
    messengers?: string[];
}

const deployConceroRouter: (hre: HardhatRuntimeEnvironment, constructorArgs?: ConstructorArgs) => Promise<void> =
    async function (hre: HardhatRuntimeEnvironment, constructorArgs: ConstructorArgs = {}) {
        const { deployer } = await hre.getNamedAccounts();
        const { deploy } = hre.deployments;
        const { name, live } = hre.network;
        const clfSrcCode = await (await fetch(infraSrcJsCodeUrl)).text();
        const clfDstCode = await (await fetch(infraDstJsCodeUrl)).text();
        const clfEthersCode = await (await fetch(ethersV6CodeUrl)).text();
        const {
            type,
            chainSelector,
            functionsRouter: clfRouter,
            donHostedSecretsVersion: clfDonHostedSecretsVersion,
            functionsSubIds,
            functionsDonIdAlias,
        } = conceroNetworks[name];
        const defaultArgs = {
            chainSelector,
            usdc: getEnvVar(`USDC_${networkEnvKeys[name]}`),
            owner: deployer,
            poolMessengers,
            clfRouter,
            clfDonHostedSecretsSlotId: constructorArgs.slotid,
            clfDonHostedSecretsVersion,
            clfSubId: functionsSubIds[0],
            clfDonId: functionsDonIdAlias,
            clfSrcJsHash: getHashSum(clfSrcCode),
            clfDstJsHash: getHashSum(clfDstCode),
            clfEthersJsHash: getHashSum(clfEthersCode),
        };
        const args = { ...defaultArgs, ...constructorArgs };
        const { maxFeePerGas, maxPriorityFeePerGas } = await getGasParameters(conceroNetworks[name]);

        log("Deploying...", "deployConceroRouter", name);

        const deployChildPool = (await deploy("ConceroRouter", {
            from: deployer,
            args: [
                args.chainSelector,
                args.usdc,
                args.poolMessengers,
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
        })) as Deployment;

        if (live) {
            log(`Deployed at: ${deployChildPool.address}`, "deployConceroRouter", name);
            updateEnvVariable(`CONCERO_ROUTER_${networkEnvKeys[name]}`, deployChildPool.address, `deployments.${type}`);
        }
    };

export default deployConceroRouter;
deployConceroRouter.tags = ["ConceroRouter"];
