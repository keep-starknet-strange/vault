mod internal_test {
    pub use super::super::freeze::AdminComponent;
    use AdminComponent::InternalAdminTrait;
    use starknet::testing::set_caller_address;
    use starknet::{contract_address_const, ContractAddress};
    #[starknet::contract]
    mod mock_contract {
        use AdminComponent::InternalAdminTrait;
        use super::AdminComponent;
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
    }

    type ComponentState = AdminComponent::ComponentState<mock_contract::ContractState>;

    fn COMPONENT() -> ComponentState {
        AdminComponent::component_state_for_testing()
    }

    #[test]
    #[should_panic(expected: "Only admin")]
    fn test_freeze_internal_not_admin() {
        let mut component = COMPONENT();
        let address = contract_address_const::<0x123>();
        // Set caller address to 0x123 as the component isn't initialized the default
        // admin address is 0.
        set_caller_address(address);
        component.freeze_internal();
    }

    #[test]
    fn test_freeze_internal_admin() {
        let mut component = COMPONENT();
        let address = contract_address_const::<0x123>();
        // Init component to set admin address to 0x123.
        component.initializer(address, address, address);
        // Call with the right address.
        set_caller_address(address);
        component.freeze_internal();
        assert!(component.is_frozen_internal());
    }

    #[test]
    fn test_freeze_internal_admin_already_frozen() {
        let mut component = COMPONENT();
        let address = contract_address_const::<0x123>();
        // Init component to set admin address to 0x123.
        component.initializer(address, address, address);
        // Call with the right address.
        set_caller_address(address);
        component.freeze_internal();
        component.freeze_internal();
        assert!(component.is_frozen_internal());
    }

    #[test]
    fn test_is_frozen_internal() {
        let mut component = COMPONENT();
        let address = contract_address_const::<0x123>();
        component.initializer(address, address, address);
        // Shouldn't be frozen yet.
        assert!(!component.is_frozen_internal());
        set_caller_address(address);
        component.freeze_internal();
        // Should be frozen.
        assert!(component.is_frozen_internal())
    }

    #[test]
    fn test_unfreeze_internal_admin() {
        let mut component = COMPONENT();
        let address = contract_address_const::<0x123>();
        // Init component to set admin address to 0x123.
        component.initializer(address, address, address);
        // Call with the right address.
        set_caller_address(address);
        component.freeze_internal();
        component.unfreeze_internal();
        assert!(!component.is_frozen_internal());
    }

    #[test]
    fn test_unfreeze_internal_admin_not_frozen() {
        let mut component = COMPONENT();
        let address = contract_address_const::<0x123>();
        // Init component to set admin address to 0x123.
        component.initializer(address, address, address);
        // Call with the right address.
        set_caller_address(address);
        component.unfreeze_internal();
        assert!(!component.is_frozen_internal());
    }

    #[test]
    #[should_panic(expected: "Only admin")]
    fn test_unfreeze_internal_not_admin() {
        let mut component = COMPONENT();
        let address = contract_address_const::<0x123>();
        // Init component to set admin address to 0x123.
        component.initializer(address, address, address);
        // Call with the right address.
        component.freeze_internal();
        component.unfreeze_internal();
    }

    #[test]
    fn test_assert_not_frozen_not_frozen() {
        let mut component = COMPONENT();
        let address = contract_address_const::<0x123>();
        // Init component to set admin address to 0x123.
        component.initializer(address, address, address);
        component.assert_not_frozen();
    }

    #[test]
    #[should_panic(expected: "Contract is frozen")]
    fn test_assert_not_frozen_frozen() {
        let mut component = COMPONENT();
        let address = contract_address_const::<0x123>();
        // Init component to set admin address to 0x123.
        component.initializer(address, address, address);
        set_caller_address(address);
        // Call with the right address.
        component.freeze_internal();
        component.assert_not_frozen();
    }
    #[test]
    fn test_assert_only_admin_admin() {
        let mut component = COMPONENT();
        let address = contract_address_const::<0x123>();
        // Init component to set admin address to 0x123.
        component.initializer(address, address, address);
        set_caller_address(address);
        component.assert_only_admin();
    }

    #[test]
    #[should_panic(expected: "Only admin")]
    fn test_assert_only_admin_not_admin() {
        let mut component = COMPONENT();
        let address = contract_address_const::<0x123>();
        // Init component to set admin address to 0x123.
        component.initializer(address, address, address);
        component.assert_only_admin();
    }
}
