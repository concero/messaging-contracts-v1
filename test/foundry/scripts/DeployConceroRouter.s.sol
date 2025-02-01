pragma solidity 0.8.28;

import {DeployConceroRouterScriptBase} from "./DeployConceroRouterBase.s.sol";
import {ConceroRouter} from "contracts/ConceroRouter.sol";

contract DeployConceroRouterScript is DeployConceroRouterScriptBase {
    function _deployConceroRouter() internal override {
        vm.prank(s_deployer);
        s_conceroRouter = address(
            new ConceroRouter(
                getChainSelector(),
                getUsdcAddress(),
                s_messengers,
                getClfRouter(),
                getClfSecretsSlotId(),
                getClfSecretsVersion(),
                getCLfSubId(),
                getDonId(),
                getClfSrcJsHash(),
                getClfDstJsHash(),
                getClfEthersJsHash()
            )
        );
    }
}
