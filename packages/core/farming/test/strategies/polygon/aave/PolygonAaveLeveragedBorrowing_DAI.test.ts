import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, Contract } from "ethers";
import { ethers } from "hardhat";

import { t } from "@/config/polygon.json";
import { setupProtocolWithStrategy } from "@/test/index";
import { advanceHours, formatValue, impersonate } from "@/utils/index";

const STRATEGY = "PolygonAaveLeveragedBorrowing_DAI";

// Use block 15869576
describe(STRATEGY, function () {
  this.timeout(600000);

  let underlying: Contract;

  let controller: Contract;
  let vault: Contract;
  let strategy: Contract;

  let deployer: SignerWithAddress;
  let governance: SignerWithAddress;
  let farmer: SignerWithAddress;

  before(async () => {
    // Set up token contracts
    underlying = await ethers.getContractAt("ERC20", t.dai);

    // Set up signers
    [deployer, governance, farmer] = await ethers.getSigners();

    // Impersonate underlying whale account
    const underlyingWhaleAddress = "0x1A50a6238eb67285cCD4DF17f75CCe430BAAE2A4";
    await impersonate(underlyingWhaleAddress);
    const underlyingWhale = await ethers.getSigner(underlyingWhaleAddress);

    // Transfer underlying from whale to farmer
    await underlying
      .connect(underlyingWhale)
      .transfer(
        farmer.address,
        await underlying.balanceOf(underlyingWhaleAddress)
      );

    // Set up protocol
    const protocolContracts = await setupProtocolWithStrategy(deployer, {
      governance,
      strategyName: STRATEGY,
    });

    controller = protocolContracts.controller;
    vault = protocolContracts.vault;
    strategy = protocolContracts.strategy;
  });

  it("farmer earns money", async () => {
    const initialFarmerBalance: BigNumber = await underlying.balanceOf(
      farmer.address
    );

    await underlying
      .connect(farmer)
      .approve(vault.address, initialFarmerBalance);
    await vault.connect(farmer).deposit(initialFarmerBalance, farmer.address);

    let oldSharePrice: BigNumber;
    let newSharePrice: BigNumber;

    for (let i = 0; i < 10; i++) {
      console.log(`Loop ${i}`);

      oldSharePrice = await vault.pricePerShare();
      await vault.connect(governance).doHardWork();
      newSharePrice = await vault.pricePerShare();

      console.log(
        `Old share price: ${await formatValue(vault, oldSharePrice)}`
      );
      console.log(
        `New share price: ${await formatValue(vault, newSharePrice)}`
      );

      await advanceHours(12);
    }

    await vault
      .connect(farmer)
      .withdraw(await vault.balanceOf(farmer.address), farmer.address);
    const currentFarmerBalance: BigNumber = await underlying.balanceOf(
      farmer.address
    );
    expect(initialFarmerBalance.lt(currentFarmerBalance)).to.be.true;

    console.log(
      `Earned ${await formatValue(
        underlying,
        currentFarmerBalance.sub(initialFarmerBalance)
      )}`
    );
  });
});
