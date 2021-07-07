import { useState, useEffect, useCallback, Fragment } from 'react';
import { useTokenBalance, useEthers, useTokenAllowance } from '@usedapp/core';
import { useModals } from './modalprovider';
import TokenSelect from './token-select';
import { formatUnits } from '@ethersproject/units'
import InvestmentSelect from './investment-select';
import Image from 'next/image'
import EthTokenList from '../public/blockchains/ethereum/tokenlist.json';

import { vaultSymbols, vaultContractsPolygon } from '../constants/vaults';
import { supportedTokenSymbols, tokenContractsPolygon } from '../constants/tokens';
const vaults = EthTokenList.tokens.filter(each => vaultSymbols.includes(each.symbol));

const mode = {
    direct: 'DIRECT',
    zap: 'ZAP',
}

const investmentType = {
    traditional: 'Traditional',
    streaming: 'Streaming',
}

// const SillyNotice = () => {
//     const { popModal } = useModals();
//     return(
//         <Fragment>
//             <div className="text-center">
//                 <p><strong>Congratulations!</strong> You have entered Wolta Finance super-highway. Powered by Superfluid™️</p>
//             </div>
//             <div className="flex justify-center space-x-4 mb-4">
                
//                 <button className="underline" onClick={popModal}>Close</button>
//             </div>
//         </Fragment>
//     )
// }

const EntryForm = ({ vault }) => {
    const { account } = useEthers()
    const { pushModal, popModal, animateStream } = useModals();
    const [ currentVault, setCurrentVault ] = useState(vault);
    const [ currentMode, setCurrentMode ] = useState(mode.direct);
    const [ walletBalance, setWalletBalance ] = useState(undefined);
    const [ investmentValue,  setInvestmentValue ] = useState(0);
    const [ currentInvestmentType, setCurrentInvestmentType ] = useState(investmentType.traditional);
    const allowance = useTokenAllowance(tokenContractsPolygon[currentVault.symbol], account, vaultContractsPolygon[currentVault.symbol])
    const balance = useTokenBalance(tokenContractsPolygon[currentVault.symbol], account);
    useEffect(()=>{
        if (balance) {
            setWalletBalance(formatUnits(balance, 18))
        }
    }, [balance])

    useEffect(() => {
        console.log('allowance', allowance, tokenContractsPolygon[currentVault.symbol], account, vaultContractsPolygon[currentVault.symbol])
    }, [allowance, currentVault])

    const handleInvestmentSelect = newInvestmentType => {
        setCurrentInvestmentType(newInvestmentType.name)
        if (newInvestmentType.name === investmentType.streaming) {
            animateStream(true);
            // pushModal(<SillyNotice />, { overlay: true });
        } else {
            animateStream(false);
        }
    }

    const handleVaultChange = v => {
        setCurrentVault(vaults[v])
        setWalletBalance(undefined);
    }

    return (
        <div className="m-4">
            <InvestmentSelect onChange={handleInvestmentSelect} />
            <label className="block mb-4">
            <span className="text-gray-700">You are depositing into</span>
                <TokenSelect 
                value={vaults.findIndex(each=>each.symbol === currentVault.symbol)}
                onChange={handleVaultChange}
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
                    selectOptions={[`${currentVault.symbol} ${walletBalance ? `(Wallet balance: ${walletBalance})` : ''}`, 'Convert token via ZAP']} />
            </label>
            
            {currentMode === mode.zap
            ? (
                <label className="block mb-4">
                <span className="text-gray-700">Token to be converted/zapped</span>
                    <TokenSelect 
                        onChange={(v)=>console.log(v)} 
                        selectOptions={['Select token', ...supportedTokenSymbols.filter(c=>c !== currentVault.symbol)]} 
                    />
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
                        <input type="number" className="mt-1 block" placeholder="" onChange={e=>setInvestmentValue(e.target.value)} value={investmentValue} />
                        <button className="ml-2 underline" onClick={()=>setInvestmentValue(walletBalance)}>MAX</button>
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
                {(allowance && formatUnits(allowance, 18) === '0.0') && <button className="p-2 border-2 border-black uppercase text-sm font-bold selector-shading"><span className="bg-white">Approve spend of {currentVault.symbol}</span></button>}
                <button className="p-2 border-2 border-black uppercase text-sm font-bold"><span className="bg-white">Deposit</span></button>
            </div>
            <div className="flex justify-center space-x-4 mb-4">
                <button className="underline" onClick={()=>{ popModal(); animateStream(false); }}>Close</button>
            </div>
        </div>
    )
}

export default EntryForm;