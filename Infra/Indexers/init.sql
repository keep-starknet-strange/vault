create table transferUSDC(
    network text,
    block_hash text,
    block_number bigint,
    transaction_hash text,
    transfer_id text unique primary key,
    from_address text,
    to_address text,
    amount text,
    created_at timestamp default current_timestamp,
    _cursor bigint
);