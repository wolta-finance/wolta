import Image from 'next/image'
import Svg from './svg-patterns';
import EntryForm from './entry-form';
import { useModals } from './modalprovider';
import { encode } from "universal-base64";
import EthTokenList from '../assets/blockchains/ethereum/tokenlist.json';
const tokenSymbols = ['DAI', 'USDC', 'MKR', 'AAVE', 'COMP'];
const vaults = EthTokenList.tokens.filter(each => tokenSymbols.includes(each.symbol));

const defaultProps = {
    vaults,
}

const Row = (props: any) => {
    const { pushModal } = useModals();
    return(
    <tr>
        <td className="border border-black px-2 py-2">
            <div className="flex">
                <div className="relative" style={{lineHeight: 0}}>
                    <Image src={`/blockchains/ethereum/assets/${props.vault.address}/logo.png`} alt="DAI Logo" width={32} height={32} />
                    <div className="inset-0 absolute" style={{
                    backgroundImage: `url("data:image/svg+xml;base64,${encode(
                        Svg({ color: 'white', density: 2, opacity: 0.7 })
                    )}")`,
                    }}></div>
                </div>
                <div className="flex items-center px-2">{props.vault.symbol}</div>
            </div>
            
        </td>
        <td className="border border-black px-2 text-center">{props.vault.collectivePosition || 0}</td>
        <td className="border border-black px-2 text-center">{props.vault.growth || '0%'}</td>
         <td className="border border-black px-2 text-center">
            <button className="p-1 border-2 border-black uppercase text-sm font-bold" onClick={()=>pushModal(<EntryForm />, { overlay: true })}>
                <span className="bg-white">Deposit</span>
            </button>
        </td>
    </tr>
)}

const VaultsTable = (props: any) => (
<table className="table-auto w-full border-2 border-black">
  <thead>
    <tr style={{
      backgroundImage: `url("data:image/svg+xml;base64,${encode(
        Svg({ color: 'black', density: 2, opacity: 0.5 })
      )}")`,
    }}>
      <th className="border border-black px-2 w-full"><span className="bg-white">Vault</span></th>
      <th className="border border-black px-2"><span className="bg-white">Collective position</span></th>
      <th className="border border-black px-2"><span className="bg-white">Growth</span></th>
      <th className="border border-black px-2"><span className="bg-white">Deposit</span></th>
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