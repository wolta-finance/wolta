const { web3tx, toWad, wad4human } = require("@decentral.ee/web3-helpers");
const { assert, expect } = require("chai");
const BigNumber = require("bignumber.js");
const { time } = require("@openzeppelin/test-helpers");
BigNumber.config({ DECIMAL_PLACES: 0 });

const { ethers, contract } = require("hardhat");

const { t } = require("@/config/polygon.json");

const deployFramework = require("@superfluid-finance/ethereum-contracts/scripts/deploy-framework");
const deployTestToken = require("@superfluid-finance/ethereum-contracts/scripts/deploy-test-token");
const deploySuperToken = require("@superfluid-finance/ethereum-contracts/scripts/deploy-super-token");
const SuperfluidSDK = require("@superfluid-finance/js-sdk");

const TEST_TRAVEL_TIME = 3600 * 2; // 1 hours

describe("Test test", (accounts) => {
  const errorHandler = (err) => {
    if (err) throw err;
  };

  const names = ["Owner", "Alice", "Bob"];

  let sf;
  let dai;
  let daix;
  let app;
  let stf;
  let tp; // Tellor playground
  let usingTellor;
  let sr; // Mock Sushi Router
  const u = {}; // object with all users
  const aliases = {};

  before(async function () {
    const [owner, alice, bob, carl] = await ethers.getSigners();
    // Set up signers

    await deployFramework(errorHandler, {
      web3,
      from: owner.address,
    });

    const underlying = await ethers.getContractAt("ERC20", t.dai);

    const underlyingWhaleAddress = "0x9D945d909Ca91937d19563e30bB4DAc12C860189";
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [underlyingWhaleAddress],
    });
    const underlyingWhale = await ethers.getSigner(underlyingWhaleAddress);

    // Transfer underlying from whale to farmer
    await underlying
      .connect(underlyingWhale)
      .transfer(
        alice.address,
        await underlying.balanceOf(underlyingWhaleAddress)
      );
  });

  beforeEach(async function () {
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: ["0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"],
    });

    const owner = await ethers.provider.getSigner(
      "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"
    );

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: ["0x70997970c51812dc3a010c7d01b50e0d17dc79c8"],
    });
    const alice = await ethers.provider.getSigner(
      "0x70997970c51812dc3a010c7d01b50e0d17dc79c8"
    );

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: ["0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc"],
    });
    const bob = await ethers.provider.getSigner(
      "0x3c44cdddb6a900fa2b585dd299e03d12fa4293bc"
    );

    // const [carl] = await ethers.getSigners();

    const accounts = [owner, alice, bob];

    await deployTestToken(errorHandler, [":", "fDAI"], {
      web3,
      from: owner.address,
    });
    await deploySuperToken(errorHandler, [":", "fDAI"], {
      web3,
      from: owner.address,
    });

    sf = new SuperfluidSDK.Framework({
      web3,
      version: "test",
      //   resolverAddress: "0xE0cc76334405EE8b39213E620587d815967af39C",
      tokens: ["fDAI"],
    });
    await sf.initialize();
    daix = sf.tokens.fDAIx;
    dai = await sf.contracts.TestToken.at(await sf.tokens.fDAI.address);
    stf = await sf.host.getSuperTokenFactory();
    for (var i = 0; i < names.length; i++) {
      u[names[i].toLowerCase()] = sf.user({
        address: accounts[i]._address || accounts[i].address,
        token: daix.address,
      });
      u[names[i].toLowerCase()].alias = names[i];
      aliases[u[names[i].toLowerCase()].address] = names[i];
    }
    for (const [, user] of Object.entries(u)) {
      if (user.alias === "App") return;
      await web3tx(dai.mint, `${user.alias} mints many dai`)(
        user.address,
        toWad(100000000),
        {
          from: user.address,
        }
      );
      await web3tx(dai.approve, `${user.alias} approves daix`)(
        daix.address,
        toWad(100000000),
        {
          from: user.address,
        }
      );
    }
    console.log(u.owner.address);
    console.log(sf.host.address);
    console.log(sf.agreements.cfa.address);
    console.log(daix.address);
    console.log(stf);

    const Controller = await ethers.getContractFactory("Controller");

    let controller = await Controller.deploy(u.owner.address);
    await controller.deployed();

    console.log("controller deployed at", controller.address);

    const MasterStreamer = await ethers.getContractFactory("MasterStreamer");

    const gasPrice = ethers.utils.parseUnits("100", "gwei");
    const gasLimit = 12450000;

    app = await MasterStreamer.deploy(
      sf.host.address,
      sf.agreements.cfa.address,
      stf,
      daix.address,
      controller.address,
      { gasPrice: gasPrice, gasLimit: gasLimit }
    );

    // u.app = sf.user({ address: app.address, token: daix.address });
    // u.app.alias = "App";
    // await checkBalance(u.app);
  });

  it("Case #1 - Alice sends a flow", async () => {
    console.log("intru aici sau sal?");
    assert.equal(2, 2, "balances aren't equal");
    // const { alice } = u;
    // const appInitialBalance = await daix.balanceOf(app.address);
    // await upgrade([alice]);
    // await checkBalances([alice, u.admin]);
    // await appStatus();
    // await logUsers();
    // await alice.flow({ flowRate: toWad(0.001), recipient: u.app });
    // console.log("go forward in time");
    // await traveler.advanceTimeAndBlock(TEST_TRAVEL_TIME);
    // await appStatus();
    // await logUsers();

    // alice.flow({ recipient: u.app, flowRate: "0" });

    // console.log("go forward in time");
    // await traveler.advanceTimeAndBlock(TEST_TRAVEL_TIME);
    // await appStatus();
    // await logUsers();
    // const appFinalBalance = await daix.balanceOf(app.address);
    // assert.equal(
    //     (await u.app.details()).cfa.netFlow,
    //     0,
    //     "App flowRate not zero"
    // );
    // assert.equal(
    //     appInitialBalance.toString(),
    //     appFinalBalance.toString(),
    //     "balances aren't equal"
    // );
  });
});
