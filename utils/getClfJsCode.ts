import { ethersV6CodeUrl, infraDstJsCodeUrl, infraSrcJsCodeUrl } from "../constants/functionsJsCodeUrls"

export enum ClfJsCodeType {
    Src,
    Dst,
    EthersV6,
}

async function fetchCode(url: string) {
    const response = await fetch(url)

    if (!response.ok) {
        throw new Error(`Failed to fetch code from ${url}: ${response.statusText}`)
    }

    return response.text()
}

export async function getClfJsCode(clfJsCodeType: ClfJsCodeType) {
    switch (clfJsCodeType) {
        case ClfJsCodeType.Src:
            return fetchCode(infraSrcJsCodeUrl)
        case ClfJsCodeType.EthersV6:
            return fetchCode(ethersV6CodeUrl)
        case ClfJsCodeType.Dst:
            return fetchCode(infraDstJsCodeUrl)
        default:
            throw new Error(`Unknown ClfJsCodeType: ${clfJsCodeType}`)
    }
}
