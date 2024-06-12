use starknet::{ContractAddress, account::Call};
use vault::utils::outside_execution::OutsideExecution;

const IOutsideExecution_V2_ID: felt252 =
    0x1d1144bb2138366ff28d8e9ab57456b1d332ac42196230c3a602003c89872;

#[starknet::interface]
trait IOutsideExecution_V2<TState> {
    /// This method allows anyone to submit a transaction on behalf of the account as long as they have the relevant signatures.
    /// This method allows reentrancy. A call to `__execute__` or `execute_from_outside` can trigger another nested transaction to `execute_from_outside` thus the implementation MUST verify that the provided `signature` matches the hash of `outside_execution` and that `nonce` was not already used.
    /// The implementation should expect version to be set to 2 in the domain separator.
    /// # Arguments
    /// * `outside_execution ` - The parameters of the transaction to execute.
    /// * `signature ` - A valid signature on the SNIP-12 message encoding of `outside_execution`.
    fn execute_from_outside_v2(
        ref self: TState, outside_execution: OutsideExecution, signature: Span<felt252>,
    ) -> Array<Span<felt252>>;

    /// Get the status of a given nonce, true if the nonce is available to use
    fn is_valid_outside_execution_nonce(self: @TState, nonce: felt252) -> bool;
}
