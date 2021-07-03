import { Fragment, useRef, createContext, useContext, useState } from 'react';
import { Dialog, Transition } from '@headlessui/react';
import Canvas from './canvas-animation';
const Modal = (props: any) => {

    const newRef = useRef();
    const initialFocus = props.initialFocus ? props.initialFocus : newRef;
    
    return(
    <Dialog
        as="div"
        static
        className="fixed z-50 inset-0 overflow-y-auto"
        initialFocus={initialFocus}
        open={true}
        onClose={()=>undefined}
      >

        <div className="flex items-center justify-center min-h-screen pt-4 px-4 pb-20 text-center sm:p-0">
            {props.overlay && <Dialog.Overlay className="fixed inset-0 bg-mono-400 bg-opacity-80 backdrop-filter backdrop-opacity-80 bg-white" />}
            {props.overlay && props.animationActive && <Canvas />}
            <div className="border border-black bg-white p-px sm:my-8 sm:max-w-lg sm:w-full transform transition-all">
            <div className="border border-black text-left overflow-hidden">
                <div className="p-1" ref={!props.initialFocus && initialFocus}>
                    {props.children}
                </div>
            </div>
            </div>
        </div>
    </Dialog>
)}

const ModalContext = createContext(null);

type ContextType = {
    stack: {}[], 
    pushModal: (component: any, modalProps: {}) => void,
    popModal: () => void,
    popAllModals: () => void,
    animateStream: (active: boolean) => void,
}

export const useModals = () => {
  const ctx: ContextType = useContext(ModalContext);

  if (!ctx) {
    throw Error(
      'The `useModals` hook must be called from a descendent of the `ModalProvider`.'
    );
  }

  return ctx
}

const { Provider } = ModalContext;

const ModalProvider = (props: any) => {
    const [stack, setStack] = useState([]);
    const [animationActive, setAnimationActive] = useState(false);
    const contextValue: ContextType = {
        stack, 
        pushModal: (component, modalProps) => setStack(current=>[...current, { component, modalProps}]),
        popModal: () => setStack(current=>current.slice(0, current.length - 1)),
        popAllModals: () => setStack([]),
        animateStream: setAnimationActive,
    }
    return (
        <Fragment>
            <Provider value={contextValue}>
                {props.children}
                {stack.map((stackItem, i)=> <Modal key={i} animationActive={animationActive} {...stackItem.modalProps}>{stackItem.component}</Modal>)}
            </Provider>
        </Fragment>
    )
}


export default ModalProvider