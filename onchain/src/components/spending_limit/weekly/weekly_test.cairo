use super::interface::IWeeklyLimit;

use super::weekly::WeeklyLimitComponent::InternalTrait;
use super::weekly_mock::{WeeklyMock, COMPONENT};

#[test]
fn test_is_below_limit() {
    let mut component = COMPONENT();

    // 0 <= 0
    assert!(component.is_below_limit(0));

    // 1 <= 0
    assert!(!component.is_below_limit(1));

    // Set limit to 2
    component.initializer(2);

    // 1 <= 2
    assert!(component.is_below_limit(1));

    // 3 <= 2
    assert!(!component.is_below_limit(3));
}

#[test]
fn test_is_allowed_simple() {
    starknet::testing::set_block_timestamp(8626176);

    let mut component = COMPONENT();

    // NO PREVIOUS EXPENSES SO THE VALUE IS THE ONLY THING CONSIDERED.
    // Not inialized so 0 <= 0
    assert!(component.is_allowed_to_spend(0));

    // 1 <= 0
    assert!(!component.is_allowed_to_spend(1));

    // Set limit to 2
    component.initializer(2);

    // 1 <= 2
    assert!(component.is_allowed_to_spend(1));

    // 3 <= 2
    assert!(!component.is_allowed_to_spend(3));
}
