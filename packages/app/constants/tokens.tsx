const supportedTokenSymbols = ['DAI', 'USDC', 'WETH', 'WMATIC', 'AAVE', 'COMP']; 

const tokenContractsPolygon = {
    'DAI': '0x8f3cf7ad23cd3cadbd9735aff958023239c6a063',
    'USDC': '0x2791bca1f2de4661ed88a30c99a7a9449aa84174',
    'WETH': '0x7ceb23fd6bc0add59e62ac25578270cff1b9f619',
    'WMATIC': '0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270',
    'MATIC': '0x0000000000000000000000000000000000001010',
    'AAVE': '0xd6df932a45c0f255f85145f286ea0b292b21c90b',
    'COMP': '0x8505b9d2254a7ae468c0e9dd10ccea3a837aef5c',
}

export {
    supportedTokenSymbols,
    tokenContractsPolygon,
}