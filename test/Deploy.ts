import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Deploy", function () {
  async function fixture() {
    const [deployer] = await ethers.getSigners();

    return { deployer };
  }

  it("Should deploy the tokens contract", async function () {
    const { deployer } = await loadFixture(fixture);

    const WETH = await ethers.getContractFactory("WETH");
    const weth = await WETH.deploy();
    await weth.deployed();
    console.log("WETH deployed to:", weth.address);

    const Matic = await ethers.getContractFactory("MATIC");
    const matic = await Matic.deploy();
    await matic.deployed();
    console.log("Matic deployed to:", matic.address);

    const USDT = await ethers.getContractFactory("USDT");
    const usdt = await USDT.deploy();
    await usdt.deployed();
    console.log("USDT deployed to:", usdt.address);
  });

  it("Should deploy the Lending Contract", async function () {
    const { deployer } = await loadFixture(fixture);

    const Lending = await ethers.getContractFactory("Lending");
    const lending = await Lending.deploy();
    await lending.deployed();
    console.log("Lending deployed to:", lending.address);
  });
});
