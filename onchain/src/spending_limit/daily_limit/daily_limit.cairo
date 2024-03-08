#[starknet::component]
mod DailyLimitComponent {
    use array::ArrayTrait;
    use starknet::info::get_block_timestamp;
    use starknet::account::Call;
    use ecdsa::check_ecdsa_signature;
    use array::IndexView;

    use vault::spending_limit::daily_limit::interface;

    const DAY_IN_SECONDS: u64 = 86400;
    const VALID: felt252 = 'VALID';

    //
    // Storage
    //

    #[storage]
    struct Storage {
        limit: u256,
        current_value: u256,
        last_modification: u64,
        public_key: felt252,
    }

    //
    // Events
    //

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        LimitUpdated: LimitUpdated
    }

    #[derive(Drop, starknet::Event)]
    struct LimitUpdated {
        new_value: u256,
        last_modification: u64,
    }

    #[embeddable_as(DailyLimitImpl)]
    impl DailyLimit<
        TContractState, +HasComponent<TContractState>, +Drop<TContractState>
    > of interface::DailyLimit<ComponentState<TContractState>> {
        fn __execute__(
            self: @ComponentState<TContractState>, calls: Array<Call>
        ) -> Array<Span<felt252>> {
            array![array![1].span()]
        }

        fn __validate__(self: @ComponentState<TContractState>, calls: Array<Call>) -> felt252 {
            1
        }

        fn is_valid_signature(
            self: @ComponentState<TContractState>, hash: felt252, signature: Array<felt252>
        ) -> felt252 {
            if signature.len() == 2
                && check_ecdsa_signature(
                    hash, self.public_key.read(), *signature[0], *signature[1]
                ) {
                VALID
            } else {
                0
            }
        }
    }

    #[generate_trait]
    impl InternalImpl<
        TContractState, +HasComponent<TContractState>
    > of InternalTrait<TContractState> {
        #[inline(always)]
        fn initializer(ref self: ComponentState<TContractState>, public_key: felt252, limit: u256) {
            self.public_key.write(public_key);
            self.limit.write(limit);
        }

        #[inline(always)]
        fn _check_below_limit_and_update(
            ref self: ComponentState<TContractState>, value: u256
        ) -> bool {
            let block_timestamp = get_block_timestamp();
            let new_value = if block_timestamp % DAY_IN_SECONDS == self
                .last_modification
                .read() % DAY_IN_SECONDS {
                self.current_value.read() + value
            } else {
                value
            };
            if new_value <= self.limit.read() {
                self.current_value.write(new_value);
                self.emit(LimitUpdated { new_value, last_modification: block_timestamp });
                true
            } else {
                false
            }
        }

        fn _validate_sum_under_limit(
            self: @ComponentState<TContractState>, ref calls: Span<Call>
        ) -> bool {
            let mut value = 0_u256;
            loop {
                match calls.pop_front() {
                    Option::Some(call) => {
                        if call.selector == @selector!("transfer") {
                            value += (*call.calldata[0]).into();
                        }
                    },
                    Option::None => { break; },
                }
            };
            self._is_below_limit(value)
        }

        #[inline(always)]
        fn _is_below_limit(self: @ComponentState<TContractState>, value: u256) -> bool {
            value <= self.limit.read()
        }
    }
}

//
// Tests
//

#[cfg(test)]
mod test {
    use vault::spending_limit::daily_limit::DailyLimitComponent::InternalTrait;
    use vault::spending_limit::daily_limit::interface::DailyLimit;

    #[starknet::contract]
    mod mock_contract {
        use super::super::DailyLimitComponent;
        component!(path: DailyLimitComponent, storage: spending_limit, event: SpendingLimitEvent);

        #[event]
        #[derive(Drop, starknet::Event)]
        enum Event {
            #[flat]
            SpendingLimitEvent: DailyLimitComponent::Event,
        }
        #[storage]
        struct Storage {
            #[substorage(v0)]
            spending_limit: DailyLimitComponent::Storage,
        }
    }

    type ComponentState = super::DailyLimitComponent::ComponentState<mock_contract::ContractState>;

    fn COMPONENT() -> ComponentState {
        super::DailyLimitComponent::component_state_for_testing()
    }

    #[test]
    fn test_is_valid_signature() {
        // Taken from OZ
        // private_key: 1234,
        // public_key: 0x1f3c942d7f492a37608cde0d77b884a5aa9e11d2919225968557370ddb5a5aa,
        // transaction_hash: 0x601d3d2e265c10ff645e1554c435e72ce6721f0ba5fc96f0c650bfc6231191a,
        // r: 0x6c8be1fb0fb5c730fbd7abaecbed9d980376ff2e660dfcd157e158d2b026891,
        // s: 0x76b4669998eb933f44a59eace12b41328ab975ceafddf92602b21eb23e22e35
        let mut component = COMPONENT();
        assert!(component.is_valid_signature(0, array![]).is_zero());
        component
            .initializer(
                0x1f3c942d7f492a37608cde0d77b884a5aa9e11d2919225968557370ddb5a5aa, 0x1
            ); // set the public key and daily limit
        assert_eq!(
            component
                .is_valid_signature(
                    0x601d3d2e265c10ff645e1554c435e72ce6721f0ba5fc96f0c650bfc6231191a, // message hash
                    array![
                        0x6c8be1fb0fb5c730fbd7abaecbed9d980376ff2e660dfcd157e158d2b026891, // r
                        0x76b4669998eb933f44a59eace12b41328ab975ceafddf92602b21eb23e22e35 // s
                    ]
                ),
            super::DailyLimitComponent::VALID
        );
    }

    #[test]
    fn test_is_below_limit() {
        let mut component = COMPONENT();
        // 0 <= 0
        assert!(component._is_below_limit(0));
        // 1 <= 0
        assert!(!component._is_below_limit(1));
        // Set public key to 1 and limit to 2
        component.initializer(1, 2);
        // 1 <= 2
        assert!(component._is_below_limit(1));
        // 3 <= 2
        assert!(!component._is_below_limit(3));
    }
}
