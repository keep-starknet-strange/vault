use starknet::{account::Call, SyscallResultTrait};

#[starknet::interface]
trait DailyLimitTrait<T> {
    fn __execute__(self: @T, calls: Array<Call>) -> Array<Span<felt252>>;
    fn __validate__(self: @T, calls: Array<Call>) -> felt252;
    fn is_valid_signature(self: @T, hash: felt252, signature: Array<felt252>) -> felt252;
}

fn execute_calls(mut calls: Array<Call>) -> Array<Span<felt252>> {
    let mut res = ArrayTrait::new();
    while let Option::Some(call) = calls.pop_front() {
        res.append(execute_single_call(call));
    };
    res
}
fn execute_single_call(call: Call) -> Span<felt252> {
    starknet::call_contract_syscall(call.to, call.selector, call.calldata).unwrap_syscall()
}
#[starknet::component]
mod spending_limit {
    use core::option::OptionTrait;
    use core::traits::TryInto;
    use array::{ArrayTrait, SpanIndex};
    use core::box::BoxTrait;
    use ecdsa::check_ecdsa_signature;
    use starknet::{
        account::Call, SyscallResultTrait,
        info::{get_block_timestamp, get_tx_info, get_caller_address}
    };
    use vault::components::spending_limit::DailyLimitTrait;

    const DAY_IN_SECONDS: u64 = 86400;
    const VALID: felt252 = 'VALID';
    const QUERY_OFFSET: u256 = 0x100000000000000000000000000000000;
    const MIN_TRANSACTION_VERSION: u256 = 1;
    #[storage]
    struct Storage {
        limit: u256,
        current_value: u256,
        last_modification: u64,
        public_key: felt252,
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
            let sender = get_caller_address();
            assert!(sender.is_zero(), "Cannot call from contract");

            // Check tx version
            let tx_info = get_tx_info().unbox();
            let tx_version = tx_info.version.into();
            // Check if tx is a query
            if (tx_version >= QUERY_OFFSET) {
                assert!(
                    QUERY_OFFSET + MIN_TRANSACTION_VERSION <= tx_version,
                    "Invalid transaction version"
                );
            } else {
                assert!(MIN_TRANSACTION_VERSION <= tx_version, "Invalid transaction version");
            }

            super::execute_calls(calls)
        }
        fn __validate__(self: @ComponentState<TContractState>, calls: Array<Call>) -> felt252 {
            let tx_info = get_tx_info().unbox();
            self.validate_signature(tx_info.transaction_hash, tx_info.signature)
        }
        fn is_valid_signature(
            self: @ComponentState<TContractState>, hash: felt252, signature: Array<felt252>
        ) -> felt252 {
            self.validate_signature(hash, signature.span())
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
            let mut i = 0_usize;
            while i < calls
                .len() {
                    let call: @Call = calls[i];
                    if call.selector == @selector!("transfer") {
                        value +=
                            (u256 {
                                low: TryInto::<felt252, u128>::try_into(*call.calldata[1]).unwrap(),
                                high: TryInto::<felt252, u128>::try_into(*call.calldata[2]).unwrap()
                            })
                            .into();
                    }
                    i += 1;
                };
            self.is_below_limit(value)
        }

        #[inline(always)]
        fn is_below_limit(self: @ComponentState<TContractState>, value: u256) -> bool {
            value <= self.limit.read()
        }

        #[inline(always)]
        fn initialize(ref self: ComponentState<TContractState>, public_key: felt252, limit: u256) {
            self.public_key.write(public_key);
            self.limit.write(limit);
        }
        fn validate_signature(
            self: @ComponentState<TContractState>, hash: felt252, signature: Span<felt252>,
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
}

#[cfg(test)]
mod test {
    use starknet::account::Call;
    use array::ArrayTrait;
    use vault::components::spending_limit::DailyLimitTrait;
    use vault::components::spending_limit::spending_limit::InternalTrait;

    #[starknet::contract]
    mod mock_contract {
        use super::super::spending_limit;
        component!(path: spending_limit, storage: spending_limit, event: SpendingLimitEvent);

        #[event]
        #[derive(Drop, starknet::Event)]
        enum Event {
            #[flat]
            SpendingLimitEvent: spending_limit::Event,
        }
        #[storage]
        struct Storage {
            #[substorage(v0)]
            spending_limit: spending_limit::Storage,
        }
    }

    type ComponentState = super::spending_limit::ComponentState<mock_contract::ContractState>;

    fn COMPONENT() -> ComponentState {
        super::spending_limit::component_state_for_testing()
    }

    // #[test]
    // fn test_validate_signature() {
    //     // Taken from OZ
    //     // private_key: 1234,
    //     // public_key: 0x1f3c942d7f492a37608cde0d77b884a5aa9e11d2919225968557370ddb5a5aa,
    //     // transaction_hash: 0x601d3d2e265c10ff645e1554c435e72ce6721f0ba5fc96f0c650bfc6231191a,
    //     // r: 0x6c8be1fb0fb5c730fbd7abaecbed9d980376ff2e660dfcd157e158d2b026891,
    //     // s: 0x76b4669998eb933f44a59eace12b41328ab975ceafddf92602b21eb23e22e35
    //     let mut component = COMPONENT();
    //     assert!(component.validate_signature(0, array![].span()).is_zero());
    //     component
    //         .initialize(
    //             0x1f3c942d7f492a37608cde0d77b884a5aa9e11d2919225968557370ddb5a5aa, 0x1
    //         ); // set the public key and daily limit
    //     assert_eq!(
    //         component
    //             .validate_signature(
    //                 0x601d3d2e265c10ff645e1554c435e72ce6721f0ba5fc96f0c650bfc6231191a, // message hash
    //                 array![
    //                     0x6c8be1fb0fb5c730fbd7abaecbed9d980376ff2e660dfcd157e158d2b026891, // r
    //                     0x76b4669998eb933f44a59eace12b41328ab975ceafddf92602b21eb23e22e35 // s
    //                 ]
    //                     .span()
    //             ),
    //         super::spending_limit::VALID
    //     );
    // }

    #[test]
    fn test_is_below_limit() {
        let mut component = COMPONENT();
        // 0 <= 0
        assert!(component.is_below_limit(0));
        // 1 <= 0
        assert!(!component.is_below_limit(1));
        // Set public key to 1 and limit to 2
        component.initialize(1, 2);
        // 1 <= 2
        assert!(component.is_below_limit(1));
        // 3 <= 2
        assert!(!component.is_below_limit(3));
    }
// fn test_validate_sum_under_limit() {
//     let mut calls = array![
//         Call {
//             to: 1.try_into().unwrap(),
//             selector: selector!("transfer"),
//             calldata: array![2, 0, 1].span()
//         }
//     ]
//         .span();
//     let mut component = COMPONENT();
//     component.validate_sum_under_limit(ref calls);
// }
}
