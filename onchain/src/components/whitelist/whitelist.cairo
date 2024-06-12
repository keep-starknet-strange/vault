/// This component will allow whitelisting:
/// * Contracts
/// * Entrypoints
/// * Class hashes
/// * Specific entrypoints of specific contracts
/// * Specific entrypoints of specific class hashes
#[starknet::component]
pub mod WhitelistComponent {
    use core::option::OptionTrait;
    use core::starknet::SyscallResultTrait;
    use core::traits::TryInto;
    use starknet::syscalls::{storage_read_syscall, storage_write_syscall};
    use starknet::{ContractAddress, ClassHash};

    /// We don't declare the contract whitelist because [ContractAddress]is already a hash so no
    /// need to hash it again. We'll store them directly with the storage write syscall.
    #[storage]
    struct Storage {
        contract_entrypoints: LegacyMap<(ContractAddress, felt252), bool>,
        class_hash_entrypoints: LegacyMap<(ClassHash, felt252), bool>,
    }

    #[generate_trait]
    impl WhitelistContractsImpl<
        TContractState, +HasComponent<TContractState>
    > of WhitelistContractsTrait<TContractState> {
        /// This function will whitelist the provided [ContractAddress]. It saves `true` at the
        /// address `address`
        ///
        /// # Arguments
        ///
        /// * `self` - Component storage.
        /// * `address` - The contract address to be whitelisted.
        ///
        /// # Note
        ///
        /// We pass the component storage as ref but we won't actually use it, we'll directly use
        /// `storage_write_syscall`
        fn whitelist_contract(ref self: ComponentState<TContractState>, address: ContractAddress) {
            let address: felt252 = address.into();
            // Address domain = 0 (always 0 until volition), storage address = contract address,
            // value = true (1 in felt)
            // ContractAddress and StorageAddress can hold the same max value
            // so it's safe to unwrap
            storage_write_syscall(0, address.try_into().unwrap(), 1).unwrap_syscall()
        }

        /// This function will blacklist the provided [ContractAddress]. It saves `false` at the
        /// address `address`
        ///
        /// # Arguments
        ///
        /// * `self` - Component storage.
        /// * `address` - The contract address to be blacklisted.
        ///
        /// # Note
        ///
        /// We pass the component storage as ref but we won't actually use it, we'll directly use
        /// `storage_write_syscall`
        fn blacklist_contract(ref self: ComponentState<TContractState>, address: ContractAddress) {
            let address: felt252 = address.into();
            // Address domain = 0 (always 0 until volition), storage address = contract address,
            // value = false (0 in felt)
            // ContractAddress and StorageAddress can hold the same max value
            // so it's safe to unwrap
            storage_write_syscall(0, address.try_into().unwrap(), 0).unwrap_syscall()
        }

        /// Is a contract whitelisted or not.
        fn is_whitelisted(self: @ComponentState<TContractState>, address: ContractAddress) -> bool {
            let address: felt252 = address.into();
            // ContractAddress and StorageAddress can hold the same max value
            // so it's safe to unwrap
            storage_read_syscall(0, address.try_into().unwrap()).unwrap_syscall() == 1
        }
    }

    #[generate_trait]
    impl WhitelistClassHashesImpl<
        TContractState, +HasComponent<TContractState>
    > of WhitelistClassHashesTrait<TContractState> {
        /// This function will whitelist the provided [ClassHash]. It saves `true` at the
        /// address `class_hash`
        ///
        /// # Arguments
        ///
        /// * `self` - Component storage.
        /// * `class_hash` - The class hash to be whitelisted.
        ///
        /// # Note
        ///
        /// We pass the component storage as ref but we won't actually use it, we'll directly use
        /// `storage_write_syscall`
        fn whitelist_class_hash(ref self: ComponentState<TContractState>, class_hash: ClassHash) {
            let class_hash: felt252 = class_hash.into();
            // address domain = 0 (always 0 until volition), storage address = class_hash,
            // value = true (1 in felt)
            // ClassHash and StorageAddress can hold the same max value
            // so it's safe to unwrap
            storage_write_syscall(0, class_hash.try_into().unwrap(), 1).unwrap_syscall()
        }

        /// This function will blacklist the provided [ClassHash]. It saves `false` at the
        /// address`class_hash`
        ///
        /// # Arguments
        ///
        /// * `self` - Component storage.
        /// * `class_hash` - The class hash to be blacklisted.
        ///
        /// # Note
        ///
        /// We pass the component storage as ref but we won't actually use it, we'll directly use
        /// `storage_write_syscall`
        fn blacklist_class_hash(ref self: ComponentState<TContractState>, class_hash: ClassHash) {
            let class_hash: felt252 = class_hash.into();
            // address domain = 0 (always 0 until volition), storage address = class_hash,
            // value = false (0 in felt)
            // ClassHash and StorageAddress can hold the same max value
            // so it's safe to unwrap
            storage_write_syscall(0, class_hash.try_into().unwrap(), 0).unwrap_syscall()
        }

        /// Is a class hash whitelisted or not.
        fn is_whitelisted(self: @ComponentState<TContractState>, class_hash: ClassHash) -> bool {
            let address: felt252 = class_hash.into();
            // ClassHash and StorageAddress can hold the same max value
            // so it's safe to unwrap
            storage_read_syscall(0, address.try_into().unwrap()).unwrap_syscall() == 1
        }
    }

