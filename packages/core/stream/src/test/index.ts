import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { BigNumberish, Contract } from "ethers";

import { deployContract } from "@/utils/index";

type ControllerDeploymentParams = {
  governance: SignerWithAddress;
};

export const deployController = async (
  deployer: SignerWithAddress,
  { governance }: ControllerDeploymentParams
): Promise<Contract> =>
  deployContract({
    name: "Controller",
    from: deployer,
    args: [governance.address],
  });

type VaultDeploymentParams = {
  name: string;
  args: (string | BigNumberish)[];
};

export const deployVault = async (
  deployer: SignerWithAddress,
  { name, args }: VaultDeploymentParams
): Promise<Contract> =>
  deployContract({
    name,
    from: deployer,
    args,
  });

type StrategyDeploymentParams = {
  name: string;
  args: (string | BigNumberish)[];
};

export const deployStrategy = async (
  deployer: SignerWithAddress,
  { name, args }: StrategyDeploymentParams
): Promise<Contract> =>
  deployContract({
    name,
    from: deployer,
    args,
  });

type BasicProtocolDeploymentParams = {
  governance: SignerWithAddress;
  strategyName: string;
  strategyArgs?: (string | BigNumberish)[];
};

type BasicProtocol = {
  controller: Contract;
  vault: Contract;
  strategy: Contract;
};

export const setupProtocolWithStrategy = async (
  deployer: SignerWithAddress,
  { governance, strategyName, strategyArgs }: BasicProtocolDeploymentParams
): Promise<BasicProtocol> => {
  const controller = await deployController(deployer, {
    governance,
  });

  const vault = await deployVault(deployer, {
    name: `${strategyName}_Vault`,
    args: [controller.address],
  });

  const defaultStrategyArgs = [vault.address];
  const strategy = await deployStrategy(deployer, {
    name: strategyName,
    args: strategyArgs || defaultStrategyArgs,
  });

  // Connect the vault and strategy via the controller
  await controller
    .connect(governance)
    .addVaultAndStrategy(vault.address, strategy.address);

  return {
    controller,
    vault,
    strategy,
  };
};

type BasicZapDeploymentParams = {
  governance: SignerWithAddress;
  router: string;
  swapRoutes: string[][];
};

export const setupUniswapV2Zap = async (
  deployer: SignerWithAddress,
  { governance, router, swapRoutes }: BasicZapDeploymentParams
): Promise<Contract> => {
  const zap = await deployContract({
    from: deployer,
    name: "UniswapV2Zap",
    args: [governance.address, router],
  });

  for (const route of swapRoutes) {
    await zap
      .connect(governance)
      .addSwapRoute(route[0], route[route.length - 1], route);
  }

  return zap;
};
