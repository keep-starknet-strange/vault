mod external_test {
    pub use AdminComponent::InternalAdminTrait;
    pub use super::super::freeze::AdminComponent;
    use AdminComponent::AdminTraitDispatcherTrait;
    use core::option::OptionTrait;
    use core::starknet::SyscallResultTrait;
    use openzeppelin::account::interface::{ISRC6Dispatcher, ISRC6DispatcherTrait};
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin::utils::serde::SerializedAppend;
    use starknet::{
        ContractAddress, contract_address_const, account::Call,
        testing::{set_caller_address, set_version, set_contract_address},
    };
    use traits::{Into, TryInto};
    use vault::contracts::account::{Account, IVaultAccountDispatcher, IVaultAccountDispatcherTrait};

    #[starknet::contract]
    mod mock_contract {
        use starknet::ContractAddress;
        use starknet::account::Call;
        use super::{AdminComponent, InternalAdminTrait};

        component!(path: AdminComponent, storage: admin, event: AdminEvent);

        #[event]
        #[derive(Drop, starknet::Event)]
        enum Event {
            #[flat]
            AdminEvent: AdminComponent::Event,
        }
        #[storage]
        struct Storage {
            #[substorage(v0)]
            admin: AdminComponent::Storage,
        }
        #[constructor]
        fn constructor(
            ref self: ContractState,
            admin: ContractAddress,
            erc20_address: ContractAddress,
            withdraw_address: ContractAddress
        ) {
            self.admin.initializer(admin, erc20_address, withdraw_address);
        }

        #[abi(embed_v0)]
        impl AdminImpl = AdminComponent::AdminImpl<ContractState>;
    }

    /// Deploys a mock erc20 contract.
    fn deploy_erc20(recipient: ContractAddress, initial_supply: u256) -> IERC20Dispatcher {
        let name: ByteArray = "Fake token";
        let symbol: ByteArray = "FT";
        let mut calldata = array![];

        calldata.append_serde(name);
        calldata.append_serde(symbol);
        calldata.append_serde(initial_supply);
        calldata.append_serde(recipient);
        calldata.append_serde(recipient);

        let (address, _) = starknet::deploy_syscall(
            openzeppelin::presets::ERC20Upgradeable::TEST_CLASS_HASH.try_into().unwrap(),
            0,
            calldata.span(),
            false
        )
            .unwrap_syscall();
        IERC20Dispatcher { contract_address: address }
    }

    /// Deploys the tx approval contract + approver.
    fn setup_contracts() -> (
        AdminComponent::AdminTraitDispatcher, IERC20Dispatcher, ContractAddress
    ) {
        // Deploy admin account with public key and weekly limit and approver is 0.
        let (admin, _) = starknet::deploy_syscall(
            Account::TEST_CLASS_HASH.try_into().unwrap(), 0, array![].span(), true
        )
            .unwrap_syscall();

        IVaultAccountDispatcher { contract_address: admin }
            .initialize(
                pub_key_x: 0xa0cb79205a8355d9c8be3a361de8068cbb7d96c17a2fc7ae4ff17facdb827b4d_u256,
                pub_key_y: 0x534fafc9e92ef2408553744e545b041fdf3e36b88c3ad825c86bd6d37d1211ca_u256,
                approver: starknet::contract_address_const::<0>(),
                limit: u256 { low: 2, high: 2 }
            );

        let erc20 = deploy_erc20(admin, 1000);
        // Deploy approval mock contract with approver address.
        let (admin_contract, _) = starknet::deploy_syscall(
            mock_contract::TEST_CLASS_HASH.try_into().unwrap(),
            0,
            array![admin.into(), erc20.contract_address.into(), admin.into()].span(),
            true
        )
            .unwrap_syscall();

        set_contract_address(admin);
        erc20.transfer(admin_contract, 1000);
        set_contract_address(contract_address_const::<0>());
        (AdminComponent::AdminTraitDispatcher { contract_address: admin_contract }, erc20, admin)
    }

    #[test]
    #[should_panic(expected: ("Only admin", 'ENTRYPOINT_FAILED'))]
    fn test_freeze_not_admin() {
        let (contract, _erc20, _admin) = setup_contracts();
        contract.freeze();
    }

    #[test]
    fn test_freeze_admin() {
        let (contract, _erc20, admin) = setup_contracts();
        set_contract_address(admin);
        contract.freeze();
        assert!(contract.is_frozen());
    }

    #[test]
    fn test_freeze_admin_already_frozen() {
        let (contract, _erc20, admin) = setup_contracts();
        set_contract_address(admin);
        contract.freeze();
        contract.freeze();
        assert!(contract.is_frozen());
    }

    #[test]
    #[should_panic(expected: ("Only admin", 'ENTRYPOINT_FAILED'))]
    fn test_unfreeze_not_admin() {
        let (contract, _erc20, _admin) = setup_contracts();
        contract.unfreeze();
    }

    #[test]
    fn test_unfreeze_admin_already_unfrozen() {
        let (contract, _erc20, admin) = setup_contracts();
        set_contract_address(admin);
        contract.unfreeze();
        assert!(!contract.is_frozen());
    }

    #[test]
    fn test_unfreeze_admin() {
        let (contract, _erc20, admin) = setup_contracts();
        set_contract_address(admin);
        contract.freeze();
        contract.unfreeze();
        assert!(!contract.is_frozen());
    }

    #[test]
    fn test_withdraw_admin() {
        let (contract, erc20, admin) = setup_contracts();
        assert_eq!(erc20.balance_of(contract.contract_address), 1000);
        assert_eq!(erc20.balance_of(admin), 0);
        set_contract_address(admin);
        contract.emergency_withdraw();
        assert_eq!(erc20.balance_of(admin), 1000);
        assert_eq!(erc20.balance_of(contract.contract_address), 0);
    }

    #[test]
    fn test_withdraw_admin_no_balance() {
        let (contract, erc20, admin) = setup_contracts();
        set_contract_address(contract.contract_address);
        erc20.transfer(admin, 1000);
        assert_eq!(erc20.balance_of(contract.contract_address), 0);
        assert_eq!(erc20.balance_of(admin), 1000);
        set_contract_address(admin);
        contract.emergency_withdraw();
        assert_eq!(erc20.balance_of(contract.contract_address), 0);
        assert_eq!(erc20.balance_of(admin), 1000);
    }
}
