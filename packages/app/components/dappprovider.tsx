import { ChainId, DAppProvider, useEthers, useEtherBalance } from '@usedapp/core'
import Svg from './svg-patterns';
import { encode } from "universal-base64";
import { formatEther } from '@ethersproject/units'
import { redirect } from 'next/dist/next-server/server/api-utils';
const config = {
  readOnlyChainId: ChainId.Mainnet,
  readOnlyUrls: {
    [ChainId.Mainnet]: 'https://mainnet.infura.io/v3/62687d1a985d4508b2b7a24827551934',
  },
}

const Dapp = () => {
const { activateBrowserWallet, account, deactivate } = useEthers()
  const etherBalance = useEtherBalance(account)
  return (
    <div className="bg-purple-700 text-white rounded-md p-4 mx-4" style={{
      backgroundImage: `url("data:image/svg+xml;base64,${encode(
        Svg({ color: 'black', density: 3, opacity: 0.7, radius: 5.75 })
      )}")`,
    }}>
      <div>
        {account 
            ? <button onClick={() => deactivate()}>Disconnect</button>
            : <button onClick={() => activateBrowserWallet()}>Connect Wallet</button>
        }
      </div>
      {account && <p>Account: {account}</p>}
      {etherBalance && <p>Balance: {formatEther(etherBalance)}</p>}
    </div>
  )
}

const MyDAppProvider = ({children}:{children: any}) => (
    <DAppProvider config={config}>
      {children}
      <Dapp />
    </DAppProvider>
)

export default MyDAppProvider
