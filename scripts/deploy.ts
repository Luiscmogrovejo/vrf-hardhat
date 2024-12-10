const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();

    // Deploy the Oracle
    const Oracle = await ethers.getContractFactory("Oracle");
    const oracle = await Oracle.deploy("0x00"); // dummy public key for now
    await oracle.deployed();
    console.log("Oracle deployed at:", oracle.address);

    // Deploy the Consumer
    const Consumer = await ethers.getContractFactory("Consumer");
    const consumer = await Consumer.deploy(oracle.address);
    await consumer.deployed();
    console.log("Consumer deployed at:", consumer.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });