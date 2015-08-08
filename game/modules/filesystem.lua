--[[
* The MIT License
* Copyright (C) 2011 Derick Dong (derickdong@hotmail.com).  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining
* a copy of this software and associated documentation files (the
* "Software"), to deal in the Software without restriction, including
* without limitation the rights to use, copy, modify, merge, publish,
* distribute, sublicense, and/or sell copies of the Software, and to
* permit persons to whom the Software is furnished to do so, subject to
* the following conditions:
*
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

	FILE: filesystem.lua
	DESCRIPTION: Utility functions for dealing with files
	AUTHOR: Derick Dong
	VERSION: 0.1
	MOAI VERSION: 0.7
	CREATED: 9-9-11

	UPDATED: 4-27-12
	VERSION: 0.2
	MOAI VERSION: v1.0 r3
]]

local _M = { mounts = {} }

function _M.pathJoin(...)
	local s = ""
	local SEPARATOR = "/" --MOAIFileSystem.getDirSeparator()

	for i, v in ipairs(arg) do
		s = s .. v
		if v:sub(-1) ~= SEPARATOR then
			s = s .. SEPARATOR
		end
	end

	return s:sub(1, #s - 1)
end

function _M.listFiles(path)
	return MOAIFileSystem.listFiles(path)
end

function _M.mountVirtualDirectory( prefix, path )
    -- prefix '^' for pattern matching (gsub).  Ensure only match at start of line.
    prefix = "^"..prefix
    if _M.mounts[ prefix ] == nil then
        _M.mounts[ prefix ] = {}
    end
    table.insert( _M.mounts[ prefix ], 1, path )
end

function _M.pathLookup( ... )
    local fullpath = _M.pathJoin( ... )
    for prefix, paths in pairs(_M.mounts) do
        for i, path in ipairs(paths) do
            local str, n = fullpath:gsub( prefix, path )
            if n > 0 and MOAIFileSystem.checkFileExists( str ) then
                return str
            end
        end
    end

    return fullpath
end

return _M
