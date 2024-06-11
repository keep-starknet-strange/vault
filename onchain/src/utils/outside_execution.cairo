use hash::{HashStateTrait, HashStateExTrait};
use poseidon::{PoseidonTrait, poseidon_hash_span};
use starknet::{ContractAddress, get_tx_info, get_contract_address, account::Call};

const ERC165_OUTSIDE_EXECUTION_INTERFACE_ID: felt252 =
    0x68cfd18b92d1907b8ba3cc324900277f5a3622099431ea85dd8089255e4181;

/// Interface ID: 0x68cfd18b92d1907b8ba3cc324900277f5a3622099431ea85dd8089255e4181
// get_outside_execution_message_hash is not part of the standard interface
#[starknet::interface]
trait IOutsideExecution<TContractState> {
    /// @notice This method allows anyone to submit a transaction on behalf of the account as long
    /// as they have the relevant signatures @param outside_execution The parameters of the
    /// transaction to execute @param signature A valid signature on the Eip712 message encoding of
    /// `outside_execution`
    /// @notice This method allows reentrancy. A call to `__execute__` or `execute_from_outside` can
    /// trigger another nested transaction to `execute_from_outside`.
    fn execute_from_outside(
        ref self: TContractState, outside_execution: OutsideExecution, signature: Array<felt252>
    ) -> Array<Span<felt252>>;

    /// Get the status of a given nonce, true if the nonce is available to use
    fn is_valid_outside_execution_nonce(self: @TContractState, nonce: felt252) -> bool;

    /// Get the message hash for some `OutsideExecution` following Eip712. Can be used to know what
    /// needs to be signed
    fn get_outside_execution_message_hash(
        self: @TContractState, outside_execution: OutsideExecution
    ) -> felt252;

    #[cfg(test)]
    fn set_usdc_address(ref self: TContractState, usdc_address: ContractAddress);
}

#[derive(Copy, Drop, Hash)]
struct StarkNetDomain {
    name: felt252,
    version: felt252,
    chain_id: felt252,
}

const OUTSIDE_EXECUTION_TYPE_HASH: felt252 =
    selector!(
        "OutsideExecution(caller:felt,nonce:felt,execute_after:felt,execute_before:felt,calls_len:felt,calls:OutsideCall*)OutsideCall(to:felt,selector:felt,calldata_len:felt,calldata:felt*)"
    );


#[derive(Copy, Drop, Serde)]
struct OutsideExecution {
    /// @notice Only the address specified here will be allowed to call `execute_from_outside`
    /// As an exception, to opt-out of this check, the value 'ANY_CALLER' can be used
    caller: ContractAddress,
    /// It can be any value as long as it's unique. Prevents signature reuse
    nonce: felt252,
    /// `execute_from_outside` only succeeds if executing after this time
    execute_after: u64,
    /// `execute_from_outside` only succeeds if executing before this time
    execute_before: u64,
    /// The calls that will be executed by the Account
    /// Using `Call` here instead of redeclaring `OutsideCall` to avoid the conversion
    calls: Span<Call>
}

#[inline(always)]
fn hash_domain(domain: @StarkNetDomain) -> felt252 {
    PoseidonTrait::new()
        .update_with(selector!("StarkNetDomain(name:felt,version:felt,chainId:felt)"))
        .update_with(*domain)
        .finalize()
}

fn hash_outside_call(outside_call: @Call) -> felt252 {
    poseidon_hash_span(
        array![
            selector!(
                "\"Call\"(\"To\":\"ContractAddress\",\"Selector\":\"selector\",\"Calldata\":\"felt*\")"
            ),
            (*outside_call.to).into(),
            *outside_call.selector,
            poseidon_hash_span(*outside_call.calldata)
        ]
            .span()
    )
}

fn hash_outside_execution(outside_execution: @OutsideExecution) -> felt252 {
    let mut calls_span = *outside_execution.calls;
    let mut hashed_calls: Array<felt252> = array![];

    loop {
        match calls_span.pop_front() {
            Option::Some(call) => { hashed_calls.append(hash_outside_call(call)); },
            Option::None(_) => { break; },
        };
    };
    poseidon_hash_span(
        array![
            selector!(
                "\"OutsideExecution\"(\"Caller\":\"ContractAddress\",\"Nonce\":\"felt\",\"Execute After\":\"u128\",\"Execute Before\":\"u128\",\"Calls\":\"Call*\")\"Call\"(\"To\":\"ContractAddress\",\"Selector\":\"selector\",\"Calldata\":\"felt*\")"
            ),
            (*outside_execution.caller).into(),
            *outside_execution.nonce,
            (*outside_execution.execute_after).into(),
            (*outside_execution.execute_before).into(),
            poseidon_hash_span(hashed_calls.span())
        ]
            .span()
    )
}

#[inline(always)]
fn hash_outside_execution_message(outside_execution: @OutsideExecution) -> felt252 {
    poseidon_hash_span(
        array![
            'StarkNet Message',
            hash_domain(
                @StarkNetDomain {
                    name: 'Account.execute_from_outside',
                    version: 2,
                    chain_id: get_tx_info().unbox().chain_id
                }
            ),
            get_contract_address().into(),
            hash_outside_execution(outside_execution)
        ]
            .span()
    )
}
