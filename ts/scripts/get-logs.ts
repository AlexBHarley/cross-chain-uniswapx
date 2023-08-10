import "cross-fetch/polyfill";
import * as dotenv from "dotenv";
dotenv.config();

import { DutchOrder, EventWatcher } from "@uniswap/uniswapx-sdk";
import { Wallet, ethers, utils, Contract } from "ethers";

import {
  REMOTE_REACTOR,
  GOERLI_CHAIN_ID,
  OPTIMISM_GOERLI_CHAIN_ID,
  UNISWAPX_SERVICE_URL,
  LOCAL_REACTOR,
} from "./constants";
import { abi as RemoteReactorAbi } from "../../out/ExclusiveDutchOrderReactor.sol/ExclusiveDutchOrderReactor.json";

async function main() {
  const provider = new ethers.providers.JsonRpcProvider(
    process.env[`${OPTIMISM_GOERLI_CHAIN_ID}_RPC_URL`]
  );
  const wallet = new Wallet(process.env.PRIVATE_KEY!, provider);

  const a = new EventWatcher(provider, LOCAL_REACTOR);

  const fillEvents = await a.getFillInfo(13131532, 13132687);
  console.log(fillEvents);
}

main();
