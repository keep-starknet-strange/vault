use starknet::{ClassHash, ContractAddress};

#[starknet::interface]
trait IFactory<TState> {
    fn set_account_class_hash(ref self: TState, account_class_hash: ClassHash);
    fn deploy_account(ref self: TState, salt: felt252, pub_key_x: u256, pub_key_y: u256);
}
