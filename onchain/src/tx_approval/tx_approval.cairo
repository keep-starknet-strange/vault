#[starknet::component]
pub mod TransactionApprovalComponent {
    use array::ArrayTrait;
    use ecdsa::check_ecdsa_signature;
    use openzeppelin::account::utils::execute_single_call;
    use openzeppelin::utils::serde::SerializedAppend;
    use option::OptionTrait;
    use starknet::{
        ContractAddress, StorageAddress, SyscallResultTrait, storage_read_syscall,
        storage_write_syscall, account::Call
    };
    use traits::TryInto;

    #[generate_trait]
    impl OriWouldntLikeItImpl of OriWouldntLikeItTrait {
        fn add(self: StorageAddress, rhs: u32) -> StorageAddress {
            TryInto::<felt252, StorageAddress>::try_into(self.into() + rhs.into())
                .expect('f felt252 => StorageAddress')
        }
    }

    #[storage]
    pub struct Storage {
        admin: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    #[event]
    pub enum Event {}

    #[generate_trait]
    impl InternalImpl<
        TContractState, +HasComponent<TContractState>
    > of InternalTrait<TContractState> {
        /// Sets the admin contract address. This should be called in the constructor
        /// of the contract.
        fn initializer(ref self: ComponentState<TContractState>, admin: ContractAddress) {
            self.admin.write(admin);
        }

        /// Register a transaction that requires an approval.
        ///
        /// # Arguments
        ///
        /// * `self` - Component storage.
        /// * `transaction` - The [Call] to register.
        /// * `transaction_hash` - The transaction hash.
        fn register_transaction(
            ref self: ComponentState<TContractState>,
            mut transaction: Call,
            transaction_hash: felt252
        ) {
            let mut i = 0;
            let transaction_hash: StorageAddress = transaction_hash.try_into().unwrap();
            storage_write_syscall(0, transaction_hash, transaction.to.into()).unwrap_syscall();
            storage_write_syscall(0, transaction_hash.add(1), transaction.selector)
                .unwrap_syscall();
            storage_write_syscall(0, transaction_hash.add(2), transaction.calldata.len().into())
                .unwrap_syscall();
            let begin_loop_value = transaction_hash.add(3);
            // If there is too much calldata it'll probably overwrite some storage vars here.
            while let Option::Some(val) = transaction
                .calldata
                .pop_front() {
                    storage_write_syscall(0, begin_loop_value.add(i), *val).unwrap_syscall();
                    i += 1;
                }
        }

        /// Returns the [Call] from a transaction hash if it exists.
        ///
        /// # Arguments
        ///
        /// * `self` - Component storage.
        /// * `transaction_hash` - The transaction hash.
        ///
        /// # Returns
        ///
        /// Returns the [Call] if the selector isn't 0.
        fn get_transaction(
            self: @ComponentState<TContractState>, transaction_hash: felt252
        ) -> Call {
            let transaction_hash: StorageAddress = transaction_hash.try_into().unwrap();
            let to: ContractAddress = storage_read_syscall(0, transaction_hash)
                .unwrap_syscall()
                .try_into()
                .unwrap();
            let selector = storage_read_syscall(0, transaction_hash.add(1)).unwrap_syscall();
            let mut calldata_len: u32 = storage_read_syscall(0, transaction_hash.add(2))
                .unwrap_syscall()
                .try_into()
                .unwrap();
            let begin_loop_value = transaction_hash.add(3);
            let mut calldata = array![];
            let mut i = 0;
            while i < calldata_len {
                calldata.append(storage_read_syscall(0, begin_loop_value.add(i)).unwrap_syscall());
                i += 1;
            };

            Call { to, selector, calldata: calldata.span() }
        }

        /// Approve a transaction request. This will check the signature of the 
        /// admin against the transaction hash.
        ///
        /// # Arguments
        ///
        /// * `self` - Component storage.
        /// * `signature` - The admin signature to approve the transaction.
        /// * `transaction_hash` - The transaction hash.
        ///
        /// # Returns
        ///
        /// Returns the result of the [Call] execution.
        ///
        /// # Panic
        ///
        /// Panics if the target contract isn't deployed, if the selector isn't found,
        /// if the signature is incorrect and if the target selector is 0
        /// (if selector is 0 we consider that this transaction was not found)
        fn approve_transaction(
            self: @ComponentState<TContractState>,
            signature: Array<felt252>,
            transaction_hash: felt252
        ) -> Span<felt252> {
            let mut calldata = array![transaction_hash];
            calldata.append_serde(signature.span());
            let mut is_valid_sig = execute_single_call(
                Call {
                    to: self.admin.read(),
                    selector: selector!("is_valid_signature"),
                    calldata: calldata.span()
                }
            );
            assert!(is_valid_sig.pop_front().unwrap() == @'VALID', "Invalid admin signature");
            let call = self.get_transaction(transaction_hash);
            assert!(call.selector != 0, "Transaction doesn't exist");
            execute_single_call(call)
        }
    }
}

#[cfg(test)]
mod test {
    use core::starknet::SyscallResultTrait;
    use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
    use openzeppelin::utils::serde::SerializedAppend;
    use starknet::{ContractAddress, contract_address_const, account::Call};
    use traits::{Into, TryInto};
    use vault::contracts::account::Account;
    use vault::tx_approval::tx_approval::TransactionApprovalComponent::InternalTrait;

