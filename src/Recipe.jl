
@kwdef mutable struct Recipe{T}
    root::String = "NProcessor"
    speed::Float64 = 1.0
    G::T = datatree()
end

graph(R::Recipe) = R.G
root(R::Recipe) = R.root
speed(R::Recipe) = R.speed

vertex_costs(R::Recipe, item) = vertex_costs(R.G, R.root, item)
vertex_cost(R::Recipe, item) = vertex_cost(R.G, R.root, item)
function resetspeed!(R::Recipe, newspeed)
    R.speed = newspeed
end

function Base.print(io::IO, r::Recipe; indent="*", kwargs...)
    for (deep, item, speed) in recipe(r)
        tabstr = repeat(indent, length(deep) + 1)
        @printf "%s %s(%0.2f[u/s])\n" tabstr item speed * r.speed
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

function (R::Recipe)(item; full=true, group=nothing, exact=false, other=true)
    costs = vertex_costs(R, item)
    if item == R.root
        costs = Dict(item => 1)
    end
    # @show costs
    # @show sum(values(costs))

    names, vals = keys(costs), values(costs)
    total = sum(vals; init=0)
    if exact
        g = gcd(collect(vals)...)
        speeds = vals./g
    else
        d, speeds = approximate_with_fractions(vals ./ total)
    end
    speeds_sources = [R.speed * vertex_cost(R, it) for it in names]

    title = @sprintf "Needs %s(%0.2f[u/s]" item R.speed * total
    if israwmaterial(item)
        # title *= @sprintf " miners: %0.2f" total/PRODUCTION_SPEED
        title *= @sprintf " starters: %i" ceil(Int, R.speed * total / PRODUCTION_SPEED)
    else
        title *= @sprintf " makers: %i" ceil(Int, R.speed * total / 0.92)
    end
    title *= ") to produce:"
    subtitle = @sprintf "-- Goal %s at (%0.2f[u/s])\n" R.root R.speed

    if length(costs) == 1
        @printf "%s >> %s(%0.2f[u/s]).\n" title first(names) R.speed * first(speeds)
        @printf "%s" subtitle
    else
        _data = permutedims(hcat(speeds, speeds./d, vals./total, speeds_sources, ceil.([Int], speeds_sources/0.92)))

        # _data = permutedims(hcat(collect(speeds), speeds_sources))
        # @show error_approx(vals./total, d, speeds)
        kwagrs = kwargs_default()
        if !isnothing(group)
            _togroup = group
            if other
                _togroup = [i for i in 1:(length(speeds)) if !(i in group)]
            end
            nn = length(_togroup)
            _data = permute_to_front(_data, _togroup, 2)
            _labels=join.(enumerate(names), ["."])
            _labels = permute_to_front(_labels, _togroup)

            _data[1, 1] = sum(_data[1, 1:nn])
            # _data[1, 2:nn] .= 0.0

            l1 = join(_labels[1:nn], "+")
            # println(nn, _labels, _data, l1)
            kwagrs = (kwagrs...,
                      column_labels=[[MultiColumn(nn, l1), _labels[(nn+1):end]...]],
                      merge_column_label_cells=:auto,
                      formatters=[(v, i, j) -> (i == 1 ? Int(v) : v),
                                  (v, i, j) -> ((i == 1 && j in 2:nn) ? "_" : v),
                                  ],
                      )
        end
        result = pretty_table(
            _data;
            column_labels=join.(enumerate(names), ["."]),
            row_labels=["Parts", "Get prop.", "To apx.", "Produce", "Makers"],
            formatters=[(v, i, j) -> ((i == 1) || (i == 5) ? Int(v) : v)],
            kwagrs...,
            show_row_number_column=false,
            source_notes="Splitting for $(item): $(sum(speeds)) parts",
            title=title,
            subtitle=subtitle,
        )
        result
    end
    if full && !istransraw(item)
        viewgraph(graph(R))(item; speed=R.speed * total)
    end
end

(R::Recipe)(; full=true, group=nothing) =
    (R)(root(R); full=full, group = group)

