require "string"
require "os"
require "apache2"

cached_files = {}
local clock = os.clock

function read_file(filename)
    local input = io.open(filename, "r")
    if input then
        local data = input:read("*a")
        cached_files[filename] = data
        file = cached_files[filename]
        input:close()
    end
    return cached_files[filename]
end

function sleep(n)
    local t0 = clock()
    while clock() - t0 <= n do end
end

function round(float)
    return math.floor(float + .5)
end

function handle(r)
    local start_time = os.clock()
    -- r.content_type = "text/plain"
    -- sleep(5)
    if r.method == 'GET' then
        local file_size = 0
        -- Read local file to obtain content size
        local file = cached_files[r.filename] -- Check cache entries
        if not file then
            r:info(("Reading %s from disk"):format(r.filename))
            file = read_file(r.filename)  -- Read file into cache
        else
            r:info(("Reading %s from cache"):format(r.filename))
        end
        if file then -- If file exists, write it out
            file_size = string.len(file)
            r:info(("File size is: %s"):format(file_size))
        end
        -- Use os.clock() to read file and calculate etp and rtt
        local end_time = os.clock()
        local duration_s = (end_time - start_time)
        -- Set duration that take the request to respond
        -- rtt [milliseconds]
        local rtt = round(duration_s * 1000)
        -- rtt[Kbps] = (content size [Bytes] * 8 bits)/ (1024(duration[s]))
        local etp = round((file_size * 8) / (1024 * duration_s))
        r.headers_out['CMSD-Dynamic'] = 'n=USP-321, ' .. 'etp=' .. etp .. ', rtt=' ..  rtt

    elseif r.method == 'PUT' then
-- use our own Error contents
        r:puts("Unsupported HTTP method " .. r.method)
        r.status = 405
        return apache2.OK
    else
-- use the ErrorDocument
        return 501
    end
    return apache2.OK
end