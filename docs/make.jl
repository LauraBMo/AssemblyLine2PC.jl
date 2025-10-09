using AssemblyLine2PC
using Documenter
using Literate

DocMeta.setdocmeta!(AssemblyLine2PC, :DocTestSetup, :(using AssemblyLine2PC); recursive=true)

pages = [
    "Home" => "index.md",
    "Architecture" => "architecture.md",
    "Performance tuning" => "performance.md",
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