    #[generate_trait]
    impl WhitelistEntrypointsImpl<
        TContractState, +HasComponent<TContractState>
    > of WhitelistEntrypointsTrait<TContractState> {
        /// This function will whitelist the provided [felt252]. It saves `true` at the
        /// address `entrypoint`
        ///
        /// # Arguments
        ///
        /// * `self` - Component storage.
        /// * `class_hash` - The entrypoint selector to be whitelisted.
        ///
        /// # Note
        ///
        /// We pass the component storage as ref but we won't actually use it, we'll directly use
        /// `storage_write_syscall`
        ///
        /// # Panics
        ///
        /// Panics if the entrypoint value is more than 2**251 - 1
        fn whitelist_entrypoint(ref self: ComponentState<TContractState>, entrypoint: felt252) {
            // address domain = 0 (always 0 until volition), storage address = class_hash,
            // value = true (1 in felt)
            storage_write_syscall(0, entrypoint.try_into().expect('felt252 <> StorageAddress'), 1)
                .unwrap_syscall()
        }

        /// This function will blacklist the provided [felt252]. It saves `true` at the
        /// address `entrypoint`
        ///
        /// # Arguments
        ///
        /// * `self` - Component storage.
        /// * `class_hash` - The entrypoint selector to be blacklisted.
        ///
        /// # Note
        ///
        /// We pass the component storage as ref but we won't actually use it, we'll directly use
        /// `storage_write_syscall`
        ///
        /// # Panics
        ///
        /// Panics if the entrypoint value is more than 2**251 - 1
        fn blacklist_entrypoint(ref self: ComponentState<TContractState>, entrypoint: felt252) {
            // address domain = 0 (always 0 until volition), storage address = class_hash,
            // value = false (0 in felt)
            storage_write_syscall(0, entrypoint.try_into().expect('felt252 <> StorageAddress'), 0)
                .unwrap_syscall()
        }

        /// Is an entrypoint whitelisted or not.
        fn is_whitelisted(self: @ComponentState<TContractState>, entrypoint: felt252) -> bool {
            storage_read_syscall(0, entrypoint.try_into().expect('felt252 <> StorageAddress'))
                .unwrap_syscall() == 1
        }
    }

    #[generate_trait]
    impl WhitelistContractEntrypointImpl<
        TContractState, +HasComponent<TContractState>
    > of WhitelistContractEntrypointTrait<TContractState> {
        /// This function will whitelist the entrypoint of the provided contract.
        ///
        /// # Arguments
        ///
        /// * `self` - Component storage.
        /// * `contract_entrypoint` - The contract address and the entrypoint selector
        /// to be whitelisted.
        ///
        /// # Panics
        ///
        /// Panics if the entrypoint value is more than 2**251 - 1
        fn whitelist_contract_entrypoint(
            ref self: ComponentState<TContractState>,
            contract_entrypoint: (ContractAddress, felt252)
        ) {
            self.contract_entrypoints.write(contract_entrypoint, true)
        }

        /// This function will blacklist the entrypoint of the provided contract.
        ///
        /// # Arguments
        ///
        /// * `self` - Component storage.
        /// * `contract_entrypoint` - The contract address and the entrypoint selector
        /// to be blacklisted.
        ///
        /// # Panics
        ///
        /// Panics if the entrypoint value is more than 2**251 - 1
        fn blacklist_contract_entrypoint(
            ref self: ComponentState<TContractState>,
            contract_entrypoint: (ContractAddress, felt252)
        ) {
            self.contract_entrypoints.write(contract_entrypoint, false)
        }

        /// Is an entrypoint at a specific address whitelisted or not.
        fn is_whitelisted(
            self: @ComponentState<TContractState>, value: (ContractAddress, felt252)
        ) -> bool {
            self.contract_entrypoints.read(value)
        }
    }

