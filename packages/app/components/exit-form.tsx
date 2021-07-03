import { useModals } from './modalprovider';

const ExitForm = () => {
    const { popModal } = useModals(); 
    return (
        <div className="m-4">
            <button onClick={popModal}>Close</button>
        </div>
    )
}

export default ExitForm;