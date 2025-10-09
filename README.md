# AssemblyLine2PC.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://LauraBMo.github.io/AssemblyLine2PC.jl/stable/) [![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://LauraBMo.github.io/AssemblyLine2PC.jl/dev/) [![Build Status](https://github.com/LauraBMo/AssemblyLine2PC.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/LauraBMo/AssemblyLine2PC.jl/actions/workflows/CI.yml?query=branch%3Amain) [![Coverage](https://codecov.io/gh/LauraBMo/AssemblyLine2PC.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/LauraBMo/AssemblyLine2PC.jl)

> Tools for exploring the resource graph of **Assembly Line 2** (PC) and planning hyper-efficient factories.

AssemblyLine2PC.jl ships the crafting tree for Assembly Line 2 together with utilities to quantify production requirements, highlight bottlenecks, and render readable reports directly from Julia. Instead of transcribing blueprints by hand, you can load the complete data graph, ask for the raw-material footprint of any item, and iterate on layouts before booting the game.

Explore the [stable documentation](https://LauraBMo.github.io/AssemblyLine2PC.jl/stable/) for API overviews and the [development documentation](https://LauraBMo.github.io/AssemblyLine2PC.jl/dev/) for the latest features.

## Why visualize the factory graph?

### The challenge of late-game planning
High-tier Assembly Line 2 machines intertwine dozens of subassemblies and radioactive refineries. Tracking how many miners, cutters, and makers are required to sustain a target output quickly becomes error prone. Missing a single intermediate recipe can cascade into hours of manual rework.

### How this package helps
AssemblyLine2PC.jl builds a directed recipe graph from the game's data and offers:

- **Material accounting** – traverse the graph and compute raw-resource demand for any item or production rate.
- **Throughput insights** – estimate miner counts and top production speeds with helpers such as `nminers` and `topspeed`.
- **Readable breakdowns** – format recipe tables with PrettyTables, highlight transformers, and surface fuel consumption for radioactive makers.
- **Graph tooling** – leverage `Graphs.jl`/`MetaGraphsNext.jl` utilities for custom analyses or alternative visualizations.

## Quick start

### 1. Install the package
```julia
julia> import Pkg
julia> Pkg.add("AssemblyLine2PC")
```

Working from a local clone? Activate the project environment and instantiate dependencies:

```julia
julia> import Pkg
julia> Pkg.activate("/path/to/AssemblyLine2PC.jl")
julia> Pkg.instantiate()
```

### 2. Inspect a recipe
```julia
julia> using AssemblyLine2PC

julia> tree = datatree();  # build the complete crafting graph

julia> AssemblyLine2PC.tracked_materials  # ordered list of raw resources and fuel

julia> Dict(zip(AssemblyLine2PC.tracked_materials, tree["ElectricEngine"]))  # per-resource demand

julia> AssemblyLine2PC.cost(tree, "ElectricEngine")  # total raw-material units
```

The tuple order matches `tracked_materials`, so zipping them helps produce a readable dictionary. The scalar `cost` helper returns the total raw-material sum for the chosen item.

### 3. Plan production throughput
```julia
julia> using AssemblyLine2PC: topspeed, nminers, viewgraph

julia> miners_needed = nminers("ElectricEngine", 4)  # 4 units per second

julia> topspeed("ElectricEngine", miners_needed)  # should echo ~4.0 if miners are sufficient

julia> VG = viewgraph(tree);

julia> VG("ElectricEngine")
# PrettyTables report showing intermediate makers, pack ratios, and raw demand…
```

`viewgraph` prints a colorized table that surfaces the most demanding intermediates, while `nminers` and `topspeed` help you size ore extraction for a target output rate. Combine these with Julia's `Plots.jl`, `GraphPlot.jl`, or your own scripts to craft dashboards for your megabase.

### 4. Configure data for distributed exploration
Planning multiple target items? Spin up workers with Julia's `Distributed` standard library and reuse the same data graph:

```julia
julia> using Distributed
julia> addprocs(4)

julia> @everywhere using AssemblyLine2PC

julia> items = ["AtomicBomb", "AIRBomber", "NProcessor"]

julia> @distributed (vcat) for item in items
           tree = datatree()
           (item, AssemblyLine2PC.cost(tree, item))
       end
```

Because `datatree()` is deterministic, each worker can build the same graph locally after calling `Pkg.instantiate()`. This makes it easy to spread sensitivity analyses or optimization scripts across cores or nodes.

## Factory graph overview
```mermaid
flowchart LR
    RM[Raw materials] --> TF[Transformers]
    TF --> MK1[Early makers]
    MK1 --> MK2[Advanced makers]
    MK2 --> MK3[Late-game assemblies]
    MK3 --> RAD[Radioactive makers]
    RAD --> Goals[Target item throughput]
    RM -.-> Fuel[Fuel consumption tracking]
    Fuel --> RAD
```

The graph encodes every recipe as a vertex with weighted edges showing ingredient ratios. Transformers (wire, liquid, gear, plate) feed makers, which in turn build late-game robotics and nuclear technology. Fuel requirements are annotated separately so radioactive chains can be planned alongside raw ore demand.

## Project resources
- 📘 [Stable Documentation](https://LauraBMo.github.io/AssemblyLine2PC.jl/stable/)
- 🧪 [Development Documentation](https://LauraBMo.github.io/AssemblyLine2PC.jl/dev/)
- 🧾 [CITATION.bib](./CITATION.bib) — cite this project in academic work.
- 📄 [License](./LICENSE)

## Governance and community

### Contributing
We welcome issues, discussions, and pull requests. To contribute:

1. Fork the repository and create feature branches from `main`.
2. Run the automated test suite (`julia --project -e 'using Pkg; Pkg.test()'`) before opening a pull request.
3. Document in-game assumptions (item rates, optional upgrades, etc.) so reviewers can reproduce your scenario.

### Code of conduct
This project follows the [Julia Community Standards](https://julialang.org/community/standards/). By participating, you agree to uphold a welcoming, inclusive environment.

### Release cadence
The `main` branch tracks active development. Tagged releases follow [Semantic Versioning](https://semver.org/) once new data drops or quality-of-life tooling stabilizes. Expect periodic patch releases for recipe corrections and documentation improvements.

### Stay in touch
- File bugs, feature ideas, or data corrections in the [issue tracker](https://github.com/LauraBMo/AssemblyLine2PC.jl/issues).
- Share factory screenshots or tooling ideas on the Julia community forums with the `assemblyline2pc` tag.

Happy factory building!
