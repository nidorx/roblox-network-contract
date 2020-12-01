
local Players        = game:GetService("Players")
local RunService     = game:GetService('RunService')
local HttpService    = game:GetService('HttpService')
local ContractFN     = require(game.ReplicatedStorage:WaitForChild('benchmark'):WaitForChild('PlayerContract'))
local Objects        = require(game.ReplicatedStorage:WaitForChild('benchmark'):WaitForChild('Objects'))

local PLAYER
local SEED     = Objects.SEED
local OBJECTS  = Objects.GetList()
local Contract = ContractFN()

-- used to control benchmark execution
local EventControl   = Instance.new('RemoteEvent')
EventControl.Parent  = game.ReplicatedStorage
EventControl.Name    = 'BenchmarkControlEvent'

-- used for normal executions (Table and Json)
local EventSimple   = Instance.new('RemoteEvent')
EventSimple.Parent  = game.ReplicatedStorage
EventSimple.Name    = 'SimpleEvent'

-- message sending algorithms
local ALGOS = {
   -- Table
   function(data)
      EventSimple:FireClient(PLAYER, data)
   end,
   -- JSON
   function(data)
      EventSimple:FireClient(PLAYER, HttpService:JSONEncode(data))
   end,
   -- NetworkContract
   function(data)
      Contract.Send(Contract.Encode(data), nil, PLAYER)
   end,
   -- NetworkContract + Delta
   function(data)
      Contract.Send(Contract.Diff(SEED, data), nil, PLAYER)
   end
}

local ALGO_NAME         = { 'TABLE', 'JSON', 'CONTRACT', 'CONTRACT_DELTA' }
local SEND_FREQUENCY    = { 512, 1024, 2048, 4096 }   -- messages per second to be sent
local SEND_MESSAGES     = { 1024, 5000, 25000 }       -- total number of messages to be sent

local WAITING           = true
local FINISHED          = false
local CURR_ALGO         = 1
local CURR_OBJECT       = 1
local CURR_MESSAGES     = 1
local CURR_FREQUENCY    = 1

local FixDeltaTime      = 0   -- Ensures execution frequency
local TimeAccumulator   = 0   -- Ensures execution frequency
local NumMessages       = 0   -- number of objects that will be sent in this batch
local AlgoSend          = nil -- Algorithm currently being used for sending messages
local FIRST_UPDATE_TIME = nil

local function RunNext()
   WAITING = true

   if SEND_MESSAGES[CURR_MESSAGES] == nil then
      CURR_MESSAGES  = 1
      CURR_FREQUENCY = CURR_FREQUENCY + 1

      if SEND_FREQUENCY[CURR_FREQUENCY] == nil then
         CURR_FREQUENCY = 1
         CURR_ALGO      = CURR_ALGO + 1

         if ALGOS[CURR_ALGO] == nil then
            FINISHED = true
         end
      end
   end

   if not FINISHED then
      CURR_OBJECT       = 1
      TimeAccumulator   = 0
      FIRST_UPDATE_TIME = nil
      AlgoSend          = ALGOS[CURR_ALGO]
      NumMessages       = SEND_MESSAGES[CURR_MESSAGES]
      FixDeltaTime      = 1000/SEND_FREQUENCY[CURR_FREQUENCY]/1000
      CURR_MESSAGES     = CURR_MESSAGES + 1

      -- inform the player about which test will be performed now, wait for the client to inform when they can start 
      -- the next test
      EventControl:FireClient(PLAYER, 'INIT', ALGO_NAME[CURR_ALGO], SEND_FREQUENCY[CURR_FREQUENCY], NumMessages)
   else
      EventControl:FireClient(PLAYER, 'FINISH')
   end
end

-- When the player informs, starts sending messages
-- It is necessary to wait for the client because he has information about when the messages stop arriving
EventControl.OnServerEvent:Connect(function(player, message)
   if message == 'INIT' then
      WAITING = false
   end
end)

RunService.Stepped:Connect(function()
   if WAITING or FINISHED then
      return
   end

   local now = os.clock()
   if FIRST_UPDATE_TIME == nil then
      FIRST_UPDATE_TIME = now
   end

   now = now - FIRST_UPDATE_TIME

   if TimeAccumulator == 0 then
      TimeAccumulator = now
   end

   while TimeAccumulator < now do

      if CURR_OBJECT >  NumMessages then
         RunNext()
         break
      end

      AlgoSend(OBJECTS[CURR_OBJECT])
      CURR_OBJECT = CURR_OBJECT+1
      TimeAccumulator = TimeAccumulator + FixDeltaTime
   end
end)

-- waits for player to connect to start execution
Players.PlayerAdded:Connect(function(player)
   PLAYER = player

   RunNext()
end)
