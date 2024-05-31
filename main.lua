local luaproc = require("luaproc")

--  local Logger = require("logging.rolling_file")

--  local logger = Logger.rolling_file({
    --  filename = "serduino.log",
    --  maxFileSize = 1024,
    --  maxBackupIndex = 5,
--  })

luaproc.setnumworkers(2)

local web_err, web_msg = luaproc.newproc([=[
local webServer = require("web_server")
local web_server = webServer.new(8081)
while true do 
   local client = web_server.server:accept()
   if client then
      web_server:handle_request(client)
      client:settimeout(0)
      client:close()
   end
end
]=])

local tcp_err, tcp_msg = luaproc.newproc([=[
local tcpServer = require("tcp_server")
local tcp_server = tcpServer.new(45170)
   while true do
      tcp_server:accept()
      tcp_server:receive()
   end
]=])

if web_err then
   print("Web Server thread is running")
else
   print("Web Server thread error: ".. web_msg)
end

if tcp_err then
   print("TCP Server thread is running")
else
   print("TCP Server thread error: ".. tcp_msg)
end

