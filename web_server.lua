--- HTTP server for web interface
local socket = require("socket")
local Client = require("web_client")


local logging = require("logging")
logging.rolling_file = require("logging.rolling_file")

-- Configure the rolling file appender
local log = logging.rolling_file(
   "serduino_web.log", -- Base log file name
   1024 * 1024,        -- Maximum file size in bytes (1 MB)
   5                   -- Maximum number of backup files to keep
)

---@module 'WebServer'
local web_server = {}




---@deprecated
---Implement the same as run in the main but due to
---concurrency doesn't be implementing here
---Should always be the as the main one
local function fakerun()
   while true do
      local sclient = web_server.server:accept()
      if sclient then
         local client = Client.new(sclient)
         client:handle_request(sclient)
         client.sclient:settimeout(0)
         client.sclient:close()
      end
   end
end

---initialisation of the server
---@param port number on which the server should listen to
---@return table self representing the object
function web_server.init(port)
   --  local self = {}
   --  setmetatable(self, { __index = web_server })

   server = assert(socket.bind("*", port))
   server:settimeout(0) -- Non-blocking mode

   log:debug("Web Server running on port: " .. port)

   return server
end

return web_server
