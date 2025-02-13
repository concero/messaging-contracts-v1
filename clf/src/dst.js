(async () => {
    const [, , , srcContractAddress, srcChainSelector, dstChainSelector, conceroMessageId, txDataHash] = bytesArgs;

    try {
        const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
        const encodeParam = (hexString, length) => {
            hexString = hexString.slice(2);
            const res = new Uint8Array(length);
            for (let i = 0; i < res.length; i++) {
                res[i] = parseInt(hexString.slice(i * 2, i * 2 + 2), 16);
            }
            return res;
        };

        const constructResult = (receiver, sender, srcChainSelector, gasLimit, messageData) => {
            const encodedReceiver = encodeParam(receiver, 20);
            const encodedSender = encodeParam(sender, 20);
            const encodedSrcChainSelector = encodeParam(srcChainSelector, 8);
            const encodedGasLimit = encodeParam(gasLimit, 8);
            const encodedMessageData = ethers.getBytes(messageData);

            const totalLength =
                encodedReceiver.length +
                encodedSender.length +
                encodedSrcChainSelector.length +
                encodedGasLimit.length +
                encodedMessageData.length;
            const result = new Uint8Array(totalLength);
            let offset = 0;

            result.set(encodedReceiver, offset);
            offset += encodedReceiver.length;

            result.set(encodedSender, offset);
            offset += encodedSender.length;

            result.set(encodedSrcChainSelector, offset);
            offset += encodedSrcChainSelector.length;

            result.set(encodedGasLimit, offset);
            offset += encodedGasLimit.length;

            result.set(encodedMessageData, offset);

            return result;
        };

        const chainMap = {
            [`0x${BigInt('${CL_CCIP_CHAIN_SELECTOR_FUJI}').toString(16)}`]: {
                urls: ['https://avalanche-fuji-c-chain-rpc.publicnode.com', 'https://rpc.ankr.com/avalanche_fuji'],
                confirmations: 3n,
                chainId: '0xa869',
            },
            [`0x${BigInt('${CL_CCIP_CHAIN_SELECTOR_SEPOLIA}').toString(16)}`]: {
                urls: ['https://ethereum-sepolia-rpc.publicnode.com'],
                confirmations: 3n,
                chainId: '0xaa36a7',
            },
            [`0x${BigInt('${CL_CCIP_CHAIN_SELECTOR_ARBITRUM_SEPOLIA}').toString(16)}`]: {
                urls: ['https://arbitrum-sepolia-rpc.publicnode.com', 'https://sepolia-rollup.arbitrum.io/rpc'],
                confirmations: 3n,
                chainId: '0x66eee',
            },
            [`0x${BigInt('${CL_CCIP_CHAIN_SELECTOR_BASE_SEPOLIA}').toString(16)}`]: {
                urls: [
                    'https://base-sepolia-rpc.publicnode.com',
                    'https://sepolia.base.org',
                    'https://base-sepolia.gateway.tenderly.co',
                ],
                confirmations: 3n,
                chainId: '0x14a34',
            },
            [`0x${BigInt('${CL_CCIP_CHAIN_SELECTOR_OPTIMISM_SEPOLIA}').toString(16)}`]: {
                urls: ['https://optimism-sepolia-rpc.publicnode.com'],
                confirmations: 3n,
                chainId: '0xaa37dc',
            },
            [`0x${BigInt('${CL_CCIP_CHAIN_SELECTOR_POLYGON_AMOY}').toString(16)}`]: {
                urls: [
                    'https://polygon-amoy.blockpi.network/v1/rpc/public',
                    'https://polygon-amoy-bor-rpc.publicnode.com',
                ],
                confirmations: 3n,
                chainId: '0x13882',
            },

            // mainnets

            [`0x${BigInt('${CL_CCIP_CHAIN_SELECTOR_POLYGON}').toString(16)}`]: {
                urls: [
                    'https://polygon-bor-rpc.publicnode.com',
                    'https://rpc.ankr.com/polygon',
                    'https://polygon.llamarpc.com',
                    'https://polygon-rpc.com',
                    'https://polygon.drpc.org',
                ],
                confirmations: 3n,
                chainId: '0x89',
            },
            [`0x${BigInt('${CL_CCIP_CHAIN_SELECTOR_ARBITRUM}').toString(16)}`]: {
                urls: [
                    'https://arbitrum-rpc.publicnode.com',
                    'https://rpc.ankr.com/arbitrum',
                    'https://arbitrum.llamarpc.com',
                    'https://arbitrum-one-rpc.publicnode.com',
                    'https://arbitrum.gateway.tenderly.co',
                    'https://arbitrum.drpc.org',
                ],
                confirmations: 3n,
                chainId: '0xa4b1',
            },
            [`0x${BigInt('${CL_CCIP_CHAIN_SELECTOR_BASE}').toString(16)}`]: {
                urls: [
                    'https://base-rpc.publicnode.com',
                    'https://rpc.ankr.com/base',
                    'https://base.gateway.tenderly.co',
                    'https://base.blockpi.network/v1/rpc/public',
                ],
                confirmations: 3n,
                chainId: '0x2105',
            },
            [`0x${BigInt('${CL_CCIP_CHAIN_SELECTOR_AVALANCHE}').toString(16)}`]: {
                urls: [
                    'https://avalanche-c-chain-rpc.publicnode.com',
                    'https://rpc.ankr.com/avalanche',
                    'https://avalanche.public-rpc.com',
                    'https://1rpc.io/avax/c',
                    'https://avalanche.drpc.org',
                ],
                confirmations: 3n,
                chainId: '0xa86a',
            },
        };

        class FunctionsJsonRpcProvider extends ethers.JsonRpcProvider {
            constructor(url) {
                super(url);
                this.url = url;
            }
            async _send(payload) {
                if (payload.method === 'eth_chainId') {
                    return [{ jsonrpc: '2.0', id: payload.id, result: chainMap[srcChainSelector].chainId }];
                }
                const resp = await fetch(this.url, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify(payload),
                });
                const result = await resp.json();
                if (payload.length === undefined) {
                    return [result];
                }
                return result;
            }
        }
        const abi = ['event ConceroMessageSent(bytes32 indexed, address, address, bytes, bytes)'];
        const topic0 = ethers.id('ConceroMessageSent(bytes32,address,address,bytes,bytes)');
        const contract = new ethers.Interface(abi);

        const { urls: rpcsUrls, confirmations } = chainMap[srcChainSelector];
        let getLogsRetryCounter = 5;
        let index = Math.floor(Math.random() * rpcsUrls.length);
        let provider;
        let latestBlockNumber;
        let logs = [];

        while (getLogsRetryCounter-- > 0 && !logs.length) {
            try {
                provider = new FunctionsJsonRpcProvider(rpcsUrls[index]);
                latestBlockNumber = BigInt(await provider.getBlockNumber());
                logs = await provider.getLogs({
                    address: srcContractAddress,
                    topics: [topic0, conceroMessageId],
                    // @dev for new blockchains with blockNumber < 1000
                    fromBlock: BigInt(Math.max(Number(latestBlockNumber - 1000n), 0)),
                    toBlock: latestBlockNumber,
                });
            } catch (e) {}

            index = (index + 1) % rpcsUrls.length;

            if (!logs.length) {
                await sleep(2000);
            }
        }

        if (!logs.length) {
            throw new Error(`No logs found ${provider.url}`);
        }

        const log = logs[0];
        const logBlockNumber = BigInt(log.blockNumber);

        while (latestBlockNumber - logBlockNumber < chainMap[srcChainSelector].confirmations) {
            await sleep(5000);
            latestBlockNumber = BigInt(await provider.getBlockNumber());
        }

        const newLogs = await provider.getLogs({
            address: srcContractAddress,
            topics: [topic0, conceroMessageId],
            fromBlock: logBlockNumber,
            toBlock: latestBlockNumber,
        });

        if (!newLogs.some(l => l.transactionHash === log.transactionHash)) {
            throw new Error('Log no longer exists.');
        }

        const logData = {
            topics: [topic0, log.topics[1]],
            data: log.data,
        };

        const decodedLog = contract.parseLog(logData);
        const messageId = decodedLog.args[0];
        const sender = decodedLog.args[1];
        const receiver = decodedLog.args[2];
        const messageData = decodedLog.args[4];
        const eventHashData = new ethers.AbiCoder().encode(
            ['bytes32', 'uint64', 'uint64', 'address', 'address', 'bytes32'],
            [messageId, srcChainSelector, dstChainSelector, sender, receiver, ethers.keccak256(messageData)],
        );

        const recomputedTxDataHash = ethers.keccak256(eventHashData);
        if (recomputedTxDataHash.toLowerCase() !== txDataHash.toLowerCase()) {
            throw new Error('MessageDataHash mismatch');
        }

        const gasLimit = new ethers.AbiCoder().decode(['tuple(uint32)'], decodedLog.args[3]);

        return constructResult(receiver, sender, srcChainSelector, '0x' + gasLimit[0][0].toString(16), messageData);
    } catch (error) {
        throw new Error(error.message.slice(0, 255));
    }
})();
