// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol';

import './JBAnonPayer.sol';

/**
    @dev This contracts deploys the minions, the anon project payer, at the addresses
         of the create2.
 */
contract JBAnonPayerFactory {

    /**
        @notice The supported Juicebox version
    */
    uint256 public immutable juiceboxVersion;

    /**
        @notice The corresponding directory
    */
    IJBDirectory public immutable directory;

    constructor(uint256 _juiceboxVersion, IJBDirectory _directory) {
        juiceboxVersion = _juiceboxVersion;
        directory = _directory;
    }

    /**
        @notice Helper to get the address where to send fund, prior to anon payer deployment
    */
    function getTargetAddress(uint256 _projectId, address _sender) external view returns(address _target) {
        bytes memory _creationBytecode = type(JBAnonPayer).creationCode;
        bytes32 _salt = keccak256(abi.encode(_projectId, _sender));

        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), _salt, keccak256(_creationBytecode))
        );

        return address(uint160(uint256(hash)));
    }

    /**
        @notice Deploy an anon payer on the address corresponding to a given project id, for a given sender,
                and trigger the call to pay() on the corresponding terminal.

        @dev    No access control on this deployment/pay, as the funds are considered as already in the
                Juicebox project
    */
    function deployMinion(uint256 _projectId, address _sender, address _token) external {
        bytes32 _salt = keccak256(abi.encode(_projectId, _sender));

        JBAnonPayer _minion = new JBAnonPayer{salt: _salt}();

        _minion.pay(directory, _projectId, _token, _sender);
    }
}