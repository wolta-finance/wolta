const Columns = (props: any) => (
    <div className={`flex justify-between flex-wrap ${props.className}`}>{props.children}</div>
)

const Col = (props: any) => (
    <div className={`border-r border-black last:border-0 p-2 flex-grow ${props.className}`}>
        {props.children}
    </div>
)

Columns.Col = Col;

export default Columns;