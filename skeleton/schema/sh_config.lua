SCHEMA.Name = 'Skeleton'
SCHEMA.Description = 'Hiiii'

SCHEMA.CustomBool = true 

function SCHEMA:Initialize()
    if self.CustomBool == true then
        print('Hiii x2')
    else
        print('No hiii :(')
    end
end

// re._kernel.Include('sv_hooks.lua') -- like a Helix