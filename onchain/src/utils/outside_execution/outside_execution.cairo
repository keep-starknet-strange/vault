use core::traits::Into;
use hash::{HashStateTrait, HashStateExTrait};
use openzeppelin::utils::cryptography::snip12::{SNIP12Metadata, StructHash};
use poseidon::{PoseidonTrait, poseidon_hash_span};
use starknet::{ContractAddress, get_tx_info, get_contract_address, account::Call};

const OUTSIDE_EXECUTION_TYPE_HASH: felt252 =
    selector!(
        "\"OutsideExecution\"(\"Caller\":\"ContractAddress\",\"Nonce\":\"felt\",\"Execute After\":\"u128\",\"Execute Before\":\"u128\",\"Calls\":\"Call*\")\"Call\"(\"To\":\"ContractAddress\",\"Selector\":\"selector\",\"Calldata\":\"felt*\")"
    );

const CALL_TYPE_HASH: felt252 =
    selector!(
        "\"Call\"(\"To\":\"ContractAddress\",\"Selector\":\"selector\",\"Calldata\":\"felt*\")"
    );

#[derive(Copy, Drop, Serde)]
struct OutsideExecution {
    caller: ContractAddress,
    nonce: felt252,
    // note that the type here is u64 and not u128 as defined in the type hash definition
    // u64 matches the type of block_timestamp in Corelib's BlockInfo struct
    execute_after: u64,
    execute_before: u64,
    calls: Span<Call>,
}

impl CallStructHash of StructHash<Call> {
    fn hash_struct(self: @Call) -> felt252 {
        let hash_state = PoseidonTrait::new();

        hash_state
            .update_with(CALL_TYPE_HASH)
            .update_with(*self.to.into())
            .update_with(*self.selector)
            .update_with(poseidon_hash_span(*self.calldata))
            .finalize()
    }
}

impl SpanStructHash<T, +StructHash<T>> of StructHash<Span<T>> {
    fn hash_struct(self: @Span<T>) -> felt252 {
        let mut hash_state = PoseidonTrait::new();
        let mut i: usize = 0;

        loop {
            if i >= (*self).len() {
                break;
            }

            hash_state = hash_state.update_with((*self).at(i).hash_struct());

            i += 1;
        };

        hash_state.finalize()
    }
}

impl OutsideExecutionStructHash of StructHash<OutsideExecution> {
    fn hash_struct(self: @OutsideExecution) -> felt252 {
        let hash_state = PoseidonTrait::new();

        hash_state
            .update_with(OUTSIDE_EXECUTION_TYPE_HASH)
            .update_with(*self.caller.into())
            .update_with(*self.nonce)
            .update_with(*self.execute_after.into())
            .update_with(*self.execute_before.into())
            .update_with(self.calls.hash_struct())
            .finalize()
    }
}

impl OutsideExecutionSNIP12Metadata of SNIP12Metadata {
    fn name() -> felt252 {
        'Account.execute_from_outside'
    }

    fn version() -> felt252 {
        2
    }
}
