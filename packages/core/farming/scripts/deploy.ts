import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber, Contract } from "ethers";
import { setupProtocolWithStrategy } from "@/test/index";
import { ethers } from "hardhat";
import { t } from "@/config/polygon.json";

const STRATEGY = "PolygonAaveLending_DAI";

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

    // Set up signers
    [deployer, governance] = await ethers.getSigners();
    console.log(governance)
    // Set up protocol
    const protocolContracts = await setupProtocolWithStrategy(deployer, {
      governance: deployer,
      strategyName: STRATEGY,
    });

    controller = protocolContracts.controller;
    vault = protocolContracts.vault;
    strategy = protocolContracts.strategy;


    console.log(vault)
    console.log(controller.address);
    console.log(vault.address);
    console.log(strategy.address);
}

main();