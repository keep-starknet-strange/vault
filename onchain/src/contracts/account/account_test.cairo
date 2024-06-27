use openzeppelin::presets::interfaces::ERC20UpgradeableABIDispatcherTrait;
use openzeppelin::utils::cryptography::snip12::OffchainMessageHashImpl;
use starknet::{account::Call, ContractAddress};
use starknet::{testing, contract_address_const, info::get_tx_info};
use vault::components::outside_execution::interface::{
    IOutsideExecution_V2Dispatcher, IOutsideExecution_V2DispatcherTrait
};
use vault::contracts::account::interface::{
    VaultAccountABIDispatcher, VaultAccountABIDispatcherTrait
};
use vault::tests::{utils, constants};
use vault::utils::claim::Claim;
use vault::utils::outside_execution::OutsideExecution;


//
// Claim link
//

#[test]
fn test_execute_from_outside_multiple_erc20_transfers_works() {
    let address = utils::setup_vault_account().contract_address;
    let erc20 = utils::setup_erc20(address);
    let execute_from_outsider = VaultAccountABIDispatcher { contract_address: address };
    let recipient1 = constants::RECIPIENT_1();
    let recipient2 = constants::RECIPIENT_2();
    let outside_execution = constants::OUTSIDE_EXECUTION_DOUBLE_TRANSFER(
        erc20_address: erc20.contract_address
    );

    // println!("addr: {}", Into::<ContractAddress, felt252>::into(address));
    // println!("erc20: {}", Into::<ContractAddress, felt252>::into(erc20.contract_address));

    // setup chain ID
    testing::set_chain_id('SN_MAIN');

    // setup timestamp
    testing::set_block_timestamp(10);

    // setup contract_address
    testing::set_contract_address(contract_address_const::<0x1>());

    // check balances before
    assert!(erc20.balance_of(recipient1).is_zero(), "Invalid initial balance");
    assert!(erc20.balance_of(recipient2).is_zero(), "Invalid initial balance");

    execute_from_outsider
        .execute_from_outside_v2(
            :outside_execution, signature: constants::VALID_SIGNATURE_EXECUTE_FROM_OUTSIDE().span()
        );

    assert!(erc20.balance_of(recipient1) == constants::AMOUNT_1, "Invalid initial balance");
    assert!(erc20.balance_of(recipient2) == constants::AMOUNT_2, "Invalid initial balance");
}

#[test]
#[should_panic(expected: ("Invalid signature for paymaster", 'ENTRYPOINT_FAILED'))]
fn test_execute_from_outside_multiple_erc20_wrong_sig_fails() {
    let address = utils::setup_vault_account().contract_address;
    let erc20 = utils::setup_erc20(address);
    let execute_from_outsider = VaultAccountABIDispatcher { contract_address: address };
    let recipient1 = constants::RECIPIENT_1();
    let recipient2 = constants::RECIPIENT_2();
    let outside_execution = constants::OUTSIDE_EXECUTION_DOUBLE_TRANSFER(
        erc20_address: erc20.contract_address
    );

    // setup timestamp
    testing::set_block_timestamp(10);

    // setup contract_address
    testing::set_contract_address(contract_address_const::<0x1>());

    // check balances before
    assert!(erc20.balance_of(recipient1).is_zero(), "Invalid initial balance");
    assert!(erc20.balance_of(recipient2).is_zero(), "Invalid initial balance");

    // execute with bad signature
    execute_from_outsider
        .execute_from_outside_v2(
            :outside_execution, signature: constants::INVALID_SIGNATURE().span()
        );
}
