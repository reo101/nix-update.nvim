



 local Option = {}


 Option["some?"] = function(mx)
 if ((_G.type(mx) == "table") and (mx[1] == "some")) then local _ = {select(2, (table.unpack or _G.unpack)(mx))} return true else local _ = mx return false end end


 Option["none?"] = function(mx)
 if ((_G.type(mx) == "table") and (mx[1] == "none")) then return true else local _ = mx return false end end


 Option["option?"] = function(mx)
 return (Option["some?"](mx) or Option["none?"](mx)) end



 Option.some = function(...)
 return {"some", ...} end
 Option.none = function(...)
 return {"none"} end
 Option.new = function(x)
 if (x == nil) then
 return Option.none() else local _ = x
 return Option.some(x) end end


 Option.pure = function(...)
 return Option.ok(...) end
 Option.join = function(mx)
 if ((_G.type(mx) == "table") and (mx[1] == "some") and ((_G.type(mx[2]) == "table") and (mx[2][1] == "some"))) then local x = {select(2, (table.unpack or _G.unpack)(mx[2]))}
 return unpack(x) else return nil end end
 Option[">>="] = function(mx, f)
 if ((_G.type(mx) == "table") and (mx[1] == "some")) then local x = {select(2, (table.unpack or _G.unpack)(mx))}
 return f(unpack(x)) else local _ = mx
 return mx end end


 Option.unwrap = function(mx)
 if ((_G.type(mx) == "table") and (mx[1] == "some")) then local x = {select(2, (table.unpack or _G.unpack)(mx))}
 return unpack(x) elseif ((_G.type(mx) == "table") and (mx[1] == "none")) then
 return nil else return nil end end
 Option["unwrap!"] = function(mx)
 if ((_G.type(mx) == "table") and (mx[1] == "some")) then local x = {select(2, (table.unpack or _G.unpack)(mx))}
 return unpack(x) elseif ((_G.type(mx) == "table") and (mx[1] == "none")) then
 return error("Tried to unwrap a none") else return nil end end

 return Option
