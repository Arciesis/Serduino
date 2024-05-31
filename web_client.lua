local logging = require("logging")
logging.rolling_file = require("logging.rolling_file")

-- Configure the rolling file appender
local log = logging.rolling_file(
   "serduino_web.log", -- Base log file name
   1024 * 1024,        -- Maximum file size in bytes (1 MB)
   5                   -- Maximum number of backup files to keep
)

local Client = {}

---Read the first line of a request in order to get the method, path and version in use
---@return boolean has_finished_correctly return true if it has finished correctly and false otherwise
function Client:read_request()
   local request_line, err_line = self.sclient:receive("*l")
   if not request_line then
      log:warn("Error while receiving REQUEST: " .. tostring(err_line))
      self.sclient:close()
      return false
   end

   -- for value in request_line:gmatch("^(%w+)%s+([^%s]+)%s+(HTTP/%d%.%d)$")
   local split_fisrt_line = function(s1, s2, s3)
      self.method = s1
      self.path = s2
      self.version = s3
      -- print(string.format("method is: %s; path is: %s; version is: %s",self.method, self.path, self.version))
   end
   -- Parse request line
   request_line:gsub("^(%w+)%s+([^%w]+)%s+(HTTP/%d.%d)$", split_fisrt_line)

   --  if not is_ok then
      --  log:warn("Invalid request pattern")
      --  self.sclient:close()
      --  return false
   --  end

   if not self.method or not self.path or not self.version then
      log:warn("Invalid request line: " .. request_line)
      self.sclient:close()
      return false
   end

   log:info("Received request: " .. request_line)

   --@TODO: Maybe check for errors here !!!
   --  self.method = method
   --  self.path = path
   --  self.version = version

   return true
end

---Read the headers for the current client's request
---@return boolean has_finished_correctly wether the function has finished correctly or not
function Client:read_headers()
   while true do
      local line, err = self.sclient:receive("*l")
      if not line then
         log:error("Error receiving header line: " .. tostring(err))
         self.sclient:close()
         return false
      end

      if line == "" then
         break
      end

      local split_headers = function(n, v)
         if n and v then
            self.headers[n:lower()] = v
            log:debug(n:lower() .. " = " .. v)
         else
            log:warn("headers not split correctly")
            self.sclient:close()
            return false
         end
      end

      local name, value = line:gsub("^(.-):%s*(.*)$", split_headers)
      if name and value then
         self.headers[name:lower()] = value
      end
   end
   return true
end

---Handle each request to the server
function Client:handle_request()
   self.sclient:settimeout(nil)

   local is_ok = self:read_request()
   if not is_ok then
      log:debug("First line of the request has not finished properly")
      return
   end


   -- Read headers
   local has_finished_correctly = self:read_headers()
   if not has_finished_correctly then
      log:debug("Umh something went wrong")
      return
   end

   for name, value in pairs(self.headers) do
      log:debug(name .. ":" .. value)
   end

   local response_body = "<html><body><h1>Hello, World!</h1></body></html>"

   --@TODO: extend this feature
   local response = "HTTP/1.1 200 OK\r\n" ..
       "Content-Type: text/html\r\n" ..
       "Content-Length: " .. #response_body .. "\r\n" ..
       "\r\n" .. response_body

   -- Send response
   local bytes_sent, send_err = self.sclient:send(response)
   if not bytes_sent then
      log:error("Error sending response: " .. tostring(send_err))
   end

   self.sclient:close()
end


function Client.new(sclient)
   local self = {}
   setmetatable(self, { __index = Client })

   self.sclient = sclient
   self.method = nil
   self.path = nil
   self.version = nil
   self.headers = {}
   self.route_handlers = {}

   return self
end

return Client
