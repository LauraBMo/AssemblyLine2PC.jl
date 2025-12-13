"""
    full_recipe(object; rate=1, p1=5, p2=5, p3=5, p4=5, p5=5, data=datatree())

Given an object, returns its recipe with detailed breakdown similar to:

** Explosive 16u/s

- Circuit 80: 16x5 packs
  - Gold: 160: 32 miners
  - CopperWire 80: 16x5 packs (16 miners)
- Heater 160: 32x5 packs
  - Aluminium 640: 128 miners
  - IronWire 320: 16x20 packs (64 miners)
- CopperCable 160: 32x5 packs
  - CopperWire 480: 96x5 packs (96 miners)
- DiamondWire 160: 32x5 packs (32 miners)

+ CopperWire 80+480=560: 28x20 packs (112 miners)
+ DiamondWire 160: 8x20 packs (32 miners)

Accepts optional parameters: p1=Wire packs size, p2=lvl1-crafter packs, etc.
Uses pretty table to print output on REPL.
"""
function full_recipe(object; rate=1, p1=5, p2=5, p3=5, p4=5, p5=5, data=datatree())
    # Get the recipe ingredients for the object
    recipe = outneighbor_labels(data, object)
    
    if isempty(recipe)
        # Object is a raw material
        println("** $object $(rate)u/s")
        miners_needed = ceil(rate / 5)
        println("- $object: $(rate)u/s ($miners_needed miners)")
        return nothing
    end
    
    println("** $object $(rate)u/s")
    
    # Track all intermediate products and their total requirements
    intermediate_totals = Dict{String, Float64}()
    raw_material_totals = Dict{String, Float64}()
    
    # Process each ingredient in the recipe
    for ingredient in recipe
        ingredient_rate = rate * data[object, ingredient]
        intermediate_totals[ingredient] = get(intermediate_totals, ingredient, 0.0) + ingredient_rate
        
        # Print main ingredient with pack info
        packs_needed = ceil(ingredient_rate / p1)
        crafters_needed = ceil(ingredient_rate)
        
        println("- $ingredient $(ingredient_rate): $(floor(Int, packs_needed))x$p1 packs ($(crafters_needed) crafters)")
        
        # Check if ingredient has sub-components
        sub_ingredients = outneighbor_labels(data, ingredient)
        if !isempty(sub_ingredients)
            # Process sub-ingredients
            for sub_ing in sub_ingredients
                sub_rate = ingredient_rate * data[ingredient, sub_ing]
                
                # Update totals for sub-ingredient
                intermediate_totals[sub_ing] = get(intermediate_totals, sub_ing, 0.0) + sub_rate
                
                # Get raw material requirements for this sub ingredient
                sub_raw_needs = data[sub_ing]
                
                # Calculate packs needed for sub ingredient
                sub_packs = ceil(sub_rate / p1)
                
                # Print sub-ingredient details
                if istransformer(sub_ing) || israwmaterial(sub_ing)
                    # It's a raw material or transformer
                    miners_needed = ceil(sub_rate / 5)
                    if sub_packs == floor(Int, sub_packs)
                        println("  - $sub_ing: $(sub_rate): $(floor(Int, sub_packs))x$p1 packs ($(miners_needed) miners)")
                    else
                        println("  - $sub_ing: $(sub_rate): $(sub_packs)x$p1 packs ($(miners_needed) miners)")
                    end
                else
                    # It's an intermediate product
                    if sub_packs == floor(Int, sub_packs)
                        println("  - $sub_ing $(sub_rate): $(floor(Int, sub_packs))x$p1 packs")
                    else
                        println("  - $sub_ing $(sub_rate): $(sub_packs)x$p1 packs")
                    end
                end
                
                # Add raw material requirements
                raw_material_names = raw_materials
                for (i, raw_mat) in enumerate(raw_material_names)
                    if i <= length(sub_raw_needs)
                        raw_amount = sub_raw_needs[i] * sub_rate
                        if raw_amount > 0
                            raw_material_totals[raw_mat] = get(raw_material_totals, raw_mat, 0.0) + raw_amount
                        end
                    end
                end
            end
        else
            # Ingredient is a raw material or transformer
            if israwmaterial(ingredient) || istransformer(ingredient)
                raw_amount = ingredient_rate
                raw_material_totals[ingredient] = get(raw_material_totals, ingredient, 0.0) + raw_amount
            end
        end
    end
    
    # Also add direct raw materials if the ingredient itself is one
    raw_needs = data[object]
    raw_material_names = raw_materials
    for (i, raw_mat) in enumerate(raw_material_names)
        if i <= length(raw_needs)
            raw_amount = raw_needs[i] * rate
            if raw_amount > 0
                raw_material_totals[raw_mat] = get(raw_material_totals, raw_mat, 0.0) + raw_amount
            end
        end
    end
    
    # Display consolidated raw material requirements using pretty table
    if !isempty(raw_material_totals)
        println()
        # Create a table for raw materials
        raw_table = Matrix{Any}(undef, length(raw_material_totals), 3)
        i = 1
        for (raw_mat, total_amount) in raw_material_totals
            miners_needed = ceil(total_amount / 5)
            raw_packs = ceil(total_amount / p1)
            raw_table[i, 1] = raw_mat
            raw_table[i, 2] = "$(total_amount)"
            raw_table[i, 3] = "$(miners_needed)"
            i += 1
        end
        
        # Use pretty table to display the raw material requirements
        using PrettyTables
        pretty_table(raw_table, 
                    header=["Raw Material", "Amount (u/s)", "Miners"], 
                    title="Raw Material Requirements",
                    alignment=[:l, :r, :r],
                    crop=:none,
                    backend=:text)
    end
end