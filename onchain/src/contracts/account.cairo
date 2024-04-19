#[starknet::contract(account)]
mod Account {
    use core::hash::HashStateTrait;
    use core::pedersen::{HashStateImpl, PedersenImpl};
    use openzeppelin::account::AccountComponent;
    use openzeppelin::account::interface::ISRC6;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use starknet::ContractAddress;
    use starknet::account::Call;
    use starknet::{get_caller_address, contract_address_const};
    use vault::spending_limit::weekly_limit::WeeklyLimitComponent;
    use vault::spending_limit::weekly_limit::interface::IWeeklyLimit;
    use vault::tx_approval::tx_approval::TransactionApprovalComponent;
    use vault::whitelist::whitelist::WhitelistComponent;


    component!(path: AccountComponent, storage: account, event: AccountEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(
        path: TransactionApprovalComponent,
        storage: transaction_approval,
        event: TransactionApprovalEvent
    );
    component!(path: WeeklyLimitComponent, storage: weekly_limit, event: WeeklyLimitEvent);
    component!(path: WhitelistComponent, storage: whitelist, event: WhitelistEvent);

    // Account
    #[abi(embed_v0)]
    impl PublicKeyImpl = AccountComponent::PublicKeyImpl<ContractState>;
    #[abi(embed_v0)]
    impl PublicKeyCamelImpl = AccountComponent::PublicKeyCamelImpl<ContractState>;
    #[abi(embed_v0)]
    impl DeclarerImpl = AccountComponent::DeclarerImpl<ContractState>;
    impl AccountInternalImpl = AccountComponent::InternalImpl<ContractState>;

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

    #[storage]
    struct Storage {
        #[substorage(v0)]
        account: AccountComponent::Storage,
        claims: LegacyMap<felt252, bool>,
        usdc_address: ContractAddress,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        transaction_approval: TransactionApprovalComponent::Storage,
        #[substorage(v0)]
        weekly_limit: WeeklyLimitComponent::Storage,
        #[substorage(v0)]
        whitelist: WhitelistComponent::Storage,
    }

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
    }

    //
    // Constructor
    //

    #[constructor]
    fn constructor(
        ref self: ContractState, public_key: felt252, approver: ContractAddress, limit: u256,
    ) {
        self.account.initializer(:public_key);
        self.transaction_approval.initializer(:approver);
        self.weekly_limit.initializer(:limit);
    }

    #[derive(Serde, Drop)]
    struct Claim {
        amount: u256,
        nonce: felt252,
        signature: Array<felt252>
    }
    #[starknet::interface]
    pub trait ClaimLinkTrait<T> {
        fn claim(ref self: T, claim: Claim);
        #[cfg(test)]
        fn set_usdc_address(ref self: T, usdc_address: ContractAddress);
    }
    #[abi(embed_v0)]
    impl ClaimLink of ClaimLinkTrait<ContractState> {
        fn claim(ref self: ContractState, claim: Claim) {
            let hash = PedersenImpl::new(claim.nonce);
            let hash = hash
                .update(claim.amount.low.into())
                .update(claim.amount.high.into())
                .finalize();
            assert!(!self.claims.read(hash), "Link already used");
            assert!(
                self.is_valid_signature(hash, claim.signature) == 'VALID',
                "Invalid signature for claim"
            );
            self.claims.write(hash, true);
            IERC20Dispatcher { contract_address: self.usdc_address.read() }
                .transfer(get_caller_address(), claim.amount);
        }

        #[cfg(test)]
        fn set_usdc_address(ref self: ContractState, usdc_address: ContractAddress) {
            self.usdc_address.write(usdc_address);
        }
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
    impl WeeklyLimit of IWeeklyLimit<ContractState> {
        fn get_weekly_limit(self: @ContractState) -> u256 {
            self.weekly_limit.get_weekly_limit()
        }
    }
}
