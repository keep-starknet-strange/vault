#[starknet::component]
pub mod OutsideExecutionComponent {
    use openzeppelin::account::interface::ISRC6;
    use openzeppelin::account::utils::execute_calls;
    use openzeppelin::introspection::src5::SRC5Component::InternalTrait as SRC5InternalTrait;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::utils::cryptography::snip12::OffchainMessageHash;
    use starknet::{get_caller_address, get_block_timestamp, get_contract_address};
    use vault::components::outside_execution::interface;
    use vault::utils::outside_execution::OutsideExecution;
    use vault::utils::starknet::CallClone;

    #[storage]
    struct Storage {
        /// Keeps track of used nonces for outside transactions (`execute_from_outside`)
        outside_nonces: LegacyMap<felt252, bool>,
    }

    #[embeddable_as(OutsideExecution_V2Impl)]
    impl OutsideExecution_V2<
        TContractState, +HasComponent<TContractState>, +ISRC6<TContractState>
    > of interface::IOutsideExecution_V2<ComponentState<TContractState>> {
        fn execute_from_outside_v2(
            ref self: ComponentState<TContractState>,
            outside_execution: OutsideExecution,
            signature: Span<felt252>,
        ) -> Array<Span<felt252>> {
            // Step 1: Checks

            // check caller
            if outside_execution.caller.into() != 'ANY_CALLER' {
                assert(get_caller_address() == outside_execution.caller, 'Invalid caller');
            }

            // check timestamp
            let block_timestamp = get_block_timestamp();
            assert(outside_execution.execute_after < block_timestamp, 'Too early');
            assert(block_timestamp < outside_execution.execute_before, 'Too late');

            // check nonce
            let nonce = outside_execution.nonce;
            assert(!self.outside_nonces.read(nonce), 'Already used nonce');

            // check signature
            let outside_execution_hash = outside_execution.get_message_hash(get_contract_address());
            assert!(
                self
                    .get_contract()
                    .is_valid_signature(
                        hash: outside_execution_hash, signature: signature.snapshot.clone()
                    ) == starknet::VALIDATED,
                "Invalid signature for paymaster"
            );

            // Effects
            self.outside_nonces.write(nonce, true);

            // Interactions
            execute_calls(calls: outside_execution.calls.snapshot.clone())
        }

        fn is_valid_outside_execution_nonce(
            self: @ComponentState<TContractState>, nonce: felt252
        ) -> bool {
            !self.outside_nonces.read(nonce)
        }
    }

    #[generate_trait]
    impl InternalImpl<
        TContractState,
        +Drop<TContractState>,
        +HasComponent<TContractState>,
        impl SRC5: SRC5Component::HasComponent<TContractState>
    > of InternalTrait<TContractState> {
        fn initializer(ref self: ComponentState<TContractState>) {
            let mut src5_component = get_dep_component_mut!(ref self, SRC5);
            src5_component.register_interface(interface::IOutsideExecution_V2_ID);
        }
    }
}
