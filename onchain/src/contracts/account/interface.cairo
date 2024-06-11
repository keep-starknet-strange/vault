use starknet::ContractAddress;

use vault::utils::{claim::Claim, outside_execution::OutsideExecution};

#[starknet::interface]
trait IVaultAccount<TState> {
    fn initialize(
        ref self: TState, pub_key_x: u256, pub_key_y: u256, approver: ContractAddress, limit: u256
    );
}

#[starknet::interface]
pub trait IVaultAccountFunctionnalities<TState> {
    fn claim(ref self: TState, claim: Claim, signature: Array<felt252>);

    /// @notice This method allows anyone to submit a transaction on behalf of the account as long
    /// as they have the relevant signatures @param outside_execution The parameters of the
    /// transaction to execute @param signature A valid signature on the Eip712 message encoding of
    /// `outside_execution`
    /// @notice This method allows reentrancy. A call to `__execute__` or `execute_from_outside` can
    /// trigger another nested transaction to `execute_from_outside`.
    fn execute_from_outside(
        ref self: TState, outside_execution: OutsideExecution, signature: Array<felt252>
    ) -> Array<Span<felt252>>;

    /// Get the status of a given nonce, true if the nonce is available to use
    fn is_valid_outside_execution_nonce(self: @TState, nonce: felt252) -> bool;

    /// Get the message hash for some `OutsideExecution` following Eip712. Can be used to know what
    /// needs to be signed
    fn get_outside_execution_message_hash(
        self: @TState, outside_execution: OutsideExecution
    ) -> felt252;

    #[cfg(test)]
    fn set_usdc_address(ref self: TState, usdc_address: ContractAddress);
}
