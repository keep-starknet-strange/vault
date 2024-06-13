#[starknet::contract(account)]
mod VaultAccount {
    use core::box::BoxTrait;
    use core::hash::Hash;
    use core::option::OptionTrait;
    use core::result::ResultTrait;
    use core::starknet::{get_tx_info, SyscallResultTrait};
    use openzeppelin::account::AccountComponent;
    use openzeppelin::account::interface::ISRC6;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin::utils::cryptography::snip12::{
        OffchainMessageHashImpl, StructHash, SNIP12Metadata
    };
    use starknet::{ContractAddress, ClassHash};
    use starknet::account::Call;
    use starknet::secp256_trait::is_valid_signature;
    use starknet::secp256r1::{Secp256r1Point, Secp256r1Impl};
    use starknet::{get_caller_address, contract_address_const, get_contract_address};
    use vault::components::spending_limit::weekly::interface::IWeeklyLimit;
    use vault::components::{
        WeeklyLimitComponent, WhitelistComponent, TransactionApprovalComponent,
        OutsideExecutionComponent
    };
    use vault::contracts::account::interface::{IVaultAccount, IClaimLink};
    use vault::utils::claim::Claim;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;

    component!(path: AccountComponent, storage: account, event: AccountEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(
        path: TransactionApprovalComponent,
        storage: transaction_approval,
        event: TransactionApprovalEvent
    );
    component!(path: WeeklyLimitComponent, storage: weekly_limit, event: WeeklyLimitEvent);
    component!(path: WhitelistComponent, storage: whitelist, event: WhitelistEvent);
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

    // Weekly Limit
    impl WeeklyLimitInternalImpl = WeeklyLimitComponent::InternalImpl<ContractState>;

    // Whitelisting
    impl WhitelistContractsInternalImpl = WhitelistComponent::WhitelistContractsImpl<ContractState>;
    impl WhitelistClassHashesInternalImpl =
        WhitelistComponent::WhitelistClassHashesImpl<ContractState>;
    impl WhitelistEntrypointsInternalImpl =
        WhitelistComponent::WhitelistEntrypointsImpl<ContractState>;
    impl WhitelistContractEntrypointInternalImpl =
        WhitelistComponent::WhitelistContractEntrypointImpl<ContractState>;
    impl WhitelistClassHashEntrypointInternalImpl =
        WhitelistComponent::WhitelistClassHashEntrypointImpl<ContractState>;

    // Transaction approval
    impl TransactionApprovalInternalImpl =
        TransactionApprovalComponent::InternalImpl<ContractState>;

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
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        transaction_approval: TransactionApprovalComponent::Storage,
        #[substorage(v0)]
        weekly_limit: WeeklyLimitComponent::Storage,
        #[substorage(v0)]
        whitelist: WhitelistComponent::Storage,
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
        TransactionApprovalEvent: TransactionApprovalComponent::Event,
        #[flat]
        WeeklyLimitEvent: WeeklyLimitComponent::Event,
        #[flat]
        WhitelistEvent: WhitelistComponent::Event,
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
            approver: ContractAddress,
            limit: u256,
        ) {
            self.public_key.write((pub_key_x, pub_key_y));
            self.transaction_approval.initializer(:approver);
            self.weekly_limit.initializer(:limit);
            self.outside_execution.initializer();
            self
                .usdc_address
                .write(
                    contract_address_const::<
                        0x053b40a647cedfca6ca84f542a0fe36736031905a9639a7f19a3c1e66bfd5080
                    >()
                );

            // Verify public key validity
            let _ = Secp256r1Impl::secp256_ec_new_syscall(pub_key_x, pub_key_y).unwrap().unwrap();
        }
    }

    //
    // ClaimLink impl
    //

    #[abi(embed_v0)]
    impl ClaimLink of IClaimLink<ContractState> {
        fn claim(ref self: ContractState, claim: Claim, signature: Array<felt252>) {
            let hash = claim.get_message_hash(get_contract_address());

            assert!(!self.claims.read(hash), "Link already used");
            assert!(
                self.is_valid_signature(hash, signature) == starknet::VALIDATED,
                "Invalid signature for claim"
            );

            self.claims.write(hash, true);

            let usdc = IERC20Dispatcher { contract_address: self.usdc_address.read() };
            usdc.transfer(get_caller_address(), claim.amount);
        }

        #[cfg(test)]
        fn set_usdc_address(ref self: ContractState, usdc_address: ContractAddress) {
            self.usdc_address.write(usdc_address);
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
    // Weekly Limit impl
    //

    #[abi(embed_v0)]
    impl WeeklyLimit of IWeeklyLimit<ContractState> {
        fn get_weekly_limit(self: @ContractState) -> u256 {
            self.weekly_limit.get_weekly_limit()
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
