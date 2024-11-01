



 local Result = {}


 Result["ok?"] = function(mx)
 if ((_G.type(mx) == "table") and (mx[1] == "ok")) then local _ = {select(2, (table.unpack or _G.unpack)(mx))} return true else local _ = mx return false end end


 Result["err?"] = function(mx)
 if ((_G.type(mx) == "table") and (mx[1] == "err")) then local _ = {select(2, (table.unpack or _G.unpack)(mx))} return true else local _ = mx return false end end


 Result["result?"] = function(mx)
 return (Result["ok?"](mx) or Result["err?"](mx)) end



 Result.ok = function(...)
 return {"ok", ...} end
 Result.err = function(...)
 return {"err", ...} end
 Result.new = function(...)
 local _3_, _4_ = ... local and_5_ = (nil ~= _3_) if and_5_ then local r = _3_ and_5_ = Result["result?"](r) end if and_5_ then local r = _3_
 return r elseif ((_3_ == nil) and (nil ~= _4_)) then local err = _4_
 return Result.err(err) else local _ = _3_
 return Result.ok(...) end end


 Result.map = function(mx, f)
 if ((_G.type(mx) == "table") and (mx[1] == "ok")) then local ok = {select(2, (table.unpack or _G.unpack)(mx))}
 return Result.ok(f(unpack(ok))) else local _ = mx
 return mx end end
 Result.maperr = function(mx, f)
 if ((_G.type(mx) == "table") and (mx[1] == "err")) then local err = {select(2, (table.unpack or _G.unpack)(mx))}
 return Result.err(f(unpack(err))) else local _ = mx
 return mx end end
 Result.bimap = function(mx, of, ef)
 if ((_G.type(mx) == "table") and (mx[1] == "ok")) then local ok = {select(2, (table.unpack or _G.unpack)(mx))}
 return Result.ok(of(unpack(ok))) elseif ((_G.type(mx) == "table") and (mx[1] == "err")) then local err = {select(2, (table.unpack or _G.unpack)(mx))}
 return Result.err(ef(unpack(err))) else return nil end end


 Result.pure = function(...)
 local _11_ = ... if (_11_ == nil) then
 return {"none"} else local _ = _11_
 return {"some", ...} end end
 Result.join = function(mx)
 if ((_G.type(mx) == "table") and (mx[1] == "some") and ((_G.type(mx[2]) == "table") and (mx[2][1] == "some"))) then local x = {select(2, (table.unpack or _G.unpack)(mx[2]))}
 return unpack(x) else return nil end end
 Result[">>="] = function(mx, f)
 if ((_G.type(mx) == "table") and (mx[1] == "ok")) then local ok = {select(2, (table.unpack or _G.unpack)(mx))}
 return f(unpack(ok)) else local _ = mx
 return mx end end


 Result.validate = function(v, p, e)
 local _3e_3d_3d_15_ = Result[">>="] local pure_16_ = Result["pure"] local function _17_(x)

 if p(x) then
 return Result.new(x) else
 return Restut.err(e) end end return _3e_3d_3d_15_(v, _17_) end
 Result.unwrap = function(mx)
 if ((_G.type(mx) == "table") and (mx[1] == "ok")) then local ok = {select(2, (table.unpack or _G.unpack)(mx))}
 return unpack(ok) else local _ = mx
 return nil end end
 Result["unwrap!"] = function(mx)
 if ((_G.type(mx) == "table") and (mx[1] == "ok")) then local ok = {select(2, (table.unpack or _G.unpack)(mx))}
 return unpack(ok) elseif ((_G.type(mx) == "table") and (mx[1] == "err")) then local err = {select(2, (table.unpack or _G.unpack)(mx))}
 return error(err) else return nil end end

 return Result
