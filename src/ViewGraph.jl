
export viewgraph

using Printf
using PrettyTables

struct ViewGraph{T}
    G::T
end

viewgraph(G) = ViewGraph(G)
graph(VG::ViewGraph) = VG.G

function get_pathdownwards(G, item, speed,
                           path::Vector{Int},
                           miners = nothing)
    if !(isnothing(miners))
        speed *= topspeed(item, miners, G)
    end
    end_item = item
    end_speed = speed
    string_path = @sprintf "%s(%0.2fu/s)" item speed
    for i in path
        next_item = outneighbor_label(G, end_item, i)
        v = G[end_item, next_item]
        end_speed *= v
        end_item = next_item
        if v > 1
            string_path *= @sprintf ">x%d>%s(%0.2fu/s)" v end_item end_speed
        else
            string_path *= @sprintf ">>%s" end_item
        end
    end
    string_path *= ":"
    return end_item, end_speed, string_path
end

function (VG::ViewGraph)(item::String, I...;
                         speed = one(Int),
                         miners = nothing)
    G = graph(VG)
    real_item, real_speed, title = get_pathdownwards(G, item, speed, I, miners)
    table = recipe_table(real_item, real_speed, G)
    if isnothing(table)
        @printf "TOTAL: %5.2fu of raw-material; Requires: %s Miners" real_speed nMiners(real_speed / 5)
        return nothing
    end
    prettyrecipe(table, real_speed, title)
end

## Total cost of items in subrecipe = [2,3] for item at level 'I' onforward.
## TODO TODO
## TODO TODO
function (VG::ViewGraph)(item::String, subrecipe::AbstractVector, I...;
                         speed=one(Int), miners=nothing)
    G = graph(VG)
    real_item, real_speed, title = get_pathdownwards(G, item, speed, I, miners)
    table = subrecipe_table(real_item, subrecipe, real_speed, G)
    if isnothing(table)
        @printf "TOTAL: %5.2fu of raw-material; Requires: %s Miners" real_speed nMiners(real_speed / 5)
        return nothing
    end
    table = sort_recipe_table(table, G)
    prettyrecipe(table, speed, title)
end
## TODO TODO
## TODO TODO

function recipe_table(name, speed=one(Int), data=datatree())
    # header = ["Component", "Rate", "Makers"; "Gold",...]
    out = Matrix{Any}(undef, 0, LENGTH + 5)
    recipe = outneighbor_labels(data, name)
    # wide = maximum(length, recipe)
    if isempty(recipe)
        return nothing
    end
    for it in recipe
        itspeed = speed * data[name, it]
        # N = nminers(it, itspeed, data)
        # N = nMiners(itspeed/5)
        newrow = [it itspeed Int(ceil(itspeed)) itspeed itspeed * collect(data[it])...]
        out = vcat(out, newrow)
    end
    return out
end

function subrecipe_table(name, subrecipe, speed=one(Int), data=datatree())
    # header = ["Component", "Rate", "Makers"; "Gold",...]
    table = recipe_table(name, speed, data)
    for i in subrecipe
        it = outneighbor_label(data, name, i)
        itspeed = speed * data[name, it]
        new_table = recipe_table(it, itspeed, data)
        table = add_recipe_table(table, new_table)
    end
    return table
end

function sort_recipe_table(table, data)
    rows = collect(eachrow(table))
    sort!(rows, by=x -> vertex_high(data, first(x)))
    out = Matrix{Any}(undef, LENGTH + 5, 0)
    out = reduce(hcat, rows; init = out)
    return permutedims(out)
end

function add_recipe_table(table1, table2)
    out = table1
    intable1(str) = findfirst(==(str), first(eachrow(table1)))
    for newrow in eachrow(table2)
        name = first(newrow)
        isintable1 = intable1(name)
        if isnothing(isintable1)
            out = vcat(out, permutedims(newrow))
        else
            out[isintable1, 2:end] += newrow[2:end]
        end
    end
    return out
end


## Make it a macro?
function highlight_mainitems(table)
    hls = TextHighlighter[]
    if size(table, 1) > 1
        _ord = sortperm(map(row -> sum(row[3:end]), eachrow(table)))
        sorteditems = table[:, 1][_ord]
        hl_item(string, color) = TextHighlighter(
            (data, i, j) -> (data[i, j] == string),
            color
        )

        hl_line(n, color) = TextHighlighter(
            (data, i, j) -> (i == n),
            color
        )
        hls = [
            hl_item(sorteditems[end], crayon"bold red"),
            hl_item(sorteditems[end-1], crayon"bold light_blue"),
            hl_line(_ord[end], crayon"red"),
            hl_line(_ord[end-1], crayon"light_blue"),
        ]
    end
    return hls
end

const LENGTH = 4
const HEADERS = [
    ["Item", "Ratio", "Mkrs", "5xPacks", raw_materials1_list...],
    # [ "", "[u/s]", "", fill("[u]", 5)...]
]
const HLENGTH = LENGTH + length(raw_materials1_list)


function prettyrecipe(table, title="", notminers_columns=[1, 2, 3])
    total = sum(table[:, (LENGTH+1):end])
    src_string = @sprintf "TOTAL: %5.2fu of raw-material; Requires: %s Miners" total nMiners(total / 5)
    frt_miner(I) = (v, i, j) -> (in(j, I) ? v : nMiners(v / 5))
    pt = pretty_table(
        table;
        title=title,
        column_labels=HEADERS,
        alignment=[:l, fill(:r, HLENGTH - 1)...],
        formatters=[frt_miner(notminers_columns)],
        #### Rows
        show_row_number_column=true,
        row_number_column_label="Num",
        summary_rows=my_summary(),
        # summary_row_labels = ["Totals:", "TOTAL:"],
        # Labels add new column, we save it.
        summary_row_labels=["", ""],
        #### Columns
        source_notes=src_string,
        highlighters=highlight_mainitems(table),
        style=TextTableStyle(;
            first_line_column_label=crayon"bold",
            source_note=crayon"bold light_blue",
        ),
        table_format=TextTableFormat(;
            @text__no_vertical_lines,
            # vertical_line_after_row_number_column = true
            vertical_line_after_continuation_column=true,
            vertical_line_at_beginning=true,
        ),
    )
    return pt
end

# using Printf
# function show_recipe(name, speed=one(Int), data=datatree())
#     # print("Recipe for $(name) at $(speed)u/s\n")
#     @printf "Recipe for %s at %0.2fu/s: Crafts & Miners\n" name speed
#     recipe = outneighbor_labels(data, name)
#     wide = maximum(length, recipe)
#     for it in recipe
#         itspeed = speed*data[name, it]
#         # N = float(MinerNumbers.number(nminers(it, itspeed, data)))
#         N = nminers(it, itspeed, data)
#         # print("|_> $(it) at $(itspeed): $(ceil(itspeed)) craft, $(N) Miners\n")
#         @printf "|_> %-*s(%5.2f u/s): %02d Mkr and %s Mi\n" wide it itspeed ceil(itspeed) N
#     end
# end
