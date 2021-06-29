import { ChainId, DAppProvider } from '@usedapp/core'
const config = {
  readOnlyChainId: ChainId.Mainnet,
  readOnlyUrls: {
    [ChainId.Mainnet]: 'https://mainnet.infura.io/v3/62687d1a985d4508b2b7a24827551934',
  },
}



const MyDAppProvider = ({children}:{children: any}) => (
    <DAppProvider config={config}>
      {children}
    </DAppProvider>
)

export default MyDAppProvider
