import { ethernal, ethers, network } from "hardhat";
import 'hardhat-ethernal';

async function main() {
  const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  const unlockTime = currentTimestampInSeconds + 60;

  const Metaedu = await ethers.getContractFactory("Metaedu");
  const owner = await ethers.getSigner(network.config.from!);
  const metaedu = await Metaedu.deploy(owner.address);

  await metaedu.deployed();

  await ethernal.push(
    {
      name: 'Metaedu',
      address: metaedu.address
    }
  )

  console.log(
    `Metaedu unlock timestamp ${unlockTime} deployed to ${metaedu.address} by ${owner.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
