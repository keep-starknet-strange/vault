use starknet::account::Call;

#[starknet::interface]
trait IWeeklyLimit<TState> {
    fn get_weekly_limit(self: @TState) -> u256;
}
