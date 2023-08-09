import "cross-fetch/polyfill";

import dotenv from "dotenv";
dotenv.config();

import { UNISWAPX_SERVICE_URL, OPTIMISM_GOERLI_CHAIN_ID } from "./constants";

async function main() {
  const result = await fetch(
    `${UNISWAPX_SERVICE_URL}/dutch-auction/orders?chainId=${OPTIMISM_GOERLI_CHAIN_ID}`
  ).then((x) => x.json());

  console.log(result);
}

main();
