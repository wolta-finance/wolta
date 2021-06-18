import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { Contract } from "ethers";
import glob from "glob";
import { ethers } from "hardhat";

export const currentTimestamp = async (): Promise<number> => {
  const latestBlock = await ethers.provider.getBlock("latest");
  return latestBlock.timestamp;
};

export const advanceHours = async (numHours: number) =>
  ethers.provider.send("evm_mine", [
    await currentTimestamp().then((t) => t + Math.round(numHours * 60 * 60)),
  ]);

export const advanceBlocks = async (numBlocks: number) => {
  for (let i = 0; i < numBlocks; i++) {
    await ethers.provider.send("evm_mine", []);
  }
};

export const impersonate = async (...addresses: string[]) =>
  ethers.provider.send("hardhat_impersonateAccount", addresses);

export const getArtifact = async (contract: string): Promise<any> =>
  new Promise((resolve, reject) => {
    glob(`**/${contract}.json`, (error, [firstMatch]) => {
      if (error) {
        return reject(error);
      } else {
        // Make sure to update the relative path when moving this file
        return resolve(require(`../../${firstMatch}`));
      }
    });
  });

type ContractDeploymentParams = {
  name: string;
  from: SignerWithAddress;
  args?: any[];
};

export const deployContract = async <T extends Contract>(
  params: ContractDeploymentParams
): Promise<T> => {
  const contractFactory = await ethers.getContractFactory(
    params.name,
    params.from
  );
  const contractInstance = await contractFactory.deploy(...(params.args || []));
  return (await contractInstance.deployed()) as T;
};
