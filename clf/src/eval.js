const m = 'https://raw.githubusercontent.com/';
const u = m + 'ethers-io/ethers.js/v6.10.0/dist/ethers.umd.min.js';
const [t, p] = await Promise.all([
    fetch(u),
    fetch(
        m +
            'concero/messaging-contracts-v1/refs/heads/' +
            '${CLF_JS_CODE_BRANCH}' +
            `/clf/dist/${BigInt(bytesArgs[2]) === 1n ? 'src' : 'dst'}.min.js`,
    ),
]);
const [e, c] = await Promise.all([t.text(), p.text()]);
const g = async s => {
    return (
        '0x' +
        Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', new TextEncoder().encode(s))))
            .map(v => ('0' + v.toString(16)).slice(-2).toLowerCase())
            .join('')
    );
};
const r = await g(c);
const x = await g(e);
const b = bytesArgs[0].toLowerCase();
const o = bytesArgs[1].toLowerCase();
if (r === b && x === o) {
    const ethers = new Function(e + '; return ethers;')();
    return await eval(c);
}
throw new Error(`${r}!=${b}||${x}!=${o}`.slice(0, 255));
