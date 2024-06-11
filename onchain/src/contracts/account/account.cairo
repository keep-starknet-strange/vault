#[starknet::contract(account)]
mod VaultAccount {
    use core::box::BoxTrait;
    use core::hash::Hash;
    use core::option::OptionTrait;
    use core::result::ResultTrait;
    use core::starknet::{get_tx_info, SyscallResultTrait};
    use openzeppelin::account::utils::execute_calls;
    use openzeppelin::account::AccountComponent;
    use openzeppelin::account::interface::ISRC6;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin::utils::cryptography::snip12::{OffchainMessageHashImpl, StructHash};
    use starknet::ContractAddress;
    use starknet::account::Call;
    use starknet::secp256_trait::is_valid_signature;
    use starknet::secp256r1::{Secp256r1Point, Secp256r1Impl};
    use starknet::{
        get_caller_address, contract_address_const, get_contract_address, get_block_timestamp,
        call_contract_syscall
    };
    use vault::components::TransactionApprovalComponent;
    use vault::components::WeeklyLimitComponent;
    use vault::components::WhitelistComponent;
    use vault::components::spending_limit::weekly::interface::IWeeklyLimit;
    use vault::contracts::account::interface::{IVaultAccount, IVaultAccountFunctionnalities};
    use vault::utils::{
        claim::Claim,
        outside_execution::{
            OutsideExecution, IOutsideExecution, hash_outside_execution_message,
            ERC165_OUTSIDE_EXECUTION_INTERFACE_ID
        }
    };
    use vault::utils::snip12::SNIP12MetadataImpl;

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

    //
    // Storage
    //

    #[storage]
    struct Storage {
        #[substorage(v0)]
        account: AccountComponent::Storage,
        claims: LegacyMap<felt252, bool>,
        usdc_address: ContractAddress,
        /// Keeps track of used nonces for outside transactions (`execute_from_outside`)
        outside_nonces: LegacyMap<felt252, bool>,
        public_key: (u256, u256),
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        transaction_approval: TransactionApprovalComponent::Storage,
        #[substorage(v0)]
        weekly_limit: WeeklyLimitComponent::Storage,
        #[substorage(v0)]
        whitelist: WhitelistComponent::Storage,
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
        TransactionExecuted: TransactionExecuted,
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
    impl ClaimLink of IVaultAccountFunctionnalities<ContractState> {
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
        fn execute_from_outside(
            ref self: ContractState, outside_execution: OutsideExecution, signature: Array<felt252>
        ) -> Array<Span<felt252>> {
            // Checks
            if outside_execution.caller.into() != 'ANY_CALLER' {
                assert(get_caller_address() == outside_execution.caller, 'Invalid caller');
            }

            let block_timestamp = get_block_timestamp();
            assert(outside_execution.execute_after < block_timestamp, 'Too early');
            assert(block_timestamp < outside_execution.execute_before, 'Too late');

            let nonce = outside_execution.nonce;

            assert(!self.outside_nonces.read(nonce), 'Already used nonce');

            let outside_tx_hash = hash_outside_execution_message(@outside_execution);

            let calls = outside_execution.calls;

            assert!(
                self.is_valid_signature(outside_tx_hash, signature) == starknet::VALIDATED,
                "Invalid signature for paymaster"
            );

            // Effects
            self.outside_nonces.write(nonce, true);

            // Interactions
            let retdata = execute_multicall(calls);

            self.emit(TransactionExecuted { hash: outside_tx_hash, response: retdata.span() });
            retdata
        }

        fn get_outside_execution_message_hash(
            self: @ContractState, outside_execution: OutsideExecution
        ) -> felt252 {
            hash_outside_execution_message(@outside_execution)
        }

        fn is_valid_outside_execution_nonce(self: @ContractState, nonce: felt252) -> bool {
            !self.outside_nonces.read(nonce)
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

    /// @notice Emitted when the account executes a transaction
    /// @param hash The transaction hash
    /// @param response The data returned by the methods called
    #[derive(Drop, starknet::Event)]
    struct TransactionExecuted {
        #[key]
        hash: felt252,
        response: Span<Span<felt252>>
    }

    fn execute_multicall(mut calls: Span<Call>) -> Array<Span<felt252>> {
        let mut result: Array<Span<felt252>> = array![];
        let mut idx = 0;
        loop {
            match calls.pop_front() {
                Option::Some(call) => {
                    match call_contract_syscall(*call.to, *call.selector, *call.calldata) {
                        Result::Ok(retdata) => {
                            result.append(retdata);
                            idx = idx + 1;
                        },
                        Result::Err(revert_reason) => {
                            let mut data = array!['Call failed', idx];
                            data.append_all(revert_reason);
                            panic(data);
                        },
                    }
                },
                Option::None => { break; },
            }
        };
        result
    }

    #[generate_trait]
    impl ArrayExtImpl<T, impl TDrop: Drop<T>> of ArrayExtTrait<T> {
        fn append_all(ref self: Array<T>, mut value: Array<T>) {
            loop {
                match value.pop_front() {
                    Option::Some(item) => self.append(item),
                    Option::None => { break; },
                }
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
}
