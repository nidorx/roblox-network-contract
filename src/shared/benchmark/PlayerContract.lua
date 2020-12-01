
local NetworkContract = require(game.ReplicatedStorage:WaitForChild('NetworkContract'))

return function (OnMessage)
   return NetworkContract(1, {
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
   }, OnMessage)
end