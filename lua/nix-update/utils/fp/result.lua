



 local Result = {}


 Result["ok?"] = function(mx)
 local _1_ = mx if ((_G.type(_1_) == "table") and ((_1_)[1] == "ok")) then local _ = {select(2, (table.unpack or _G.unpack)(_1_))} return true elseif true then local _ = _1_ return false else return nil end end


 Result["err?"] = function(mx)
 local _3_ = mx if ((_G.type(_3_) == "table") and ((_3_)[1] == "err")) then local _ = {select(2, (table.unpack or _G.unpack)(_3_))} return true elseif true then local _ = _3_ return false else return nil end end


 Result["result?"] = function(mx)
 return (Result["ok?"](mx) or Result["err?"](mx)) end



 Result.ok = function(...)
 return {"ok", ...} end
 Result.err = function(...)
 return {"err", ...} end
 Result.new = function(...)
 local _5_, _6_ = ... local function _7_(...) local r = _5_ return Result["result?"](r) end if ((nil ~= _5_) and _7_(...)) then local r = _5_
 return r elseif ((_5_ == nil) and (nil ~= _6_)) then local err = _6_
 return Result.err(err) elseif true then local _ = _5_
 return Result.ok(...) else return nil end end


 Result.map = function(mx, f)
 local _9_ = mx if ((_G.type(_9_) == "table") and ((_9_)[1] == "ok")) then local ok = {select(2, (table.unpack or _G.unpack)(_9_))}
 return Result.ok(f(unpack(ok))) elseif true then local _ = _9_
 return mx else return nil end end
 Result.maperr = function(mx, f)
 local _11_ = mx if ((_G.type(_11_) == "table") and ((_11_)[1] == "err")) then local err = {select(2, (table.unpack or _G.unpack)(_11_))}
 return Result.err(f(unpack(err))) elseif true then local _ = _11_
 return mx else return nil end end
 Result.bimap = function(mx, of, ef)
 local _13_ = mx if ((_G.type(_13_) == "table") and ((_13_)[1] == "ok")) then local ok = {select(2, (table.unpack or _G.unpack)(_13_))}
 return Result.ok(of(unpack(ok))) elseif ((_G.type(_13_) == "table") and ((_13_)[1] == "err")) then local err = {select(2, (table.unpack or _G.unpack)(_13_))}
 return Result.err(ef(unpack(err))) else return nil end end


 Result.pure = function(...)
 local _15_ = ... if (_15_ == nil) then
 return {"none"} elseif true then local _ = _15_
 return {"some", ...} else return nil end end
 Result.join = function(mx)
 local _17_ = mx if ((_G.type(_17_) == "table") and ((_17_)[1] == "some") and ((_G.type((_17_)[2]) == "table") and (((_17_)[2])[1] == "some"))) then local x = {select(2, (table.unpack or _G.unpack)((_17_)[2]))}
 return unpack(x) else return nil end end
 Result[">>="] = function(mx, f)
 local _19_ = mx if ((_G.type(_19_) == "table") and ((_19_)[1] == "ok")) then local ok = {select(2, (table.unpack or _G.unpack)(_19_))}
 return f(unpack(ok)) elseif true then local _ = _19_
 return mx else return nil end end


 Result.validate = function(v, p, e)
 if true then local _let_23_ = Result local _3e_3d_3d_21_ = _let_23_[">>="] local pure_22_ = _let_23_["pure"] local function _24_(x)

 if p(x) then
 return Result.new(x) else
 return Restut.err(e) end end return _3e_3d_3d_21_(v, _24_) else return nil end end
 Result.unwrap = function(mx)
 local _27_ = mx if ((_G.type(_27_) == "table") and ((_27_)[1] == "ok")) then local ok = {select(2, (table.unpack or _G.unpack)(_27_))}
 return unpack(ok) elseif true then local _ = _27_
 return nil else return nil end end
 Result["unwrap!"] = function(mx)
 local _29_ = mx if ((_G.type(_29_) == "table") and ((_29_)[1] == "ok")) then local ok = {select(2, (table.unpack or _G.unpack)(_29_))}
 return unpack(ok) elseif ((_G.type(_29_) == "table") and ((_29_)[1] == "err")) then local err = {select(2, (table.unpack or _G.unpack)(_29_))}
 return error(err) else return nil end end

 return Result
