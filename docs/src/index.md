```@meta
CurrentModule = AssemblyLine2PC
```

# AssemblyLine2PC

Welcome to the documentation portal for `AssemblyLine2PC.jl`, the Julia toolkit for
analyzing Assembly Line 2 production graphs. The package ships the full recipe data
set together with helpers for computing material requirements, sizing mining fleets,
and rendering readable build reports.

Use the navigation sidebar to explore:

- **Architecture** – how the data graph is constructed and how to extend it.
- **Performance tuning** – tips for squeezing the most out of the traversal and
  reporting utilities.
- **Tutorials** – literate, executable walkthroughs that demonstrate multi-node
  coordination, resilience strategies, and metrics instrumentation.
- **API reference** – detailed signatures and docstrings for public entry points.

## Quick start

```julia
julia> using AssemblyLine2PC

julia> tree = datatree();  # build the complete crafting graph

julia> miners = nminers("ElectricEngine", 4)  # miners required for 4 u/s

julia> topspeed("ElectricEngine", miners)    # confirm the throughput budget
4.0
```

Ready to dive deeper? Start with the [architecture tour](@ref) to understand how the
graph is built, then try the hands-on [tutorials](@ref tutorial-hub).
