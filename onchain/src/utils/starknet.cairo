use core::Clone;
use starknet::account::Call;

impl CallClone of Clone<Call> {
    #[inline(always)]
    fn clone(self: @Call) -> Call {
        Call { to: *self.to, selector: *self.selector, calldata: self.calldata.clone(), }
    }
}
