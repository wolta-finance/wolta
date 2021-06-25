import { encode } from "universal-base64";
import Svg from './svg-patterns';

const MainPaperWindow = (props: any) => (
    <main className=" max-w-screen-lg mx-auto relative pr-16 pb-16 mt-10">
    <div className="absolute inset-0 left-5 top-5 right-10 bottom-10  border border-black bg-white z-20"></div>
    <div className="absolute inset-0 left-10 top-10 right-5 bottom-5  border border-black bg-white z-10"></div>
    <div className="absolute inset-0 left-16 top-16 right-0 bottom-0 bg-black z-0" style={{
      backgroundImage: `url("data:image/svg+xml;base64,${encode(
        Svg({ color: '#FFFFFF', density: 4 })
      )}")`,
    }}></div>
    <div className="relative border border-black bg-white p-5 z-50">
        {props.children}
    </div>
    </main>
)

export default MainPaperWindow;