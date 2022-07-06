module.exports = async ({getNamedAccounts, hardhatArguments, deployments, ethers, config}) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();

    const registrar = await deployments.get('BaseRegistrarImplementation');
    const priceOracle = await deployments.get('StablePriceOracle');
    const namedReservations = await deployments.get('NamedReservations');
    const minCommitmentAge = 60;
    const maxCommitmentAge = 86400;

    await deploy('NNSRegistrarControllerWithReservation', {
        from: deployer,
        args: [
            registrar.address,
            priceOracle.address,
            minCommitmentAge,
            maxCommitmentAge,
            config.ethRegistry,
            namedReservations.address,
        ],
        log: true,
    });
};

module.exports.tags = ['NNSRegistrarControllerWithReservation'];
module.exports.dependencies = ['BaseRegistrarImplementation', 'StablePriceOracle'];