    #[generate_trait]
    impl WhitelistClassHashEntrypointImpl<
        TContractState, +HasComponent<TContractState>
    > of WhitelistClassHashEntrypointTrait<TContractState> {
        /// This function will whitelist the entrypoint of the class hash.
        ///
        /// # Arguments
        ///
        /// * `self` - Component storage.
        /// * `class_hash_entrypoint` - The class hash and the entrypoint selector
        /// to be whitelisted.
        ///
        /// # Panics
        ///
        /// Panics if the entrypoint value is more than 2**251 - 1
        fn whitelist_class_hash_entrypoint(
            ref self: ComponentState<TContractState>, class_hash_entrypoint: (ClassHash, felt252)
        ) {
            self.class_hash_entrypoints.write(class_hash_entrypoint, true)
        }

        /// This function will blacklist the provided [felt252]. It saves `true` at the
        /// address `entrypoint`
        ///
        /// # Arguments
        ///
        /// * `self` - Component storage.
        /// * `class_hash_entrypoint` - The class hash and the entrypoint selector
        /// to be blacklisted.
        ///
        /// # Panics
        ///
        /// Panics if the entrypoint value is more than 2**251 - 1
        fn blacklist_class_hash_entrypoint(
            ref self: ComponentState<TContractState>, class_hash_entrypoint: (ClassHash, felt252)
        ) {
            self.class_hash_entrypoints.write(class_hash_entrypoint, false)
        }
        /// Is an entrypoint of a specific class hash whitelisted or not.
        fn is_whitelisted(
            self: @ComponentState<TContractState>, value: (ClassHash, felt252)
        ) -> bool {
            self.class_hash_entrypoints.read(value)
        }
    }
}

//
// TESTS
//

#[cfg(test)]
mod test {
    use starknet::{ContractAddress, contract_address_const, ClassHash, class_hash_const};
    use vault::components::WhitelistComponent::{
        WhitelistContractsTrait, WhitelistClassHashesTrait, WhitelistEntrypointsTrait,
        WhitelistContractEntrypointTrait, WhitelistClassHashEntrypointTrait
    };

    #[starknet::contract]
    mod mock_contract {
        use super::super::WhitelistComponent;
        component!(path: WhitelistComponent, storage: whitelist, event: WhitelistEvent);

        #[event]
        #[derive(Drop, starknet::Event)]
        enum Event {
            #[flat]
            WhitelistEvent: WhitelistComponent::Event,
        }
        #[storage]
        struct Storage {
            #[substorage(v0)]
            whitelist: WhitelistComponent::Storage,
        }
    }

    type ComponentState = super::WhitelistComponent::ComponentState<mock_contract::ContractState>;

    fn COMPONENT() -> ComponentState {
        super::WhitelistComponent::component_state_for_testing()
    }

