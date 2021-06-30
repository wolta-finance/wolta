import '../styles/globals.css'
import type { AppProps } from 'next/app'
import DappProvider from '../components/dappprovider';
import ModalProvider from '../components/modalprovider';

function MyApp({ Component, pageProps }: AppProps) {
  return <DappProvider>
      <ModalProvider>
        <Component {...pageProps} />
      </ModalProvider>
    </DappProvider>
}
export default MyApp
