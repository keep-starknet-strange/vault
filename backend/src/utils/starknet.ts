import { Account, Contract, ec, json, RpcProvider, stark } from "starknet";
import ClassHashInfo from "../assets/class_hashes.json";
import dotenv from "dotenv";
import fs from "fs";
dotenv.config();

const starknet_rpc = process.env.STARKNET_RPC || "";
const wallet_p_key = process.env.WALLET_P_KEY || "";
const wallet_address = process.env.WALLET_ADDRESS || "";

export const deployAccountContract = async (
  public_key = "0",
  approver = "0",
  limit = "0",
  phone_number: string
): Promise<string> => {
  try {
    const provider = new RpcProvider({
      nodeUrl: starknet_rpc,
    });
    const account = new Account(provider, wallet_address, wallet_p_key);

    const class_hash_network = await check_class_hash(
      provider,
      ClassHashInfo.sierra
    );

    const compiledSierra = json.parse(
      fs
        .readFileSync("./src/assets/vault_account.sierra.json")
        .toString("ascii")
    );
    const compiledCasm = json.parse(
      fs.readFileSync("./src/assets/vault_account.casm.json").toString("ascii")
    );

    if (!class_hash_network) {
      const txn = await account.declare({
        contract: compiledSierra,
        classHash: ClassHashInfo.sierra,
        compiledClassHash: ClassHashInfo.casm,
      });

      await provider.waitForTransaction(txn.transaction_hash);

      console.log(txn.class_hash);
    }

    const deploy_txn = await account.deployContract({
      classHash: ClassHashInfo.sierra,
      constructorCalldata: [public_key, approver, limit],
    });

    await provider.waitForTransaction(deploy_txn.transaction_hash);

    return deploy_txn.contract_address;
  } catch (error: any) {
    throw new Error(
      `Error : ${error}, Error in deploying contract for Phone Number : ${phone_number}`
    );
  }
};

const check_class_hash = async (
  provider: RpcProvider,
  class_hash: string
): Promise<boolean> => {
  try {
    const class_hash_network = await provider.getClassByHash(class_hash);
    return true;
  } catch (error) {
    return false;
  }
};

export const generateRandomAddress = (): {
  random_p_key: string;
  public_key: string;
} => {
  const random_p_key = stark.randomAddress();
  const public_key = ec.starkCurve.getStarkKey(random_p_key);

  return { random_p_key, public_key };
};
