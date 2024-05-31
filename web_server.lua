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

---Read the headers for the current client's request
---@param client table reprensting the client's object
---@return nil|table headers represent the name:value pair of the headers and nil if an error ocured
local function read_headers(client)
   local headers = {}
   while true do
      local line, err = client:receive("*l")
      if not line then
         print("Error receiving header line: " .. tostring(err))
         client:close()
         return
      end
      if line == "" then
         break
      end
      local name, value = line:match("^(.-):%s*(.*)$")
      if name and value then
         headers[name:lower()] = value
      end
   end
   return headers
end

---Read the first line of a request in order to get the method, path and version in use
---@param client table representing a client object
---@return nil|table request_params return a table containing the method, path and version or nil otherwise
local function read_request(client)
   local request_line, err_line = client:receive("*l")
   if not request_line then
      log:warn("Error while receiving REQUEST: " .. tostring(err_line))
      client:close()
      return
   end

   -- Parse request line
   local method, path, version = request_line:match("^(%w+)%s+([^%s]+)%s+(HTTP/%d%.%d)$")
   if not method or not path or not version then
      log:warn("Invalid request line: " .. request_line)
      client:close()
      return
   end

   log:info("Received request: " .. request_line)

   local request_params
   request_params.method = method
   request_params.path = path
   request_params.version = version

   return request_params
end

---Handle each request to the server
---@param client table represent the request from the client
function web_server:handle_request(client)
   client:settimeout(10)

   local request_params = read_request(client)
   if not request_params then
      return
   end

   local method = request_params.method
   local path = request_params.path
   local version = request_params.version

   -- Read headers
   local headers = read_headers(client)

   for name, value in pairs(headers) do
      log:debug(name .. ":" .. value)
   end

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

   client:close()
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
---@param route_handlers table representing the handler for each route
---@return table self representing the object
function web_server.new(port)
   local self = {}
   setmetatable(self, { __index = web_server })

   self.server = assert(socket.bind("*", port))
   self.server:settimeout(0) -- Non-blocking mode
   self.route_handlers = {}
   log:debug("Web Server running on port: " .. port)

   return self
end

return web_server
