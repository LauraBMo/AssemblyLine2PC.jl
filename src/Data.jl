# Complete Assembly Line 2 Crafting Tree Dictionary

# ==================== RAW MATERIALS ====================
const raws1 = ["Gold", "Diamond", "Iron", "Copper", "Aluminum"]
const raws2 = ["Uranium", "Plutonium"]


"""
    raw_materials

String ordered vector of raw resources that anchor all cost tuples produced by
AssemblyLine2PC.jl.
"""
const raw_materials = vcat(raws1, raws2)

israwmaterial(string) = any(==(string), raw_materials)


const transformers_types = ["Wire", "Liquid", "Gear", "Plate"]
const transformers_split = "."
trans_concat(type, raw; split = transformers_split) = type * split * raw 

## Cable, Refined (missing)
# transformers_names = ["WMaker", "Furnace", "Cutter", "CMaker", "HPress", "Refinery"]
# transformers_dict = transformers_types .=> transformers_names

# ==================== BASIC COMPONENTS ====================
function recipes_transformers(raw = raws1,
                              refined = raws2,
                              transformers = transformers_types)
    recipes = Dict()
    for (type, material) in Iterators.product(transformers, raw)
        name = trans_concat(type, material)
        push!(recipes, name => Dict(material => 1))
    end
    # Add Cable version (slightly different)
    for material in raw
        name = trans_concat("Cable", material)
        ingredient = trans_concat("Wire", material) 
        push!(recipes,
            name => Dict(ingredient => 3))
    end
    # Add Refinery version (slightly different)
    for material in refined
        name = trans_concat("Refined", material)
        ingredient = material
        push!(recipes,
            name => Dict(ingredient => 1))
    end
    return recipes
end

const transformer_items = collect(keys(recipes_transformers()))
istransformer(string) = in(string, transformer_items)
istransorraw(string) = istransformer(string) || israwmaterial(string)
splittransformer(string) = split(string, transformers_split)


# ==================== MAKERS RECIPES ====================
mk1 = Dict(
    "Battery" => Dict(
        "Copper" => 1,
        trans_concat("Liquid", "Copper") => 2,
    ),
    "Circuit" => Dict(
        "Gold" => 2,
        trans_concat("Wire", "Copper") => 1,
    ),
    "ElectricBoard" => Dict(
        trans_concat("Wire", "Copper") => 3,
        "Aluminum" => 2,
    ),
    "Engine" => Dict(
        trans_concat("Gear", "Iron") => 2,
        "Gold" => 2,
    ),
    "Heater" => Dict(
        trans_concat("Wire", "Iron") => 2,
        "Aluminum" => 4,
    ),
    "ServerRack" => Dict(
        "Aluminum" => 1,
        "Iron" => 3,
    ),
    "SolarCell" => Dict(
        trans_concat("Liquid", "Diamond") => 1,
        "Gold" => 2,
    ),
)

mk2 = Dict(
    "AdvancedEngine" => Dict(
        "Engine" => 6,
        "Circuit" => 6,
        "Diamond" => 10,
    ),
    "Computer" => Dict(
        "Processor" => 1,
        "PowerSupply" => 1,
        "Fan" => 1,
    ),
    "Fan" => Dict(
        "Circuit" => 2,
        trans_concat("Gear", "Diamond") => 4,
        "Aluminum" => 6,
    ),
    "Laser" => Dict(
        "Battery" => 6,
        "Heater" => 6,
        trans_concat("Liquid", "Iron") => 6,
    ),
    "PowerSupply" => Dict(
        "Circuit" => 1,
        "Diamond" => 6,
        trans_concat("Liquid", "Aluminum") => 6,
    ),
    "Processor" => Dict(
        "Circuit" => 2,
        trans_concat("Liquid", "Gold") => 4,
        trans_concat("Wire", "Diamond") => 4,
    ),
    "SolarPanel" => Dict(
        "SolarCell" => 1,
        "Circuit" => 1,
        "ElectricBoard" => 1,
    ),
    "SuperComputer" => Dict(
        "Computer" => 2,
        "ServerRack" => 6,
        "Circuit" => 6,
        trans_concat("Cable", "Gold") => 6,
    ),
)

