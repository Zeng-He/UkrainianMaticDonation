// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  const [deployer, signer1, signer2] = await hre.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  console.log("Deploying MultiSigMaxCap Contract...");
  var numConfirmationsRequired = 3;
  var initialValue = 1000;
  const MultiSigMaxCap = await hre.ethers.getContractFactory("MultiSigMaxCap");
  const multiSigMaxCap = await MultiSigMaxCap.deploy([deployer, signer1, signer2], numConfirmationsRequired, initialValue);

  // We get the contract to deploy
  // const UkrainianMaticDonation = await hre.ethers.getContractFactory("UkrainianMaticDonation");
  // const ukrainianMaticDonation = await UkrainianMaticDonation.deploy();

  await multiSigMaxCap.deployed();
  // await ukrainianMaticDonation.deployed();

  console.log("MultiSigMaxCap deployed to:", multiSigMaxCap.address);
  // console.log("UkrainianMaticDonation deployed to:", ukrainianMaticDonation.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
