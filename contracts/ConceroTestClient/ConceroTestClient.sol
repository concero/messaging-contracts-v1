//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.28;

import {ConceroClient} from "../ConceroClient/ConceroClient.sol";

contract ConceroTestClient is ConceroClient {
    event MessageReceived(bytes32 indexed id, uint64 srcChainSelector, address sender, bytes data);

    constructor(address conceroRouter) ConceroClient(conceroRouter) {}

    function _conceroReceive(Message calldata message) internal override {
        emit MessageReceived(message.id, message.srcChainSelector, message.sender, message.data);
    }
}
