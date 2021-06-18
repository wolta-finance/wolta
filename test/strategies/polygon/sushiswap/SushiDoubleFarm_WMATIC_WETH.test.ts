import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, Contract } from "ethers";
import { ethers } from "hardhat";

import { setupBasicProtocol } from "@/protocol/index";
import { advanceHours, getArtifact, impersonate } from "@/utils/index";

const STRATEGY = "SushiDoubleFarm_WMATIC_WETH";

// Use block 15482261
describe(STRATEGY, () => {
  let underlying: Contract;

  let controller: Contract;
  let vault: Contract;
  let strategy: Contract;

  let deployer: SignerWithAddress;
  let governance: SignerWithAddress;
  let farmer: SignerWithAddress;

  before(async () => {
    const IERC20 = await getArtifact("IERC20");

    // Setup underlying
    underlying = new Contract(
      "0xc4e595acdd7d12fec385e5da5d43160e8a0bac0e", // WMATIC/WETH SLP
      IERC20.abi,
      ethers.provider
    );

    // Setup signers
    [deployer, governance, farmer] = await ethers.getSigners();

    // Impersonate whale account
    const whaleAddress = "0x0160afFF7a7A824429A8202995D03239d2D418fa";
    await impersonate(whaleAddress);
    const whale = await ethers.getSigner(whaleAddress);

    // Transfer from whale to farmer
    await underlying
      .connect(whale)
      .transfer(farmer.address, await underlying.balanceOf(whale.address));

    // Setup protocol
    const contracts = await setupBasicProtocol(deployer, {
      governance,
      underlying,
      investmentPercentage: ethers.utils.parseEther("1"),
      strategyName: STRATEGY,
    });

    controller = contracts.controller;
    vault = contracts.vault;
    strategy = contracts.strategy;
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
        `Old share price: ${ethers.utils.formatEther(oldSharePrice)}`
      );
      console.log(
        `New share price: ${ethers.utils.formatEther(newSharePrice)}`
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
      `Earned ${currentFarmerBalance.sub(initialFarmerBalance).toString()}`
    );
  }).timeout(600000);
});
