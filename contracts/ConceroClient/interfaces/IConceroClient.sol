pragma solidity 0.8.28;

interface IConceroClient {
    struct Message {
        bytes32 id;
        uint64 srcChainSelector;
        address sender;
        bytes data;
    }

    function conceroReceive(Message calldata message) external;
}
