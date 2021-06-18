import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { BigNumberish, Contract } from "ethers";

import { deployContract } from "@/utils/index";

type ControllerDeploymentParams = {
  governance: SignerWithAddress;
};

export const deployController = async (
  deployer: SignerWithAddress,
  params: ControllerDeploymentParams
): Promise<Contract> =>
  deployContract({
    name: "Controller",
    from: deployer,
    args: [params.governance.address],
  });

type VaultDeploymentParams = {
  governance: SignerWithAddress;
  controller: Contract;
  underlying: Contract;
  investmentPercentage: BigNumberish;
};

export const deployVault = async (
  deployer: SignerWithAddress,
  params: VaultDeploymentParams
): Promise<Contract> =>
  deployContract({
    name: "Vault",
    from: deployer,
    args: [
      params.governance.address,
      params.controller.address,
      params.underlying.address,
      params.investmentPercentage,
    ],
  });

type StrategyDeploymentParams = {
  name: string;
  args: (string | BigNumberish)[];
};

export const deployStrategy = async (
  deployer: SignerWithAddress,
  params: StrategyDeploymentParams
): Promise<Contract> =>
  deployContract({
    name: params.name,
    from: deployer,
    args: params.args,
  });

type BasicProtocolDeploymentParams = {
  governance: SignerWithAddress;
  underlying: Contract;
  investmentPercentage: BigNumberish;
  strategyName: string;
  strategyArgs?: (string | BigNumberish)[];
};

type BasicProtocol = {
  controller: Contract;
  vault: Contract;
  strategy: Contract;
};

export const setupBasicProtocol = async (
  deployer: SignerWithAddress,
  params: BasicProtocolDeploymentParams
): Promise<BasicProtocol> => {
  const controller = await deployController(deployer, {
    governance: params.governance,
  });

  const vault = await deployVault(deployer, {
    governance: params.governance,
    controller,
    underlying: params.underlying,
    investmentPercentage: params.investmentPercentage,
  });

  const defaultStrategyArgs = [params.governance.address, vault.address];
  const strategy = await deployStrategy(deployer, {
    name: params.strategyName,
    args: params.strategyArgs || defaultStrategyArgs,
  });

  // Connect the vault and strategy via the controller
  await controller
    .connect(params.governance)
    .addVaultAndStrategy(vault.address, strategy.address);

  return {
    controller,
    vault,
    strategy,
  };
};
