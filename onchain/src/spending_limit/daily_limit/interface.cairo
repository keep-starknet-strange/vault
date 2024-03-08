use starknet::account::Call;

#[starknet::interface]
trait IDailyLimit<TState> {
    fn get_daily_limit(self: @TState) -> u256;

    fn set_daily_limit(ref self: TState, new_limit: u256);
}
