import Svg from './svg-patterns';
import { encode } from "universal-base64";

const TokenDropdown = () => (
    <div className="flex items-center">
        <div className="text-3xl border border-black px-3">TokenDropdown</div>
        <div className="border border-l border-black text-3xl -ml-px px-3" style={{
      backgroundImage: `url("data:image/svg+xml;base64,${encode(
        Svg({ color: 'black', density: 2, opacity: 0.5 })
      )}")`,
    }}>&darr;</div>
    </div>
)

export default TokenDropdown;