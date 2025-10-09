# # Multi-node coordination
# ```@id tutorial-multinode```
# ```
#
# This walkthrough shows how to distribute throughput sizing across multiple
# Julia workers. We request additional processes, load AssemblyLine2PC on each, and
# then use `pmap` to compute miner allocations for different target items.
#
# ## Provision workers
#
using Distributed

if nprocs() == 1
    addprocs(2; exeflags="--project=$(Base.active_project())")
end

@info "Workers available" workers()

# ## Broadcast the package
#
# Each worker must load the package inside its own module space.
@everywhere using AssemblyLine2PC

# ## Define the remote workload
#
# We encapsulate the analysis in a dedicated function so `pmap` can ship it to each
# worker efficiently. The function returns a named tuple for readability.
@everywhere function throughput_summary(item, rate)
    tree = datatree()
    miners = nminers(item, rate, tree)
    (; item, rate, miners, supported = topspeed(item, miners, tree))
end

items = ["ElectricEngine", "NProcessor", "AtomicBomb"]
rate = 3

summaries = pmap(item -> throughput_summary(item, rate), items)

# ## Aggregate results
#
# The result is a list of named tuples that can be post-processed locally. For the
# tutorial we simply render a table-style view.
foreach(summary -> println(rpad(summary.item, 16), " | miners=", summary.miners, " | supported=", summary.supported), summaries)

# ## Clean up (optional)
#
# Workers can stay alive for subsequent tutorials. Uncomment the next line if you
# prefer returning to a single-process session.
# rmprocs(workers())
