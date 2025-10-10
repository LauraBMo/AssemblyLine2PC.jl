# Performance tuning

AssemblyLine2PC ships efficient defaults, but large-scale analyses and reporting
pipelines can benefit from a few best practices.

## Reuse the data graph

Calling [`datatree`](@ref datatree) constructs the entire recipe graph. The traversal is
fast but still non-trivial—reuse the resulting `MetaGraph` whenever possible:

```julia
julia> tree = datatree();

julia> map(item -> cost(tree, item), ["ElectricEngine", "NProcessor"])
2-element Vector{NTuple{23, Int64}}:
 (...)
```
