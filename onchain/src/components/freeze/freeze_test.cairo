use openzeppelin::presets::interfaces::erc20::{
    ERC20UpgradeableABIDispatcher, ERC20UpgradeableABIDispatcherTrait
};
use starknet::ContractAddress;
use starknet::{contract_address_const, testing};
use super::freeze::AdminComponent::AdminTraitDispatcher;
use super::freeze::AdminComponent::InternalAdminTrait;
use super::freeze::AdminComponent;
use super::freeze_mock::{AdminMock, COMPONENT};
use vault::components::AdminComponent::AdminTraitDispatcherTrait;
use vault::tests::{utils, constants};

/// Deploys the tx approval contract + approver.
fn setup_contracts() -> (AdminTraitDispatcher, ERC20UpgradeableABIDispatcher, ContractAddress) {
    // Deploy admin signer
    let admin_address = utils::setup_signer().contract_address;

    // Deploy erc20 with admin as recipient
    let erc20 = utils::setup_erc20(admin_address);

    // Deploy admin mock contract with admin address.
    let calldata: Array<felt252> = array![
        admin_address.into(), erc20.contract_address.into(), admin_address.into()
    ];

    // deploy manageable
    let manageable_address = utils::deploy(AdminMock::TEST_CLASS_HASH, :calldata);

    // send SUPPLY tokens to manageable
    testing::set_contract_address(admin_address);
    erc20.transfer(manageable_address, constants::SUPPLY);
    testing::set_contract_address(contract_address_const::<0>());

    (AdminTraitDispatcher { contract_address: manageable_address }, erc20, admin_address)
}

//
// Externals
//

#[test]
#[should_panic(expected: ("Only admin", 'ENTRYPOINT_FAILED'))]
fn test_freeze_not_admin() {
    let (contract, _erc20, _admin) = setup_contracts();

    contract.freeze()
}

#[test]
fn test_freeze_admin() {
    let (contract, _erc20, admin) = setup_contracts();

    testing::set_contract_address(admin);
    contract.freeze();

    assert!(contract.is_frozen());
}

#[test]
fn test_freeze_admin_already_frozen() {
    let (contract, _erc20, admin) = setup_contracts();

    testing::set_contract_address(admin);
    contract.freeze();
    contract.freeze();

    assert!(contract.is_frozen());
}

#[test]
#[should_panic(expected: ("Only admin", 'ENTRYPOINT_FAILED'))]
fn test_unfreeze_not_admin() {
    let (contract, _erc20, _admin) = setup_contracts();

    contract.unfreeze();
}

#[test]
fn test_unfreeze_admin_already_unfrozen() {
    let (contract, _erc20, admin) = setup_contracts();

    testing::set_contract_address(admin);
    contract.unfreeze();

    assert!(!contract.is_frozen());
}

#[test]
fn test_unfreeze_admin() {
    let (contract, _erc20, admin) = setup_contracts();

    testing::set_contract_address(admin);
    contract.freeze();
    contract.unfreeze();

    assert!(!contract.is_frozen());
}

#[test]
fn test_withdraw_admin() {
    let (contract, erc20, admin) = setup_contracts();

    assert_eq!(erc20.balance_of(contract.contract_address), constants::SUPPLY);
    assert_eq!(erc20.balance_of(admin), 0);

    testing::set_contract_address(admin);
    contract.emergency_withdraw();

    assert_eq!(erc20.balance_of(admin), constants::SUPPLY);
    assert_eq!(erc20.balance_of(contract.contract_address), constants::SUPPLY - constants::SUPPLY);
}

#[test]
fn test_withdraw_admin_no_balance() {
    let (contract, erc20, admin) = setup_contracts();

    testing::set_contract_address(contract.contract_address);
    erc20.transfer(admin, constants::SUPPLY);

    assert_eq!(erc20.balance_of(contract.contract_address), 0);
    assert_eq!(erc20.balance_of(admin), constants::SUPPLY);

    testing::set_contract_address(admin);
    contract.emergency_withdraw();

    assert_eq!(erc20.balance_of(contract.contract_address), 0);
    assert_eq!(erc20.balance_of(admin), constants::SUPPLY);
}

