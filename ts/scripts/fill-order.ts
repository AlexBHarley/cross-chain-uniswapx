import "cross-fetch/polyfill";
import * as dotenv from "dotenv";
dotenv.config();

import { DutchOrder } from "@uniswap/uniswapx-sdk";
import { Wallet, ethers, utils, Contract } from "ethers";

import {
  REMOTE_REACTOR,
  GOERLI_CHAIN_ID,
  OPTIMISM_GOERLI_CHAIN_ID,
  UNISWAPX_SERVICE_URL,
} from "./constants";
import { abi as RemoteReactorAbi } from "../../out/ExclusiveDutchOrderReactor.sol/ExclusiveDutchOrderReactor.json";

const [, , orderHash] = process.argv;
if (!orderHash) {
  console.log("Missing order hash");
  process.exit(1);
}

async function main() {
  const provider = new ethers.providers.JsonRpcProvider(
    process.env[`${GOERLI_CHAIN_ID}_RPC_URL`]
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

  const executor = new Contract(REMOTE_REACTOR, RemoteReactorAbi, wallet);

  console.log({
    order: order.encodedOrder,
    sig: order.signature,
  });

  const response = await executor.execute(
    {
      order: order.encodedOrder,
      sig: order.signature,
    },
    {
      value: utils.parseEther("0.001"),
    }
  );
  console.log(response);
}

main();
