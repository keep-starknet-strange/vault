#[starknet::contract]
mod VaultFactory {
    use core::starknet::SyscallResultTrait;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::{
        IUpgradeable, IUpgradeableDispatcher, IUpgradeableDispatcherTrait
    };
    use starknet::{ClassHash, ContractAddress};
    use vault::contracts::account::interface::{
        IVaultAccountDispatcher, IVaultAccountDispatcherTrait
    };
    use vault::contracts::factory::interface::IFactory;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    // Ownable Mixin
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // Upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    //
    // Storage
    //

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        account_class_hash: ClassHash,
        blank_account_class_hash: ClassHash,
    }

    //
    // Events
    //

    #[derive(Drop, starknet::Event)]
    struct VaultAccountDeployed {
        address: ContractAddress,
        salt: felt252
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        VaultAccountDeployed: VaultAccountDeployed,
    }

    //
    // Constructor
    //

    #[constructor]
    fn constructor(
        ref self: ContractState,
        blank_account_class_hash: ClassHash,
        account_class_hash: ClassHash,
        owner: ContractAddress
    ) {
        self.ownable.initializer(:owner);
        self.initializer(:blank_account_class_hash, :account_class_hash)
    }

    //
    // Upgradeable
    //

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        /// Upgrades the contract class hash to `new_class_hash`.
        /// This may only be called by the contract owner.
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable._upgrade(:new_class_hash);
        }
    }

    //
    // Upgradeable
    //

    #[abi(embed_v0)]
    impl FactoryImpl of IFactory<ContractState> {
        fn set_account_class_hash(ref self: ContractState, account_class_hash: ClassHash) {
            // Owner only
            self.ownable.assert_only_owner();

            self.account_class_hash.write(account_class_hash);
        }

        fn deploy_account(
            ref self: ContractState,
            salt: felt252,
            pub_key_x: u256,
            pub_key_y: u256,
            approver: ContractAddress,
            limit: u256
        ) {
            // Owner only
            self.ownable.assert_only_owner();

            let blank_account_class_hash = self.blank_account_class_hash.read();
            let account_class_hash = self.account_class_hash.read();

            // Step 1: Deploy a blank account
            let (address, _) = starknet::deploy_syscall(
                class_hash: blank_account_class_hash,
                contract_address_salt: salt,
                calldata: array![].span(),
                deploy_from_zero: false
            )
                .unwrap_syscall();

            // Step 2: Upgrade it to a regular account
            IUpgradeableDispatcher { contract_address: address }
                .upgrade(new_class_hash: account_class_hash);

            // Step 3: Set up the account
            IVaultAccountDispatcher { contract_address: address }
                .initialize(:pub_key_x, :pub_key_y, :approver, :limit);

            // Emit event
            self.emit(VaultAccountDeployed { address, salt });
        }
    }

    //
    // Internal
    //

    #[generate_trait]
    impl Internal of InternalTrait {
        fn initializer(
            ref self: ContractState,
            blank_account_class_hash: ClassHash,
            account_class_hash: ClassHash
        ) {
            self.blank_account_class_hash.write(blank_account_class_hash);
            self.account_class_hash.write(account_class_hash);
        }
    }
}
// TODO: tests


