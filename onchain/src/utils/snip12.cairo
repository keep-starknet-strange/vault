use openzeppelin::utils::cryptography::snip12::SNIP12Metadata;

impl SNIP12MetadataImpl of SNIP12Metadata {
    fn name() -> felt252 {
        'Vault'
    }

    fn version() -> felt252 {
        0
    }
}
