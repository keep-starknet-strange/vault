use core::hash::{HashStateExTrait};
use core::poseidon::{HashStateTrait, PoseidonTrait};

use openzeppelin::utils::cryptography::snip12::StructHash;
use starknet::ContractAddress;

const U256_TYPE_HASH: felt252 = selector!("\"u256\"(\"low\":\"u128\",\"high\":\"u128\")");
const CLAIM_TYPE_HASH: felt252 =
    selector!(
        "\"Claim\"(\"amount\":\"u256\",\"nonce\":\"felt\")\"u256\"(\"low\":\"u128\",\"high\":\"u128\")"
    );

#[derive(Drop, Serde, Clone, Copy, Hash)]
pub struct Claim {
    amount: u256,
    nonce: felt252,
}

#[starknet::interface]
pub trait ClaimLinkTrait<T> {
    fn claim(ref self: T, claim: Claim, signature: Array<felt252>);

    #[cfg(test)]
    fn set_usdc_address(ref self: T, usdc_address: ContractAddress);
}

impl StructHashImpl of StructHash<Claim> {
    fn hash_struct(self: @Claim) -> felt252 {
        let hash_state = PoseidonTrait::new();
        hash_state
            .update_with(CLAIM_TYPE_HASH)
            .update_with(
                PoseidonTrait::new()
                    .update_with(U256_TYPE_HASH)
                    .update_with(*self.amount)
                    .finalize()
            )
            .update_with(*self.nonce)
            .finalize()
    }
}
