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

-- Right to the point if you want a type switch, usually 
function macros.EventCaseType(ev, val)
    local innerCase = macros.CaseType(val)
    goal.Defer(
        function() Event(ev)(innerCase)
    end)
    local function chainCall(...) innerCase = innerCase(...) ; return chainCall end ; return chainCall
end

-- Expose to global context:
for k, v in pairs(macros) do _G[k] = v end