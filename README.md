# Doxa

**Doxa is the simplest way to fair-launch tokens with instant liquidity. Programmed for no pre-sales, no rug-pulls.**

> **Note**: This protocol is **NOT** audited. Please use your own discretion.

Doxa consists of:

- **DoxaBondingCurve**: An ERC-20 smart contract that sells tokens on the following bonding curve:

```
F(n) = 10,000 * (0.997)^n
```

where _n_ is the amount of ether spent buying tokens, modulo 1 ether. The contract starts by selling 10,000 tokens in exchange for the first 1 ether, and 0.3% less tokens per next ether.

On every token purchase, the contract deposits all its ether and proportionate tokens as liquidity in a Uniswap V2 AMM Pool,
up till _n=100_. After that, the contract uses all its ether balance to buy back the token on the AMM and burning it, creating
upward price pressure.

- **DoxaFactory**: A factory for deploying `DoxaBondingCurve` contracts.

## Deployments

**Doxa** is live on [Base](https://basescan.org/) and all contracts are verified.

- `DoxaFactory`: [0x8191bf8672b7142de7b2ff8eeded033a672d17b4](https://basescan.org/address/0x8191bf8672b7142de7b2ff8eeded033a672d17b4)
- `DoxaBondingCurve` implementation: [0xB6cF389aC2B12dA0C5C648434176DfCc13b8Bba0](https://basescan.org/address/0xB6cF389aC2B12dA0C5C648434176DfCc13b8Bba0)

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ make test FORK_URL=<Base Mainnet RPC>
```

### Format

```shell
$ forge fmt
```
