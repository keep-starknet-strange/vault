#[starknet::component]
mod WeeklyLimitComponent {
    use core::option::OptionTrait;
    use core::starknet::SyscallResultTrait;
    use core::traits::Into;
    use core::traits::TryInto;
    use starknet::info::get_block_timestamp;

    /// Number of seconds in an hour.
    const HOUR_IN_SECONDS: u64 = consteval_int!(60 * 60);
    /// Number of seconds in a week.
    const WEEK_IN_SECONDS: u64 = consteval_int!(60 * 60 * 24 * 7);

    //
    // Storage
    //
    #[storage]
    struct Storage {
        limit: u256,
        last_modification: u64,
    }

    //
    // Events
    //
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}

    #[derive(Drop, starknet::Event)]
    struct LimitUpdated {
        new_value: u256,
        last_modification: u64,
    }

    #[generate_trait]
    impl InternalImpl<
        TContractState, +HasComponent<TContractState>
    > of InternalTrait<TContractState> {
        /// Initializes this component with a spending limit for 7 rolling days.
        #[inline(always)]
        fn initializer(ref self: ComponentState<TContractState>, limit: u256) {
            self.limit.write(limit);
        }

        /// Checks if the user is allowed to spend `value` according to his weekly limit.
        ///
        /// # Arguments
        ///
        /// * `self` - The component state.
        /// * `value` -  The amount the user wants to spend.
        ///
        /// # Returns
        ///
        /// * `bool` - Is the user allowed to spend `value` according to the limit previously set.
        fn is_allowed_to_spend(ref self: ComponentState<TContractState>, mut value: u256) -> bool {
            if !self.is_below_limit(value) {
                return false;
            }
            let block_timestamp = get_block_timestamp();

            // Get the previous hour timestamp.
            let rounded_down_hour = block_timestamp - (block_timestamp % HOUR_IN_SECONDS);
            // Get the timestamp of 1 week before to compute all the expenses during that week.
            let mut hour_index = rounded_down_hour - WEEK_IN_SECONDS;
            while hour_index <= rounded_down_hour {
                // Get the low value of the expenses for that hour.
                let low = starknet::syscalls::storage_read_syscall(
                    // Using the timestamp as the storage address to avoid computing hashes.
                    // These will never collide as the time can only go forward.
                    // Unwrap can't fail because our value is a [u64] which is small enough.
                    0, Into::<u64, felt252>::into(hour_index).try_into().unwrap()
                )
                    .unwrap_syscall()
                    .try_into()
                    .unwrap();
                // Get the high value of the expenses for that hour.
                let high = starknet::syscalls::storage_read_syscall(
                    // Using the timestamp as the storage address to avoid computing hashes.
                    // These will never collide as the time can only go forward.
                    // Unwrap can't fail because our value is a [u64] which is small enough.
                    0, Into::<u64, felt252>::into(hour_index + 1).try_into().unwrap()
                )
                    .unwrap_syscall()
                    .try_into()
                    // Can't panic because it was serialized as [u256]
                    .unwrap();
                value += u256 { low, high };
                hour_index += HOUR_IN_SECONDS;
            };
            // Is value + week expenses under the weekly limit.
            value <= self.limit.read()
        }

        /// Checks if `value` is below limit.
        /// This is mostly an internal function to avoid looping over the last week
        /// if the value is above the limit.
        #[inline(always)]
        fn is_below_limit(self: @ComponentState<TContractState>, value: u256) -> bool {
            value <= self.limit.read()
        }

        /// Returns the 7 rolling days limit.
        fn get_weekly_limit(self: @ComponentState<TContractState>) -> u256 {
            self.limit.read()
        }

        /// Sets the 7 rolling days limit.
        fn set_daily_limit(ref self: ComponentState<TContractState>, new_limit: u256) {
            self.limit.write(new_limit);
        }
    }
}

//
// Tests
//

#[cfg(test)]
mod test {
    use vault::spending_limit::weekly_limit::WeeklyLimitComponent::InternalTrait;
    use vault::spending_limit::weekly_limit::interface::IWeeklyLimit;

    #[starknet::contract]
    mod mock_contract {
        use super::super::WeeklyLimitComponent;
        component!(path: WeeklyLimitComponent, storage: spending_limit, event: SpendingLimitEvent);

        #[event]
        #[derive(Drop, starknet::Event)]
        enum Event {
            #[flat]
            SpendingLimitEvent: WeeklyLimitComponent::Event,
        }
        #[storage]
        struct Storage {
            #[substorage(v0)]
            spending_limit: WeeklyLimitComponent::Storage,
        }
    }

    type ComponentState = super::WeeklyLimitComponent::ComponentState<mock_contract::ContractState>;

    fn COMPONENT() -> ComponentState {
        super::WeeklyLimitComponent::component_state_for_testing()
    }

    #[test]
    fn test_is_below_limit() {
        let mut component = COMPONENT();
        // 0 <= 0
        assert!(component.is_below_limit(0));
        // 1 <= 0
        assert!(!component.is_below_limit(1));
        // Set limit to 2
        component.initializer(2);
        // 1 <= 2
        assert!(component.is_below_limit(1));
        // 3 <= 2
        assert!(!component.is_below_limit(3));
    }

    #[test]
    fn test_is_allowed_simple() {
        starknet::testing::set_block_timestamp(8626176);
        let mut component = COMPONENT();
        // NO PREVIOUS EXPENSES SO THE VALUE IS THE ONLY THING CONSIDERED.
        // Not inialized so 0 <= 0
        assert!(component.is_allowed_to_spend(0));
        // 1 <= 0
        assert!(!component.is_allowed_to_spend(1));
        // Set limit to 2
        component.initializer(2);
        // 1 <= 2
        assert!(component.is_allowed_to_spend(1));
        // 3 <= 2
        assert!(!component.is_allowed_to_spend(3));
    }
}
