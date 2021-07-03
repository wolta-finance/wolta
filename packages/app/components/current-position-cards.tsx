import { useEffect, useLayoutEffect } from 'react';
import Image from 'next/image';
import Svg from './svg-patterns';
import { encode } from "universal-base64";
import Chart from './chart';
import ExitForm from './exit-form';
import { useModals } from './modalprovider';
import EthTokenList from '../public/blockchains/ethereum/tokenlist.json';
const tokenSymbols = ['USDC', 'COMP'];
const vaults = EthTokenList.tokens.filter(each => tokenSymbols.includes(each.symbol));
const Card = (props: any) => {
  const { pushModal } = useModals();
  return (
  <div className="border border-black p-px mr-3 max-w-4xl" style={{minWidth: '15rem'}}>
  <div className="border border-black">
    <div className="flex p-2" style={{
        backgroundImage: `url("data:image/svg+xml;base64,${encode(
        Svg({ color: 'black', density: 2, opacity: 0.2 })
      )}")`,
        }}>
        <div className="relative" style={{lineHeight: 0}}>
            <Image src={`/blockchains/ethereum/assets/${props.vault.address}/logo.png`} alt="DAI Logo" width={32} height={32} />
            <div className="inset-0 absolute" style={{
            backgroundImage: `url("data:image/svg+xml;base64,${encode(
                Svg({ color: 'white', density: 2, opacity: 0.7 })
            )}")`,
            }}></div>
        </div>
        <div className="flex items-center px-2">{props.vault.symbol}</div>
        <button className="p-1 ml-auto border-2 border-black uppercase text-sm font-bold" onClick={()=>pushModal(<ExitForm />, {overlay: true})}><span className="bg-white">Manage</span></button>
        
    </div>
    <div className="p-2">
      <div className="flex justify-between">
        <div>Current amount:</div>
        <div>0</div>
      </div>
      <div className="flex justify-between">
        <div>Growth:</div>
        <div>0%</div>
      </div>
    </div>
    <Chart />
  </div>
</div>
)
}

const CurrentPositionCards = () => (
  <div className="flex flex-wrap">
    <Card vault={vaults[0]} />
    <Card vault={vaults[1]} />
  </div>
)

export default CurrentPositionCards;