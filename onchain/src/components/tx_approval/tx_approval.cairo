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

    //
    // Storage
    //

    #[storage]
    pub struct Storage {
        approver: ContractAddress,
    }

    //
    // Events
    //

    #[derive(Drop, starknet::Event)]
    #[event]
    pub enum Event {}

    //
    // Internals
    //

    #[generate_trait]
    impl InternalImpl<
        TContractState, +HasComponent<TContractState>
    > of InternalTrait<TContractState> {
        /// Sets the approver contract address. This should be called in the constructor
        /// of the contract.
        fn initializer(ref self: ComponentState<TContractState>, approver: ContractAddress) {
            self.approver.write(approver);
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
            let transaction_hash: StorageAddress = transaction_hash.try_into().unwrap();

            storage_write_syscall(0, transaction_hash, transaction.to.into()).unwrap_syscall();
            storage_write_syscall(0, transaction_hash.add(1), transaction.selector)
                .unwrap_syscall();
            storage_write_syscall(0, transaction_hash.add(2), transaction.calldata.len().into())
                .unwrap_syscall();

            let begin_loop_value = transaction_hash.add(3);
            let mut i = 0;

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
        /// approver against the transaction hash.
        ///
        /// # Arguments
        ///
        /// * `self` - Component storage.
        /// * `signature` - The approver signature to approve the transaction.
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
                    to: self.approver.read(),
                    selector: selector!("is_valid_signature"),
                    calldata: calldata.span()
                }
            );

            assert!(
                is_valid_sig.pop_front().unwrap() == @starknet::VALIDATED,
                "Invalid approver signature"
            );

            let call = self.get_transaction(transaction_hash);

            assert!(call.selector != 0, "Transaction doesn't exist");

            execute_single_call(call)
        }
    }

    //
    // Helpers
    //

    #[generate_trait]
    impl OriWouldntLikeItImpl of OriWouldntLikeItTrait {
        fn add(self: StorageAddress, rhs: u32) -> StorageAddress {
            TryInto::<felt252, StorageAddress>::try_into(self.into() + rhs.into())
                .expect('f felt252 => StorageAddress')
        }
    }
}
