import { useModals } from './modalprovider';
const EntryForm = () => {
    const { popModal } = useModals(); 
    return (
        <div>
        <form>
            <label>Amount: </label>
            <input name="amount" type="number" value={0}></input>
        </form>
        <button onClick={popModal}>Close</button>
        </div>
    )
}

export default EntryForm;