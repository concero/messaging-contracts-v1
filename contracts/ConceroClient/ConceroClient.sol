//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.28;

import {IConceroClient} from "./interfaces/IConceroClient.sol";

abstract contract ConceroClient is IConceroClient {
    error InvalidConceroRouter(address router);

    address internal immutable i_conceroRouter;

    constructor(address router) {
        if (router == address(0)) {
            revert InvalidConceroRouter(router);
        }

        if (router.code.length == 0) {
            revert InvalidConceroRouter(router);
        }

        i_conceroRouter = router;
    }

    function conceroReceive(Message calldata message) external {
        if (msg.sender != i_conceroRouter) {
            revert InvalidConceroRouter(msg.sender);
        }

        _conceroReceive(message);
    }

    function getConceroRouter() public view returns (address) {
        return i_conceroRouter;
    }

    function _conceroReceive(Message calldata message) internal virtual;
}
