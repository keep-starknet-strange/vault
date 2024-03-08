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

    #[generate_trait]
    impl InternalImpl<
        TContractState, +HasComponent<TContractState>
    > of InternalTrait<TContractState> {
        #[inline(always)]
        fn initializer(ref self: ComponentState<TContractState>, limit: u256) {
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

        // Limit value mgmt

        fn _get_daily_limit(self: @ComponentState<TContractState>) -> u256 {
            self.limit.read()
        }

        fn _set_daily_limit(ref self: ComponentState<TContractState>, new_limit: u256) {
            self.limit.write(new_limit);
        }
    }
}

//
// Tests
//

#[cfg(test)]
mod test {
    use vault::spending_limit::daily_limit::DailyLimitComponent::InternalTrait;
    use vault::spending_limit::daily_limit::interface::IDailyLimit;

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
    fn test_is_below_limit() {
        let mut component = COMPONENT();
        // 0 <= 0
        assert!(component._is_below_limit(0));
        // 1 <= 0
        assert!(!component._is_below_limit(1));
        // Set limit to 2
        component.initializer(2);
        // 1 <= 2
        assert!(component._is_below_limit(1));
        // 3 <= 2
        assert!(!component._is_below_limit(3));
    }
}