    #[test]
    fn test_whitelist_contract() {
        let mut component = COMPONENT();
        let address: ContractAddress = contract_address_const::<0x123>();
        // No contract whitelisted yet
        assert!(
            !WhitelistContractsTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, address)
        );
        // Revoke whitelisting of already blacklisted address, shouldn't change anything
        component.blacklist_contract(address);
        assert!(
            !WhitelistContractsTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, address)
        );
        // Whitelist contract
        component.whitelist_contract(address);
        // Should be whitelisted
        assert!(
            WhitelistContractsTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, address)
        );
        // Whitelist again same contract shouldn't change anything
        component.whitelist_contract(address);
        // Should be whitelisted
        assert!(
            WhitelistContractsTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, address)
        );
        // Revoke whitelisting
        component.blacklist_contract(address);
        // Shouldn't be whitelisted
        assert!(
            !WhitelistContractsTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, address)
        );
    }

    #[test]
    fn test_whitelist_class_hash() {
        let mut component = COMPONENT();
        let class_hash: ClassHash = class_hash_const::<0x123>();
        // No contract whitelisted yet
        assert!(
            !WhitelistClassHashesTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, class_hash)
        );
        // Revoke whitelisting of already blacklisted class hash, shouldn't change anything
        component.blacklist_class_hash(class_hash);
        assert!(
            !WhitelistClassHashesTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, class_hash)
        );
        // Whitelist class hash
        component.whitelist_class_hash(class_hash);
        // Should be whitelisted
        assert!(
            WhitelistClassHashesTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, class_hash)
        );
        // Whitelist again same class hash shouldn't change anything
        component.whitelist_class_hash(class_hash);
        // Should be whitelisted
        assert!(
            WhitelistClassHashesTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, class_hash)
        );
        // Revoke whitelisting
        component.blacklist_class_hash(class_hash);
        // Shouldn't be whitelisted
        assert!(
            !WhitelistClassHashesTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, class_hash)
        );
    }

    #[test]
    fn test_whitelist_entrypoint() {
        let mut component = COMPONENT();
        let entrypoint: felt252 = 0x123;
        // No contract whitelisted yet
        assert!(
            !WhitelistEntrypointsTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, entrypoint)
        );
        // Revoke whitelisting of already blacklisted entrypoint, shouldn't change anything
        component.blacklist_entrypoint(entrypoint);
        assert!(
            !WhitelistEntrypointsTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, entrypoint)
        );
        // Whitelist Entrypoints
        component.whitelist_entrypoint(entrypoint);
        // Should be whitelisted
        assert!(
            WhitelistEntrypointsTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, entrypoint)
        );
        // Whitelist entrypoint shouldn't change anything
        component.whitelist_entrypoint(entrypoint);
        // Should be whitelisted
        assert!(
            WhitelistEntrypointsTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, entrypoint)
        );
        // Revoke whitelisting
        component.blacklist_entrypoint(entrypoint);
        // Shouldn't be whitelisted
        assert!(
            !WhitelistEntrypointsTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, entrypoint)
        );
    }

    #[test]
    fn test_whitelist_contract_entrypoint() {
        let mut component = COMPONENT();
        let contract_entrypoint: (ContractAddress, felt252) = (
            contract_address_const::<0x123>(), 0x123
        );
        // No contract whitelisted yet
        assert!(
            !WhitelistContractEntrypointTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, contract_entrypoint)
        );
        // Revoke whitelisting of already blacklisted contract entrypoint, shouldn't change anything
        component.blacklist_contract_entrypoint(contract_entrypoint);
        assert!(
            !WhitelistContractEntrypointTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, contract_entrypoint)
        );
        // Whitelist Entrypoints
        component.whitelist_contract_entrypoint(contract_entrypoint);
        // Should be whitelisted
        assert!(
            WhitelistContractEntrypointTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, contract_entrypoint)
        );
        // Whitelist contract entrypoint shouldn't change anything
        component.whitelist_contract_entrypoint(contract_entrypoint);
        // Should be whitelisted
        assert!(
            WhitelistContractEntrypointTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, contract_entrypoint)
        );
        // Revoke whitelisting
        component.blacklist_contract_entrypoint(contract_entrypoint);
        // Shouldn't be whitelisted
        assert!(
            !WhitelistContractEntrypointTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, contract_entrypoint)
        );
    }

    #[test]
    fn test_whitelist_class_hash_entrypoint() {
        let mut component = COMPONENT();
        let class_hash_entrypoint: (ClassHash, felt252) = (class_hash_const::<0x123>(), 0x123);
        // No class hash entrypoint whitelisted yet
        assert!(
            !WhitelistClassHashEntrypointTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, class_hash_entrypoint)
        );
        // Revoke whitelisting of already blacklisted class hash entrypoint, shouldn't change anything
        component.blacklist_class_hash_entrypoint(class_hash_entrypoint);
        assert!(
            !WhitelistClassHashEntrypointTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, class_hash_entrypoint)
        );
        // Whitelist Entrypoints
        component.whitelist_class_hash_entrypoint(class_hash_entrypoint);
        // Should be whitelisted
        assert!(
            WhitelistClassHashEntrypointTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, class_hash_entrypoint)
        );
        // Whitelist class hash entrypoint shouldn't change anything
        component.whitelist_class_hash_entrypoint(class_hash_entrypoint);
        // Should be whitelisted
        assert!(
            WhitelistClassHashEntrypointTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, class_hash_entrypoint)
        );
        // Revoke whitelisting
        component.blacklist_class_hash_entrypoint(class_hash_entrypoint);
        // Shouldn't be whitelisted
        assert!(
            !WhitelistClassHashEntrypointTrait::<
                mock_contract::ContractState
            >::is_whitelisted(@component, class_hash_entrypoint)
        );
    }
}
