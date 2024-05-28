// TODO: implement account
#[starknet::contract(account)]
mod BlankAccount {
    use openzeppelin::account::interface::ISRC6;
    use starknet::account::Call;

    #[storage]
    struct Storage {}

    //
    // SRC6 override
    //

    #[abi(embed_v0)]
    impl ISRC6Impl of ISRC6<ContractState> {
        fn __execute__(self: @ContractState, calls: Array<Call>) -> Array<Span<felt252>> {
            array![]
        }

        fn __validate__(self: @ContractState, calls: Array<Call>) -> felt252 {
            0
        }

        fn is_valid_signature(
            self: @ContractState, hash: felt252, signature: Array<felt252>
        ) -> felt252 {
            0
        }
    }
}
