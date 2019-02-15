dofile("ShapeDatabase.lua")

-- BlockSpawner.lua --

--print("[BlockSpawner] file init")

BlockSpawner = class( nil )
BlockSpawner.maxChildCount = -1
BlockSpawner.maxParentCount = -1
BlockSpawner.connectionInput = sm.interactable.connectionType.logic + sm.interactable.connectionType.power
BlockSpawner.connectionOutput = sm.interactable.connectionType.logic
BlockSpawner.colorNormal = sm.color.new( 0x404040ff )
BlockSpawner.colorHighlight = sm.color.new( 0x606060ff )
BlockSpawner.poseWeightCount = 3

BlockSpawner.measureDistance = 20

--[[
    -----------Logic signal-------------
    Any logic         = Spawn block/part
    2nd grey          = dynamic
    3rd grey          = forceSpawn

    -----------Number signals-----------
    2nd brown         = offsetZ
    2nd red           = offsetY
    2nd magenta       = offsetX
    
    white/Color Block = color
    black             = shapeID
    
    4th brown         = sizeZ
    4th red           = sizeY
    4th magenta       = sizeX
    
    -----------Output-------------------
    1 tick signal with a delay of 2 ticks if the block is spawned.
    Can cause a false positive when there is lag present.
]]
function BlockSpawner.server_onRefresh( self )
    self:server_onCreate()
end

function BlockSpawner.server_onCreate( self )
    self.hasSpawned = false
    self.lastSpawnedShape = nil
    self.lastSpawnedShapeTick = nil
    self.selfEnabled = false
    --self.BlockSpawner = nil
end

function BlockSpawner.client_onCreate( self )
    self:printDescription()
    self:client_setSelfEnabled(false)
end

function BlockSpawner.printDescription()
    -- Console doesn't have a monospace font ;(
    local message = "Block Spawner Usage: \n"..
    "---------------Logic signal------------------------ \n"..
    "Any logic             = Spawn block/part            \n"..
    "2nd grey             = dynamic                      \n"..
    "3rd grey              = forceSpawn                  \n"..
    "---------------Number signals------------------     \n"..
    "2nd brown          = offsetZ                        \n"..
    "2nd red              = offsetY                      \n"..
    "2nd magenta      = offsetX                          \n"..
    "white/Color Block = color                           \n"..
    "black/Sensor       = shapeID                        \n"..
    "4th brown           = sizeZ                         \n"..
    "4th red               = sizeY                       \n"..
    "4th magenta       = sizeX                           \n"..
    "---------------Output-------------------------------\n"..
    "1 tick signal with a delay of 2 ticks if the block is spawned.\n"..
    "Can cause a false positive when there is lag present.\n"..
    "---------------------------------------------------------"
    print(message)
end

