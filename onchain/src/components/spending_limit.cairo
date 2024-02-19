#[starknet::interface]
trait DailyLimitTrait<T> {
    fn check_below_limit_and_update(ref self: T, value: u256) -> bool;
    fn check_below_limit(self: @T, value: u256) -> bool;
}

#[starknet::component]
mod spending_limit {
    use vault::components::spending_limit::DailyLimitTrait;
    use starknet::info::get_block_timestamp;

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
        TContractState, +HasComponent<TContractState>
    > of super::DailyLimitTrait<ComponentState<TContractState>> {
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

        #[inline(always)]
        fn check_below_limit(self: @ComponentState<TContractState>, value: u256) -> bool {
            value <= self.limit.read()
        }
    }
}
