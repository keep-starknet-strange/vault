use starknet::account::Call;
use super::tx_approval::TransactionApprovalComponent;

#[starknet::interface]
trait TestExternal<TState> {
    fn get_transaction(self: @TState, transaction_hash: felt252) -> Call;

    fn register_transaction(ref self: TState, transaction: Call, transaction_hash: felt252);
    fn approve_transaction(
        self: @TState, signature: Array<felt252>, transaction_hash: felt252
    ) -> Span<felt252>;
}

#[starknet::contract]
mod TransactionApprovalMock {
    use starknet::ContractAddress;
    use starknet::account::Call;
    use vault::components::TransactionApprovalComponent::InternalTrait;
    use vault::components::TransactionApprovalComponent;

    component!(
        path: TransactionApprovalComponent, storage: approval, event: TransactionApprovalEvent
    );

    //
    // Storage
    //

    #[storage]
    struct Storage {
        #[substorage(v0)]
        approval: TransactionApprovalComponent::Storage,
    }

    //
    // Events
    //

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        TransactionApprovalEvent: TransactionApprovalComponent::Event,
    }

    //
    // Constructor
    //

    #[constructor]
    fn constructor(ref self: ContractState, approver: ContractAddress) {
        self.approval.initializer(approver);
    }

    //
    // Test External impl
    //

    #[abi(embed_v0)]
    impl Ext of super::TestExternal<ContractState> {
        fn register_transaction(
            ref self: ContractState, transaction: Call, transaction_hash: felt252
        ) {
            self.approval.register_transaction(transaction, transaction_hash)
        }

        fn get_transaction(self: @ContractState, transaction_hash: felt252) -> Call {
            self.approval.get_transaction(transaction_hash)
        }

        fn approve_transaction(
            self: @ContractState, signature: Array<felt252>, transaction_hash: felt252
        ) -> Span<felt252> {
            self.approval.approve_transaction(signature, transaction_hash)
        }
    }
}

type ComponentState =
    TransactionApprovalComponent::ComponentState<TransactionApprovalMock::ContractState>;

fn COMPONENT() -> ComponentState {
    TransactionApprovalComponent::component_state_for_testing()
}
