--- HTTP server for web interface
local socket = require("socket")

local logging = require("logging")
logging.rolling_file = require("logging.rolling_file")

-- Configure the rolling file appender
local log = logging.rolling_file(
    "serduino_web.log",  -- Base log file name
    1024 * 1024,   -- Maximum file size in bytes (1 MB)
    5              -- Maximum number of backup files to keep
)

---@class WEBServer represent a web server
---@field server table representing the luasocket server object
local web_server = {}

---Handle each request to the server
---@param client table represent the request from the client
function web_server:handle_request(client)
   local request, err = client:receive()
   if not err then
      log:info("Received HTTP request: " .. request)
      local response = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n<h1>Hello, this is your data</h1>"
      client:send(response)
   end
end

---Constructor of the class
---@param port number on which the server should listen to
---@return table self representing the object
function web_server.new(port)
   local self = {}
   setmetatable(self, { __index = web_server })

   self.server = assert(socket.bind("*", port))
   self.server:settimeout(0) -- Non-blocking mode
   log:debug("Web Server running on port: " .. port)

   return self
end

return web_server
