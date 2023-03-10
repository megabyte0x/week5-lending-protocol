// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "hardhat/console.sol";

error ZeroValue();
error ETHDeposit();
error NotEnoughCollateralized();
error MaticBorrow();
error USDTBorrow();

contract Lending is Ownable {
    IERC20 public wETH;
    IERC20 public usdt;
    IERC20 public matic;

    AggregatorV3Interface internal wETHPriceFeed =
        AggregatorV3Interface(0x0715A7794a1dc8e42615F059dD6e406A6594651A);
    AggregatorV3Interface internal maticPriceFeed =
        AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);

    struct Deposit {
        address user;
        address token;
        uint256 amount;
    }

    struct WEthData {
        uint256 amountDeposited;
        uint256 collateralAmount;
        uint256 collateralAmountClaimed;
        uint256 collateralAmountUnclaimed;
    }

    struct MaticData {
        uint256 valueInUSD;
        uint256 borrowedAmount;
    }

    struct UsdtData {
        uint256 valueInUSD;
        uint256 borrowedAmount;
    }

    mapping(address => WEthData) wethDepositDetails;
    mapping(address => MaticData) maticBorrowDetails;
    mapping(address => UsdtData) usdtBorrowDetails;

    event WETHDeposited(address indexed user, uint256 indexed amount);

    event MaticBorrowed(address indexed user, uint256 indexed amount);

    event USDTBorrowed(address indexed user, uint256 indexed amount);

    constructor() {}

    function setMaticAddress(address _matic) external onlyOwner {
        matic = IERC20(_matic);
    }

    function setETHAddress(address _weth) external onlyOwner {
        wETH = IERC20(_weth);
    }

    function setUSDTAddress(address _usdt) external onlyOwner {
        usdt = IERC20(_usdt);
    }

    function depositWETH() external payable {
        uint256 value = msg.value;
        if (msg.value == 0) revert ZeroValue();

        wETH.transferFrom(msg.sender, address(this), value);

        WEthData storage wethDataDetails = wethDepositDetails[msg.sender];

        wethDepositDetails[msg.sender].amountDeposited += value;
        wethDataDetails.collateralAmount += calculateCollateral(value);
        wethDataDetails.collateralAmountUnclaimed += calculateCollateral(value);

        emit WETHDeposited(msg.sender, value);
    }

    function borrowMatic(uint256 amount) external {
        WEthData memory _ethData = wethDepositDetails[msg.sender];
        uint256 amountValueInUSD = amount * getMaticLatestPrice();
        uint256 collateralValueInUSD = _ethData.collateralAmountUnclaimed *
            getWETHLatestPrice();

        if (amountValueInUSD > collateralValueInUSD)
            revert NotEnoughCollateralized();

        uint256 wethClaimed = amountValueInUSD / getWETHLatestPrice();
        _ethData.collateralAmountClaimed += wethClaimed;
        _ethData.collateralAmountUnclaimed -= wethClaimed;

        MaticData memory _maticData = maticBorrowDetails[msg.sender];
        _maticData.borrowedAmount += amount;
        _maticData.valueInUSD += amountValueInUSD;

        matic.transferFrom(address(this), msg.sender, amount);
    }

    function borrowUSDT(uint256 amount) external {
        WEthData memory _wethData = wethDepositDetails[msg.sender];
        uint256 collateralValueInUSD = _wethData.collateralAmountUnclaimed *
            getWETHLatestPrice();

        if (amount > collateralValueInUSD) revert NotEnoughCollateralized();

        uint256 ethClaimed = amount / getWETHLatestPrice();
        _wethData.collateralAmountClaimed += ethClaimed;
        _wethData.collateralAmountUnclaimed -= ethClaimed;

        UsdtData memory _usdtData = usdtBorrowDetails[msg.sender];
        _usdtData.borrowedAmount += amount;
        _usdtData.valueInUSD += amount;

        (bool success, ) = address(usdt).call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                msg.sender,
                amount
            )
        );
        if (!success) revert USDTBorrow();
    }

    function calculateCollateral(uint256 value) public pure returns (uint256) {
        return (value * 7) / 10;
    }

    function getWETHDepositDetails() public view returns (WEthData memory) {
        return wethDepositDetails[msg.sender];
    }

    function getMaticDepositDetails() public view returns (MaticData memory) {
        return maticBorrowDetails[msg.sender];
    }

    function getUSDTDepositDetails() public view returns (UsdtData memory) {
        return usdtBorrowDetails[msg.sender];
    }

    function getWETHLatestPrice() public view returns (uint256) {
        (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = wETHPriceFeed.latestRoundData();
        uint256 finalAnswer = uint256((price * 10 ** 3) / 10 ** 12);
        return finalAnswer;
    }

    function getMaticLatestPrice() public view returns (uint256) {
        (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = maticPriceFeed.latestRoundData();
        uint256 finalAnswer = uint256((price * 10 ** 3) / 10 ** 12);
        return finalAnswer;
    }

    receive() external payable {}

    fallback() external payable {}
}
