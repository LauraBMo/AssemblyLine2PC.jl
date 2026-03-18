
@kwdef mutable struct Recipe{T}
    root::String = "NProcessor"
    speed::Float64 = 1.0
    G::T = datatree()
end

graph(R::Recipe) = R.G
root(R::Recipe) = R.root
speed(R::Recipe) = R.speed

function resetspeed!(R::Recipe, newspeed)
    R.speed = newspeed
end

function Base.print(io::IO, r::Recipe; indent="*", kwargs...)
    for (deep, item, speed) in recipe(r)
        tabstr = repeat(indent, length(deep) + 1)
        @printf "%s %s(%0.2f[u/s])\n" tabstr item speed*r.speed
    end
end
Base.show(io::IO, recipe::Recipe) = Base.print(io, recipe)
Base.show(io::IO, ::MIME"text/plain", recipe::Recipe) = Base.print(io, recipe)

function recipe(item::String, speed=1.0, G=datatree(); miners=nothing)
    if !isnothing(miners)
        speed = topspeed(item, miners, G)
    end
    return Recipe{typeof(G)}(item, speed, G)
end

function recipe(R::Recipe, item::String=R.root, speed=R.speed, deep="", G=R.G)
    out = [(deep=deep, item=item, speed=speed)]
    alphebet = collect('a':'z')
    # if !istransorraw(item)
    # if !israwmaterial(item)
    neighborhood = outneighbor_labels(G, item)
    if !isempty(neighborhood)
        for (i, next_item) in enumerate(neighborhood)
            loc_speed = speed * G[item, next_item]
            loc_deep = deep * alphebet[i]
            append!(out, recipe(R, next_item, loc_speed, loc_deep))
        end
    end
    return out
end

function (R::Recipe{T})(item, del...;
                        include=[], delete=[], full=true, split=nothing) where T
    costs = vertex_costs(R.G, R.root, item)
    if item == R.root
        costs = Dict(item => 1)
    end
    # @show costs
    # @show sum(values(costs))

    names, speeds = keys(costs), values(costs)
    total = sum(speeds; init = 0)
    d, frac = approximate_with_fractions(speeds ./ total)
    speeds_sources = [R.speed*vertex_cost(R.G, R.root, it) for it in names]

    title = @sprintf "Needs %s(%0.2f[u/s]" item R.speed*total 
    if israwmaterial(item)
        # title *= @sprintf " miners: %0.2f" total/PRODUCTION_SPEED
        title *= @sprintf " miners: %i" ceil(Int, total/PRODUCTION_SPEED)
    end
    title *= ") to produce:"
    subtitle = @sprintf "-- Goal %s at (%0.2f[u/s])\n" R.root R.speed

    if length(costs) == 1
        @printf "%s >> %s(%0.2f[u/s]).\n" title first(names) first(speeds)*R.speed
        @printf "%s" subtitle
    else
        result = pretty_table(
            ## row1 are parts, row2 target speeds
            permutedims(hcat(frac, speeds_sources));
            kwargs_default()...,
            formatters=[(v, i, j) -> (i == 1 ? Int(v) : v)],
            # column_labels          = collect(enumerate(first.(inv_recipe))),
            column_labels=join.(enumerate(names), ["."]),
            show_row_number_column=false,
            source_notes="Splitting for $(item): $d parts",
            # subtitle = "split factor $d",
            title=title,
            subtitle=subtitle,
        )
        result
    end
    if full && !istransraw(item)
        viewgraph(graph(R))(item; speed=R.speed*total)
    end
end

(R::Recipe)(; include=[], delete=[], full=true) = 
 (R)(root(R); include=include, delete=delete, full=full)
