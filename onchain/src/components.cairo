mod freeze;
mod outside_execution;
mod spending_limit;
mod tx_approval;
mod whitelist;

use freeze::freeze::AdminComponent;
use outside_execution::outside_execution::OutsideExecutionComponent;
use spending_limit::weekly::weekly::WeeklyLimitComponent;
use tx_approval::tx_approval::TransactionApprovalComponent;
use whitelist::whitelist::WhitelistComponent;
