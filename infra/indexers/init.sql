create table transfer_usdc(
    network text,
    block_hash text,
    block_number bigint,
    block_timestamp timestamp,
    transaction_hash text,
    transfer_id text unique primary key,
    from_address text,
    to_address text,
    amount text,
    created_at timestamp default current_timestamp,
    _cursor bigint
);

create table balance_usdc(
    network text,
    block_number bigint,
    block_timestamp timestamp,
    address text,
    balance text,
    _cursor bigint
);