    #[starknet::interface]
    trait TestExternal<T> {
        fn register_transaction(ref self: T, transaction: Call, transaction_hash: felt252);

        fn get_transaction(self: @T, transaction_hash: felt252) -> Call;
        fn approve_transaction(
            self: @T, signature: Array<felt252>, transaction_hash: felt252
        ) -> Span<felt252>;
    }

    #[starknet::contract]
    mod mock_contract {
        use starknet::ContractAddress;
        use starknet::account::Call;
        use super::super::{
            TransactionApprovalComponent, TransactionApprovalComponent::InternalTrait
        };
        component!(
            path: TransactionApprovalComponent, storage: approval, event: TransactionApprovalEvent
        );

        #[event]
        #[derive(Drop, starknet::Event)]
        enum Event {
            #[flat]
            TransactionApprovalEvent: TransactionApprovalComponent::Event,
        }
        #[storage]
        struct Storage {
            #[substorage(v0)]
            approval: TransactionApprovalComponent::Storage,
        }
        #[constructor]
        fn constructor(ref self: ContractState, admin: ContractAddress) {
            self.approval.initializer(admin);
        }
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
        super::TransactionApprovalComponent::ComponentState<mock_contract::ContractState>;

    fn COMPONENT() -> ComponentState {
        super::TransactionApprovalComponent::component_state_for_testing()
    }

    /// Deploys a mock erc20 contract.
    fn deploy_erc20(recipient: ContractAddress, initial_supply: u256) -> IERC20Dispatcher {
        let name = 0;
        let symbol = 0;
        let mut calldata = array![];

        calldata.append_serde(name);
        calldata.append_serde(symbol);
        calldata.append_serde(initial_supply);
        calldata.append_serde(recipient);

        let (address, _) = starknet::deploy_syscall(
            openzeppelin::presets::ERC20::TEST_CLASS_HASH.try_into().unwrap(),
            0,
            calldata.span(),
            false
        )
            .unwrap_syscall();
        IERC20Dispatcher { contract_address: address }
    }

    /// Deploys the tx approval contract + admin.
    fn setup_contracts() -> (TestExternalDispatcher, ContractAddress) {
        // private_key: 1234,
        // public_key: 0x1f3c942d7f492a37608cde0d77b884a5aa9e11d2919225968557370ddb5a5aa,
        // r: 0x6c8be1fb0fb5c730fbd7abaecbed9d980376ff2e660dfcd157e158d2b026891,
        // s: 0x76b4669998eb933f44a59eace12b41328ab975ceafddf92602b21eb23e22e35 

        // Deploy admin account with public key and weekly limit and admin is 0.
        let (admin, _) = starknet::deploy_syscall(
            Account::TEST_CLASS_HASH.try_into().unwrap(),
            0,
            array![0x1f3c942d7f492a37608cde0d77b884a5aa9e11d2919225968557370ddb5a5aa, 0, 2, 2]
                .span(),
            true
        )
            .unwrap_syscall();
        // Deploy approval mock contract with admin address.
        let (approval_contract, _) = starknet::deploy_syscall(
            mock_contract::TEST_CLASS_HASH.try_into().unwrap(), 0, array![admin.into()].span(), true
        )
            .unwrap_syscall();
        (TestExternalDispatcher { contract_address: approval_contract }, admin)
    }

