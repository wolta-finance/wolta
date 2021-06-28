import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, Contract } from "ethers";
import { ethers } from "hardhat";

import { lpt, r, t } from "@/config/polygon.json";
import { setupProtocolWithStrategy, setupUniswapV2Zap } from "@/test/index";
import {
  advanceHours,
  formatBalance,
  formatValue,
  impersonate,
} from "@/utils/index";

const STRATEGY = "PolygonSushiDoubleFarm_WMATIC_WETH";

// Use block 15482261
describe(STRATEGY, function () {
  this.timeout(600000);

  let underlying: Contract;
  let usdc: Contract;

  let controller: Contract;
  let vault: Contract;
  let strategy: Contract;

  let zap: Contract;

  let deployer: SignerWithAddress;
  let governance: SignerWithAddress;
  let farmer: SignerWithAddress;
  let zapper: SignerWithAddress;

  before(async () => {
    // Set up token contracts
    underlying = await ethers.getContractAt("ERC20", lpt.sushiWmaticWeth);
    usdc = await ethers.getContractAt("ERC20", t.usdc);

    // Set up signers
    [deployer, governance, farmer, zapper] = await ethers.getSigners();

    // Impersonate underlying whale account
    const underlyingWhaleAddress = "0x0160afFF7a7A824429A8202995D03239d2D418fa";
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

    // Impersonate USDC whale account
    const usdcWhaleAddress = "0x86fE8d6D4C8A007353617587988552B6921514Cb";
    await impersonate(usdcWhaleAddress);
    const usdcWhale = await ethers.getSigner(usdcWhaleAddress);

    // Transfer USDC from whale to zapper
    await usdc
      .connect(usdcWhale)
      .transfer(zapper.address, await usdc.balanceOf(usdcWhaleAddress));

    // Set up zap
    zap = await setupUniswapV2Zap(deployer, {
      governance,
      router: r.sushiswap,
      swapRoutes: [
        [t.usdc, t.weth],
        [t.usdc, t.weth, t.wmatic],
        [t.weth, t.usdc],
        [t.wmatic, t.weth, t.usdc],
      ],
    });
  });

  it("zap", async () => {
    const zapInBalance = await usdc.balanceOf(zapper.address);

    console.log("Before zap in");
    console.log(`Balance: ${await formatBalance(usdc, zapper.address)}`);
    console.log(`Shares: ${await formatBalance(vault, zapper.address)}`);

    await usdc.connect(zapper).approve(zap.address, zapInBalance);
    await zap.connect(zapper).zapIn(vault.address, t.usdc, zapInBalance, 1);

    console.log("After zap in");
    console.log(`Balance: ${await formatBalance(usdc, zapper.address)}`);
    console.log(`Shares: ${await formatBalance(vault, zapper.address)}`);

    expect((await usdc.balanceOf(zapper.address)).eq(0)).to.be.true;
    expect((await vault.balanceOf(zapper.address)).eq(0)).to.be.false;

    const zapOutBalance = await vault.balanceOf(zapper.address);

    await vault.connect(zapper).approve(zap.address, zapOutBalance);
    await zap
      .connect(zapper)
      .zapOutAndSwap(vault.address, zapOutBalance, t.usdc, 1);

    console.log("After zap out");
    console.log(`Balance: ${await formatBalance(usdc, zapper.address)}`);
    console.log(`Shares: ${await formatBalance(vault, zapper.address)}`);

    expect((await usdc.balanceOf(zapper.address)).eq(0)).to.be.false;
    expect((await vault.balanceOf(zapper.address)).eq(0)).to.be.true;
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
