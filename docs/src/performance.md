# Performance tuning

AssemblyLine2PC ships efficient defaults, but large-scale analyses and reporting
pipelines can benefit from a few best practices.

## Reuse the data graph

Calling [`datatree`](@ref) constructs the entire recipe graph. The traversal is
fast but still non-trivial—reuse the resulting `MetaGraph` whenever possible:

```julia
julia> tree = datatree();

julia> map(item -> cost(tree, item), ["ElectricEngine", "NProcessor"])
2-element Vector{NTuple{23, Int64}}:
 (...)
```

## Preallocate outputs

Many helper functions return tuples or arrays with a fixed layout. When
aggregating results, preallocate containers to minimize garbage collection:

```julia
items = ["ElectricEngine", "NProcessor", "AtomicBomb"]
footprints = Vector{NTuple{length(tracked_materials), Int}}(undef, length(items))

for (i, item) in enumerate(items)
    footprints[i] = cost(tree, item)
end
```

## Batch distributed workloads

When coordinating multiple nodes, prefer chunked workloads and avoid broadcasting
large intermediates. The [`Distributed`](@ref) walkthrough demonstrates how to
stage recipe lookups and aggregations without saturating network links.

```julia
@everywhere using AssemblyLine2PC

function batch_cost(items)
    tree = datatree()
    return map(item -> total_material(item, 1, tree), items)
end

@distributed (vcat) for chunk in Iterators.partition(items, 10)
    batch_cost(chunk)
end
```

## Profiling tips

- Use `@time`, `@btime` (from BenchmarkTools), or Julia's built-in `@profview` to
  validate throughput-critical sections.
- Inspect `MetaGraph` vertex counts (`nv(tree)`) and edge counts (`ne(tree)`) when
  debugging unusual performance regressions.
- Enable Documenter's doctests in CI (already part of this repository) to catch
  code examples that fall out of sync and trigger expensive rebuilds.
