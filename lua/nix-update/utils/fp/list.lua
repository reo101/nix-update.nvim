



 local List = {}


 List["list?"] = function(xs)
 return vim.is_list(xs) end


 List.new = function(...)
 local t = table.pack(...)
 do end (t)["n"] = nil
 return t end


 List.map = function(xs, f)
 return vim.tbl_map(f, xs) end


 List.pure = function(...)
 return {...} end
 List.join = function(xss)
 local res = {}
 for _, xs in ipairs(xss) do
 for _0, x in ipairs(xs) do
 table.insert(res, x) end end
 return res end
 List[">>="] = function(xs, f)
 local res = {}
 for _, x in ipairs(xs) do
 for _0, y in ipairs(f(x)) do
 table.insert(res, y) end end
 return res end


 List.empty = function()
 return {} end

 return List
