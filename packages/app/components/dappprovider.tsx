import { ChainId, DAppProvider, useEthers, useEtherBalance } from '@usedapp/core'
import { formatEther } from '@ethersproject/units'
import styles from '../styles/Home.module.css'
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
    <div className={styles.card}>
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
      <Dapp />
      {children}
    </DAppProvider>
)

export default MyDAppProvider
