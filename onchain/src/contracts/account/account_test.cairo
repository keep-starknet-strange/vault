use openzeppelin::utils::cryptography::snip12::OffchainMessageHashImpl;
use starknet::{testing, contract_address_const};
use vault::contracts::account::interface::{IClaimLinkDispatcher, IClaimLinkDispatcherTrait};
use vault::tests::{utils, constants};
use vault::utils::claim::Claim;
use vault::utils::snip12::SNIP12MetadataImpl;

//
// Claim link
//

#[test]
fn test_claim_link_valid_signature_not_already_claimed_works() {
    let address = utils::setup_vault_account().contract_address;
    let erc20 = utils::setup_erc20(address);
    let claimer = IClaimLinkDispatcher { contract_address: address };

    claimer.set_usdc_address(erc20.contract_address);

    testing::set_contract_address(contract_address_const::<0x1>());

    claimer
        .claim(
            Claim { amount: constants::AMOUNT, nonce: 0 }, signature: constants::VALID_SIGNATURE()
        );
}

#[test]
#[should_panic(expected: ("Invalid signature for claim", 'ENTRYPOINT_FAILED'))]
fn test_claim_link_invalid_signature_not_already_claimed_fails() {
    let address = utils::setup_vault_account().contract_address;
    let erc20 = utils::setup_erc20(address);
    let claimer = IClaimLinkDispatcher { contract_address: address };

    claimer.set_usdc_address(erc20.contract_address);

    testing::set_contract_address(contract_address_const::<0x1>());

    // println!("hash: {}", Claim { amount: constants::AMOUNT, nonce: 0 }.get_message_hash(address));

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
    let claimer = IClaimLinkDispatcher { contract_address: address };

    claimer.set_usdc_address(erc20.contract_address);

    testing::set_contract_address(contract_address_const::<0x1>());

    claimer
        .claim(
            Claim { amount: constants::AMOUNT, nonce: 0 }, signature: constants::VALID_SIGNATURE()
        );
    claimer
        .claim(
            Claim { amount: constants::AMOUNT, nonce: 0 }, signature: constants::VALID_SIGNATURE()
        );
}
