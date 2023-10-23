## Seaport 1.6 Development Repo

Welcome to the home of Seaport 1.6 development. For the most part, it's safe to treat this repo like you'd treat [Seaport](https://github.com/ProjectOpenSea/seaport). The documentation found there will substantialy serve for this repo.

### Structure

The [`./src`](./src) directory is broken up into [`/core`](./src/core), [`/main`](./src/main), [`/sol`](./src/sol), and [`/types`](./src/types), which closely correspond to the [seaport-core](https://github.com/ProjectOpenSea/seaport-core), ["main"](https://github.com/ProjectOpenSea/seaport), [seaport-sol](https://github.com/ProjectOpenSea/seaport-sol), and [seaport-types](https://github.com/ProjectOpenSea/seaport-types) repos, respectively.

The remappings in the [foundry.toml](./foundry.toml) file are configured to use the same import style found in the production repos (e.g. `from "seaport-types/src/..."`), but instead of pointing to a dependency in `./lib`, they point to some portion of `./src`.  The idea is to duplicate the experience of working in [Seaport](https://github.com/ProjectOpenSea/seaport), but without the headache of keeping cross-repo changes synced. The tradeoff is that comile times will be longer, but the intial experience of working across multiple repos and fighting git submodules strongly suggested that this approach is preferable.

When 1.6 is ready, we'll create 1.6 branches on all of the seaport repos and move the changes over from this repo to those repos.

### Differences between this repo and the production repos

- This repo has the `authorizeOrder` interface added to zones.
- This repo uses 0.8.21 instead of 0.8.17.
- Some files that appear in multiple repos, such as the [Transfer](https://github.com/ProjectOpenSea/seaport-core/blob/main/src/helpers/TransferHelper.sol) [Helper](https://github.com/ProjectOpenSea/seaport/blob/main/contracts/helpers/TransferHelper.sol) have been removed or modified to inherit from a single source of truth.
- Some files were lightly jiggled around internally to avoid yul stack too deep errors during the optimized build.
- The Hardhat tests are gone. If we need to add them back, we can.
- Styling is now handled with `forge fmt` instead of prettier. [The `forge fmt` bug affecting functions that return functions](https://github.com/foundry-rs/foundry/issues/4080) still exists, but it's possible to work around it, which this repo now does. It's recommended to handle the issue with `// forgefmt: disable-start` and `// forgefmt: disable-end` until the issue is fixed.
