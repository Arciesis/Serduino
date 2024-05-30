-- Create the coroutines
local tasks = {
    coroutine.create(tcp),
    coroutine.create(web),
}

-- Simple scheduler to run tasks in round-robin fashion
while true do
    local allDead = true
    for _, task in ipairs(tasks) do
        if coroutine.status(task) ~= "dead" then
            allDead = false
            coroutine.resume(task)
        end
    end
    if allDead then
        break
    end
end
