# # Metrics collection pipeline
# ```@id tutorial-metrics```
# ```
#
# Monitoring large factories requires consistent metrics. This tutorial builds a
# simple collector that exports throughput summaries as structured data for dashboards
# or alerting.

using AssemblyLine2PC
using Statistics
using Dates

# ## Collect raw samples
items = ["ElectricEngine", "AtomicBomb", "NProcessor"]
tree = datatree()

function footprint(item)
    cost(tree, item)
end

samples = map(footprint, items)

# ## Derive KPIs
#
# We convert tuples into aggregate statistics: total ore demand, maximum single
# resource pressure, and miner requirements for a nominal target rate.
function kpi(item, footprint; target_rate=2)
    total = sum(footprint)
    peak = maximum(footprint)
    miners = nminers(item, target_rate, tree)
    (; item, total, peak, miners)
end

metrics = map(kpi, items, samples)

# ## Report results
for metric in metrics
    println(rpad(metric.item, 16), " | total=", metric.total, " | peak=", metric.peak, " | miners@2u/s=", metric.miners)
end

# ## Export hook
#
# Metrics can be serialized for downstream systems. Here we build a dictionary that
# mirrors a JSON payload, ready for use with HTTP.jl or OpenTelemetry exporters.
export_payload = Dict(
    :generated_at => Dates.now(),
    :items => [Dict(metric) for metric in metrics],
)

@show export_payload
