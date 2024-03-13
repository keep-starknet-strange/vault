#[starknet::contract(account)]
mod Account {
    use starknet::account::Call;
    use openzeppelin::account::AccountComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::account::interface::ISRC6;

    use vault::spending_limit::daily_limit::DailyLimitComponent;
    use vault::spending_limit::daily_limit::interface::IDailyLimit;

    component!(path: AccountComponent, storage: account, event: AccountEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: DailyLimitComponent, storage: daily_limit, event: DailyLimitEvent);

    // Account
    #[abi(embed_v0)]
    impl PublicKeyImpl = AccountComponent::PublicKeyImpl<ContractState>;
    #[abi(embed_v0)]
    impl PublicKeyCamelImpl = AccountComponent::PublicKeyCamelImpl<ContractState>;
    #[abi(embed_v0)]
    impl DeclarerImpl = AccountComponent::DeclarerImpl<ContractState>;
    #[abi(embed_v0)]
    impl DeployableImpl = AccountComponent::DeployableImpl<ContractState>;
    impl AccountInternalImpl = AccountComponent::InternalImpl<ContractState>;

    // Daily Limit
    impl DailyLimitInternalImpl = DailyLimitComponent::InternalImpl<ContractState>;

    // SRC5
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        account: AccountComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        daily_limit: DailyLimitComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        AccountEvent: AccountComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        DailyLimitEvent: DailyLimitComponent::Event,
    }

    //
    // Constructor
    //

    #[constructor]
    fn constructor(ref self: ContractState, public_key: felt252, limit: u256) {
        self.account.initializer(:public_key);
        self.daily_limit.initializer(:limit);
    }

    //
    // SRC6 override
    //

    #[abi(embed_v0)]
    impl ISRC6Impl of ISRC6<ContractState> {
        fn __execute__(self: @ContractState, calls: Array<Call>) -> Array<Span<felt252>> {
            self.account.__execute__(:calls)
        }

        fn __validate__(self: @ContractState, calls: Array<Call>) -> felt252 {
            // execute some checks here using `DailyLimitInternalImpl`
            self.account.__validate__(:calls)
        // or here
        }

        fn is_valid_signature(
            self: @ContractState, hash: felt252, signature: Array<felt252>
        ) -> felt252 {
            self.account.is_valid_signature(:hash, :signature)
        }
    }

    //
    // Daily Limit
    //

    #[abi(embed_v0)]
    impl DailyLimit of IDailyLimit<ContractState> {
        fn get_daily_limit(self: @ContractState) -> u256 {
            self.daily_limit.get_daily_limit()
        }

        fn set_daily_limit(ref self: ContractState, new_limit: u256) {
            self.daily_limit.set_daily_limit(:new_limit);
        }
    }
}
