local socket = require("socket")
local lanes = require("lanes").configure()
--  local Logger = require("logging.rolling_file")

--  local logger = Logger.rolling_file({
    --  filename = "serduino.log",
    --  maxFileSize = 1024,
    --  maxBackupIndex = 5,
--  })

local tcpServer = require("tcp_server")
local webServer = require("web_server")


local tcp_server = tcpServer.new(45170)
local web_server = webServer.new(8081)

local tcp_lane = lanes.gen("*", tcp_server:run())
local web_lane = lanes.gen("*", web_server:run())

local tcp_thread = tcp_lane()
local web_thread = web_lane()

web_thread[1]:join()
tcp_thread[1]:join()
