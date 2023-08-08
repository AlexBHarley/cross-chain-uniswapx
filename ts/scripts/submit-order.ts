import { DutchOrderBuilder } from "@uniswap/uniswapx-sdk";
import { BigNumber, Wallet, constants, ethers } from "ethers";
import { optimismGoerli } from "viem/chains";

import dotenv from "dotenv";
dotenv.config();

const OPTIMISM_GOERLI_CHAIN_ID = 420;
const GOERLI_CHAIN_ID = 5;

const ONE_HOUR = 60 * 60;
const DEADLINE = Date.now() / 1000 + ONE_HOUR;

async function main() {
  const client = new ethers.providers.JsonRpcProvider(
    process.env[`${OPTIMISM_GOERLI_CHAIN_ID}_RPC_URL`]
  );

  const wallet = new Wallet(process.env.PRIVATE_KEY!);

  const nonce = await client.getTransactionCount(await wallet.getAddress());

  const chainId = optimismGoerli.id;
  const builder = new DutchOrderBuilder(chainId);

  const order = builder
    .deadline(DEADLINE)
    .decayEndTime(DEADLINE)
    .decayStartTime(DEADLINE - 100)
    .nonce(BigNumber.from(nonce))
    .input({
      token: constants.AddressZero,
      startAmount: BigNumber.from("1"),
      endAmount: BigNumber.from("1"),
    })
    .output({
      token: constants.AddressZero,
      startAmount: BigNumber.from("1"),
      endAmount: BigNumber.from("1"),
      recipient: await wallet.getAddress(),
    })
    .validation({
      additionalValidationData: GOERLI_CHAIN_ID.toString(),
      additionalValidationContract: "",
    })
    .build();

  // Sign the built order
  const { domain, types, values } = order.permitData();
  const signature = wallet._signTypedData(domain, types, values);

  const serializedOrder = order.serialize();

  console.log({
    signature,
    serializedOrder,
  });
  // submit serializedOrder and signature to order pool
}

main();
