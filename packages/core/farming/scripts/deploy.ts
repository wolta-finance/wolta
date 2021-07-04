import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import ethers, { BigNumber, Contract } from "ethers";
import { t } from "@/config/polygon.json";

let underlying: Contract;

let controller: Contract;
let vault: Contract;
let strategy: Contract;

let deployer: SignerWithAddress;
let governance: SignerWithAddress;
let farmer: SignerWithAddress;

async function main() {
    // Set up token contracts
    underlying = await ethers.getContractAt("ERC20", t.dai);
}

main();