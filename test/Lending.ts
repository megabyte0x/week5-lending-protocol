import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Lending: Setting the contract addresses", function () {
  async function fixture() {
    const [deployer, user1, user2] = await ethers.getSigners();

    const Lending = await ethers.getContractFactory("Lending");
    const lending = await Lending.deploy();
    await lending.deployed();

    const amountOfToken = ethers.utils.parseEther("1000");

    const WETH = await ethers.getContractFactory("WETH");
    const weth = await WETH.deploy();
    await weth.deployed();

    await weth.connect(user1).mint(amountOfToken);
    await weth.connect(user1).approve(lending.address, amountOfToken);

    const Matic = await ethers.getContractFactory("MATIC");
    const matic = await Matic.deploy();
    await matic.deployed();

    await matic.connect(user1).mint(amountOfToken);
    await matic.connect(deployer).mint(amountOfToken);
    await matic.connect(user1).approve(lending.address, amountOfToken);
    await matic.transfer(lending.address, amountOfToken);

    const USDT = await ethers.getContractFactory("USDT");
    const usdt = await USDT.deploy();
    await usdt.deployed();

    await usdt.connect(user1).mint(amountOfToken);
    await usdt.connect(user1).approve(lending.address, amountOfToken);

    return {
      deployer,
      user1,
      user2,
      lending,
      weth,
      matic,
      usdt,
      amountOfToken,
    };
  }

  it("Should set the token addresses", async function () {
    const { deployer, lending, weth, matic, usdt } = await loadFixture(fixture);

    await lending.connect(deployer).setETHAddress(weth.address);
    await lending.connect(deployer).setMaticAddress(matic.address);
    await lending.connect(deployer).setUSDTAddress(usdt.address);

    console.log(await lending.wETH());
    expect(await lending.wETH()).to.be.equal(weth.address);
    expect(await lending.matic()).to.be.equal(matic.address);
    expect(await lending.usdt()).to.be.equal(usdt.address);
  });
});

describe("Lending: Depositing WETH", function () {
  async function fixture() {
    const [deployer, user1, user2] = await ethers.getSigners();

    const Lending = await ethers.getContractFactory("Lending");
    const lending = await Lending.deploy();
    await lending.deployed();

    const amountOfToken = ethers.utils.parseEther("1000");
    const depositAmount = ethers.utils.parseEther("100");

    const WETH = await ethers.getContractFactory("WETH");
    const weth = await WETH.deploy();
    await weth.deployed();

    await weth.connect(user1).mint(amountOfToken);
    await weth.connect(user1).approve(lending.address, amountOfToken);
    await lending.connect(deployer).setETHAddress(weth.address);

    const Matic = await ethers.getContractFactory("MATIC");
    const matic = await Matic.deploy();
    await matic.deployed();

    await matic.connect(user1).mint(amountOfToken);
    await matic.connect(user1).approve(lending.address, amountOfToken);
    await lending.connect(deployer).setMaticAddress(matic.address);

    const USDT = await ethers.getContractFactory("USDT");
    const usdt = await USDT.deploy();
    await usdt.deployed();

    await usdt.connect(user1).mint(amountOfToken);
    await usdt.connect(user1).approve(lending.address, amountOfToken);
    await lending.connect(deployer).setUSDTAddress(usdt.address);

    return {
      deployer,
      user1,
      user2,
      lending,
      weth,
      matic,
      usdt,
      amountOfToken,
      depositAmount,
    };
  }

  it("Should deposit WETH", async function () {
    const { deployer, user1, lending, weth, depositAmount } = await loadFixture(
      fixture
    );

    await lending.connect(user1).depositWETH({ value: depositAmount });
    expect(await weth.balanceOf(lending.address)).to.be.equal(depositAmount);
    expect(
      await lending
        .connect(user1.address)
        .getWETHDepositDetails()
        .then((val) => {
          return val[0];
        })
    ).to.be.equal(depositAmount);
  });
});
