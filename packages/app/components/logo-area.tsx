import DappWalet from "./dappwallet";
import { Fragment } from "react";
const LogoArea = () => (
    <section className="relative">
        <div className="flex justify-center flex-col items-center">
            <h1 className="heading text-3xl">
            The Farming Daily
            </h1>
            <div className="sub-heading text-2xl">Presents</div>
        </div>
        <div className="flex justify-center border-b border-black -ml-5 -mr-5">
            <h2 className="logo tracking-wider text-5xl md:text-7xl lg:text-8xl lg:leading-tight pb-5">
            Wolta Finance
            </h2>
        </div>
        <div className="absolute top-0 right-0">
            <DappWalet />
        </div>
    </section>
);

export default LogoArea;