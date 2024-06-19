use core::starknet::SyscallResultTrait;
use core::traits::TryInto;
use openzeppelin::presets::interfaces::{
    AccountUpgradeableABIDispatcher, AccountUpgradeableABIDispatcherTrait,
    ERC20UpgradeableABIDispatcher, ERC20UpgradeableABIDispatcherTrait
};
use openzeppelin::presets::{ERC20Upgradeable, AccountUpgradeable};
use openzeppelin::token::erc20::dual20::DualCaseERC20Trait;
use openzeppelin::utils::serde::SerializedAppend;
use snforge_std as snf;
use snforge_std::{declare, CheatTarget, ContractClassTrait};
use starknet::{testing, ContractAddress, contract_address_const};
use super::constants;
use vault::contracts::VaultAccount;
use vault::contracts::account::interface::{IVaultAccountDispatcher, IVaultAccountDispatcherTrait};


fn deploy_vault(calldata: Array<felt252>) -> starknet::ContractAddress {
    let contract_class_hash = declare("VaultAccount").unwrap();

    let (address, _) = contract_class_hash.deploy(@calldata).unwrap_syscall();

    return address;
}

fn deploy_account_upgradeable(calldata: Array<felt252>) -> starknet::ContractAddress {
    let contract_class_hash = declare("AccountUpgradeable").unwrap();
    let (address, _) = contract_class_hash.deploy(@calldata).unwrap_syscall();

    return address;
}

fn deploy_er20_upgradeable(calldata: Array<felt252>) -> starknet::ContractAddress {
    let contract_class_hash = declare("ERC20Upgradeable").unwrap();

    let (address, _) = contract_class_hash.deploy(@calldata).unwrap_syscall();

    return address;
}

fn deploy(contract_class_hash: felt252, calldata: Array<felt252>) -> starknet::ContractAddress {
    let (address, _) = starknet::deploy_syscall(
        contract_class_hash.try_into().unwrap(), 0, calldata.span(), false
    )
        .unwrap_syscall();

    address
}

fn setup_erc20(recipient: ContractAddress) -> ERC20UpgradeableABIDispatcher {
    let mut calldata = array![];

    calldata.append_serde(constants::NAME());
    calldata.append_serde(constants::SYMBOL());
    calldata.append_serde(constants::SUPPLY); // 1 ETH
    calldata.append_serde(recipient);
    calldata.append_serde(recipient);

    // deploy
    let address = deploy_er20_upgradeable(calldata);
    
    // deploy(ERC20Upgradeable::TEST_CLASS_HASH, calldata);

    ERC20UpgradeableABIDispatcher { contract_address: address }
}

// fn setup_erc20_deploy(recipient: ContractAddress) -> ERC20UpgradeableABIDispatcher {
//     let mut calldata = array![];

//     calldata.append_serde(constants::NAME());
//     calldata.append_serde(constants::SYMBOL());
//     calldata.append_serde(constants::SUPPLY); // 1 ETH
//     calldata.append_serde(recipient);
//     calldata.append_serde(recipient);

//     // let (contract_address, _) = deploy_sn("ERC20Upgradeable", @callData)

//     let contract_address = deploy_er20_upgradeable(calldata);

//     ERC20UpgradeableABIDispatcher { contract_address: contract_address }
// }

fn setup_vault_account() -> IVaultAccountDispatcher {
    setup_custom_vault_account(
        approver: contract_address_const::<0>(), limit: u256 { low: 2, high: 2 }
    )
}


fn setup_custom_vault_account(approver: ContractAddress, limit: u256) -> IVaultAccountDispatcher {
    let calldata = array![];

    // deploy
    let address = deploy_vault(calldata);

    

    let (pub_key_x, pub_key_y) = constants::P256_PUBLIC_KEY;

    let vault_account = IVaultAccountDispatcher { contract_address: address };

    vault_account.initialize(:pub_key_x, :pub_key_y, :approver, :limit);

    vault_account
}

fn setup_signer() -> AccountUpgradeableABIDispatcher {
    setup_custom_signer(constants::PUBLIC_KEY)
}

fn setup_custom_signer(public_key: felt252) -> AccountUpgradeableABIDispatcher {
    let calldata = array![public_key];

    // deploy
     let address = deploy_account_upgradeable(calldata);

    AccountUpgradeableABIDispatcher { contract_address: address }
}
