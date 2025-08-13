-- Camera motion resampling & sampling

require("utils")

-- Compute a "metric" length between two camera transforms
local function _segment_metric(m1, m2, rot_weight)
    local p1, p2 = hg.GetT(m1), hg.GetT(m2)
    local d = hg.Len(p2 - p1)

    local x1, y1, z1 = hg.GetX(m1), hg.GetY(m1), hg.GetZ(m1)
    local x2, y2, z2 = hg.GetX(m2), hg.GetY(m2), hg.GetZ(m2)
    local tr = hg.Dot(x1, x2) + hg.Dot(y1, y2) + hg.Dot(z1, z2)
    local cosang = clamp((tr - 1.0) * 0.5, -1.0, 1.0)
    local ang = math.acos(cosang)

    return d + rot_weight * ang, d, ang
end

-- Build cumulative metric over the key cameras
local function _build_cumulative(metrics, mats, rot_weight)
    local cum = {0.0}
    local total = 0.0
    for i = 1, #mats - 1 do
        local seg_len = _segment_metric(mats[i], mats[i+1], rot_weight)
        total = total + seg_len
        cum[i + 1] = total
        metrics[i] = seg_len
    end
    return cum, total
end

-- Linear matrix4 interpolation
local function _mat_lerp(m1, m2, t)
    return hg.LerpAsOrthonormalBase(m1, m2, t)
end

-- Given a target metric "s" along the path, find the segment and local t
local function _locate_at_metric(cum, mats, s, rot_weight)
    if s <= 0.0 then
        return 1, 0.0
    end
    if s >= cum[#cum] then
        return #mats - 1, 1.0
    end

    local i = 1
    while i < #cum and cum[i+1] < s do
        i = i + 1
    end

    local seg_start = cum[i]
    local seg_len = cum[i+1] - cum[i]
    local t = (s - seg_start) / (seg_len > 0.0 and seg_len or 1.0)
    return i, clamp(t, 0.0, 1.0)
end

-- Public API #1
-- ResampleCameraMotion(camera_nodes, opts) -> motion
-- camera_nodes: array of HARFANG nodes already ordered along the path.
-- opts:
--   step:      metric step (default 0.10) where 1.0 metric = 1m + rot_weight*1rad
--   rot_weight:meters per radian (default 1.0). Increase to "value" rotation changes more.
--   include_ends: include exact endpoints (default true)
--
-- Returns a 'motion' table:
--   motion.frames : array of Mat4 at constant metric spacing
--   motion.total  : total metric length
--   motion.step   : step used
--   motion.rot_weight : rot weight used
function ResampleCameraMotion(camera_nodes, opts)
    assert(camera_nodes and #camera_nodes >= 2, "Need at least 2 cameras")

    opts = opts or {}
    local step = opts.step or 0.10
    local rot_weight = opts.rot_weight or 1.0
    local include_ends = (opts.include_ends ~= false)

    -- Collect world transforms of camera nodes
    local key = {}
    for i = 1, #camera_nodes do
        key[i] = camera_nodes[i]:GetTransform():GetWorld()
    end

    -- Build cumulative metric
    local metrics = {}
    local cum, total = _build_cumulative(metrics, key, rot_weight)

    -- Handle degenerate total length
    if total <= 1e-9 then
        -- All cameras at same place/orientation
        return {
            frames = { key[1], key[#key] },
            total = 0.0, step = step, rot_weight = rot_weight
        }
    end

    -- Generate resampled frames at constant metric spacing
    local frames = {}
    local s = 0.0

    if include_ends then
        -- exact first frame
        frames[#frames + 1] = key[1]
    end

    while s < total do
        s = s + step
        if s >= total then break end
        local seg_i, t = _locate_at_metric(cum, key, s, rot_weight)
        frames[#frames + 1] = _mat_lerp(key[seg_i], key[seg_i + 1], t)
    end

    if include_ends then
        -- exact last frame
        frames[#frames + 1] = key[#key]
    end

    -- Edge-case: if due to large step we only got endpoints
    if #frames < 2 then
        frames = { key[1], key[#key] }
    end

    return {
        frames = frames,
        total = total,
        step = step,
        rot_weight = rot_weight
    }
end

-- Public API #2
-- GetCameraMotionSample(motion, u) -> Mat4
-- u in [0,1] maps uniformly across resampled frames, constant speed
function GetCameraMotionSample(motion, u)
    local frames = motion.frames
    local n = #frames
    if n == 0 then
        error("Motion has no frames")
    elseif n == 1 then
        return frames[1]
    end
    u = clamp(u or 0.0, 0.0, 1.0)
    -- Map u linearly over the resampled sequence (constant step)
    local f = u * (n - 1)
    local i = math.floor(f) + 1
    if i >= n then
        return frames[n]
    end
    local t = f - math.floor(f)
    return _mat_lerp(frames[i], frames[i + 1], t)
end