mk3 = Dict(
    "AIProcessor" => Dict(
        "Circuit" => 5,
        "SuperComputer" => 3,
        trans_concat("Plate", "Copper") => 10,
        trans_concat("Cable", "Copper") => 10,
    ),
    "AIRobot" => Dict(
        "AIRobotBody" => 1,
        "AIRobotHead" => 1,
        trans_concat("Plate", "Iron") => 15,
        trans_concat("Cable", "Diamond") => 10,
    ),
    "AIRobotArms" => Dict(
        "Laser" => 3,
        trans_concat("Plate", "Aluminum") => 6,
        trans_concat("Cable", "Aluminum") => 6,
        "Iron" => 10,
    ),
    "AIRobotBody" => Dict(
        "ElectricEngine" => 3,
        "SolarPanel" => 4,
        "AIRobotArms" => 4,
        "ElectricBoard" => 6,
    ),
    "AIRobotHead" => Dict(
        "AIProcessor" => 1,
        trans_concat("Plate", "Gold") => 10,
        trans_concat("Cable", "Diamond") => 5,
        "Circuit" => 15,
    ),
    "ElectricEngine" => Dict(
        "Battery" => 5,
        "AdvancedEngine" => 2,
        "ElectricBoard" => 6,
        trans_concat("Plate", "Iron") => 6,
    ),
    "Explosive" => Dict(
        "Circuit" => 5,
        trans_concat("Wire", "Diamond") => 10,
        trans_concat("Cable", "Copper") => 10,
        "Heater" => 10,
    ),
    "IgnitionSystem" => Dict(
        "Trigger" => 2,
        "Explosive" => 5,
        "AIProcessor" => 1,
        "Battery" => 5,
    ),
    "Trigger" => Dict(
        "Iron" => 40,
        trans_concat("Wire", "Diamond") => 10,
        "Circuit" => 5,
        "ElectricBoard" => 8,
    ),
)

# ==================== RADIOACTIVE MAKERS RECIPES ====================
## This makers need fuel to work, exactly 1/6th of a refined Uranium or Plutonium unit per second.
## We add "Fuel" flag to account for it in costs computations.
rmk1 = Dict(
    "NCell" => Dict(
        "PCell" => 2,
        "UCell" => 2,
        "SolarCell" => 3,
        "ElectricBoard" => 3,
        "Heater" => 3,
    ),
    "NCircuit" => Dict(
        "PCircuit" => 2,
        "UCircuit" => 2,
        "Circuit" => 3,
        trans_concat("Cable", "Gold") => 3,
        "Processor" => 3,
    ),
    "PCell" => Dict(
        "Plutonium" => 4,
        "SolarCell" => 4,
        trans_concat("Liquid", "Diamond") => 10,
        trans_concat("Cable", "Gold") => 4,
        trans_concat("Cable", "Copper") => 4,
    ),
    "PCircuit" => Dict(
        "Plutonium" => 5,
        "Circuit" => 5,
        "Copper" => 5,
        trans_concat("Cable", "Gold") => 3,
        trans_concat("Wire", "Diamond") => 3,
    ),
    "UCell" => Dict(
        "Uranium" => 4,
        "SolarCell" => 4,
        trans_concat("Liquid", "Diamond") => 10,
        trans_concat("Cable", "Gold") => 4,
        trans_concat("Cable", "Copper") => 4,
    ),
    "UCircuit" => Dict(
        "Uranium" => 5,
        "Circuit" => 5,
        "Copper" => 5,
        trans_concat("Cable", "Gold") => 3,
        trans_concat("Wire", "Diamond") => 3,
    ),
)

rmk2 = Dict(
    "NCore" => Dict(
        "NCell" => 1,
        "PCell" => 1,
        "UCell" => 1,
        "Processor" => 10,
        trans_concat("Cable", "Diamond") => 4,
        trans_concat("Cable", "Gold") => 4,
    ),
    "NProcessor" => Dict(
        "NCircuit" => 1,
        "PCircuit" => 1,
        "UCircuit" => 1,
        "AIProcessor" => 1,
        "Processor" => 5,
        trans_concat("Plate", "Diamond") => 10,
    ),
    "AtomicBomb" => Dict(
        "NProcessor" => 1,
        "NCore" => 1,
        "IgnitionSystem" => 2,
        "NCell" => 2,
        "Uranium" => 15,
        "Plutonium" => 15,
    ),
    "AIRBomber" => Dict(
        "AtomicBomb" => 1,
        "AIRobot" => 1,
        "NCore" => 1,
        "NCell" => 1,
        "NProcessor" => 1,
        "NCircuit" => 1,
    ),
)

const radioactive_makers = union(collect(keys(rmk1)), collect(keys(rmk2)))
isradioactive(string) = in(string, radioactive_makers)
