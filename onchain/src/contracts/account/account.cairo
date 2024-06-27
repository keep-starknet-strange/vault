#[starknet::contract(account)]
mod VaultAccount {
    use core::{box::BoxTrait, hash::Hash, option::OptionTrait, result::ResultTrait,};
    use openzeppelin::{
        account::AccountComponent, account::interface::ISRC6, introspection::src5::SRC5Component,
        token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait},
        upgrades::UpgradeableComponent, upgrades::interface::IUpgradeable,
        utils::cryptography::snip12::{OffchainMessageHashImpl, StructHash, SNIP12Metadata}
    };
    use starknet::{
        account::Call, get_tx_info, SyscallResultTrait, secp256_trait::is_valid_signature,
        secp256r1::{Secp256r1Point, Secp256r1Impl}, {ContractAddress, ClassHash},
        {get_caller_address, contract_address_const, get_contract_address}
    };
    use vault::{
        components::OutsideExecutionComponent, contracts::account::interface::IVaultAccount,
    };

    component!(path: AccountComponent, storage: account, event: AccountEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(
        path: OutsideExecutionComponent, storage: outside_execution, event: OutsideExecutionEvent
    );
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    // Account
    #[abi(embed_v0)]
    impl PublicKeyImpl = AccountComponent::PublicKeyImpl<ContractState>;
    #[abi(embed_v0)]
    impl PublicKeyCamelImpl = AccountComponent::PublicKeyCamelImpl<ContractState>;
    #[abi(embed_v0)]
    impl DeclarerImpl = AccountComponent::DeclarerImpl<ContractState>;
    impl AccountInternalImpl = AccountComponent::InternalImpl<ContractState>;

    // Outside Execution
    #[abi(embed_v0)]
    impl OutsideExecution_V2 =
        OutsideExecutionComponent::OutsideExecution_V2Impl<ContractState>;
    impl OutsideExecution_V2InternalImpl = OutsideExecutionComponent::InternalImpl<ContractState>;


    // SRC5
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    // Upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    //
    // Storage
    //

    #[storage]
    struct Storage {
        claims: LegacyMap<felt252, bool>,
        usdc_address: ContractAddress,
        public_key: (u256, u256),
        admin_address: ContractAddress,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        account: AccountComponent::Storage,
        #[substorage(v0)]
        outside_execution: OutsideExecutionComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
    }

    //
    // Events
    //

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        AccountEvent: AccountComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        #[flat]
        OutsideExecutionEvent: OutsideExecutionComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
    }

    // SNIP12
    impl VaultSNIP12Metadata of SNIP12Metadata {
        fn name() -> felt252 {
            'Vault'
        }

        fn version() -> felt252 {
            0
        }
    }

    //
    // Vault Account
    //

    #[abi(embed_v0)]
    impl VaultAccount of IVaultAccount<ContractState> {
        fn initialize(
            ref self: ContractState,
            pub_key_x: u256,
            pub_key_y: u256,
            admin_address: ContractAddress
        ) {
            let contract_admin_address = self.admin_address.read();
            if contract_admin_address != contract_address_const::<0>() {
                assert!(
                    get_caller_address() == contract_admin_address, "Only admin can call initialize"
                );
            }
            self.admin_address.write(admin_address);
            // Verify public key validity
            Secp256r1Impl::secp256_ec_new_syscall(pub_key_x, pub_key_y)
                .unwrap()
                .expect('Invalid public key');
            self.public_key.write((pub_key_x, pub_key_y));
            self.outside_execution.initializer();
            self
                .usdc_address
                .write(
                    contract_address_const::<
                        0x053b40a647cedfca6ca84f542a0fe36736031905a9639a7f19a3c1e66bfd5080
                    >()
                );
        }
    }


    //
    // SRC6 impl
    //

    #[abi(embed_v0)]
    impl ISRC6Impl of ISRC6<ContractState> {
        fn __execute__(self: @ContractState, calls: Array<Call>) -> Array<Span<felt252>> {
            self.account.__execute__(:calls)
        }

        fn __validate__(self: @ContractState, calls: Array<Call>) -> felt252 {
            let tx_info = get_tx_info().unbox();
            let signature = tx_info.signature.snapshot.clone();
            let hash = tx_info.transaction_hash;

            self.is_valid_signature(:hash, :signature)
        }

        fn is_valid_signature(
            self: @ContractState, hash: felt252, signature: Array<felt252>
        ) -> felt252 {
            if signature.len() != 4 {
                return 'INVALID';
            }

            let (x, y) = self.public_key.read();
            let public_key = Secp256r1Impl::secp256_ec_new_syscall(x, y).unwrap().unwrap();

            if is_valid_signature::<
                Secp256r1Point
            >(
                hash.into(),
                u256 {
                    low: (*signature[0]).try_into().unwrap(),
                    high: (*signature[1]).try_into().unwrap()
                },
                u256 {
                    low: (*signature[2]).try_into().unwrap(),
                    high: (*signature[3]).try_into().unwrap()
                },
                public_key
            ) {
                starknet::VALIDATED
            } else {
                'INVALID'
            }
        }
    }

    //
    // Upgradeable impl
    //

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.account.assert_only_self();
            self.upgradeable._upgrade(new_class_hash);
        }
    }
}