    #[test]
    fn test_register_transaction() {
        let mut component = COMPONENT();
        // private_key: 1234,
        // public_key: 0x1f3c942d7f492a37608cde0d77b884a5aa9e11d2919225968557370ddb5a5aa,
        let transaction_hash = 0x601d3d2e265c10ff645e1554c435e72ce6721f0ba5fc96f0c650bfc6231191a;
        // r: 0x6c8be1fb0fb5c730fbd7abaecbed9d980376ff2e660dfcd157e158d2b026891,
        // s: 0x76b4669998eb933f44a59eace12b41328ab975ceafddf92602b21eb23e22e35 
        let recipient = contract_address_const::<0x123>();
        let to = contract_address_const::<0x1>();

        let calldata = array![recipient.into(), 200, 0];
        let call = Call { to, selector: selector!("transfer"), calldata: calldata.span() };
        let expected_call = Call { to, selector: call.selector, calldata: calldata.span() };
        component.register_transaction(call, transaction_hash);
        let res = component.get_transaction(transaction_hash);
        assert_eq!(expected_call.to, res.to, "Invalid contract address");
        assert_eq!(expected_call.selector, res.selector, "Invalid selector");
        assert_eq!(expected_call.calldata, res.calldata, "Invalid calldata");
    }

    #[test]
    fn test_approve_transaction() {
        let (approval_contract_dispatcher, admin) = setup_contracts();
        // Deploy erc20 mock token.
        let erc20_dispatcher = deploy_erc20(approval_contract_dispatcher.contract_address, 1000);
        // Mock tx hash.
        let transaction_hash = 0x601d3d2e265c10ff645e1554c435e72ce6721f0ba5fc96f0c650bfc6231191a;
        // Craft tx calldata to call `transfer`.
        // recipient, amount low, amount high.
        let calldata = array![admin.into(), 200, 0];
        // The actual call to ask approval for.
        let call = Call {
            to: erc20_dispatcher.contract_address,
            selector: selector!("transfer"),
            calldata: calldata.span()
        };

        // Register the approval request.
        approval_contract_dispatcher.register_transaction(call, transaction_hash);
        // Approve the request with the admin signature.
        approval_contract_dispatcher
            .approve_transaction(
                array![
                    0x6c8be1fb0fb5c730fbd7abaecbed9d980376ff2e660dfcd157e158d2b026891,
                    0x76b4669998eb933f44a59eace12b41328ab975ceafddf92602b21eb23e22e35
                ],
                transaction_hash
            );
    }

    #[test]
    #[should_panic(expected: ("Invalid admin signature", 'ENTRYPOINT_FAILED'))]
    fn test_approve_transaction_invalid_admin_sig() {
        let (approval_contract_dispatcher, admin) = setup_contracts();
        // Deploy erc20 mock token.
        let erc20_dispatcher = deploy_erc20(approval_contract_dispatcher.contract_address, 1000);
        // Mock tx hash.
        let transaction_hash = 0x601d3d2e265c10ff645e1554c435e72ce6721f0ba5fc96f0c650bfc6231191a;
        // Craft tx calldata to call `transfer`.
        // recipient, amount low, amount high.
        let calldata = array![admin.into(), 200, 0];
        // The actual call to ask approval for.
        let call = Call {
            to: erc20_dispatcher.contract_address,
            selector: selector!("transfer"),
            calldata: calldata.span()
        };

        // Register the approval request.
        approval_contract_dispatcher.register_transaction(call, transaction_hash);
        // Approve the request with an invalid admin signature.
        approval_contract_dispatcher.approve_transaction(array![1, 1], transaction_hash);
    }

