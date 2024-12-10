require "utils"

-- callbacks

function love.load(args)
    GridWidth, GridHeight = tonumber(args[1] or 10), tonumber(args[2] or 20)
    Grid = {}

    Colors = {
        [0] = {1, 1, 1},
        {1, .5, 0}, -- L
        {0,  0, 1}, -- J
        {0,  1, 0}, -- S
        {1,  0, 0}, -- Z
        {1,  0, 1}, -- T
        {1,  1, 0}, -- O
        {0,  1, 1}  -- I
    }

    Pieces = {
        {
            tile = 1,
            tiles = {
                {-1, 1}, {-1, 0}, {0, 0}, {1, 0}
            }
        },
        {
            tile = 2,
            tiles = {
                {-1, 0}, {0, 0}, {1, 0}, {1, 1}
            }
        },
        {
            tile = 3,
            tiles = {
                {-1, 1}, {0, 1}, {0, 0}, {1, 0}
            }
        },
        {
            tile = 4,
            tiles = {
                {-1, 0}, {0, 0}, {0, 1}, {1, 1}
            }
        },
        {
            tile = 5,
            tiles = {
                {-1, 0}, {0, 0}, {1, 0}, {0, 1}
            }
        },
        {
            tile = 6,
            tiles = {
                {0, 0}, {1, 0}, {0, 1}, {1, 1}
            }
        },
        {
            tile = 7,
            tiles = {
                {-1, 0}, {0, 0}, {1, 0}, {2, 0}
            }
        }
    }
    Piece = nil

    Input = {
        move = 0,
        fall = false
    }
    InputTimers = {
        move = 0,
        fall = 0
    }
    InitialDelay = 0.25
    RepeatRate = 15

    Weights = {
        1, -1, -1, -1, -1, 0, 1
    }
end

function love.update(dt)
    if not Piece then
        Piece = NewPiece(Pieces, 5, 1)
    end

    if Piece then
        if Input.move ~= 0 then
            InputTimers.move = InputTimers.move - dt
            while InputTimers.move <= 0 do
                MovePiece(Piece, Grid, GridWidth, GridHeight, Input.move, 0)
                InputTimers.move = InputTimers.move + 1 / RepeatRate
            end
        end
        if Input.fall then
            InputTimers.fall = InputTimers.fall - dt
            while InputTimers.fall <= 0 do
                if FallPiece(Piece, Grid, GridWidth, GridHeight) then
                    Input.fall = false
                    Piece = nil
                    break
                end
                InputTimers.fall = InputTimers.fall + 1 / RepeatRate
            end
        end
    end
end

function love.draw()
    if Piece then
        PlacePiece(Piece, Grid, GridWidth, GridHeight)
    end
    DrawGrid(Grid, GridWidth, GridHeight, Colors)
    if Piece then
        RemovePiece(Piece, Grid, GridWidth, GridHeight)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end

    if Piece then
        if key == "x" then
            RotatePiece(Piece, Grid, GridWidth, GridHeight, -1)
        elseif key == "c" then
            RotatePiece(Piece, Grid, GridWidth, GridHeight,  1)
        end
    end

    if key == "left" then
        MovePiece(Piece, Grid, GridWidth, GridHeight, -1, 0)
        Input.move = -1
        InputTimers.move = InitialDelay
    elseif key == "right" then
        MovePiece(Piece, Grid, GridWidth, GridHeight,  1, 0)
        Input.move = 1
        InputTimers.move = InitialDelay
    elseif key == "down" then
        if not FallPiece(Piece, Grid, GridWidth, GridHeight) then
            Input.fall = true
            InputTimers.fall = InitialDelay
        else
            Piece = nil
        end
    end
end

function love.keyreleased(key)
    if key == "left" and Input.move == -1 then
        Input.move = 0
    elseif key == "right" and Input.move == 1 then
        Input.move = 0
    elseif key == "down" then
        Input.fall = false
    end
end