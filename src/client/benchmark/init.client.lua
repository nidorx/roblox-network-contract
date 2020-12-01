repeat wait() until game:GetService('Players').LocalPlayer.Character

local RunService     = game:GetService('RunService')
local HttpService    = game:GetService('HttpService')
local StatsService   = game:GetService('Stats')
local ContractFN     = require(game.ReplicatedStorage:WaitForChild('benchmark'):WaitForChild('PlayerContract'))
local Objects        = require(game.ReplicatedStorage:WaitForChild('benchmark'):WaitForChild('Objects'))
local RunUnitTests   = require(script.Parent:WaitForChild('test'):WaitForChild('UnitTests'))

-- used to control benchmark execution
local EventControl   = game.ReplicatedStorage:WaitForChild('BenchmarkControlEvent')

-- used for normal executions (Table and Json)
local EventSimple   = game.ReplicatedStorage:WaitForChild('SimpleEvent')

local T                    = '\t'
local FINISHED             = false
local NEXT_ALGO            = nil
local NEXT_FREQUENCY       = nil
local NEXT_NUM_MESSAGES    = nil

local WAIT_SECS            = 10  -- Time you must wait to confirm that you have not received any more messages
local ALGO                 = nil
local FREQUENCY            = 0
local NUM_MESSAGES         = 0
local COUNT_MESSAGES       = 0   -- Number of messages received
local TIME_LAST_MESSAGE    = nil -- Instant of the last message received
local TIME_FIRST_MESSAGE   = nil -- First message received

local STATS_TPS            = {}
local STATS_KBPS           = {}
local STATS_HEARTBEAT      = {}
local STATS_MEMORY_TOTAL   = {}
local STATS_MEMORY_SIGNAL  = {}
local STATS_MEMORY_SCRIPT  = {}

local SEED = Objects.SEED
local Contract = ContractFN(function(data, id, isDelta, player, contract)

   -- Performs decoding in order to guarantee real numbers in the test
   if isDelta then
      contract.Patch(SEED, data)
   else
      contract.Decode(data)
   end

   COUNT_MESSAGES = COUNT_MESSAGES + 1
   TIME_LAST_MESSAGE = os.clock()
   if TIME_FIRST_MESSAGE == nil then
      TIME_FIRST_MESSAGE = TIME_LAST_MESSAGE
   end
end)

------------------------------------------------------------------------------------------------------------------------
-- Run unit tests before the benchmark
------------------------------------------------------------------------------------------------------------------------
RunUnitTests(Contract)
------------------------------------------------------------------------------------------------------------------------

EventSimple.OnClientEvent:Connect(function(data)

   if NEXT_ALGO == 'JSON' then
      -- Performs decoding in order to guarantee real numbers in the test
      HttpService:JSONDecode(data)
   end

   COUNT_MESSAGES = COUNT_MESSAGES + 1
   TIME_LAST_MESSAGE = os.clock()
   if TIME_FIRST_MESSAGE == nil then
      TIME_FIRST_MESSAGE = TIME_LAST_MESSAGE
   end
end)

-- Server inform the client that they want to start the next test
EventControl.OnClientEvent:Connect(function(message, algoName, frequency, numMessages)
   if message == 'FINISH' then
      FINISHED = true
   else
      NEXT_ALGO         = algoName
      NEXT_FREQUENCY    = frequency
      NEXT_NUM_MESSAGES = numMessages
   end
end)

-- Every second, it generates a statistical record
local SampleInterval             = 1
local TimeAccumulator            = 0
local LastSampleMessagesReceived = 0

