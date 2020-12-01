
local function RuntTests(Contract)
   local Seed = {
      PositionX      = -10.33,
      PositionY      = 20.33,
      PositionZ      = 0.33,
      BodyRotationX  = 120.33,
      BodyRotationY  = -120.33,
      BodyRotationZ  = -140.33,
      LookRotationX  = -100.33,
      LookRotationY  = -200.33,
      LookRotationZ  = -50.33,
      Ammo           = 27,
      Health         = 80,
      Armor          = 90,
      WeaponID       = 5,
      Nick           = 'JohnDoe',
      UserId         = 76576725225576266762,
      Alive          = true
   }

   local ATTRS = {
      'PositionX',
      'PositionY',
      'PositionZ',
      'BodyRotationX',
      'BodyRotationY',
      'BodyRotationZ',
      'LookRotationX',
      'LookRotationY',
      'LookRotationZ',
      'Ammo',
      'Health',
      'Armor',
      'WeaponID',
      'Alive',
      'Nick',
      'UserId'
   }

   local ATTRS_IDX = {}
   for index, key in ipairs(ATTRS) do
      ATTRS_IDX[key] = index
   end

   local function testEQL(a, b)
      for attr, value in pairs(a) do
         if a[attr] ~= b[attr] then
            print('value=', a[attr], ', other=', b[attr])
            error('Invalid: attribute '..attr)
         end
      end

      for attr, value in pairs(b) do
         if a[attr] ~= b[attr] then
            print('value=', a[attr], ', other=', b[attr])
            error('Invalid: attribute '..attr)
         end
      end
   end

   local function testDecoded(object, decoded)
      for attr, value in pairs(object) do
         if decoded[attr] ~= value then
            print('value=', value, ', other=', decoded[attr])
            error('Invalid: attribute '..attr)
         end
      end
   end

   --[[
      Verifying the generated encode is correct, in the format
      {TRUE, BITMASK, VALUE_A, VALUE_B, VALUE_N ...}
   ]]
   local function testEncoded(object, encoded)
      if table.getn(encoded) ~= table.getn(ATTRS) + 2 then
         error('Encode length invalid')
      end

      local encodeMask = 0x0

      for index, key in ipairs(ATTRS) do
         local attrIdx = ATTRS_IDX[key]-1
         encodeMask = bit32.bor(encodeMask, bit32.lshift(1, attrIdx))

         if object[key] ~= encoded[index+2] then
            print('objectValue=', object[key], ', encodedValue=', encoded[index+2])
            error('Invalid: attribute '..key)
         end
      end

      if encoded[1] ~= true then
         print('expected=', true, ', value=', encoded[1] )
         error('Invalid Signature')
      end

      if encoded[2] ~= encodeMask then
         print('expectedMask=', encodeMask, ', encodeMask=', encoded[2] )
         error('Invalid BITMASK')
      end
   end

   --[[
      Checks whether the generated delta is correct, in the format
      {FALSE, BITMASK_DEL, BITMASK_MOD, VALUE_A, VALUE_B, VALUE_N...}
   ]]
   local function testDelta(object, delta, removedKeys, changedKeys)

      if table.getn(delta) ~= table.getn(changedKeys) + 3 then
         error('Delta length invalid')
      end

      local removedMask = 0x0
      local changedMask = 0x0
      for _, key in ipairs(removedKeys) do
         local attrIdx = ATTRS_IDX[key]-1
         removedMask = bit32.bor(removedMask, bit32.lshift(1, attrIdx))
      end

      for index, key in ipairs(changedKeys) do
         local attrIdx = ATTRS_IDX[key]
         changedMask = bit32.bor(changedMask, bit32.lshift(1, attrIdx -1))
         if object[key] == delta[index+3] then
            print('objectValue=', object[key], ', deltaValue=', delta[index+3])
            error('Invalid, Value must be different: attribute '..key)
         end
      end

      if delta[1] ~= false then
         print('expected=', false, ', value=', delta[1])
         error('Invalid Signature')
      end

      if delta[2] ~= removedMask then
         print('expectedMask=', removedMask, ', deltaMask=', delta[2] )
         error('Invalid BITMASK')
      end

      if delta[3] ~= changedMask then
         print('expectedMask=', changedMask, ', deltaMask=', delta[3] )
         error('Invalid BITMASK')
      end
   end

   -- Checks Encoded
   local Encoded = Contract.Encode(Seed)
   testEncoded(Seed, Encoded)

   -- Checks Decoded
   local Decoded = Contract.Decode(Encoded)
   testDecoded(Seed, Decoded)

   -- Checks the Diff
   local Changed = {
      PositionX      = 736.34,                     -- CHANGED
      PositionY      = Decoded.PositionY,
      PositionZ      = Decoded.PositionZ,
      -- BodyRotationX  = Decoded.BodyRotationX,   -- REMOVED
      BodyRotationY  = Decoded.BodyRotationY,
      BodyRotationZ  = Decoded.BodyRotationZ,
      LookRotationX  = Decoded.LookRotationX,
      LookRotationY  = 736.298362,                 -- CHANGED
      --LookRotationZ  = Decoded.LookRotationZ,    -- REMOVED
      Ammo           = Decoded.Ammo,
      --Health         = Decoded.Health,           -- REMOVED
      Armor          = Decoded.Armor,
      WeaponID       = Decoded.WeaponID,
      --Nick           = Decoded.Nick,             -- REMOVED
      UserId         = Decoded.UserId,
      Alive          = false                       -- CHANGED
   }

   local Delta = Contract.Diff(Decoded, Changed)
   testDelta(Decoded, Delta, {'BodyRotationX', 'LookRotationZ', 'Health', 'Nick'}, {'PositionX', 'LookRotationY', 'Alive'})

   -- Checks the Patch
   local PatchedUp = Contract.Patch(Decoded, Delta)
   testEQL(Changed, PatchedUp)

   -- Should revert to the original value
   local Recovered = {
      PositionX      = Decoded.PositionX,          -- Recovered
      PositionY      = PatchedUp.PositionY,
      PositionZ      = PatchedUp.PositionZ,
      BodyRotationX  = Decoded.BodyRotationX,      -- Recovered
      BodyRotationY  = PatchedUp.BodyRotationY,
      BodyRotationZ  = PatchedUp.BodyRotationZ,
      LookRotationX  = PatchedUp.LookRotationX,
      LookRotationY  = Decoded.LookRotationY,      -- Recovered
      LookRotationZ  = Decoded.LookRotationZ,      -- Recovered
      Ammo           = PatchedUp.Ammo,
      Health         = Decoded.Health,             -- Recovered
      Armor          = PatchedUp.Armor,
      WeaponID       = PatchedUp.WeaponID,
      Nick           = Decoded.Nick,               -- Recovered
      UserId         = Decoded.UserId,
      Alive          = Decoded.Alive               -- Recovered
   }

   local DeltaR = Contract.Diff(PatchedUp, Recovered)
   testDelta(PatchedUp, DeltaR, {}, {'BodyRotationX', 'LookRotationZ', 'Health', 'Nick', 'PositionX', 'LookRotationY', 'Alive'})

   local PatchedUpR = Contract.Patch(PatchedUp, DeltaR)

   -- in the end, all objects must be equal
   testEQL(PatchedUpR, Recovered)
   testEQL(PatchedUpR, Seed)
   testEQL(Recovered, Seed)

   print('Unit tests successfully completed!')
end

return RuntTests