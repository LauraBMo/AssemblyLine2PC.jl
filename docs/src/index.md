```@meta
CurrentModule = AssemblyLine2PC
```

# AssemblyLine2PC

Welcome to the documentation portal for `AssemblyLine2PC.jl`, the Julia toolkit for
analyzing Assembly Line 2 production graphs.
The package ships the full recipe data set together with helpers for computing material requirements, sizing mining fleets, and rendering readable build reports.

Use the navigation sidebar to explore:

- **Architecture** – how the data graph is constructed and how to extend it.
- **Performance tuning** – tips for squeezing the most out of the traversal and
  reporting utilities.
- **Tutorials** – literate, executable walkthroughs that demonstrate multi-node
  coordination, resilience strategies, and metrics instrumentation.
- **API reference** – detailed signatures and docstrings for public entry points.

## Quick start

Naviagate recipe for AI Robot Bomber ("AIRBomber" in [`Data.jl`](https://github.com/LauraBMo/AssemblyLine2PC.jl/blob/main/src/Data.jl)) at max theoretical speed for your given limit of starters:

```julia
julia> using AssemblyLine2PC: topspeed, nminers, viewgraph

julia> VG = viewgraph(tree);

julia> airb = "AIRBomber"

julia> max_miners = 310 + 46*2  # Your starters limit for the job. 

julia> VG(airb; miners = max_miners)
# PrettyTables report showing intermediate makers, pack ratios, and raw demand…

julia> VG(airb, 4, 6; miners = max_miners)
```

Ready to dive deeper? Start with the [architecture tour](@ref) to understand how the
graph is built, then try the hands-on [tutorials](@ref tutorial-hub).
