import "cross-fetch/polyfill";
import dotenv from "dotenv";
dotenv.config();

import { DutchOrder } from "@uniswap/uniswapx-sdk";
import { Wallet, ethers, utils, Contract } from "ethers";

import {
  CROSS_CHAIN_EXECUTOR,
  OPTIMISM_GOERLI_CHAIN_ID,
  UNISWAPX_SERVICE_URL,
} from "./constants";
import { abi as CrossChainExecutorAbi } from "../../out/CrossChainExecutor.sol/CrossChainExecutor.json";

const [, , orderHash] = process.argv;
if (!orderHash) {
  console.log("Missing order hash");
  process.exit(1);
}

async function main() {
  const provider = new ethers.providers.JsonRpcProvider(
    process.env[`${OPTIMISM_GOERLI_CHAIN_ID}_RPC_URL`]
  );
  const wallet = new Wallet(process.env.PRIVATE_KEY!, provider);

  const result = await fetch(
    `${UNISWAPX_SERVICE_URL}/dutch-auction/orders?chainId=${OPTIMISM_GOERLI_CHAIN_ID}&orderHash=${orderHash}&orderStatus=open`
  ).then((x) => x.json());
  if (!result.orders.length) {
    console.log("Invalid order hash");
    process.exit(1);
  }

  const order = result.orders[0];
  const parsed = DutchOrder.parse(
    order.encodedOrder,
    420,
    "0x000000000022d473030f116ddee9f6b43ac78ba3"
  );

  console.log("Cross Chain Dutch Auction");
  console.log(
    "Input:",
    utils.formatEther(parsed.info.input.startAmount),
    "ETH", // parsed.info.input.token,
    "on chain",
    parsed.chainId
  );
  console.log(
    "Output:",
    utils.formatEther(parsed.info.outputs[0].startAmount),
    "ETH", // parsed.info.outputs[0].token,
    "on chain",
    parseInt(parsed.info.additionalValidationData)
  );

  const executor = new Contract(
    CROSS_CHAIN_EXECUTOR,
    CrossChainExecutorAbi,
    wallet
  );
}

main();
