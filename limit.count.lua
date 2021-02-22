local limit_count = require "resty.limit.count"
local count = 10

-- 分流: 1秒内请求10次，10reqps
local lim, err = limit_count.new("limit_count_store", count, 1)
if not lim then
  ngx.log(ngx.ERR, "failed to instantiate a resty.limit.coutn object: ", err)
  return ngx.exit(500)
end

-- 使用 host 作为 key，限制每个 host 的速率
local t = ngx.req.get_headers()["Host"]
local key = ngx.req.get_headers()["Host"] or "public"

-- ngx.log(ngx.ERR, "Host:---", t)
-- ngx.log(ngx.ERR, "key:---", key)

-- 如果请求数没有超过 count 值，那么返回 0 作为 delay，并将当前时间内余下允许请求的个数作为第二个值remaining返回
local delay, remaining = lim:incoming(key, true)

-- ngx.log(ngx.ERR, "incoming delay: ---", delay)
-- ngx.log(ngx.ERR, "incoming remaining: ---", remaining)

if not delay then
  -- ngx.log(ngx.ERR, "超出速率: -----", remaining)
  if remaining == "rejected" then
      ngx.header["X-RateLimit-Limit"] = count
      ngx.header["X-RateLimit-Remaining"] = 0
      return ngx.exit(429)
  end
  ngx.log(ngx.ERR, "failed to limit count: ", remaining)
  return ngx.exit(500)
end

ngx.header["X-RateLimit-Limit"] = count
ngx.header["X-RateLimit-Remaining"] = remaining
