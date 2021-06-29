import { useEthers, useEtherBalance, shortenAddress } from '@usedapp/core'
import Svg from './svg-patterns';
import { encode } from "universal-base64";
import { formatEther } from '@ethersproject/units'

const Button = (props: any) => (
    <button className="p-2 border-4 border-white font-bold uppercase" onClick={props.onClick}>
        {props.children}
    </button>
)

const DappWalet = () => {
    const { activateBrowserWallet, account, deactivate } = useEthers()
    //   const etherBalance = useEtherBalance(account)
      return (
        <div className="bg-purple-700 text-white p-4 flex" style={{
          backgroundImage: `url("data:image/svg+xml;base64,${encode(
            Svg({ color: 'white', density: 1, opacity: 0.5 })
          )}")`,
        }}>
          {account && <div style={{margin: '4px'}} className="p-2 border-purple-700 font-bold">
              <span className="bg-purple-700">{shortenAddress(account)}</span>
            </div>}
          <div>
            {account 
                ? <Button onClick={() => deactivate()}>Disconnect</Button>
                : <Button onClick={() => activateBrowserWallet()}>Connect Wallet</Button>
            }
          </div>

          {/* {etherBalance && <p>Balance: {formatEther(etherBalance)}</p>} */}
        </div>
      )
    }

export default DappWalet;