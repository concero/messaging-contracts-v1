import "@nomicfoundation/hardhat-chai-matchers"
import { conceroNetworks, networkEnvKeys } from "../../../constants"
import { getFallbackClients } from "../../../utils/getViemClients"
import { getEnvVar } from "../../../utils"
import { approve } from "../../../utils/approve"
import { handleError } from "../../../utils/handleError"
import { Address } from "viem"

describe("sendMessage\n", async () => {
    it("should send and receiveMessage in test concero client", async () => {
        try {
            const srcChain = conceroNetworks.arbitrumSepolia
            const dstChain = conceroNetworks.baseSepolia
            const srcChainConceroRouter = getEnvVar(`CONCERO_ROUTER_PROXY_${networkEnvKeys[srcChain.name]}`) as Address
            const srcChainUsdc = getEnvVar(`USDC_${networkEnvKeys[srcChain.name]}`) as Address
            const { publicClient: srcChainPublicClient, walletClient: srcChainWalletClient } =
                getFallbackClients(srcChain)
            const { abi: conceroRouterAbi } = await import(
                "../../../artifacts/contracts/ConceroRouter.sol/ConceroRouter.json"
            )

            const messageFee = await srcChainPublicClient.readContract({
                address: srcChainConceroRouter,
                abi: conceroRouterAbi,
                functionName: "getFeeInUsdc",
                args: [dstChain.chainSelector],
            })

            await approve(srcChainUsdc, srcChainConceroRouter, messageFee, srcChainWalletClient, srcChainPublicClient)

            const message = {
                feeToken: srcChainUsdc,
                receiver: getEnvVar(`CONCERO_TEST_CLIENT_${networkEnvKeys[dstChain.name]}`) as Address,
                dstChainSelector: BigInt(dstChain.chainSelector),
                dstChainGasLimit: 1_000_000n,
                data: "0x",
            }

            const sendMessageReq = (
                await srcChainPublicClient.simulateContract({
                    account: srcChainWalletClient.account,
                    address: srcChainConceroRouter,
                    abi: conceroRouterAbi,
                    functionName: "sendMessage",
                    args: [message],
                })
            ).request
            const sendMessageHash = await srcChainWalletClient.writeContract(sendMessageReq)
            const sendMessageStatus = await srcChainPublicClient.waitForTransactionReceipt({ hash: sendMessageHash })

            if (sendMessageStatus.status === "success") {
                console.log(`sendMessage successful`, "sendMessage", "hash:", sendMessageHash)
            } else {
                throw new Error(`sendMessage failed. Hash: ${sendMessageHash}`)
            }
        } catch (error) {
            handleError(error, "send message test")
        }
    }).timeout(0)
})
