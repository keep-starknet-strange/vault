use openzeppelin::utils::cryptography::snip12::OffchainMessageHashImpl;
use starknet::{account::Call, ContractAddress};
use starknet::{testing, contract_address_const, info::get_tx_info};
use vault::contracts::account::interface::{
    IVaultAccountFunctionnalitiesDispatcher, IVaultAccountFunctionnalitiesDispatcherTrait
};
use openzeppelin::presets::interfaces::ERC20UpgradeableABIDispatcherTrait;
use vault::tests::{utils, constants};
use vault::utils::{outside_execution::OutsideExecution, claim::Claim};
use vault::utils::snip12::SNIP12MetadataImpl;

//
// Claim link
//

#[test]
fn test_claim_link_valid_signature_not_already_claimed_works() {
    let address = utils::setup_vault_account().contract_address;
    let erc20 = utils::setup_erc20(address);
    let claimer = IVaultAccountFunctionnalitiesDispatcher { contract_address: address };

    claimer.set_usdc_address(erc20.contract_address);

    testing::set_contract_address(contract_address_const::<0x1>());

    claimer
        .claim(
            Claim { amount: constants::AMOUNT, nonce: 0 },
            signature: constants::VALID_SIGNATURE_CLAIM()
        );
}

#[test]
#[should_panic(expected: ("Invalid signature for claim", 'ENTRYPOINT_FAILED'))]
fn test_claim_link_invalid_signature_not_already_claimed_fails() {
    let address = utils::setup_vault_account().contract_address;
    let erc20 = utils::setup_erc20(address);
    let claimer = IVaultAccountFunctionnalitiesDispatcher { contract_address: address };

    claimer.set_usdc_address(erc20.contract_address);

    testing::set_contract_address(contract_address_const::<0x1>());

    // println!("hash: {}", Claim { amount: constants::AMOUNT, nonce: 0
    // }.get_message_hash(address));

    claimer
        .claim(
            Claim { amount: constants::AMOUNT, nonce: 0 }, signature: constants::INVALID_SIGNATURE()
        );
}

#[test]
#[should_panic(expected: ("Link already used", 'ENTRYPOINT_FAILED'))]
fn test_claim_link_valid_signature_already_claimed_fails() {
    let address = utils::setup_vault_account().contract_address;
    let erc20 = utils::setup_erc20(address);
    let claimer = IVaultAccountFunctionnalitiesDispatcher { contract_address: address };

    claimer.set_usdc_address(erc20.contract_address);

    testing::set_contract_address(contract_address_const::<0x1>());

    claimer
        .claim(
            Claim { amount: constants::AMOUNT, nonce: 0 },
            signature: constants::VALID_SIGNATURE_CLAIM()
        );
    claimer
        .claim(
            Claim { amount: constants::AMOUNT, nonce: 0 },
            signature: constants::VALID_SIGNATURE_CLAIM()
        );
}

#[test]
fn test_execute_from_outside_multiple_erc20_transfers_works() {
    let address = utils::setup_vault_account().contract_address;
    let erc20 = utils::setup_erc20(address);
    let execute_from_outsider = IVaultAccountFunctionnalitiesDispatcher {
        contract_address: address
    };

    testing::set_block_timestamp(10);
    execute_from_outsider.set_usdc_address(erc20.contract_address);
    println!("address: {}", Into::<ContractAddress, felt252>::into(address));

    testing::set_contract_address(contract_address_const::<0x1>());
    assert!(erc20.balance_of(contract_address_const::<0xb00b5>()) == 0, "Invalid initial balance");
    assert!(erc20.balance_of(contract_address_const::<0xdead>()) == 0, "Invalid initial balance");
    let calls = array![
        Call {
            to: erc20.contract_address,
            selector: selector!("transfer"),
            calldata: array![0xb00b5, 1000000, 0].span()
        },
        Call {
            to: erc20.contract_address,
            selector: selector!("transfer"),
            calldata: array![0xdead, 2000000, 0].span()
        }
    ]
        .span();
    let exec = OutsideExecution {
        caller: contract_address_const::<'ANY_CALLER'>(),
        nonce: 1,
        execute_after: 0,
        execute_before: 999999999999,
        calls
    };
    execute_from_outsider
        .execute_from_outside(exec, signature: constants::VALID_SIGNATURE_EXECUTE_FROM_OUTSIDE());
    assert!(
        erc20.balance_of(contract_address_const::<0xb00b5>()) == 1000000, "Invalid final balance"
    );
    assert!(
        erc20.balance_of(contract_address_const::<0xdead>()) == 2000000, "Invalid final balance"
    );
}

#[test]
#[should_panic(expected: ("Invalid signature for paymaster", 'ENTRYPOINT_FAILED'))]
fn test_execute_from_outside_multiple_erc20_wrong_sig_fails() {
    let address = utils::setup_vault_account().contract_address;
    let erc20 = utils::setup_erc20(address);
    let execute_from_outsider = IVaultAccountFunctionnalitiesDispatcher {
        contract_address: address
    };

    testing::set_block_timestamp(10);
    execute_from_outsider.set_usdc_address(erc20.contract_address);

    testing::set_contract_address(contract_address_const::<0x1>());
    assert!(erc20.balance_of(contract_address_const::<0xb00b5>()) == 0, "Invalid initial balance");
    assert!(erc20.balance_of(contract_address_const::<0xdead>()) == 0, "Invalid initial balance");
    let calls = array![
        Call {
            to: erc20.contract_address,
            selector: selector!("transfer"),
            calldata: array![0xb00b5, 1000000, 0].span()
        },
        Call {
            to: erc20.contract_address,
            selector: selector!("transfer"),
            calldata: array![0xdead, 2000000, 0].span()
        }
    ]
        .span();
    let exec = OutsideExecution {
        caller: contract_address_const::<'ANY_CALLER'>(),
        nonce: 1,
        execute_after: 0,
        execute_before: 999999999999,
        calls
    };
    execute_from_outsider.execute_from_outside(exec, signature: constants::INVALID_SIGNATURE());
    assert!(
        erc20.balance_of(contract_address_const::<0xb00b5>()) == 1000000, "Invalid final balance"
    );
    assert!(
        erc20.balance_of(contract_address_const::<0xdead>()) == 2000000, "Invalid final balance"
    );
}
