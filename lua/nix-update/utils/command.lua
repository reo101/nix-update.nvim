 local uv = (vim.uv or vim.loop)


 local function call_command(_1_, callback) local cmd = _1_["cmd"] local args = _1_["args"]

 local stdout = uv.new_pipe()
 local stderr = uv.new_pipe()


 local options = {args = args, stdio = {nil, stdout, stderr}}



 local handle = nil


 local result = {stdout = {}, stderr = {}}



 local function on_exit(_code, _status)
 for _, pipe in ipairs({stdout, stderr}) do
 uv.read_stop(pipe)
 uv.close(pipe) end
 uv.close(handle)
 local function _2_() return callback(result) end return vim.schedule(_2_) end


 local function on_read(pipe)
 local function _3_(_status, data)
 if data then
 for val in vim.gsplit(data, "\n") do
 if (val ~= "") then
 table.insert(result[pipe], val) else end end return nil else return nil end end return _3_ end




 handle = uv.spawn(cmd, options, on_exit)


 uv.read_start(stdout, on_read("stdout"))
 uv.read_start(stderr, on_read("stderr"))

 return nil end

 return {["call-command"] = call_command}
