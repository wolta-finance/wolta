const TokenSelect = ({ selectOptions = [], currentlySelectedImage, onChange, value}) => (
<div className="relative">
    <div className="absolute pl-2 pt-1">
        {currentlySelectedImage}
    </div>
    <select value={value} onChange={event => onChange(event.target.value)} className={(currentlySelectedImage ? 'pl-11 ' : '') + "block w-full mt-1  focus:border-purple-500 focus:ring-purple-500"}>
        {selectOptions.map((option, i)=>(
            <option value={i} key={Math.random()}>{option}</option>
        ))}
    </select>
</div>
)

export default TokenSelect;