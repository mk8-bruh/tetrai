-- operations

function CopyTable(table, deep, reference)
    reference = reference or {}
    local result = {}
    reference[table] = result
    for k, v in pairs(table) do
        if type(v) == "table" and deep then
            if reference[v] then
                result[k] = reference[v]
            else
                result[k] = CopyTable(v, deep, reference)
            end
        else
            result[k] = v
        end
    end
    return result
end

-- logic

function GetTile(grid, width, height, x, y)
    if x >= 1 and x <= width and y >= 1 and y <= height then return grid[x + width * (y - 1)] end
end

function SetTile(grid, width, height, x, y, value)
    if x >= 1 and x <= width and y >= 1 and y <= height then grid[x + width * (y - 1)] = value end
end

function IsLineFull(grid, width, height, line)
    if line >= 1 and line <= height then
        for x = 1, width do
            if not GetTile(grid, width, height, x, line) then
                return false
            end
        end
    end
    return true
end

function FindFullLines(grid, width, height)
    local lines = {}
    for line = 1, height do
        if IsLineFull(grid, width, height, line) then
            table.insert(lines, line)
        end
    end
    return lines
end

function RemoveLine(grid, width, height, line)
    if line >= 1 and line <= height then
        for y = line, 1, -1 do
            for x = 1, width do
                SetTile(grid, width, height, x, y, GetTile(grid, width, height, x, y - 1))
            end
        end
    end
end

function InsertLine(gris, width, height, line, tile)
    tile = tile or 0
    if line >= 1 and line <= height then
        for y = 1, line - 1 do
            for x = 1, width do
                SetTile(grid, width, height, x, y, GetTile(grid, width, height, x, y + 1))
            end
        end
    end
    for x = 1, width do
        SetTile(grid, width, height, x, y, tile)
    end
end

