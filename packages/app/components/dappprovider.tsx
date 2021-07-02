import { ChainId, DAppProvider } from '@usedapp/core'
const config = {
  readOnlyChainId: ChainId.Polygon,
  readOnlyUrls: {
    [ChainId.Polygon]: process.env.NEXT_PUBLIC_RPC_URL,
  },
}

const MyDAppProvider = ({children}:{children: any}) => (
    <DAppProvider config={config}>
      {children}
    </DAppProvider>
)

export default MyDAppProvider
