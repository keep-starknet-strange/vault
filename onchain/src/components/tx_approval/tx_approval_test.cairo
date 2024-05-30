use core::starknet::SyscallResultTrait;
use openzeppelin::presets::ERC20Upgradeable;
use openzeppelin::presets::interfaces::erc20::{
    ERC20UpgradeableABIDispatcher, ERC20UpgradeableABIDispatcherTrait
};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use openzeppelin::utils::serde::SerializedAppend;
use starknet::{ContractAddress, contract_address_const, account::Call};
use super::tx_approval_mock::{
    COMPONENT, TransactionApprovalMock, TestExternalDispatcher, TestExternalDispatcherTrait
};
use traits::{Into, TryInto};
use vault::components::TransactionApprovalComponent::InternalTrait;
use vault::tests::utils;

fn SIGNATURE() -> Array<felt252> {
    let mut res = array![];

    res.append_serde(0x6C8BE1FB0FB5C730FBD7ABAECBED9D980376FF2E660DFCD157E158D2B026891);
    res.append_serde(0x76B4669998EB933F44A59EACE12B41328AB975CEAFDDF92602B21EB23E22E35);

    res
}

const TRANSACTION_HASH: felt252 = 0x601d3d2e265c10ff645e1554c435e72ce6721f0ba5fc96f0c650bfc6231191a;

/// Deploys the tx approval contract + approver.
fn setup_contracts() -> (TestExternalDispatcher, ContractAddress, ContractAddress) {
    // Deploy approver account with public key and weekly limit and approver is 0.
    let approver_address = utils::setup_signer().contract_address;

    // Deploy approval mock contract with approver address.
    let calldata: Array<felt252> = array![approver_address.into()];

    let approval_address = utils::deploy(TransactionApprovalMock::TEST_CLASS_HASH, :calldata);

    // Deploy ERC20
    let erc20_address = utils::setup_erc20(recipient: approval_address).contract_address;

    (TestExternalDispatcher { contract_address: approval_address }, approver_address, erc20_address)
}

#[test]
fn test_register_transaction() {
    let mut component = COMPONENT();

    let recipient = contract_address_const::<0x123>();
    let to = contract_address_const::<0x1>();
    let calldata = array![recipient.into(), 200, 0];
    let call = Call { to, selector: selector!("transfer"), calldata: calldata.span() };
    let expected_call = Call { to, selector: call.selector, calldata: calldata.span() };

    component.register_transaction(call, TRANSACTION_HASH);
    let res = component.get_transaction(TRANSACTION_HASH);

    assert_eq!(expected_call.to, res.to, "Invalid contract address");
    assert_eq!(expected_call.selector, res.selector, "Invalid selector");
    assert_eq!(expected_call.calldata, res.calldata, "Invalid calldata");
}

#[test]
fn test_approve_transaction() {
    let (approval, approver_address, erc20_address) = setup_contracts();

    // Mock tx hash.
    // Craft tx calldata to call `transfer`.
    // recipient, amount low, amount high.
    let calldata = array![approver_address.into(), 200, 0];

    // The actual call to ask approval for.
    let call = Call {
        to: erc20_address, selector: selector!("transfer"), calldata: calldata.span()
    };

    // Register the approval request.
    approval.register_transaction(call, TRANSACTION_HASH);
    // Approve the request with the approver signature.
    approval.approve_transaction(SIGNATURE(), TRANSACTION_HASH);
}

#[test]
#[should_panic(expected: ("Invalid approver signature", 'ENTRYPOINT_FAILED'))]
fn test_approve_transaction_invalid_approver_sig() {
    let (approval, approver_address, erc20_address) = setup_contracts();

    // Mock tx hash.
    // Craft tx calldata to call `transfer`.
    // recipient, amount low, amount high.
    let calldata = array![approver_address.into(), 200, 0];

    // The actual call to ask approval for.
    let call = Call {
        to: erc20_address, selector: selector!("transfer"), calldata: calldata.span()
    };

    // Register the approval request.
    approval.register_transaction(call, TRANSACTION_HASH);
    // Approve the request with an invalid approver signature.
    approval.approve_transaction(array![1, 1], TRANSACTION_HASH);
}

#[test]
#[should_panic(expected: ('CONTRACT_NOT_DEPLOYED', 'ENTRYPOINT_FAILED'))]
fn test_approve_transaction_undeployed_contract() {
    let (approval, approver_address, _) = setup_contracts();

    // Mock tx hash.
    // Craft tx calldata to call `transfer`.
    // recipient, amount low, amount high.
    let calldata = array![approver_address.into(), 200, 0];

    // The actual call to ask approval for to a contract that is not deployed.
    let call = Call {
        to: contract_address_const::<0x123>(),
        selector: selector!("transfer"),
        calldata: calldata.span()
    };

    // Register the approval request.
    approval.register_transaction(call, TRANSACTION_HASH);
    // Approve the request with the approver signature.
    approval.approve_transaction(SIGNATURE(), TRANSACTION_HASH);
}

#[test]
#[should_panic(expected: ('ENTRYPOINT_NOT_FOUND', 'ENTRYPOINT_FAILED'))]
fn test_approve_transaction_invalid_selector() {
    let (approval, approver_address, erc20_address) = setup_contracts();

    // Mock tx hash.
    // Craft tx calldata to call `transfer`.
    // recipient, amount low, amount high.
    let calldata = array![approver_address.into(), 200, 0];

    // The actual call to ask approval for to a contract that is not deployed.
    let call = Call {
        to: erc20_address, selector: selector!("transfoor"), calldata: calldata.span()
    };

    // Register the approval request.
    approval.register_transaction(call, TRANSACTION_HASH);
    // Approve the request with the approver signature.
    approval.approve_transaction(SIGNATURE(), TRANSACTION_HASH);
}

#[test]
#[should_panic(expected: ("Transaction doesn't exist", 'ENTRYPOINT_FAILED'))]
fn test_approve_transaction_inexstant_tx() {
    let (approval, approver_address, erc20_address) = setup_contracts();

    // Mock tx hash.
    let transaction_hash = 0x1;

    // Craft tx calldata to call `transfer`.
    // recipient, amount low, amount high.
    let calldata = array![approver_address.into(), 200, 0];

    // The actual call to ask approval for to a contract that is not deployed.
    let call = Call {
        to: erc20_address, selector: selector!("transfoor"), calldata: calldata.span()
    };

    // Register the approval request.
    approval.register_transaction(call, transaction_hash);
    // Approve the request with the approver signature.
    approval.approve_transaction(SIGNATURE(), TRANSACTION_HASH);
}
