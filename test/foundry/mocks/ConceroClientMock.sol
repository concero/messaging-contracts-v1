//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.28;

import {ConceroClient} from "contracts/ConceroClient/ConceroClient.sol";

contract ConceroClientMock is ConceroClient {
    event ConceroMessageReceived(bytes32 indexed id);

    constructor(address conceroRouter) ConceroClient(conceroRouter) {}

    function _conceroReceive(Message calldata conceroMessage) internal override {
        emit ConceroMessageReceived(conceroMessage.id);
    }
}
