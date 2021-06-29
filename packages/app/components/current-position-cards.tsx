import { useEffect, useLayoutEffect } from 'react';
import Image from 'next/image';
import Svg from './svg-patterns';
import { encode } from "universal-base64";
import Chart from './chart';
import EthTokenList from '../assets/blockchains/ethereum/tokenlist.json';
const tokenSymbols = ['MATIC', 'COMP'];
const vaults = EthTokenList.tokens.filter(each => tokenSymbols.includes(each.symbol));
const Card = (props: any) => {
  return (
  <div className="border border-black p-px mr-3">
  <div className="border border-black p-2">
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
    <Chart />
  </div>
</div>
)
}

const CurrentPositionCards = () => (
  <div className="flex">
    <Card vault={vaults[0]} />
    <Card vault={vaults[1]} />
  
  </div>
)

export default CurrentPositionCards;