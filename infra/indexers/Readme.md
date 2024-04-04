# Indexers Setup

Current Status :

| Indexer        | Dev | Prod |
| -------------- | --- | ---- |
| USDC::Transfer | ✅  |      |
| USDC::Balances | ✅  |      |

To run the indexer :

```sh
AUTH_TOKEN=<AUTH_TOKEN> docker-compose up
```

To configure the k8s indexer :

```sh
cp envs.example.yaml envs.yaml
kubectl apply -f envs.yaml
```
