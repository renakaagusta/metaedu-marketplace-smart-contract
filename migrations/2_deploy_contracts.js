const Metaedu = artifacts.require("Metaedu");
// const ArtMarketplace = artifacts.require("ArtMarketplace");

module.exports = async function(deployer) {
  await deployer.deploy(Metaedu);

  const token = await Metaedu.deployed()

  // await deployer.deploy(ArtMarketplace, token.address)

  // const market = await ArtMarketplace.deployed()

  // await token.setMarketplace(market.address)
};
