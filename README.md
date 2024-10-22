# Doxa

**Doxa is the simplest way to fair-launch tokens with instant liquidity. No pre-sales. No rug-pulls.**

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

- `DoxaFactory`: [0x1d5756eF591743E02c2FdDa287e34B9846017CFc](https://basescan.org/address/0x1d5756eF591743E02c2FdDa287e34B9846017CFc)
- `DoxaBondingCurve` implementation: [0xF907FdC9437E2B72D155747DBDd4C2905AB4A957](https://basescan.org/address/0xF907FdC9437E2B72D155747DBDd4C2905AB4A957)

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
