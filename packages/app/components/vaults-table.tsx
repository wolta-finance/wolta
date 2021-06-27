import Image from 'next/image'
import dynamic from 'next/dynamic'

import EthTokenList from '../assets/blockchains/ethereum/tokenlist.json';
const tokenSymbols = ['DAI', 'USDC', 'MKR', 'AAVE', 'COMP'];
const vaults = EthTokenList.tokens.filter(each => tokenSymbols.includes(each.symbol));
console.log(vaults);
// const addr = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';
// const DynamicComponent = dynamic(() => import(`../assets/blockchains/ethereum/assets/${addr}/logo.png`))

const defaultProps = {
    vaults,
}

const Row = (props: any) => (
    <tr>
        <td className="border border-black px-2 py-2">
            <div className="flex">
                <Image src={`/blockchains/ethereum/assets/${props.vault.address}/logo.png`} alt="DAI Logo" width={32} height={32} />
                <div className="flex items-center px-2">{props.vault.symbol}</div>
            </div>
            
        </td>
        <td className="border border-black px-2 text-center">{props.vault.collectivePosition || 0}</td>
        <td className="border border-black px-2 text-center">{props.vault.growth || '0%'}</td>
    </tr>
)

const VaultsTable = (props: any) => (
<table className="table-auto w-full border-2 border-black">
  <thead>
    <tr>
      <th className="border border-black px-2 w-full">Vault</th>
      <th className="border border-black px-2">Collective position</th>
      <th className="border border-black px-2">Growth</th>
    </tr>
  </thead>
  <tbody className="divide-x divide-black">
      {props.vaults.map((each: any)=>(
        <Row vault={each} key={Math.random()} />
      ))}
  </tbody>
</table>
)

VaultsTable.defaultProps = defaultProps;

export default VaultsTable;