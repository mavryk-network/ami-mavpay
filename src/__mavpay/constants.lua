return {
    protected_files = {
        "config.hjson",
        "remote_signer.hjson",
        "payout_wallet_private.key",
        "reports/"
    },
    configurations = {
        config = "https://raw.githubusercontent.com/mavryk-network/mavpay/main/docs/configuration/config.default.hjson",
        ["remote_signer"] =
        "https://raw.githubusercontent.com/mavryk-network/mavpay/main/docs/configuration/remote_signer.sample.hjson",
        ["payout_wallet_private_key"] =
        "https://raw.githubusercontent.com/mavryk-network/mavpay/main/docs/configuration/payout_wallet_private.sample.key"
    }
}
