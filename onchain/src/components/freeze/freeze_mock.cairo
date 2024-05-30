use super::freeze::AdminComponent;

#[starknet::contract]
mod AdminMock {
    use starknet::ContractAddress;
    use starknet::account::Call;
    use vault::components::AdminComponent::InternalAdminTrait;
    use vault::components::AdminComponent;

    component!(path: AdminComponent, storage: admin, event: AdminEvent);

    // Admin
    #[abi(embed_v0)]
    impl AdminImpl = AdminComponent::AdminImpl<ContractState>;

    //
    // Storage
    //

    #[storage]
    struct Storage {
        #[substorage(v0)]
        admin: AdminComponent::Storage,
    }

    //
    // Events
    //

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        AdminEvent: AdminComponent::Event,
    }

    //
    // Constructor
    //

    #[constructor]
    fn constructor(
        ref self: ContractState,
        admin: ContractAddress,
        erc20_address: ContractAddress,
        withdraw_address: ContractAddress
    ) {
        self.admin.initializer(admin, erc20_address, withdraw_address);
    }
}

type ComponentState = AdminComponent::ComponentState<AdminMock::ContractState>;

fn COMPONENT() -> ComponentState {
    AdminComponent::component_state_for_testing()
}
