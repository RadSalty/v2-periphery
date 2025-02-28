pragma solidity =0.6.6;

import '@RadSalty/solidity-lib/contracts/libraries/TransferHelper.sol';

import './interfaces/IPxlswapV2Migrator.sol';
import './interfaces/V1/IPxlswapV1Factory.sol';
import './interfaces/V1/IPxlswapV1Exchange.sol';
import './interfaces/IPxlswapV2Router01.sol';
import './interfaces/IERC20.sol';

contract PxlswapV2Migrator is IPxlswapV2Migrator {
    IPxlswapV1Factory immutable factoryV1;
    IPxlswapV2Router01 immutable router;

    constructor(address _factoryV1, address _router) public {
        factoryV1 = IPxlswapV1Factory(_factoryV1);
        router = IPxlswapV2Router01(_router);
    }

    // needs to accept ETH from any v1 exchange and the router. ideally this could be enforced, as in the router,
    // but it's not possible because it requires a call to the v1 factory, which takes too much gas
    receive() external payable {}

    function migrate(
        address token,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external override {
        IPxlswapV1Exchange exchangeV1 = IPxlswapV1Exchange(factoryV1.getExchange(token));
        uint256 liquidityV1 = exchangeV1.balanceOf(msg.sender);
        require(exchangeV1.transferFrom(msg.sender, address(this), liquidityV1), 'TRANSFER_FROM_FAILED');
        (uint256 amountETHV1, uint256 amountTokenV1) = exchangeV1.removeLiquidity(liquidityV1, 1, 1, uint256(-1));
        TransferHelper.safeApprove(token, address(router), amountTokenV1);
        (uint256 amountTokenV2, uint256 amountETHV2, ) = router.addLiquidityETH{value: amountETHV1}(
            token,
            amountTokenV1,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
        if (amountTokenV1 > amountTokenV2) {
            TransferHelper.safeApprove(token, address(router), 0); // be a good blockchain citizen, reset allowance to 0
            TransferHelper.safeTransfer(token, msg.sender, amountTokenV1 - amountTokenV2);
        } else if (amountETHV1 > amountETHV2) {
            // addLiquidityETH guarantees that all of amountETHV1 or amountTokenV1 will be used, hence this else is safe
            TransferHelper.safeTransferETH(msg.sender, amountETHV1 - amountETHV2);
        }
    }
}
