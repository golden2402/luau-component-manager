--!strict

local CollectionService = game:GetService("CollectionService")

local function useDestructor()
	-- your maid creation goes here

	return function()
		-- your created maid's destroy goes here
	end, function(item: () -> () | RBXScriptConnection)
		-- your created maid's task add goes here
	end
end

export type ComponentFunction = (instance: Instance) -> () -> ()

type ComponentManagerData = {
	_functions: { [string]: ComponentFunction },
}

local function instanceToKey(instance: Instance): string
	return tostring(instance)
end

local ComponentManager = {}
ComponentManager.__index = ComponentManager

export type ComponentManager = typeof(setmetatable({} :: ComponentManagerData, ComponentManager))

function ComponentManager.new(): ComponentManager
	return setmetatable({ _functions = {} }, ComponentManager)
end

function ComponentManager.add(self: ComponentManager, tag: string, componentFunction: ComponentFunction)
	self._functions[tag] = componentFunction
	return self
end

function ComponentManager.run(self: ComponentManager)
	local destructor, addToDestructor = useDestructor()
	local destroying = false

	local cleanupMap: { [string]: () -> () } = {}

	for tag, create in self._functions do
		local function onInstanceAdded(instance: Instance)
			assert(destroying == false)
			cleanupMap[instanceToKey(instance)] = create(instance)
		end

		addToDestructor(CollectionService:GetInstanceAddedSignal(tag):Connect(onInstanceAdded))
		addToDestructor(CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
			assert(destroying == false)

			local cleanup = cleanupMap[instanceToKey(instance)]
			if cleanup ~= nil then
				cleanup()
			end
		end))

		for _, component in CollectionService:GetTagged(tag) do
			onInstanceAdded(component)
		end
	end

	addToDestructor(function()
		local i, cleanup = next(cleanupMap)
		while i ~= nil do
			cleanupMap[i] = nil
			cleanup()

			i, cleanup = next(cleanupMap)
		end
	end)

	return function()
		destroying = true
		destructor()
	end
end

return ComponentManager
