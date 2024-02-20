use starknet::account::Call;

#[starknet::interface]
trait DailyLimitTrait<T> {
    fn __execute__(self: @T, calls: Array<Call>) -> Array<Span<felt252>>;
    fn __validate__(self: @T, calls: Array<Call>) -> felt252;
    fn is_valid_signature(self: @T, hash: felt252, signature: Array<felt252>) -> felt252;
}

#[starknet::component]
mod spending_limit {
    use vault::components::spending_limit::DailyLimitTrait;
    use starknet::info::get_block_timestamp;
    use starknet::account::Call;
    use core::SpanTrait;

    const DAY_IN_SECONDS: u64 = 86400;
    #[storage]
    struct Storage {
        limit: u256,
        current_value: u256,
        last_modification: u64,
    }
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

    #[embeddable_as(DailyLimit)]
    impl DailyLimitU256<
        TContractState, +HasComponent<TContractState>, +Drop<TContractState>
    > of super::DailyLimitTrait<ComponentState<TContractState>> {
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
            'valid'
        }
    }

    #[generate_trait]
    impl InternalImpl<
        TContractState, +HasComponent<TContractState>
    > of InternalTrait<TContractState> {
        #[inline(always)]
        fn check_below_limit_and_update(
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
        fn validate_sum_under_limit(
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
            self.is_below_limit(value)
        }
        #[inline(always)]
        fn is_below_limit(self: @ComponentState<TContractState>, value: u256) -> bool {
            value <= self.limit.read()
        }
    }
}