//
// Internals
//

#[test]
#[should_panic(expected: "Only admin")]
fn test_freeze_internal_not_admin() {
    let mut component = COMPONENT();
    let address = contract_address_const::<0x123>();

    // Set caller address to 0x123 as the component isn't initialized the default
    // admin address is 0.
    testing::set_caller_address(address);
    component.freeze_internal();
}

#[test]
fn test_freeze_internal_admin() {
    let mut component = COMPONENT();
    let address = contract_address_const::<0x123>();

    // Init component to set admin address to 0x123.
    component.initializer(address, address, address);

    // Call with the right address.
    testing::set_caller_address(address);
    component.freeze_internal();

    assert!(component.is_frozen_internal());
}

#[test]
fn test_freeze_internal_admin_already_frozen() {
    let mut component = COMPONENT();
    let address = contract_address_const::<0x123>();

    // Init component to set admin address to 0x123.
    component.initializer(address, address, address);

    // Call with the right address.
    testing::set_caller_address(address);
    component.freeze_internal();
    component.freeze_internal();

    assert!(component.is_frozen_internal());
}

#[test]
fn test_is_frozen_internal() {
    let mut component = COMPONENT();
    let address = contract_address_const::<0x123>();

    component.initializer(address, address, address);

    // Shouldn't be frozen yet.
    assert!(!component.is_frozen_internal());

    testing::set_caller_address(address);
    component.freeze_internal();

    // Should be frozen.
    assert!(component.is_frozen_internal())
}

#[test]
fn test_unfreeze_internal_admin() {
    let mut component = COMPONENT();
    let address = contract_address_const::<0x123>();

    // Init component to set admin address to 0x123.
    component.initializer(address, address, address);

    // Call with the right address.
    testing::set_caller_address(address);
    component.freeze_internal();
    component.unfreeze_internal();

    assert!(!component.is_frozen_internal());
}

#[test]
fn test_unfreeze_internal_admin_not_frozen() {
    let mut component = COMPONENT();
    let address = contract_address_const::<0x123>();

    // Init component to set admin address to 0x123.
    component.initializer(address, address, address);

    // Call with the right address.
    testing::set_caller_address(address);
    component.unfreeze_internal();

    assert!(!component.is_frozen_internal());
}

#[test]
#[should_panic(expected: "Only admin")]
fn test_unfreeze_internal_not_admin() {
    let mut component = COMPONENT();
    let address = contract_address_const::<0x123>();

    // Init component to set admin address to 0x123.
    component.initializer(address, address, address);

    // Call with the right address.
    component.freeze_internal();
    component.unfreeze_internal();
}

#[test]
fn test_assert_not_frozen_not_frozen() {
    let mut component = COMPONENT();
    let address = contract_address_const::<0x123>();

    // Init component to set admin address to 0x123.
    component.initializer(address, address, address);

    component.assert_not_frozen();
}

#[test]
#[should_panic(expected: "Contract is frozen")]
fn test_assert_not_frozen_frozen() {
    let mut component = COMPONENT();
    let address = contract_address_const::<0x123>();

    // Init component to set admin address to 0x123.
    component.initializer(address, address, address);

    // Call with the right address.
    testing::set_caller_address(address);
    component.freeze_internal();
    component.assert_not_frozen();
}

#[test]
fn test_assert_only_admin_admin() {
    let mut component = COMPONENT();
    let address = contract_address_const::<0x123>();

    // Init component to set admin address to 0x123.
    component.initializer(address, address, address);

    testing::set_caller_address(address);
    component.assert_only_admin();
}

#[test]
#[should_panic(expected: "Only admin")]
fn test_assert_only_admin_not_admin() {
    let mut component = COMPONENT();
    let address = contract_address_const::<0x123>();

    // Init component to set admin address to 0x123.
    component.initializer(address, address, address);

    component.assert_only_admin();
}
