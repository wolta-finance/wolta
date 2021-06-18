// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./interfaces/IVault.sol";

contract Controller {
    // --------------- Fields ---------------

    address public governance;

    mapping(address => bool) public vaults;
    mapping(address => bool) public hardWorkers;

    // --------------- Events ---------------

    event HardWorkerAdded(address hardWorker);
    event HardWorkerRemoved(address hardWorker);

    event VaultAdded(address vault);

    event HardWorked(address vault, address strategy, uint256 newSharePrice);

    // --------------- Modifiers ---------------

    modifier onlyGovernance {
        require(msg.sender == governance, "Not governance");
        _;
    }

    modifier onlyHardWorkerOrGovernance {
        require(
            hardWorkers[msg.sender] || msg.sender == governance,
            "Not a hard worker or governance"
        );
        _;
    }

    modifier protectFromSandwhich(
        address vault,
        uint256 wantedSharePrice,
        uint256 deviation
    ) {
        require(vaults[vault], "Vault does not exist");

        uint256 currentSharePrice = IVault(vault).pricePerShare();
        if (currentSharePrice > wantedSharePrice) {
            require(
                currentSharePrice / wantedSharePrice <= deviation,
                "Share price deviated"
            );
        } else {
            require(
                wantedSharePrice / currentSharePrice <= deviation,
                "Share price deviated"
            );
        }

        _;
    }

    // --------------- Constructor ---------------

    constructor(address governance_) {
        governance = governance_;
    }

    // --------------- Actions ---------------

    function addHardWorker(address hardWorker) public onlyGovernance {
        require(!hardWorkers[hardWorker], "Hard worker already exists");

        hardWorkers[hardWorker] = true;
        emit HardWorkerAdded(hardWorker);
    }

    function removeHardWorker(address hardWorker) public onlyGovernance {
        require(hardWorkers[hardWorker], "Hard worker does not exist");

        hardWorkers[hardWorker] = false;
        emit HardWorkerRemoved(hardWorker);
    }

    function addVaultAndStrategy(address vault, address strategy)
        public
        onlyGovernance
    {
        require(vault != address(0), "Vault not defined");
        require(strategy != address(0), "Strategy not defined");
        require(!vaults[vault], "Vault already exists");

        vaults[vault] = true;
        IVault(vault).setStrategy(strategy);
        emit VaultAdded(vault);
    }

    function doHardWork(
        address vault,
        uint256 wantedSharePrice,
        uint256 deviation
    )
        public
        onlyHardWorkerOrGovernance
        protectFromSandwhich(vault, wantedSharePrice, deviation)
    {
        IVault(vault).doHardWork();
        emit HardWorked(
            vault,
            IVault(vault).strategy(),
            IVault(vault).pricePerShare()
        );
    }
}
