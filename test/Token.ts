import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Tokens", function () {
  async function fixture() {
    const [deployer, user1, user2] = await ethers.getSigners();

    const amountOfToken = ethers.utils.parseEther("1000");

    const WETH = await ethers.getContractFactory("WETH");
    const weth = await WETH.deploy();
    await weth.deployed();

    const Matic = await ethers.getContractFactory("MATIC");
    const matic = await Matic.deploy();
    await matic.deployed();

    const USDT = await ethers.getContractFactory("USDT");
    const usdt = await USDT.deploy();
    await usdt.deployed();

    return { deployer, user1, user2, weth, matic, usdt, amountOfToken };
  }

  it("Should mint tokens on each contract", async function () {
    const { deployer, user1, weth, matic, usdt, amountOfToken } =
      await loadFixture(fixture);

    // Mint WETH
    await weth.connect(user1).mint(amountOfToken);
    expect(await weth.balanceOf(user1.address)).to.equal(amountOfToken);

    // Mint MATIC
    await matic.connect(user1).mint(amountOfToken);
    expect(await matic.balanceOf(user1.address)).to.equal(amountOfToken);

    // Mint USDT
    await usdt.connect(user1).mint(amountOfToken);
    expect(await usdt.balanceOf(user1.address)).to.equal(amountOfToken);
  });
});