function BlockSpawner.server_onFixedUpdate( self, timeStep )
    self.interactable.active = false
    local wantSpawn = false --If one of the parents is active
    
    local offsetX = 0
    local offsetY = 0
    local offsetZ = 1
    local color = nil
    local rotation = nil --self.shape:getWorldRotation()
    local uuid = nil
    local numericId = 0
    local raycastUuid = sm.uuid.getNil()
    --local raycastColor = nil
    local sizeX = 1
    local sizeY = 1
    local sizeZ = 1
    local dynamic = true
    local forceSpawn = false
    local sensorShape = nil

    
    
    
    
    local parents = self.interactable:getParents()
    if #parents > 0 then
        for k,v in pairs(parents) do
            if v:getType() == "scripted" and tostring(v.shape.shapeUuid) ~= "6f2dd83e-bc0d-43f3-8ba5-d5209eb03d07" then -- Number stuff and not tick button
                if tostring(v.shape.shapeUuid) == "921a2ace-b543-4ca3-8a9b-6f3dd3132fa9" then --colorblock
                    color = sm.color.new(v.power * 2^8 + 255)
                elseif tostring(v.shape.shapeUuid) == "4081ca6f-6b80-4c39-9e79-e1f747039bec" then --smart sensor
                    if v.active then 
                        sensorShape = v.shape
                    end
                else
                    if tostring(v:getShape():getColor()) == "df7f00ff" then -- 2nd brown
                        offsetZ = v.power
                    elseif tostring(v:getShape():getColor()) == "d02525ff" then -- 2nd red
                        offsetY = v.power
                    elseif tostring(v:getShape():getColor()) == "cf11d2ff" then -- 2nd magenta
                        offsetX = v.power
                    elseif tostring(v:getShape():getColor()) == "eeeeeeff" then -- white
                        color = sm.color.new(v.power * 2^8 + 255)
                    elseif tostring(v:getShape():getColor()) == "472800ff" then -- 4th brown
                        sizeZ = v.power
                    elseif tostring(v:getShape():getColor()) == "560202ff" then -- 4th red
                        sizeY = v.power
                    elseif tostring(v:getShape():getColor()) == "520653ff" then -- 4th magenta
                        sizeX = v.power
                    elseif tostring(v:getShape():getColor()) == "222222ff" then -- black
                        numericId = round(v.power)
                    end
                end
            elseif v:getType() == "sensor" then
                if v.active then 
                    sensorShape = v.shape
                end
            else -- Logic
                if tostring(v:getShape():getColor()) == "7f7f7fff" then -- 2nd grey
                    dynamic = v.active
                elseif tostring(v:getShape():getColor()) == "4a4a4aff" then -- 3nd grey
                    forceSpawn = v.active
                else
                    if not wantSpawn and v.active then
                        wantSpawn = true
                    end
                end
            end
        end
    end
    
    local databaseEntry = shapeDatabase[tostring(numericId)]
    if sensorShape == nil and numericId >= 0 then
        if databaseEntry then
            uuid = sm.uuid.new(databaseEntry.uuid)
        else
            uuid = sm.uuid.getNil()
        end
    else
        numericId = nil
        uuid = sm.uuid.getNil()
    end
    
    --print(sm.game.getCurrentTick(), self.shape.id, uuid)
    
    
    --error()
    --print(self.shape.id, self.lastSpawnedShape, self.lastSpawnedShape ~= nil and tostring(sm.exists(self.lastSpawnedShape)) or "")
    self.interactable.active =
        self.lastSpawnedShape ~= nil and
        sm.exists(self.lastSpawnedShape) and
        self.lastSpawnedShapeTick ~= nil and
        sm.game.getCurrentTick() == self.lastSpawnedShapeTick + 1
    --if self.interactable.active then
    --    print(self.lastSpawnedShapeTick, sm.game.getCurrentTick(), self.lastSpawnedShapeTick, self.interactable.active, sm.game.getCurrentTick() - (self.lastSpawnedShapeTick ~= nil and self.lastSpawnedShapeTick or 0))
    --end
    self.lastSpawnedShape = nil
    
    local selfEnabled = wantSpawn
    
    if not self.hasSpawned and wantSpawn then
        if numericId == nil then
            --print(sm.game.getCurrentTick(), numericId)
            --print("*pokes*", sensorShape, "go do raycast")
            local hit,raycastResult = sm.physics.raycast(sensorShape.worldPosition, sensorShape.worldPosition + -sensorShape.up * self.measureDistance * -0.25)
            if hit and raycastResult.type == "body" then
                local rcShape = raycastResult:getShape()
                --local rcJoint = raycastResult:getJoint() --Raycast does not hit joints. Bug?
                
                if rcShape then
                    raycastUuid = rcShape.shapeUuid
                    color = rcShape.color
                    
                    local lookedupId = shapeDatabaseLookup[tostring(raycastUuid)]
                    if lookedupId then
                        numericId = lookedupId
                    end
                    print(shapeDatabaseLookup, lookedupId, numericId)
                end
            end
            
            --if uuid == nil then
            uuid = raycastUuid
            --end
        end
    
        -- Try spawn
        if uuid ~= sm.uuid.getNil() then
            -- Calculate rotation
            rotation = sm.quat.lookRotation(-self.shape.at, self.shape.right)
            
            -- Spawn block
            local succes, spawnedShape = pcall(sm.shape.createBlock,
                uuid,
                sm.vec3.new(sizeX, sizeY, sizeZ),
                self.shape:getWorldPosition() + rotation * sm.vec3.new(offsetX-0, offsetY-0.5, offsetZ-0.5) * 0.25,
                rotation,
                dynamic,
                forceSpawn
            )
            
            -- If the UUID is not a block, it must be a part.
            if not succes then
                succes, spawnedShape = pcall(sm.shape.createPart,
                    uuid,
                    self.shape:getWorldPosition() + rotation * sm.vec3.new(offsetX-0, offsetY-0.5, offsetZ-0.5) * 0.25,
                    rotation,
                    dynamic,
                    forceSpawn
                )
            end
            
            if succes and color then -- Set the color of the spawned shape
                spawnedShape.color = color
                print(self.shape:getBoundingBox(), self.shape:getWorldPosition(), spawnedShape:getWorldPosition(), self.shape:getWorldPosition()-spawnedShape:getWorldPosition())
            end
            
            self.lastSpawnedShape = succes and spawnedShape or nil
            self.lastSpawnedShapeTick = succes and sm.game.getCurrentTick() or nil
            
            self.hasSpawned = true
        else
            self.hasSpawned = true
        end
        
        --selfEnabled = true
        if numericId then
            self.network:sendToClients("client_setDisplay", numericId)
        end
    elseif self.hasSpawned and not wantSpawn then
        self.hasSpawned = false
    end
    
    if selfEnabled ~= self.selfEnabled then
        self.network:sendToClients("client_setSelfEnabled", selfEnabled)
        self.selfEnabled = selfEnabled
    end
end

function BlockSpawner.client_setDisplay( self, value )
    self.interactable:setUvFrameIndex(value)
end

function BlockSpawner.client_setSelfEnabled( self, value )
    --self.interactable:setPoseWeight(0, value and 1 or 0)
    self:client_setLightRedEnabled(not value)
    self:client_setLightGreenEnabled(value)
end

function BlockSpawner.client_setLightRedEnabled( self, value )
    self.interactable:setPoseWeight(1, value and 1 or 0)
end

function BlockSpawner.client_setLightGreenEnabled( self, value )
    self.interactable:setPoseWeight(2, value and 1 or 0)
end



function round(x)
  if x%2 ~= 0.5 then
    return math.floor(x+0.5)
  end
  return x-0.5
end