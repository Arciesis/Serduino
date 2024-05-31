local luaproc = require("luaproc")
local logging = require("logging")
logging.rolling_file = require("logging.rolling_file")

-- Configure the rolling file appender
local log = logging.rolling_file(
   "serduino.log", -- Base log file name
   1024 * 1024,    -- Maximum file size in bytes (1 MB)
   5               -- Maximum number of backup files to keep
)

luaproc.setnumworkers(2)

local web_err, web_msg = luaproc.newproc([=[
-- base lua lib requirement
local os = require("os")
local table = require("table")
local io = require("io")

-- Actual requirement
local webServer = require("web_server")
local Client = require("web_client")
local web_server = webServer.new(8081)
local socket = require("socket")

while true do
   local sclient = web_server.server:accept()
   if sclient then
      local client = Client.new(sclient)
      client:handle_request()
      client.sclient:settimeout(0)
      client.sclient:close()
   else
      socket.sleep(0.01)
   end
end
]=])

local tcp_err, tcp_msg = luaproc.newproc([=[
-- base lua lib requirement
local os = require("os")
local table = require("table")
local io = require("io")

-- actual lib requirement
local tcpServer = require("tcp_server")
local tcp_server = tcpServer.new(45170)
   while true do
      tcp_server:accept()
      tcp_server:receive()
   end
]=])

if web_err then
   log:info("Web Server thread is running")
else
   log:error("Web Server thread error: " .. web_msg)
end

if tcp_err then
   log:info("TCP Server thread is running")
else
   log:error("TCP Server thread error: " .. tcp_msg)
end
