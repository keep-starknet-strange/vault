#[starknet::component]
pub mod AdminComponent {
    use openzeppelin::token::erc20::interface::{IERC20DispatcherTrait, IERC20Dispatcher};
    use starknet::ContractAddress;
    use starknet::{get_caller_address, get_contract_address};

    #[storage]
    pub struct Storage {
        admin: ContractAddress,
        erc20_address: ContractAddress,
        is_frozen: bool,
        withdraw_address: ContractAddress,
    }
    #[starknet::interface]
    trait AdminTrait<TContractState> {
        fn freeze(ref self: TContractState);
        fn unfreeze(ref self: TContractState);
        fn is_frozen(self: @TContractState) -> bool;
        fn emergency_withdraw(self: @TContractState);
    }

    #[embeddable_as(Admin)]
    impl AdminExternal<
        TContractState, +Drop<TContractState>, +HasComponent<TContractState>
    > of AdminTrait<ComponentState<TContractState>> {
        /// Freezes the contract. Can be unfrozen with `unfreeze` 
        fn freeze(ref self: ComponentState<TContractState>) {
            self.freeze_internal()
        }
        /// Unfreezes the contract.
        fn unfreeze(ref self: ComponentState<TContractState>) {
            self.unfreeze_internal()
        }
        /// Returns if the contract is frozen or not.
        fn is_frozen(self: @ComponentState<TContractState>) -> bool {
            self.is_frozen_internal()
        }
        /// Withdraw all the tokens of an erc20 previously set to a predefined address.
        fn emergency_withdraw(self: @ComponentState<TContractState>) {
            self.emergency_withdraw_internal()
        }
    }


    #[generate_trait]
    impl InternalAdmin<
        TContractState, +HasComponent<TContractState>
    > of InternalAdminTrait<TContractState> {
        fn initializer(
            ref self: ComponentState<TContractState>,
            admin: ContractAddress,
            erc20_address: ContractAddress,
            withdraw_address: ContractAddress
        ) {
            self.admin.write(admin);
            self.erc20_address.write(erc20_address);
            self.withdraw_address.write(withdraw_address);
        }

        /// Freezes the contract. Can be unfrozen with `unfreeze` 
        #[inline(always)]
        fn freeze_internal(ref self: ComponentState<TContractState>) {
            self.assert_only_admin();
            self.is_frozen.write(true);
        }

        /// Unfreezes the contract.
        #[inline(always)]
        fn unfreeze_internal(ref self: ComponentState<TContractState>) {
            self.assert_only_admin();
            self.is_frozen.write(false)
        }

        /// Returns if the contract is frozen or not.
        #[inline(always)]
        fn is_frozen_internal(self: @ComponentState<TContractState>) -> bool {
            self.is_frozen.read()
        }

        /// Withdraw all the tokens of an erc20 previously set to a predefined address.
        fn emergency_withdraw_internal(self: @ComponentState<TContractState>) {
            self.assert_only_admin();
            let erc20 = IERC20Dispatcher { contract_address: self.erc20_address.read() };
            erc20.transfer(self.withdraw_address.read(), erc20.balance_of(get_contract_address()));
        }

        /// Panics if the contract is frozen.
        #[inline(always)]
        fn assert_not_frozen(self: @ComponentState<TContractState>) {
            assert!(!self.is_frozen_internal(), "Contract is frozen");
        }

        /// Panics if the caller is not the admin contract.
        fn assert_only_admin(self: @ComponentState<TContractState>) {
            assert!(get_caller_address() == self.admin.read(), "Only admin");
        }
    }
}