    #[test]
    #[should_panic(expected: ('CONTRACT_NOT_DEPLOYED', 'ENTRYPOINT_FAILED'))]
    fn test_approve_transaction_undeployed_contract() {
        let (approval_contract_dispatcher, admin) = setup_contracts();
        // Mock tx hash.
        let transaction_hash = 0x601d3d2e265c10ff645e1554c435e72ce6721f0ba5fc96f0c650bfc6231191a;
        // Craft tx calldata to call `transfer`.
        // recipient, amount low, amount high.
        let calldata = array![admin.into(), 200, 0];
        // The actual call to ask approval for to a contract that is not deployed.
        let call = Call {
            to: contract_address_const::<0x123>(),
            selector: selector!("transfer"),
            calldata: calldata.span()
        };

        // Register the approval request.
        approval_contract_dispatcher.register_transaction(call, transaction_hash);
        // Approve the request with the admin signature.
        approval_contract_dispatcher
            .approve_transaction(
                array![
                    0x6c8be1fb0fb5c730fbd7abaecbed9d980376ff2e660dfcd157e158d2b026891,
                    0x76b4669998eb933f44a59eace12b41328ab975ceafddf92602b21eb23e22e35
                ],
                transaction_hash
            );
    }

    #[test]
    #[should_panic(expected: ('ENTRYPOINT_NOT_FOUND', 'ENTRYPOINT_FAILED'))]
    fn test_approve_transaction_invalid_selector() {
        let (approval_contract_dispatcher, admin) = setup_contracts();
        // Deploy erc20 mock token.
        let erc20_dispatcher = deploy_erc20(approval_contract_dispatcher.contract_address, 1000);
        // Mock tx hash.
        let transaction_hash = 0x601d3d2e265c10ff645e1554c435e72ce6721f0ba5fc96f0c650bfc6231191a;
        // Craft tx calldata to call `transfer`.
        // recipient, amount low, amount high.
        let calldata = array![admin.into(), 200, 0];
        // The actual call to ask approval for to a contract that is not deployed.
        let call = Call {
            to: erc20_dispatcher.contract_address,
            selector: selector!("transfoor"),
            calldata: calldata.span()
        };

        // Register the approval request.
        approval_contract_dispatcher.register_transaction(call, transaction_hash);
        // Approve the request with the admin signature.
        approval_contract_dispatcher
            .approve_transaction(
                array![
                    0x6c8be1fb0fb5c730fbd7abaecbed9d980376ff2e660dfcd157e158d2b026891,
                    0x76b4669998eb933f44a59eace12b41328ab975ceafddf92602b21eb23e22e35
                ],
                transaction_hash
            );
    }

    #[test]
    #[should_panic(expected: ("Transaction doesn't exist", 'ENTRYPOINT_FAILED'))]
    fn test_approve_transaction_inexstant_tx() {
        let (approval_contract_dispatcher, admin) = setup_contracts();
        // Deploy erc20 mock token.
        let erc20_dispatcher = deploy_erc20(approval_contract_dispatcher.contract_address, 1000);
        // Mock tx hash.
        let transaction_hash = 0x1;
        // Craft tx calldata to call `transfer`.
        // recipient, amount low, amount high.
        let calldata = array![admin.into(), 200, 0];
        // The actual call to ask approval for to a contract that is not deployed.
        let call = Call {
            to: erc20_dispatcher.contract_address,
            selector: selector!("transfoor"),
            calldata: calldata.span()
        };

        // Register the approval request.
        approval_contract_dispatcher.register_transaction(call, transaction_hash);
        // Approve the request with the admin signature.
        approval_contract_dispatcher
            .approve_transaction(
                array![
                    0x6c8be1fb0fb5c730fbd7abaecbed9d980376ff2e660dfcd157e158d2b026891,
                    0x76b4669998eb933f44a59eace12b41328ab975ceafddf92602b21eb23e22e35
                ],
                0x601d3d2e265c10ff645e1554c435e72ce6721f0ba5fc96f0c650bfc6231191a
            );
    }
}