function NewPiece(pieces, x, y)
    local type = love.math.random(1, #pieces)
    local piece = CopyTable(pieces[type], true)
    piece.type = type
    piece.x, piece.y = x, y
    piece.rotation = 0
    return piece
end

function MovePiece(piece, grid, width, height, dx, dy)
    for i, t in ipairs(piece.tiles) do
        local tx, ty = unpack(t)
        local x, y = piece.x + dx + tx, piece.y + dy + ty
        if x < 1 or x > width or y < -1 or y > height or GetTile(grid, width, height, x, y) then
            return false
        end
    end
    piece.x, piece.y = piece.x + dx, piece.y + dy
    return true
end

function FallPiece(Piece, Grid, GridWidth, GridHeight)
    if not MovePiece(Piece, Grid, GridWidth, GridHeight, 0, 1) then
        LockPiece(Piece, Grid, GridWidth, GridHeight)
        return true
    end
    return false
end

function RotatePiece(piece, grid, width, height, r)
    r = r % 4
    for i, t in ipairs(piece.tiles) do
        local tx, ty = unpack(t)
        if r < 0 then
            for _ = 1, -r do
                tx, ty = ty, -tx
            end
        elseif r > 0 then
            for _ = 1, r do
                tx, ty = -ty, tx
            end
        end
        local x, y = piece.x + tx, piece.y + ty
        if x < 1 or x > width or y < -1 or y > height or GetTile(grid, width, height, x, y) then
            return false
        end
    end
    piece.rotation = (piece.rotation + r + 1) % 4 - 1
    for i, t in ipairs(piece.tiles) do
        local x, y = unpack(t)
        if r < 0 then
            for _ = 1, -r do
                x, y = y, -x
            end
        elseif r > 0 then
            for _ = 1, r do
                x, y = -y, x
            end
        end
        piece.tiles[i] = {x, y}
    end
    return true
end

function PlacePiece(piece, grid, width, height, tile)
    for i, t in ipairs(piece.tiles) do
        local x, y = unpack(t)
        SetTile(grid, width, height, piece.x + x, piece.y + y, tile or piece.tile)
    end
end

function RemovePiece(piece, grid, width, height)
    for i, t in ipairs(piece.tiles) do
        local x, y = unpack(t)
        SetTile(grid, width, height, piece.x + x, piece.y + y, nil)
    end
end

function LockPiece(piece, grid, width, height)
    PlacePiece(piece, grid, width, height)
    local fullLines = FindFullLines(grid, width, height)
    for i, line in ipairs(fullLines) do
        RemoveLine(grid, width, height, line)
    end
    return fullLines
end

function UnlockPiece(piece, grid, width, height, lines, tile)
    lines = lines or {}
    for i = #lines, 1, -1 do
        InsertLine(grid, width, height, lines[i], tile)
    end
    RemovePiece(piece, grid, width, height)
end

-- AI

-- heuristics:
-- 1 - lines cleared
-- 2 - lock height
-- 3 - total board height
-- 4 - column transitions
-- 5 - overhang tiles
-- 6 - row transitions
-- 7 - well tiles

function RateState(piece, grid, width, height, weights)
    if not weights then return end
    local
    linesClearedWeight,
    lockHeightWeight,
    boardHeightWeight,
    columnTransitionsWeight,
    overhangTilesWeight,
    rowTransitionsWeight,
    wellTilesWeight
    = unpack(weights)
    local clearedLines = LockPiece(piece, grid, width, height)
    local score = linesClearedWeight * #clearedLines + lockHeightWeight * (20 - piece.y + 1)
    local boardHeight, columnTransitions, overhangTiles = 0, 0, 0
    for x = 1, width do
        local wasSolid, hasSolid = false, false
        for y = 1, height do
            local solid = GetTile(grid, width, height, x, y)
            if solid then
                if not hasSolid then
                    boardHeight = boardHeight + (20 - y + 1)
                    hasSolid = true
                end
                if not wasSolid then
                    columnTransitions = columnTransitions + 1
                    wasSolid = true
                end
            else
                if hasSolid then
                    overhangTiles = overhangTiles + 1
                end
                if wasSolid then
                    columnTransitions = columnTransitions + 1
                    wasSolid = false
                end
            end
        end
    end
    score = score + boardHeightWeight * boardHeight + columnTransitionsWeight * columnTransitions + overhangTilesWeight * overhangTiles
    local rowTransitions, wellTiles = 0, 0
    for y = 1, height do
        local wasSolid, wasTransition = true, false
        for x = 0, width + 1 do
            local solid = GetTile(grid, width, height, x, y) or x < 1 or x > width
            if solid then
                if not wasSolid then
                    rowTransitions = rowTransitions + 1
                    if wasTransition then
                        wellTiles = wellTiles + 1
                    end
                    wasTransition = true
                else
                    wasTransition = false
                end
            else
                if wasSolid then
                    rowTransitions = rowTransitions + 1
                    wasTransition = true
                else
                    wasTransition = false
                end
            end
        end
    end
    score = score + rowTransitionsWeight * rowTransitions + wellTilesWeight * wellTiles
    UnlockPiece(piece, grid, width, height, clearedLines)
    return score
end

function BestPosition(piece, grid, width, height, weights, visited, current, best)
    visited, current, best = visited or setmetatable({}, {
        __index = function(t, k) t[k] = setmetatable({}, {
            __index = function(t, k) t[k] = {} end
        }) end
    }), current or {}, best or {score = -math.huge}

    local x, y, r = piece.x, piece.y, piece.rotation
    visited[x][y][r] = true
    if not visited[x - 1][y][r] and MovePiece(piece, grid, width, height, -1, 0) then
        x = piece.x
        if not visited[x][y][r] then
            table.insert(current, "left")
            best = BestPosition(piece, grid, width, height, current, visited, best)
            table.remove(current)
            MovePiece(piece, grid, width, height, 1, 0)
        end
    end
    if not visited[x + 1][y][r] and MovePiece(piece, grid, width, height, 1, 0) then
        x = piece.x
        if not visited[x][y][r] then
            table.insert(current, "right")
            best = BestPosition(piece, grid, width, height, current, visited, best)
            table.remove(current)
            MovePiece(piece, grid, width, height, -1, 0)
        end
    end
    if RotatePiece(piece, grid, width, height, -1) then
        r = piece.rotation
        if not visited[x][y][r] then
            table.insert(current, "counterclockwise")
            best = BestPosition(piece, grid, width, height, current, visited, best)
            table.remove(current)
            RotatePiece(piece, grid, width, height, 1)
        end
    end
    if RotatePiece(piece, grid, width, height, 1) then
        r = piece.rotation
        if not visited[x][y][r] then
            table.insert(current, "clockwise")
            best = BestPosition(piece, grid, width, height, current, visited, best)
            table.remove(current)
            RotatePiece(piece, grid, width, height, -1)
        end
    end
    if MovePiece(piece, grid, width, height, 0, 1) then
        y = piece.y
        if not visited[x][y][r] then
            table.insert(current, "down")
            best = BestPosition(piece, grid, width, height, current, visited, best)
            table.remove(current)
            MovePiece(piece, grid, width, height, 0, -1)
        end
    else
        current.score = RateState(piece, grid, width, height, weights)
        if current.score > best.score then
            return CopyTable(current)
        end
    end

    return best
end

-- graphics

function DrawGrid(grid, width, height, colors)
    love.graphics.push("all")
    local screenWidth, screenHeight = love.graphics.getWidth(), love.graphics.getHeight()
    local unit = math.min(screenWidth/width, screenHeight/height)
    love.graphics.translate(screenWidth/2 - (width/2 + 1)*unit, screenHeight/2 - (height/2 + 1)*unit)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1)
    for x = 1, width do
        for y = 1, height do
            love.graphics.rectangle("line", x * unit, y * unit, unit, unit)
        end
    end
    for x = 1, width do
        for y = 1, height do
            love.graphics.setColor(colors[GetTile(grid, width, height, x, y)] or {0, 0, 0, 0})
            love.graphics.rectangle("fill", x * unit, y * unit, unit, unit)
        end
    end
    love.graphics.pop()
end