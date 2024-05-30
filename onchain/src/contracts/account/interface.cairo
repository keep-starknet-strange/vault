use starknet::ContractAddress;
use vault::utils::claim::Claim;

#[starknet::interface]
trait IVaultAccount<TState> {
    fn initialize(
        ref self: TState, pub_key_x: u256, pub_key_y: u256, approver: ContractAddress, limit: u256
    );
}

#[starknet::interface]
pub trait IClaimLink<TState> {
    fn claim(ref self: TState, claim: Claim, signature: Array<felt252>);

    #[cfg(test)]
    fn set_usdc_address(ref self: TState, usdc_address: ContractAddress);
}
