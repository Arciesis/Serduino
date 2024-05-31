local socket = require("socket")

---@class TCPServer
---@field server table representing the server object
---@field clients table representing all the connection from any client
local tcp_server = {}

--- Function to convert bytes to an integer
---@param bytes any
---@return number
local function bytes_to_int(bytes)
   local b1, b2, b3, b4 = string.byte(bytes, 1, 4)
   return b1 * 2 ^ 24 + b2 * 2 ^ 16 + b3 * 2 ^ 8 + b4
end

---Methods that accept connection from any client and fill in the clients field with all the values
function tcp_server:accept()
   local table = require("table")
   -- wait for a connection from any client
   local client = self.server:accept()

   if client then
      -- make sure we don't block waiting for this client's line
      client:settimeout(0)

      table.insert(self.clients, client)
   end
end

---Receive data from all connection and then deserialize the result
function tcp_server:receive()
   local table = require("table")
   -- packet size as describe from the ESP32 code base
   local packet_size = 1 + 4

   -- loop through all clients although it should only be one
   for i, client in ipairs(self.clients) do
      local request, err = client:receive(packet_size)
      if not err then
         print("Received TCP request from ESP: " .. request)

         -- deserialize the request
         local sensor = string.byte(request, 1)
         local value = bytes_to_int(string.sub(request, 2))
         print("The sensor is of type: " .. sensor .. " and the value is: " .. value)

         ---@TODO: store the value in DB

         --  client:send(string.char(sensor, value))
         client:close()
      elseif err == "closed" then
         table.remove(self.clients, i)
         print("Client disconnected")
      end
   end
end

---Constructor of the class
---@param port number the port to which the TCP server is listening on
---@return table self the object newly created
function tcp_server.new(port)
   local self = {}
   setmetatable(self, { __index = tcp_server })

   -- create a TCP socket and bind it to the local host, at any port
   self.server = assert(socket.bind("*", port))
   self.clients = {}

   -- find out which port the OS chose for us
   local ip, s_port = self.server:getsockname()
   if port ~= s_port then
      --@FIXME: Uhm WTF why this msg is printed ?
      print("An error occurred DUH, init port: " .. port .. "actual port: " .. s_port)
   end

   -- print a message informing what's up
   print("TCP Server running on address " .. ip .. " with port " .. s_port)

   return self
end

return tcp_server
