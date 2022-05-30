module.exports = async ({getNamedAccounts, hardhatArguments, deployments, ethers, config}) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();

    const registrar = await deployments.get('BaseRegistrarImplementation');
    const priceOracle = await deployments.get('StablePriceOracle');
    const minCommitmentAge = 60;
    const maxCommitmentAge = 86400;

    await deploy('ETHRegistrarControllerWithReservation', {
        from: deployer,
        args: [
            registrar.address,
            priceOracle.address,
            minCommitmentAge,
            maxCommitmentAge,
            config.ethRegistrar
        ],
        log: true,
    });
};

module.exports.tags = ['ETHRegistrarControllerWithReservation'];
module.exports.dependencies = ['BaseRegistrarImplementation', 'StablePriceOracle'];