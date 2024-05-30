use super::weekly::WeeklyLimitComponent;

#[starknet::contract]
mod WeeklyMock {
    use vault::components::WeeklyLimitComponent;

    component!(path: WeeklyLimitComponent, storage: spending_limit, event: SpendingLimitEvent);

    //
    // Storage
    //

    #[storage]
    struct Storage {
        #[substorage(v0)]
        spending_limit: WeeklyLimitComponent::Storage,
    }

    //
    // Events
    //

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        SpendingLimitEvent: WeeklyLimitComponent::Event,
    }
}

type ComponentState = WeeklyLimitComponent::ComponentState<WeeklyMock::ContractState>;

fn COMPONENT() -> ComponentState {
    WeeklyLimitComponent::component_state_for_testing()
}
