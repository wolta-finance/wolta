import '../styles/globals.css'
import type { AppProps } from 'next/app'
import DappProvider from '../components/dappprovider';

function MyApp({ Component, pageProps }: AppProps) {
  return <DappProvider>
      <Component {...pageProps} />
    </DappProvider>
}
export default MyApp
