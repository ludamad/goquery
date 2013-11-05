-- Included with the standard prelude, provides macros that only use global variables and 
-- the following supported API functions:
--  * goal.CallableNode
--  * goal.Defer 
--  * TODO
macros = {}

function macros.CaseType(value)
    -- See test 09 for a use example.
    -- Syntatic sugar backflips follow:
    local conditionWrap,statementWrap
    function conditionWrap(f) return function(type) 
        return statementWrap(f(TypeCheck(type, value)))
    end end
    function statementWrap(f) return function(...) 
        local R = f(...) ; return goal.CallableNode(R, conditionWrap(R))
    end end
    return conditionWrap(Case)
end

local function EventCaseWrap(casef) return function(ev, --[[Optional]] val)
    local innerCase = val and casef(val) or casef
    goal.Defer(
        function() Event(ev)(innerCase)
    end)
    local function chainCall(...) innerCase = innerCase(...) ; return chainCall end ; return chainCall
end end
macros.EventCase = EventCaseWrap(Case)
-- Right to the point if you want a type switch, usually 
macros.EventCaseType = EventCaseWrap(macros.CaseType)

function macros.ForAll(value) return ForPairs("")(value) end

-- Expose to global context:
for k, v in pairs(macros) do _G[k] = v end