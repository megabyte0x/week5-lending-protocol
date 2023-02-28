// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error ZeroValue();
error NotEnoughCollateralized();
error MaticBorrow();
error USDTBorrow();

contract Lending is Ownable {
    IERC20 wETH;
    IERC20 usdt;
    IERC20 matic;

    AggregatorV3Interface internal immutable wETHPriceFeed =
        AggregatorV3Interface(0xF9680D99D6C9589e2a93a78A04A279e509205945);
    AggregatorV3Interface internal immutable maticPriceFeed =
        AggregatorV3Interface(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);

    struct Deposit {
        address user;
        address token;
        uint256 amount;
    }

    struct EthData {
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

    mapping(address => EthData) ethDepositDetails;
    mapping(address => MaticData) maticDepositDetails;
    mapping(address => UsdtData) usdtDepositDetails;

    event ETHDeposited(address indexed user, uint256 indexed amount);

    event MaticBorrowed(address indexed user, uint256 indexed amount);

    event USDTBorrowed(address indexed user, uint256 indexed amount);

    constructor() {}

    function setMaticAddress(address _matic) external onlyOwner {
        matic = IERC20(_matic);
    }

    function setETHAddress(address _eth) external onlyOwner {
        wETH = IERC20(_eth);
    }

    function setUSDTAddress(address _usdt) external onlyOwner {
        usdt = IERC20(_usdt);
    }

    function depositETH() external payable {
        uint256 value = msg.value;
        if (msg.value == 0) revert ZeroValue();

        EthData memory ethDataDetails = ethDepositDetails[msg.sender];

        ethDataDetails.amountDeposited += value;
        ethDataDetails.collateralAmount += calculateCollateral(value);
        ethDataDetails.collateralAmountUnclaimed += calculateCollateral(value);

        emit ETHDeposited(msg.sender, value);
    }

    function borrowMatic(uint256 amount) external payable {
        EthData memory _ethData = ethDepositDetails[msg.sender];
        uint256 amountValueInUSD = amount * getMaticLatestPrice();
        uint256 collateralValueInUSD = _ethData.collateralAmountUnclaimed *
            getETHLatestPrice();

        if (amountValueInUSD > collateralValueInUSD)
            revert NotEnoughCollateralized();

        uint256 ethClaimed = amountValueInUSD / getETHLatestPrice();
        _ethData.collateralAmountClaimed += ethClaimed;
        _ethData.collateralAmountUnclaimed -= ethClaimed;

        MaticData memory _maticData = maticDepositDetails[msg.sender];
        _maticData.borrowedAmount += amount;
        _maticData.valueInUSD += amountValueInUSD;

        (bool success, ) = address(matic).call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                msg.sender,
                amount
            )
        );
        if (!success) revert MaticBorrow();
    }

    function borrowUSDT(uint256 amount) external payable {
        EthData memory _ethData = ethDepositDetails[msg.sender];
        uint256 collateralValueInUSD = _ethData.collateralAmountUnclaimed *
            getETHLatestPrice();

        if (amount > collateralValueInUSD) revert NotEnoughCollateralized();

        uint256 ethClaimed = amount / getETHLatestPrice();
        _ethData.collateralAmountClaimed += ethClaimed;
        _ethData.collateralAmountUnclaimed -= ethClaimed;

        UsdtData memory _usdtData = usdtDepositDetails[msg.sender];
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

    function calculateCollateral(
        uint256 value
    ) internal pure returns (uint256) {
        return (value * 7) / 10;
    }

    function getETHLatestPrice() internal view returns (uint80) {
        (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = wETHPriceFeed.latestRoundData();
        return answeredInRound;
    }

    function getMaticLatestPrice() internal view returns (uint80) {
        (
            uint80 roundId,
            int256 price,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = maticPriceFeed.latestRoundData();
        return answeredInRound;
    }

    receive() external payable {}

    fallback() external payable {}
}
