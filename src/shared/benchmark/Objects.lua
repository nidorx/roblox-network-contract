
-- reset random
math.randomseed(65476487266)

local SEED

local function CreateObject()
   if not SEED then
      return {
         PositionX      = math.random(-100.00, 100.00),
         PositionY      = math.random(-100.00, 100.00),
         PositionZ      = math.random(-100.00, 100.00),
         BodyRotationX  = math.random(-100.00, 100.00),
         BodyRotationY  = math.random(-100.00, 100.00),
         BodyRotationZ  = math.random(-100.00, 100.00),
         LookRotationX  = math.random(-100.00, 100.00),
         LookRotationY  = math.random(-100.00, 100.00),
         LookRotationZ  = math.random(-100.00, 100.00),
         Ammo           = math.floor(math.random(0, 30)),
         Health         = math.floor(math.random(0, 100)),
         Armor          = math.floor(math.random(0, 100)),
         WeaponID       = math.floor(math.random(0, 10)),
         Nick           = 'JohnDoe',
         UserId         = math.floor(math.random(0, 100000)),
         Alive          = math.random() < 0.5
      }
   else
      return {
         PositionX      = math.random() <0.5 and SEED.PositionX     or math.random(-100.00, 100.00),
         PositionY      = math.random() <0.5 and SEED.PositionY     or math.random(-100.00, 100.00),
         PositionZ      = math.random() <0.5 and SEED.PositionZ     or math.random(-100.00, 100.00),
         BodyRotationX  = math.random() <0.5 and SEED.BodyRotationX or math.random(-100.00, 100.00),
         BodyRotationY  = math.random() <0.5 and SEED.BodyRotationY or math.random(-100.00, 100.00),
         BodyRotationZ  = math.random() <0.5 and SEED.BodyRotationZ or math.random(-100.00, 100.00),
         LookRotationX  = math.random() <0.5 and SEED.LookRotationX or math.random(-100.00, 100.00),
         LookRotationY  = math.random() <0.5 and SEED.LookRotationY or math.random(-100.00, 100.00),
         LookRotationZ  = math.random() <0.5 and SEED.LookRotationZ or math.random(-100.00, 100.00),
         Ammo           = math.random() <0.5 and SEED.Ammo          or math.floor(math.random(0, 30)),
         Health         = math.random() <0.5 and SEED.Health        or math.floor(math.random(0, 100)),
         Armor          = math.random() <0.5 and SEED.Armor         or math.floor(math.random(0, 100)),
         WeaponID       = math.random() <0.5 and SEED.WeaponID      or math.floor(math.random(0, 10)),
         Nick           = SEED.Nick,
         UserId         = SEED.UserId,
         Alive          = math.random() < 0.5
      }
   end
end

SEED = CreateObject()

return {
   SEED     = SEED,
   GetList  = function()
      local list = {}
      for i=0, 25000 do
         table.insert(list, CreateObject())
      end
      return list
   end
}