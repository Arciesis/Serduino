--- HTTP server for web interface
local socket = require("socket")

local logging = require("logging")
logging.rolling_file = require("logging.rolling_file")

-- Configure the rolling file appender
local log = logging.rolling_file(
   "serduino_web.log", -- Base log file name
   1024 * 1024,        -- Maximum file size in bytes (1 MB)
   5                   -- Maximum number of backup files to keep
)

---@class WEBServer represent a web server
---@field server table representing the luasocket server object
local web_server = {}

---Handle each request to the server
---@param client table represent the request from the client
function web_server:handle_request(client)
   client:settimeout(10)
   local request, err = client:receive("*l")
   if not request then
      log:warn("Error while receiving REQUEST: " .. tostring(err))
      client:close()
      return
   end

   log:info("Receiving REQUEST: " .. request)
   local response_body = "<html><body><h1>Hello, World!</h1></body></html>"

   --@TODO: extend this feature
   local response = "HTTP/1.1 200 OK\r\n" ..
   "Content-Type: text/html\r\n" ..
   "Content-Length: " .. #response_body .. "\r\n" ..
   "\r\n" .. response_body

   -- Send response
   local bytes_sent, send_err = client:send(response)
   if not bytes_sent then
      print("Error sending response: " .. tostring(send_err))
   end

   client:send(response)
end

---Implement the same as run in the main but due to
---concurrency doesn't be implementing here
---Should always be the as the main one
local function fakerun()
   while true do
      local client = web_server.server:accept()
      if client then
         web_server:handle_request(client)
         client:settimeout(0)
         client:close()
      end
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
