# luau-component-manager

A lean component manager class.

## Usage

```luau
local function sayHello(instance: Instance)
    print(`I am {instance}, and a tag`)

    return function()
        print(`{instance} is leaving. Bye bye!`)
    end
end

-- first, add tags:
local manager = ComponentManager.new()
    :add("tag_1", sayHello)
    :add("tag_2", sayHello)

-- ...then apply behavior for these tags:
local destroy = manager:run()
-- this is a standalone environment, so any new tag functionality added to the
-- manager after this point will not apply behavior

------------

-- not typical but you can also...
-- add a new tag to the manager:
manager:add("tag_3", sayHello)

-- kill the last running set of tag functionality & listeners:
destroy()
-- and now run methods for tag 1, 2, and 3 on top of the other instance
local destroyNewManager = manager:run()
```

## Caveats

- There is no method to remove a tag functionality from a `ComponentManager` instance. If you need to actively manage clusters of tag functionality, create individual `ComponentManager` instances for them.
- There are no checks for running the same behavior function on an instance; if you apply the same function to the same tag twice, that function will apply twice.

- If you need some behavior to end early, you can make use of closure properties:

```luau
local function sayHello(instance: Instance)
    local destroyed = false

    local function destroy()
        print(`{instance} is leaving. Bye bye!`)
    end

    return function()
        if destroyed == false then
            destroy()
        end
    end
end
```

Be wary of memory accumulation if using this method. These functions will be dangling until the tag on that particular instance is removed.
