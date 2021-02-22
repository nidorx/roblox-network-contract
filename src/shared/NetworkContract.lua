--[[
   NetworkContract v1.2 [2020-12-05 12:40]

   Facilitates Client Server communication through Events. Has Encode, Decode, Diff, Patch and Message Knowledge

   https://github.com/nidorx/roblox-network-contract

   Discussions about this script are at https://devforum.roblox.com/t/900276

   ------------------------------------------------------------------------------

   MIT License

   Copyright (c) 2020 Alex Rodin

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.
]]

local RunService = game:GetService('RunService')

-- binary operators
local band      = bit32.band
local bor       = bit32.bor
local lshift    = bit32.lshift

-- https://en.wikipedia.org/wiki/Bit_field
local FLAGS = {}
local ZERO  = 0x0
for i=0, 31 do
   -- (1 << 0) = 1, (1 << 1) = 2, (1 << 2) = 4, ... (1 << 31) = 2147483648 = "1111 1111 1111 1111 1111 1111 1111 1111"
   table.insert(FLAGS, lshift(1, i))
end

-- Exponential weighted moving average RTT (https://en.wikipedia.org/wiki/Round-trip_delay)
local RTT_ALPHA      = 0.2
local RTT_ALPHA_INV  = 1 - RTT_ALPHA
local RTTClients     = {}
local RTTServer      = 0

local function EMPTY_FN() end

-- precision (aka 1e-5)
local EPSILON = 0.00001

local function FuzzyEqNumber(a, b)
   if a == b then
      return true
   end

   return math.abs(a - b) < EPSILON
end

local function FuzzyEqCFrame(cframea, cframeb)
   if cframea == cframeb then
      return true
   end

   if not cframea.Position:FuzzyEq(cframeb.Position) then
      return false
   end

   if not cframea.LookVector:FuzzyEq(cframeb.LookVector) then
      return false
   end

   if not cframea.RightVector:FuzzyEq(cframeb.RightVector) then
      return false
   end

   if not cframea.UpVector:FuzzyEq(cframeb.UpVector) then
      return false
   end

   return true
end

--[[
   Generates an encoded record for transport.

   The resulting record has the following format: {TRUE, BITMASK, VALUE_A, VALUE_B, VALUE_N ...}

   An important detail is that the data is arranged respecting the index of the contract's attributes, this reduces 
   the time needed to perform the decoding (which validates the BITMASKs in order).
]]
local function Encode(data, IDX_TO_KEY)
   local mask  = ZERO
   local out   = { true, mask }

   for index, key in ipairs(IDX_TO_KEY) do
      local value = data[key]
      if value ~= nil then
         mask = bor(mask, FLAGS[index])
         table.insert(out, value)
      end
   end

   out[2] = mask

   return out
end

--[[
   It decodes the data encoded by the Encode method.

   An encoded record has the following signature {TRUE, BITMASK, VALUE_A, VALUE_B, VALUE_N ...}. The values are 
   arranged respecting the ordering of the contract's attributes.

   Where:
      TRUE     = Always true, to differentiate from a DIFF
      BITMASK  = Attribute Ids
      VALUE_N  = Values

   In order for the algorithm to work with the highest possible performance, it is important that the contract takes 
   into account this aspect, the attributes that are carried more frequently must be placed at the beginning of the contract.
]]
local function Decode(data, IDX_TO_KEY, LEN)
   if not data then
      return {}
   end

   local out       = {}
   local len       = table.getn(data)
   local mask      = data[2]
   local lastIdx   = 1

   for i=3, len do
      for currIdx=lastIdx, LEN do     
         lastIdx = lastIdx+1
         if band(mask, FLAGS[currIdx]) ~= ZERO then
            out[IDX_TO_KEY[currIdx]] = data[i]
            break
         end
      end
   end

   return out
end

--[[
   Generates a Diff (delta) of two objects. A diff contains the following signature:

   { BITMASK_DEL, BITMASK_MOD, VALUE_A, VALUE_B, VALUE_N ...}

   Where:
      BITMASK_DEL    = Attribute IDs removed
      BITMASK_MOD    = Modified attribute ids
      VALUE_N        = Values modified
]]
local function Diff(old, nue, IDX_TO_KEY)

   local maskMod   = ZERO
   local maskDel   = ZERO
   local out       = { maskDel, maskMod }

   for index, key in ipairs(IDX_TO_KEY) do
      local aVal = old[key]
      local bVal = nue[key]

      if aVal == nil then
         if bVal ~= nil then
            -- added value
            maskMod = bor(maskMod, FLAGS[index])
            table.insert(out, bVal)
         end
      elseif bVal == nil then
         -- A exists and B has been removed
         maskDel = bor(maskDel, FLAGS[index])
      else
         -- the two values exist, compare difference
         local aType =  typeof(aVal)
         local bType =  typeof(bVal)
         local diff = false

         if aType == bType then
            if aType == 'number' and not FuzzyEqNumber(aVal, bVal) then
               diff = true
            elseif aType == 'Vector3' and not aVal:FuzzyEq(bVal) then
               diff = true
            elseif aType == 'CFrame' and not FuzzyEqCFrame(aVal, bVal) then
               diff = true
            elseif aVal ~= bVal then
               diff = true
            end
         elseif aVal ~= bVal then
            diff = true
         end

         if diff then
            -- modified value
            maskMod = bor(maskMod, FLAGS[index])
            table.insert(out, bVal)
         end
      end
   end

   out[1] = maskDel
   out[2] = maskMod

   return out
end

--[[
   Apply the delta to an object, returning the result of the join. A diff contains the following signature:

   { BITMASK_DEL, BITMASK_MOD, VALUE_A, VALUE_B, VALUE_N ...}

   Where:
      BITMASK_DEL    = Attribute IDs removed
      BITMASK_MOD    = Modified attribute ids
      VALUE_N        = Values modified
]]
local function Patch(old, delta, IDX_TO_KEY, KEY_TO_IDX, LEN)
   if not delta then
      delta = { ZERO, ZERO }
   end

   if not old then
      old = {}
   end

   local out       = {}
   local maskDel   = delta[1] -- removals
   local maskMod   = delta[2] -- additions / changes
   local ignored   = {}       -- attributes that will be ignored when copying from old
   local len       = table.getn(delta)

   local lastIdx   = 1

   if maskMod ~= ZERO then
      for i=3, len do
         for currIdx=lastIdx, LEN do
            lastIdx     = lastIdx+1
            local flag  = FLAGS[currIdx]

            if band(maskDel, flag) ~= ZERO then
               -- data removed
               ignored[currIdx] = true
            elseif band(maskMod, flag) ~= ZERO then
               -- changed or new data
               ignored[currIdx] = true
               out[IDX_TO_KEY[currIdx]] = delta[i]
               break
            end
         end
      end
   end

   -- validation of removed items (if they still exist)
   if maskDel >= lshift(1, lastIdx-1) then
      for currIdx=lastIdx, LEN do
         lastIdx = lastIdx+1
         if band(maskDel, FLAGS[currIdx]) ~= ZERO then
            ignored[currIdx] = true
         end
      end
   end

   -- copies the original data that has not been ignored (removed or modified)
   for key,value in pairs(old) do
      local index = KEY_TO_IDX[key]
      if index ~= nil and value ~= nil and not ignored[index]  then
         out[key] = value
      end
   end

   return out
end

local function IsDelta(data)
   return data[1] ~= true
end

--[[
   Instantiates a new contract.

   Contracts are used to encode and decode messages.

   This standard format makes it possible to create delta changes and diffs

   Only simple objects (Flat) are accepted as input and preferably primitive data.

   Eg A Vector3, the ideal is to transport the elements (X, Y, Z) separately, this will reduce the size of the delta
   carried when only

   Params:
      ID                {Number|String}
      attributes        {String []}
      OnMessage         {Function (data, id, isDelta, player, contract)}
      OnAcknowledge     {Function (id, player, contract)}
      AutoAcknowledge   {bool} default true
]]
local function CreateNewContract(ID, attributes, OnMessage, OnAcknowledge, AutoAcknowledge)

   local KEY_TO_IDX = {}
   local IDX_TO_KEY = {}

   for index, key in ipairs(attributes) do
      KEY_TO_IDX[key] = index
      table.insert(IDX_TO_KEY, key)
   end

   local LEN = table.getn(IDX_TO_KEY)

   local Contract =  {
      Encode = function(data)
         return Encode(data, IDX_TO_KEY)
      end,

      Decode = function(data)
         return Decode(data, IDX_TO_KEY, LEN)
      end,

      Diff = function(old, nue)
         return Diff(old, nue, IDX_TO_KEY)
      end,

      Patch = function(old, delta)
         return Patch(old, delta, IDX_TO_KEY, KEY_TO_IDX, LEN)
      end,

      IsDelta = function(data)
         return IsDelta(data)
      end
   }

   if OnMessage == nil then
      -- If OnMessage is not informed it means that the interest in this contract is only to use the utility
      -- methods (Encode, Decode, Diff and Patch). Thus, there is no need to create events
      Contract.Send        = EMPTY_FN
      Contract.Acknowledge = EMPTY_FN
      Contract.RTT = function()
         return 0
      end
   else
      local Event
      local EventName = 'NCRCT_'..ID

      AutoAcknowledge  = AutoAcknowledge ~= false

      if RunService:IsServer() then
         if game.ReplicatedStorage:FindFirstChild(EventName) then
            error('There is already an event with the given ID ('..EventName..')')
         end

         Event = Instance.new('RemoteEvent')
         Event.Parent = game.ReplicatedStorage
         Event.Name = EventName

         -- latest messages sent per player, used to calculate RTT
         local LastMessages = {}

         local function CalculateRTT(messageId, player)
            local userId = player.UserId
            if LastMessages[userId] ~= nil and LastMessages[userId][messageId] ~= nil then               
               if RTTClients[userId] == nil then
                  RTTClients[userId] = {
                     LastRttTime = -math.huge,
                     RTT         = 0
                  }
               end
               local clientRtt   = RTTClients[userId]
               local sendTime    = LastMessages[userId][messageId]

               -- ignore if you have already processed a more recent message
               if sendTime > clientRtt.LastRttTime then
                  local SampleRTT = os.clock() - sendTime
                  if clientRtt.RTT == 0 then
                     clientRtt.RTT = SampleRTT
                  else
                     -- EstimatedRTT = α*SampleRTT + (1- α)*EstimatedRTT
                     clientRtt.RTT = RTT_ALPHA * SampleRTT + RTT_ALPHA_INV * clientRtt.RTT
                  end
                  clientRtt.LastRttTime = sendTime
               end               
               LastMessages[userId][messageId] = nil
            end
         end

         -- Receives client messages
         Event.OnServerEvent:Connect(function(player, message)
            local data  = message[1]
            local messageId    = message[2]

            if data == true then
               -- Acknowledgement  message
               if messageId ~= nil then
                  if AutoAcknowledge then
                     CalculateRTT(messageId, player)
                  end

                  if OnAcknowledge ~= nil then
                     OnAcknowledge(messageId, player, Contract)
                  end
               end
            else
               -- the message is never nil
               if data ~= nil then
                  if AutoAcknowledge and messageId ~= nil then
                     -- Sends knowledge message to the player
                     Event:FireClient(player, {true, messageId})
                  end
                  OnMessage(data, messageId, IsDelta(data), player, Contract)
               end
            end
         end)

         Contract.Send = function(data, messageId, player)
            if data == nil then
               return
            end
            if AutoAcknowledge and messageId ~= nil then
               -- Records the moment of sending the message, used to calculate the RTT of that client
               -- Only do this if auto responder is set up
               local userId = player.UserId
               if LastMessages[userId] == nil then
                  LastMessages[userId] = {}
               end
               if LastMessages[userId][messageId] == nil then
                  -- only saves the first time the message with this code was sent
                  LastMessages[userId][messageId] = os.clock()
               end
            end

            Event:FireClient(player, {data, messageId})
         end

         Contract.Acknowledge = function(id, player)
            -- Sends knowledge message to the player
            Event:FireClient(player, {true, id})
         end

         -- Average Client RTT
         Contract.RTT = function(player)
            local clientRtt = RTTClients[player.UserId]
            if clientRtt ~= nil then
               return clientRtt.RTT
            end
            return 0
         end
      else
         Event = game.ReplicatedStorage:WaitForChild(EventName)

         -- latest messages sent to the server
         local LastMessages = {}
         local LastRttTime = -math.huge

         local function CalculateRTT(messageId)
            if LastMessages[messageId] ~= nil then      
               local sendTime = LastMessages[messageId]
               -- ignore if you have already processed a more recent message
               if sendTime > LastRttTime then
                  local SampleRTT = os.clock() - sendTime
                  if RTTServer == 0 then
                     RTTServer = SampleRTT
                  else
                     -- EstimatedRTT = α*SampleRTT + (1- α)*EstimatedRTT
                     RTTServer = RTT_ALPHA * SampleRTT + RTT_ALPHA_INV * RTTServer
                  end
                  LastRttTime = sendTime
               end

               LastMessages[messageId] = nil
            end
         end

         -- Receives server messages
         Event.OnClientEvent:Connect(function(message)
            local data        = message[1]
            local messageId   = message[2]

            if data == true then
               -- Acknowledgement  message
               if messageId ~= nil then

                  if AutoAcknowledge then
                     CalculateRTT(messageId)
                  end

                  if OnAcknowledge ~= nil then
                     OnAcknowledge(messageId, nil, Contract)
                  end
               end
            else
               -- the message is never nil
               if data ~= nil then
                  if AutoAcknowledge and messageId ~= nil then
                     -- Sends knowledge message to the server
                     Event:FireServer({true, messageId})
                  end
   
                  OnMessage(data, messageId, IsDelta(data), nil, Contract)
               end
            end
         end)

         Contract.Send = function(data, messageId)
            if data == nil then
               return
            end
            if AutoAcknowledge and messageId ~= nil then
               -- Records the moment of sending the message, used to calculate the RTT of that client
               -- Only do this if auto responder is set up
               if LastMessages[messageId] == nil then
                  -- Only saves the first time the message with this code was sent
                  LastMessages[messageId] = os.clock()
               end
            end
            Event:FireServer({data, messageId})
         end

         Contract.Acknowledge = function(id)
            -- Sends knowledge message to the server
            Event:FireServer({true, id})
         end

         Contract.RTT = function()
            return RTTServer
         end
      end
   end

   return Contract
end

return CreateNewContract
