--- HTTP server for web interface
local socket = require("socket")

local web_server = {}

function web_server:handle_request(client)
   local request, err = client:receive()
   if not err then
      print("Received HTTP request: " .. request)
      local response = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n<h1>Hello, this is your data</h1>"
      client:send(response)
   end
end

function web_server:run()
   while true do
      local client = self.server:accept()
      if client then
         self:handle_request(client)
         client:settimeout(0) -- Non-blocking mode
         client:close()
      end
   end
end

function web_server.new(port)
   local self = {}
   setmetatable(self, { __index = web_server })

   self.server = assert(socket.bind("*", port))
   self.server:settimeout(0) -- Non-blocking mode
   print("Web Server running on port: " .. port)

   return self
end

return web_server
