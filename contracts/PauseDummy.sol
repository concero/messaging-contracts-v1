pragma solidity 0.8.28;

error Paused();

contract PauseDummy {
    fallback() external payable {
        revert Paused();
    }
    receive() external payable {
        revert Paused();
    }
}
