mod freeze;
mod spending_limit;
mod tx_approval;
mod whitelist;

use freeze::freeze::AdminComponent;
use spending_limit::weekly::weekly::WeeklyLimitComponent;
use tx_approval::tx_approval::TransactionApprovalComponent;
use whitelist::whitelist::WhitelistComponent;
