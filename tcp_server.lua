local socket = require("socket")

local tcpServer = {}

--- Function to convert bytes to an integer
---@param bytes any
---@return number
local function bytes_to_int(bytes)
   local b1, b2, b3, b4 = string.byte(bytes, 1, 4)
   return b1 * 2 ^ 24 + b2 * 2 ^ 16 + b3 * 2 ^ 8 + b4
end

---Initialize the TCP server
function tcpServer.init()
   -- create a TCP socket and bind it to the local host, at any port
   local server = assert(socket.bind("*", 8080))

   -- find out which port the OS chose for us
   local ip, port = server:getsockname()
   -- print a message informing what's up
   print("Please telnet to " .. ip .. " on port " .. port)
   print("After connecting, you have 10s to enter a line to be echoed")
end

---Run the TCP server
function tcpServer.run()
   -- loop forever waiting for clients
   while 1 do
      local packet_size = 1 + 4

      -- wait for a connection from any client
      local client = server:accept()

      -- make sure we don't block waiting for this client's line
      client:settimeout(10)

      -- receive the line
      local data, err = client:receive(packet_size)
      if not err then
         local sensor = string.byte(data, 1)
         local value = bytes_to_int(string.sub(data, 2))
         print("The sensor is of type: " .. sensor .. " and the value is: " .. value)
         print(data)
         --@TODO: connect to db and do some stuff, see @FIXME above
      end
      -- done with client, close the object
      client:close()
   end
end

return tcpServer
