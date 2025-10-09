using AssemblyLine2PC
using Documenter
using Literate

DocMeta.setdocmeta!(AssemblyLine2PC, :DocTestSetup, :(using AssemblyLine2PC); recursive=true)

# Generate tutorial pages from literate scripts
tutorial_specs = [
    ("Multi-node coordination", "multi_node_coordination"),
    ("Failure handling", "failure_handling"),
    ("Metrics collection", "metrics_collection"),
]

for (name, stem) in tutorial_specs
    Literate.markdown(
        joinpath(@__DIR__, "literate", "$(stem).jl"),
        joinpath(@__DIR__, "src", "tutorials");
        documenter=true,
        execute=true,
        name=name,
    )
end

pages = [
    "Home" => "index.md",
    "Architecture" => "architecture.md",
    "Performance tuning" => "performance.md",
    "Tutorials" => Any[
        "Overview" => "tutorials/index.md",
        "Multi-node coordination" => "tutorials/multi_node_coordination.md",
        "Failure handling" => "tutorials/failure_handling.md",
        "Metrics collection" => "tutorials/metrics_collection.md",
    ],
    "API reference" => "api.md",
]

makedocs(;
    modules=[AssemblyLine2PC],
    authors="LauBMo <laurea987@gmail.com> and contributors",
    sitename="AssemblyLine2PC.jl",
    format=Documenter.HTML(;
        canonical="https://LauraBMo.github.io/AssemblyLine2PC.jl",
        prettyurls=get(ENV, "CI", "") == "true",
        edit_link="main",
        assets=String[],
    ),
    pages=pages,
    strict=true,
    linkcheck=true,
    doctest=true,
)

deploydocs(;
    repo="github.com/LauraBMo/AssemblyLine2PC.jl",
    devbranch="main",
    versions=[
        "stable" => "v^",
        "dev" => "main",
    ],
)