RunService.Heartbeat:Connect(function(step)
	TimeAccumulator = TimeAccumulator + step
	if TimeAccumulator >= SampleInterval then
      TimeAccumulator = TimeAccumulator - SampleInterval

      if (NEXT_ALGO ~= nil or FINISHED) and (TIME_LAST_MESSAGE == nil or (TIME_LAST_MESSAGE + WAIT_SECS) < os.clock()) then
         -- It's been 10 seconds since you received any messages, consider that there is no more message to receive
         -- Displays statistics and tells the server that it can start executing the next round

         if TIME_LAST_MESSAGE ~= nil then

            local part           = 'client'
            local algo           = ALGO
            local frequency      = FREQUENCY
            local messages       = NUM_MESSAGES
            local received       = COUNT_MESSAGES
            local time           = TIME_LAST_MESSAGE - TIME_FIRST_MESSAGE
            local tps_min        = math.huge
            local tps_max        = -math.huge
            local tps_avg        = 0
            local kbps_min       = math.huge
            local kbps_max       = -math.huge
            local kbps_avg       = 0
            local mem_sig_min    = math.huge
            local mem_sig_max    = -math.huge
            local mem_sig_avg    = 0
            local mem_scr_min    = math.huge
            local mem_scr_max    = -math.huge
            local mem_scr_avg    = 0
            local mem_tot_min    = math.huge
            local mem_tot_max    = -math.huge
            local mem_tot_avg    = 0
            local heartbeat_min  = math.huge
            local heartbeat_max  = -math.huge
            local heartbeat_avg  = 0

            local itot     = 0
            local len      = table.getn(STATS_TPS)
            for i = 1, len do
               local tps         = STATS_TPS[i]

               -- ignores when sample did not receive message
               if tps > 0 then
                  itot = itot+1

                  local kbps        = STATS_KBPS[i]
                  local mem_sig     = STATS_MEMORY_SIGNAL[i]
                  local mem_scr     = STATS_MEMORY_SCRIPT[i]
                  local mem_tot     = STATS_MEMORY_TOTAL[i]
                  local heartbeat   = STATS_HEARTBEAT[i]

                  tps_min        = math.min(tps_min,        tps)
                  kbps_min       = math.min(kbps_min,       kbps)
                  mem_sig_min    = math.min(mem_sig_min,    mem_sig)
                  mem_scr_min    = math.min(mem_scr_min,    mem_scr)
                  mem_tot_min    = math.min(mem_tot_min,    mem_tot)
                  heartbeat_min  = math.min(heartbeat_min,  heartbeat)

                  tps_max        = math.max(tps_max,        tps)
                  kbps_max       = math.max(kbps_max,       kbps)
                  mem_sig_max    = math.max(mem_sig_max,    mem_sig)
                  mem_scr_max    = math.max(mem_scr_max,    mem_scr)
                  mem_tot_max    = math.max(mem_tot_max,    mem_tot)
                  heartbeat_max  = math.max(heartbeat_max,  heartbeat)

                  tps_avg        = tps_avg + tps
                  kbps_avg       = kbps_avg + kbps
                  mem_sig_avg    = mem_sig_avg + mem_sig
                  mem_scr_avg    = mem_scr_avg + mem_scr
                  mem_tot_avg    = mem_tot_avg + mem_tot
                  heartbeat_avg  = heartbeat_avg + heartbeat
               end
            end

            tps_avg        = tps_avg/itot
            kbps_avg       = kbps_avg/itot
            mem_sig_avg    = mem_sig_avg/itot
            mem_scr_avg    = mem_scr_avg/itot
            mem_tot_avg    = mem_tot_avg/itot
            heartbeat_avg  = heartbeat_avg/itot

            print(
               part,          T,
               algo,          T,
               frequency,     T,
               messages,      T,
               received,      T,
               time,          T,
               tps_min,       T,
               tps_max,       T,
               tps_avg,       T,
               kbps_min,      T,
               kbps_max,      T,
               kbps_avg,      T,
               mem_sig_min,   T,
               mem_sig_max,   T,
               mem_sig_avg,   T,
               mem_scr_min,   T,
               mem_scr_max,   T,
               mem_scr_avg,   T,
               mem_tot_min,   T,
               mem_tot_max,   T,
               mem_tot_avg,   T,
               heartbeat_min, T,
               heartbeat_max, T,
               heartbeat_avg
            )
         end

         -- reset
         COUNT_MESSAGES       = 0
         TIME_LAST_MESSAGE    = nil
         TIME_FIRST_MESSAGE   = nil
         STATS_TPS            = {}
         STATS_KBPS           = {}
         STATS_HEARTBEAT      = {}
         STATS_MEMORY_TOTAL   = {}
         STATS_MEMORY_SIGNAL  = {}
         STATS_MEMORY_SCRIPT  = {}
         ALGO                 = NEXT_ALGO
         FREQUENCY            = NEXT_FREQUENCY
         NUM_MESSAGES         = NEXT_NUM_MESSAGES
         NEXT_ALGO            = nil
         NEXT_FREQUENCY       = nil
         NEXT_NUM_MESSAGES    = nil

         TimeAccumulator            = 0
         LastSampleMessagesReceived = 0

         if FINISHED then
            print('FINISHED')
         else
            -- tells the server to start sending
            EventControl:FireServer('INIT')
         end
      else
         table.insert(STATS_TPS,             COUNT_MESSAGES - LastSampleMessagesReceived)
         table.insert(STATS_KBPS,            StatsService.DataReceiveKbps)
         table.insert(STATS_HEARTBEAT,       StatsService.HeartbeatTimeMs)
         table.insert(STATS_MEMORY_SIGNAL,   StatsService:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.Signals))
         table.insert(STATS_MEMORY_SCRIPT,   StatsService:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag.Script))
         table.insert(STATS_MEMORY_TOTAL,    StatsService:GetTotalMemoryUsageMb())
         LastSampleMessagesReceived = COUNT_MESSAGES
      end
    end
end)

-- HEADERS
print(
   'part',           T,
   'algo',           T,
   'frequency',      T,
   'messages',       T,
   'received',       T,
   'time',           T,
   'tps_min',        T,
   'tps_max',        T,
   'tps_avg',        T,
   'kbps_min',       T,
   'kbps_max',       T,
   'kbps_avg',       T,
   'mem_sig_min',    T,
   'mem_sig_max',    T,
   'mem_sig_avg',    T,
   'mem_scr_min',    T,
   'mem_scr_max',    T,
   'mem_scr_avg',    T,
   'mem_tot_min',    T,
   'mem_tot_max',    T,
   'mem_tot_avg',    T,
   'heartbeat_min',  T,
   'heartbeat_max',  T,
   'heartbeat_avg'
)
