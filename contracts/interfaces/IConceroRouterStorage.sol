//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.28;

interface IConceroRouterStorage {
    enum ClfReqType {
        Empty,
        SendUnconfirmedMessage,
        ConfirmMessage
    }

    struct ClfRequest {
        ClfReqType reqType;
        bytes32 conceroMessageId;
    }
}
