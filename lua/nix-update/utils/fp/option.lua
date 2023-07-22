



 local Option = {}


 Option["some?"] = function(mx)
 local _1_ = mx if ((_G.type(_1_) == "table") and ((_1_)[1] == "some")) then local _ = {select(2, (table.unpack or _G.unpack)(_1_))} return true elseif true then local _ = _1_ return false else return nil end end


 Option["none?"] = function(mx)
 local _3_ = mx if ((_G.type(_3_) == "table") and ((_3_)[1] == "none")) then return true elseif true then local _ = _3_ return false else return nil end end


 Option["option?"] = function(mx)
 return (Option["some?"](mx) or Option["none?"](mx)) end



 Option.some = function(...)
 return {"some", ...} end
 Option.none = function(...)
 return {"none"} end
 Option.new = function(x)
 local _5_ = x if (_5_ == nil) then
 return Option.none() elseif true then local _ = _5_
 return Option.some(x) else return nil end end


 Option.pure = function(...)
 return Option.ok(...) end
 Option.join = function(mx)
 local _7_ = mx if ((_G.type(_7_) == "table") and ((_7_)[1] == "some") and ((_G.type((_7_)[2]) == "table") and (((_7_)[2])[1] == "some"))) then local x = {select(2, (table.unpack or _G.unpack)((_7_)[2]))}
 return unpack(x) else return nil end end
 Option[">>="] = function(mx, f)
 local _9_ = mx if ((_G.type(_9_) == "table") and ((_9_)[1] == "some")) then local x = {select(2, (table.unpack or _G.unpack)(_9_))}
 return f(unpack(x)) elseif true then local _ = _9_
 return mx else return nil end end


 Option.unwrap = function(mx)
 local _11_ = mx if ((_G.type(_11_) == "table") and ((_11_)[1] == "some")) then local x = {select(2, (table.unpack or _G.unpack)(_11_))}
 return unpack(x) elseif ((_G.type(_11_) == "table") and ((_11_)[1] == "none")) then
 return nil else return nil end end
 Option["unwrap!"] = function(mx)
 local _13_ = mx if ((_G.type(_13_) == "table") and ((_13_)[1] == "some")) then local x = {select(2, (table.unpack or _G.unpack)(_13_))}
 return unpack(x) elseif ((_G.type(_13_) == "table") and ((_13_)[1] == "none")) then
 return error("Tried to unwrap a none") else return nil end end

 return Option
