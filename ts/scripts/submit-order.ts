import { DutchOrderBuilder } from "@uniswap/uniswapx-sdk";
import { BigNumber, Wallet, constants, ethers } from "ethers";
import { optimismGoerli } from "viem/chains";

import dotenv from "dotenv";
import { hexlify, parseEther } from "ethers/lib/utils";
dotenv.config();

const OPTIMISM_GOERLI_CHAIN_ID = 420;
const GOERLI_CHAIN_ID = 5;

const ONE_HOUR = 60 * 60;
const DEADLINE = Math.floor(Date.now() / 1000 + ONE_HOUR);

async function main() {
  const client = new ethers.providers.JsonRpcProvider(
    process.env[`${OPTIMISM_GOERLI_CHAIN_ID}_RPC_URL`]
  );

  const wallet = new Wallet(process.env.PRIVATE_KEY!);

  const nonce = await client.getTransactionCount(await wallet.getAddress());

  const chainId = optimismGoerli.id;
  const builder = new DutchOrderBuilder(
    chainId,
    "0x37f189ebd107c3Ec2447Bdd9387a2B54d6ff9197", // reactor
    "0x000000000022d473030f116ddee9f6b43ac78ba3" // Permit2 https://docs.uniswap.org/contracts/v3/reference/deployments
  );

  const startAmount = parseEther("0.01");
  const endAmount = parseEther("0.009");

  const order = builder
    .deadline(DEADLINE)
    .decayEndTime(DEADLINE)
    .decayStartTime(DEADLINE - 100)
    .nonce(BigNumber.from(nonce))
    .input({
      token: constants.AddressZero,
      startAmount: startAmount,
      endAmount: startAmount,
    })
    .output({
      token: constants.AddressZero,
      startAmount,
      endAmount,
      recipient: await wallet.getAddress(),
    })
    .validation({
      additionalValidationData: hexlify(GOERLI_CHAIN_ID),
      additionalValidationContract: constants.AddressZero,
    })
    .swapper(process.env.ADDRESS!)
    .build();

  // Sign the built order
  const { domain, types, values } = order.permitData();
  const signature = await wallet._signTypedData(domain, types, values);

  const serializedOrder = order.serialize();

  console.log({
    signature,
    serializedOrder,
  });
  // submit serializedOrder and signature to order pool
}

main();
