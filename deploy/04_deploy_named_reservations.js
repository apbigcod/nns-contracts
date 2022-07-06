module.exports = async ({getNamedAccounts, hardhatArguments, deployments, ethers, config}) => {
    const {deploy} = deployments;
    const {deployer} = await getNamedAccounts();

    await deploy('NamedReservations', {
        from: deployer,
        args: [],
        log: true,
    });
};

module.exports.tags = ['NamedReservations'];