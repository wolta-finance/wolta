import { useState, Fragment } from 'react';
import { useModals } from './modalprovider';
import TokenSelect from './token-select';
import InvestmentSelect from './investment-select';
import Image from 'next/image'
import EthTokenList from '../public/blockchains/ethereum/tokenlist.json';

import { vaultSymbols } from '../constants/vaults';
const vaults = EthTokenList.tokens.filter(each => vaultSymbols.includes(each.symbol));

const mode = {
    direct: 'DIRECT',
    zap: 'ZAP',
}

const investmentType = {
    traditional: 'Traditional',
    streaming: 'Streaming',
}

const SillyNotice = () => {
    const { popModal } = useModals();
    return(
        <Fragment>
            <div className="text-center">
                <p><strong>Congratulations!</strong> You have entered Wolta Finance super-highway. Powered by Superfluid™️</p>
            </div>
            <div className="flex justify-center space-x-4 mb-4">
                
                <button className="underline" onClick={popModal}>Close</button>
            </div>
        </Fragment>
    )
}

const EntryForm = ({ vault }) => {
    const { pushModal, popModal, animateStream } = useModals();
    const [ currentVault, setCurrentVault] = useState(vault);
    const [currentMode, setCurrentMode] = useState(mode.direct);
    const [currentInvestmentType, setCurrentInvestmentType] = useState(investmentType.traditional);
    console.log(currentVault)

    const handleInvestmentSelect = newInvestmentType => {
        setCurrentInvestmentType(newInvestmentType.name)
        if (newInvestmentType.name === investmentType.streaming) {
            animateStream(true);
            pushModal(<SillyNotice />, { overlay: true });
        } else {
            animateStream(false);
        }
    }

    return (
        <div className="m-4">
            <InvestmentSelect onChange={handleInvestmentSelect} />
            <label className="block mb-4">
            <span className="text-gray-700">You are depositing into</span>
                <TokenSelect 
                value={vaults.findIndex(each=>each.symbol === currentVault.symbol)}
                onChange={v=>setCurrentVault(vaults[v])}
                selectOptions={vaults.map(each => `${each.symbol} Vault`)} 
                currentlySelectedImage={<Image 
                    src={`/blockchains/ethereum/assets/${currentVault.address}/logo.png`} 
                    alt="Vercel Logo" 
                    width={32} 
                    height={32} 
                />}/>
            </label>

            <label className="block mb-4">
            <span className="text-gray-700">Using token</span>
                <TokenSelect 
                    onChange={(v)=>setCurrentMode(mode[Object.keys(mode)[v]])} 
                    value={Object.values(mode).findIndex(e=>e===currentMode)} 
                    selectOptions={['DAI (Wallet balance: 0.1)', 'Convert token via ZAP']} />
            </label>
            
            {currentMode === mode.zap
            ? (
                <label className="block mb-4">
                <span className="text-gray-700">Token to be converted/zapped</span>
                    <TokenSelect onChange={(v)=>console.log(v)} selectOptions={['Select token', 'USDC']} />
                </label>
            )
            : (
                <p className="my-7">
                    Your token will not be converted, but may be wrapped into an equivalent token. When using a streaming investment, your whole balance will be wrapped.
                </p>
            )}
            {currentInvestmentType === investmentType.traditional
                ? (
                    <label className="block mb-4">
                    <span className="text-gray-700">Amount to invest</span>
                    <div className="flex">
                        <input type="number" className="mt-1 block" placeholder="" defaultValue={0} />
                        <button className="ml-2 underline" onClick={()=>true}>MAX</button>
                    </div>
                    </label>
                )
                : (
                    <label className="block mb-4">
                    <span className="text-gray-700">Flow rate per day</span>
                    <div className="flex">
                        <input type="number" className="mt-1 block" placeholder="" defaultValue={0} />
                        <p className="ml-2 mt-3">Full ballance will be wrapped</p>
                    </div>
                    </label>
                )
            }
            

            <div className="flex justify-center space-x-4 mb-4">
                <button className="p-2 border-2 border-black uppercase text-sm font-bold selector-shading"><span className="bg-white">Approve spend of $TOKEN</span></button>
                <button className="p-2 border-2 border-black uppercase text-sm font-bold"><span className="bg-white">Deposit</span></button>
            </div>
            <div className="flex justify-center space-x-4 mb-4">
                <button className="underline" onClick={()=>{ popModal(); animateStream(false); }}>Close</button>
            </div>
        </div>
    )
}

export default EntryForm;