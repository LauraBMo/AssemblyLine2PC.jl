# # Failure handling strategies
# ```@id tutorial-failure```
# ```
#
# Long-running planning sessions can fail when items are missing or when
# distributed workers encounter transient errors. This example demonstrates how to
# harden analysis loops with retries and validation helpers.

using Distributed
using AssemblyLine2PC

# ## Ensure workers are ready
if nprocs() == 1
    addprocs(2; exeflags="--project=$(Base.active_project())")
end
@everywhere using AssemblyLine2PC

# ## Validation helpers
#
# We wrap raw lookups with guards that emit helpful diagnostics when the target item
# is not available in the dataset.
function ensure_item(tree, item)
    haskey(tree, item) && return tree[item]
    error("Unknown item `$(item)` – check spelling or update the dataset.")
end

function resilient_cost(item; attempts=3)
    for trial in 1:attempts
        try
            tree = datatree()
            ensure_item(tree, item)
            return total_material(item, 1, tree)
        catch err
            if trial == attempts
                rethrow(err)
            else
                @warn "Retrying cost computation" item trial error=err
            end
        end
    end
end

# ## Batch analysis with graceful fallbacks
items = ["ElectricEngine", "NonExisting", "AtomicBomb"]

results = map(items) do item
    try
        resilient_cost(item)
    catch err
        err
    end
end

# ## Summarize outcomes
for (item, result) in zip(items, results)
    if result isa Exception
        println("✗ ", item, " => ", result)
    else
        println("✓ ", item, " => total raw demand = ", sum(result))
    end
end
