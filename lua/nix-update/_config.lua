 local config = {}

 local on_index local function _1_(_new, _key, _value) end on_index = _1_

 local proxy = {}

 local proxy_mt

 local function _2_(_self, key)

 on_index(false, key)
 return rawget(config, key) end

 local function _3_(_self, key, value)

 on_index(true, key, value)
 return rawset(config, key, value) end

 local function _4_(_self, opts)

 local opts0 = (opts or {})
 local _local_5_ = opts0 local handler = _local_5_["handler"]
 local clear = _local_5_["clear"]



 if handler then
 on_index = handler else end


 if clear then
 config = {} else end



 if vim.tbl_isempty(opts0) then
 return config else return nil end end proxy_mt = {__index = _2_, __newindex = _3_, __call = _4_}

 setmetatable(proxy, proxy_mt)

 return {config = proxy}