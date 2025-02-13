type envString = string | undefined

export type CLFSecrets = {
    MESSENGER_0_PRIVATE_KEY: envString
    MESSENGER_1_PRIVATE_KEY: envString
    MESSENGER_2_PRIVATE_KEY: envString
}

export const clfSecrets: CLFSecrets = {
    MESSENGER_0_PRIVATE_KEY: process.env.MESSENGER_0_PRIVATE_KEY,
    MESSENGER_1_PRIVATE_KEY: process.env.MESSENGER_1_PRIVATE_KEY,
    MESSENGER_2_PRIVATE_KEY: process.env.MESSENGER_2_PRIVATE_KEY,
}

export const CLF_SECRETS_TESTNET_EXPIRATION = 4320
export const CLF_SECRETS_MAINNET_EXPIRATION = 129600
