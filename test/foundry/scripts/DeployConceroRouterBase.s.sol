pragma solidity 0.8.28;

import {DeployHelper} from "../utils/DeployHelper.sol";
import {PauseDummy} from "contracts/PauseDummy.sol";
import {Script} from "forge-std/src/Script.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "contracts/Proxy/TransparentUpgradeableProxy.sol";
import {console} from "forge-std/src/console.sol";
import {ConceroRouter} from "contracts/ConceroRouter.sol";

abstract contract DeployConceroRouterScriptBase is DeployHelper {
    // @notice contract addresses
    TransparentUpgradeableProxy internal s_conceroRouterProxy;
    address internal s_conceroRouter;

    // @notice helper variables
    address internal s_proxyDeployer = vm.envAddress("PROXY_DEPLOYER");
    address internal s_deployer = vm.envAddress("DEPLOYER_ADDRESS");
    address[3] internal s_messengers = [
        vm.envAddress("MESSENGER_0_ADDRESS"),
        vm.envAddress("MESSENGER_1_ADDRESS"),
        vm.envAddress("MESSENGER_2_ADDRESS")
    ];

    function run() public returns (address) {
        _deployFullConceroRouter();
        return address(s_conceroRouterProxy);
    }

    function run(uint256 forkId) public returns (address) {
        vm.selectFork(forkId);
        return run();
    }

    function setProxyImplementation(address implementation) public {
        vm.prank(s_proxyDeployer);
        ITransparentUpgradeableProxy(address(s_conceroRouterProxy)).upgradeToAndCall(
            implementation,
            bytes("")
        );
    }

    function getConceroRouterProxy() public view returns (address) {
        return address(s_conceroRouterProxy);
    }

    function _deployFullConceroRouter() internal {
        _deployConceroRouterProxy();
        _deployAndSetImplementation();
    }

    function _deployConceroRouterProxy() internal {
        vm.prank(s_proxyDeployer);
        s_conceroRouterProxy = new TransparentUpgradeableProxy(
            address(new PauseDummy()),
            s_proxyDeployer,
            ""
        );
    }

    function _deployAndSetImplementation() internal {
        _deployConceroRouter();

        setProxyImplementation(address(s_conceroRouter));
    }

    function _deployConceroRouter() internal virtual;
}
