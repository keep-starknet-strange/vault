use starknet::ContractAddress;
use vault::utils::claim::Claim;
use vault::utils::outside_execution::OutsideExecution;

#[starknet::interface]
trait VaultAccountABI<TState> {
    fn execute_from_outside_v2(
        ref self: TState, outside_execution: OutsideExecution, signature: Span<felt252>,
    ) -> Array<Span<felt252>>;

    fn is_valid_outside_execution_nonce(self: @TState, nonce: felt252) -> bool;

    fn initialize(
        ref self: TState, pub_key_x: u256, pub_key_y: u256, approver: ContractAddress, limit: u256
    );
    #[cfg(test)]
    fn set_usdc_address(ref self: TState, usdc_address: ContractAddress);
}

#[starknet::interface]
trait IVaultAccount<TState> {
    fn initialize(
        ref self: TState, pub_key_x: u256, pub_key_y: u256, admin_address: ContractAddress
    );
}
