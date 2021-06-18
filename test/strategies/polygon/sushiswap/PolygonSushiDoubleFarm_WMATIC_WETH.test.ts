import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { BigNumber, Contract } from "ethers";
import { ethers } from "hardhat";

import { lpTokens, routers, tokens } from "@/config/polygon.json";
import { setupProtocolWithStrategy } from "@/test/index";
import {
  advanceHours,
  deployContract,
  getArtifact,
  impersonate,
} from "@/utils/index";

const { sushiswap } = routers;
const { dai, weth, wmatic } = tokens;
const { sushiWmaticWeth } = lpTokens;

const STRATEGY = "PolygonSushiDoubleFarm_WMATIC_WETH";

// Use block 15482261
describe(STRATEGY, function () {
  this.timeout(600000);

  let underlying: Contract;

  let controller: Contract;
  let vault: Contract;
  let strategy: Contract;

  let zap: Contract;

  let deployer: SignerWithAddress;
  let governance: SignerWithAddress;
  let farmer: SignerWithAddress;
  let zapper: SignerWithAddress;

  before(async () => {
    const IERC20 = await getArtifact("IERC20");

    // Setup underlying
    underlying = new Contract(sushiWmaticWeth, IERC20.abi, ethers.provider);

    // Setup signers
    [deployer, governance, farmer, zapper] = await ethers.getSigners();

    // Impersonate whale account
    const underlyingWhaleAddress = "0x0160afFF7a7A824429A8202995D03239d2D418fa";
    await impersonate(underlyingWhaleAddress);
    const underlyingWhale = await ethers.getSigner(underlyingWhaleAddress);

    // Transfer from whale to farmer
    await underlying
      .connect(underlyingWhale)
      .transfer(
        farmer.address,
        await underlying.balanceOf(underlyingWhale.address)
      );

    // Setup protocol
    const contracts = await setupProtocolWithStrategy(deployer, {
      governance,
      strategyName: STRATEGY,
    });

    controller = contracts.controller;
    vault = contracts.vault;
    strategy = contracts.strategy;

    // zap = await deployContract({
    //   from: deployer,
    //   name: "UniswapV2Zap",
    //   args: [governance.address, sushiswap],
    // });

    // await zap.connect(governance).addSwapRoute(dai, weth, [dai, weth]);
    // await zap
    //   .connect(governance)
    //   .addSwapRoute(dai, wmatic, [dai, weth, wmatic]);
    // await zap.connect(governance).addSwapRoute(weth, dai, [weth, dai]);
    // await zap
    //   .connect(governance)
    //   .addSwapRoute(wmatic, dai, [wmatic, weth, dai]);

    // // Impersonate whale account
    // const daiWhaleAddress = "0x493BEb822506d75eD7C6484b219A2E5979EE377c";
    // await impersonate(daiWhaleAddress);
    // const daiWhale = await ethers.getSigner(daiWhaleAddress);

    // // Transfer from whale to zapper
    // const daiContract = new Contract(dai, IERC20.abi, ethers.provider);
    // await daiContract
    //   .connect(daiWhale)
    //   .transfer(zapper.address, await daiContract.balanceOf(daiWhale.address));
  });

  // it("zap in", async () => {
  //   const IERC20 = await getArtifact("IERC20");
  //   const daiContract = new Contract(dai, IERC20.abi, ethers.provider);

  //   console.log(
  //     "Dai before before",
  //     await daiContract.balanceOf(zapper.address).then((n: any) => n.toString())
  //   );

  //   await daiContract
  //     .connect(zapper)
  //     .approve(zap.address, await daiContract.balanceOf(zapper.address));
  //   await zap
  //     .connect(zapper)
  //     .zapIn(
  //       vault.address,
  //       dai,
  //       await daiContract.balanceOf(zapper.address),
  //       1
  //     );

  //   console.log(
  //     "Dai before",
  //     await daiContract.balanceOf(zapper.address).then((n: any) => n.toString())
  //   );
  //   console.log(
  //     "Shares before",
  //     await vault.balanceOf(zapper.address).then((n: any) => n.toString())
  //   );

  //   await vault
  //     .connect(zapper)
  //     .approve(zap.address, await vault.balanceOf(zapper.address));
  //   await zap
  //     .connect(zapper)
  //     .zapOutAndSwap(
  //       vault.address,
  //       await vault.balanceOf(zapper.address),
  //       dai,
  //       1
  //     );

  //   console.log(
  //     "Dai after",
  //     await daiContract.balanceOf(zapper.address).then((n: any) => n.toString())
  //   );
  //   console.log(
  //     "Shares after",
  //     await vault.balanceOf(zapper.address).then((n: any) => n.toString())
  //   );
  // });

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
  });
}).timeout(600000);
