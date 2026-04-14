
export viewgraph

struct ViewGraph{T}
    G::T
end

viewgraph(G=datatree()) = ViewGraph(G)
graph(VG::ViewGraph) = getfield(VG, :G)
labels(VG::ViewGraph) = MetaGraphsNext.labels(graph(VG))

# # Get all vertex labels from the MetaGraph
# function Base.propertynames(VG::ViewGraph)
#     return tuple(Symbol.(labels(VG)))
# end

# # Access vertices by property
# function Base.getproperty(VG::ViewGraph, name::Symbol)
#     return VG(string(name))
# end

@kwdef mutable struct ShowRecipe{T}
    item::String
    speed::T
    header::String = @sprintf "%s(%0.2fu/s)" item speed
end

showrecipe(root::String, speed, G, path=[]) =
    showrecipe!(ShowRecipe(; item=root, speed=speed), G, path)

function showrecipe!(R::ShowRecipe, G, path)
    for i in path
        next_item = outneighbor_label(G, R.item, i)
        iterate!(R, next_item, G[R.item, next_item])
    end
    R.header *= ":"
    return R.item, R.speed, R.header
end

function iterate!(R::ShowRecipe, next_item, rate)
    R.item = next_item
    if rate > 1
        R.speed *= rate
        R.header *= @sprintf ">x%d>%s(%0.2fu/s)" rate R.item R.speed
    else
        R.header *= @sprintf ">>%s" R.item
    end
end

# function fuel_summary(R, G)
#     makers = vertex_fuel_cost(G, R.item, R.speed)
#     per_second = makers / 6
#     miners = nMiners(per_second / (5*GAME_FACTOR))
#     summary = @sprintf "Total Fuel: %0.2f refined material u/s; Miners: %s" per_second miners
#     print(Crayon(foreground=:light_blue, bold=true), summary)
# end

function (VG::ViewGraph)(root::String, path...; speed=1.0, miners=nothing, npacks=5)
    G = graph(VG)
    if !(isnothing(miners))
        speed = topspeed(G, root, miners)
    end
    item, item_speed, header = showrecipe(root, speed, G, path)
    table, notes = recipe_table(item, item_speed, npacks, G)

    I = findalltransraw(table)
    if isempty(I)
        pretty_table(table;
                     kwargs_recipetable(table, header, npacks)...,
                     source_notes=notes)
    elseif length(I) == size(table, 1)
        pretty_table(build_transraw_table(table[I, :]);
                     kwargs_transrawtable()...,
                     source_notes=notes)
    else
        pretty_table(table; kwargs_recipetable(table, header, npacks)...)
        pretty_table(build_transraw_table(table[I, :]);
                     kwargs_transrawtable()...,
                     source_notes=notes)
    end
    # fuel_summary(R, G)
end

const LENGTH = 5
function recipe_table(item, speed, n=5, G=datatree())
    recipe = collect(outneighbor_labels(G, item))
    total = speed
    if !israw(item)
        total *= raw_cost(G, item)
    end
    notes = @sprintf "TOTAL: %5.2fu of raw-material; Requires: %s Starters" total nMiners(total / (5 * GAME_FACTOR))

    out = Matrix{Any}(undef, 0, LENGTH)
    # newrow = [it  ## Name
    #           it_speed ## Ratio
    #           ceil(Int, it_speed/GAME_FACTOR) ## Makers
    #           it_speed/(n*GAME_FACTOR) ## Packs of makers
    #           round(Int, raws) ## Cost in raw materials
    #           ]
    newrow(item, speed, n, total) =
        [item speed ceil(Int, speed/GAME_FACTOR) speed/(n*GAME_FACTOR) round(Int, total)]
    if isempty(recipe)
        out = newrow(item, speed, n, total)
    end
    for it in recipe
        it_speed = speed * G[item, it]
        raws = it_speed
        if !israw(it)
            raws *= raw_cost(G, it)
        end
        out = vcat(out, newrow(it, it_speed, n, raws))
    end
    return out, notes
end

const RLENGTH = 4
function build_transraw_table(recipes)
    out = Matrix{Any}(undef, 0, RLENGTH)
    for row in eachrow(recipes)
        new_row = [row[1] row[2] ceil(Int, row[2] / GAME_FACTOR) row[LENGTH] / (5 * GAME_FACTOR)]
        out = vcat(out, new_row)
    end
    return out
end

function kwargs_recipetable(table, title="", n=5)
    return (
        kwargs_default()...,
        title=title,
        column_labels=[
            ["Item", "Ratio", "Mkrs", "$(n)xPacks", "Raws"],
        ],
        alignment=[:l, fill(:r, LENGTH - 1)...],
        formatters=[miner_formatter([4])],
        highlighters=highlighters_recipetable(table),
        summary_rows=my_summary(),
        summary_row_labels=["", ""],
    )
end

function kwargs_transrawtable()
    return (
        kwargs_default()...,
        title="Transformers & Raw Materials",
        column_labels=[
            ["Materials", "Ratio", "Mkrs", "nStarters"],
        ],
        formatters=[miner_formatter([4])],
        alignment=[:l, fill(:r, RLENGTH - 1)...],
    )
end
