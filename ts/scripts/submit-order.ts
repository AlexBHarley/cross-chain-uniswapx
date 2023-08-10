import "cross-fetch/polyfill";

import { DutchOrder, DutchOrderBuilder } from "@uniswap/uniswapx-sdk";
import { BigNumber, Wallet, constants, ethers } from "ethers";

import * as dotenv from "dotenv";
import { hexlify, parseEther } from "ethers/lib/utils";
dotenv.config();

import {
  UNISWAPX_SERVICE_URL,
  OPTIMISM_GOERLI_CHAIN_ID,
  GOERLI_CHAIN_ID,
  LOCAL_REACTOR,
  PERMIT2,
  REMOTE_REACTOR,
} from "./constants";

const FIVE_MINUTES = 60 * 5;
const DEADLINE = Math.floor(Date.now() / 1000 + FIVE_MINUTES);

async function main() {
  const client = new ethers.providers.JsonRpcProvider(
    process.env[`${OPTIMISM_GOERLI_CHAIN_ID}_RPC_URL`]
  );

  const wallet = new Wallet(process.env.PRIVATE_KEY!);

  const nonce = await client.getTransactionCount(await wallet.getAddress());

  const chainId = OPTIMISM_GOERLI_CHAIN_ID;

  const startAmount = parseEther("0.01");
  const endAmount = parseEther("0.009");

  const order = new DutchOrder(
    {
      reactor: LOCAL_REACTOR,
      deadline: DEADLINE,
      decayEndTime: DEADLINE,
      decayStartTime: DEADLINE - 100,
      input: {
        token: constants.AddressZero,
        startAmount: startAmount,
        endAmount: startAmount,
      },
      outputs: [
        {
          token: constants.AddressZero,
          startAmount,
          endAmount,
          recipient: await wallet.getAddress(),
        },
      ],
      nonce: BigNumber.from(nonce),
      swapper: process.env.ADDRESS!,
      additionalValidationContract: constants.AddressZero,
      additionalValidationData: "0x",
      exclusiveFiller: constants.AddressZero,
      exclusivityOverrideBps: BigNumber.from(0),
    },
    420,
    "0x000000000022d473030f116ddee9f6b43ac78ba3" // Permit2
  );

  // Sign the built order
  const { domain, types, values } = order.permitData();
  const signature = await wallet._signTypedData(domain, types, values);

  const serializedOrder = order.serialize();

  console.log(order.hash());

  const response = await fetch(`${UNISWAPX_SERVICE_URL}/dutch-auction/order`, {
    method: "POST",
    body: JSON.stringify({
      encodedOrder: serializedOrder,
      signature,
      chainId,
    }),
    headers: {
      "Content-Type": "application/json",
    },
  });
  console.log(response.status);
}

main();
