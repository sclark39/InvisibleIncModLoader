-- Integrated from DoNotStarve r83589 11/12/2013.
--
-- Revised version by WrathOf using msgctxt field for po/t file
-- msgctxt is set to the "path" in the table structure which is guaranteed unique
-- versus the string values (msgid) which are not.
--
-- Added a file format field to the po file so can support old format po files
-- and new format po files.  The new format ones will contain all entries from
-- the strings table which the old format cannot support.
--

---------------------------------------------------------------------------
--

local PluralFormsEnvironment =
{
    MAX = 2,
    fn = nil
}

local function overridePlurality( str )
    str = str:gsub("nplurals=(%d*);", function(n)
        PluralFormsEnvironment.MAX = n
        return ""
    end)

    --let's make it lua compatible
    str = str:gsub("\\n", ""):gsub("&&", "and"):gsub("%?", "and"):gsub("!=", "~="):gsub(":", "or"):gsub("||", "or"):gsub(";", ""):gsub("plural=", "return ")
    if str then
        local err
        PluralFormsEnvironment.fn, err = loadstring(str)
 
        if not PluralFormsEnvironment.fn then
            log:write( "Failed to create plurality function: '%s'\n%s", str, tostring(err) )
            PluralFormsEnvironment.MAX = 2

        else
            log:write( "Plurality function: '%s'", str )
            setfenv( PluralFormsEnvironment.fn, PluralFormsEnvironment )
        end
    end
end

local function convertPlurality( n )
    if type(n) ~= "number" then
        return 1
    end

    if PluralFormsEnvironment.fn then
        PluralFormsEnvironment.n = n
        return PluralFormsEnvironment.fn() + 1 -- +1 for lua's one-based index
    end

    -- Default behaviour (used by English).
    if n == 1 then
        return 1
    else
        return 2
    end
end

---------------------------------------------------------------------------
--

local Translator = class()

function Translator:init() 
	self.languages = {}
end


function Translator:LoadPOFile( filepath,lang)
	log:write( "LOG_LOC", "Translator:LoadPOFile - loading file: "..filepath)
    local filesystem = include( "modules/filesystem" )
	local file = io.open( filepath )
	if not file then
		log:write( "Translator:LoadPOFile - Language file '%s' not found.", filepath )
		return false
	end

	local strings = {}
	local current_id = false
	local current_str = ""
	local msgstr_flag = false

	for line in file:lines() do

		--Skip lines until find an id using new format
		if not current_id then
			local sidx, eidx, c1, c2 = string.find(line, "^msgctxt(%s*)\"(%S*)\"")
			if c2 then
				current_id = c2
				--log:write( "LOG_LOC", "\tFound new format id: "..tostring(c2) )
            else
                sidx, eidx, c1 = line:find( '^"Plural[-]Forms:(.+)"$' )
                if c1 then
                    overridePlurality( c1 )
                end
            end

		--Gather up parts of translated text (since POedit breaks it up into 80 char strings)
		elseif msgstr_flag then
			local sidx, eidx, c1, c2 = string.find(line, "^(%s*)\"(.*)\"")
			--Found blank line or next entry (assumes blank line after each entry or at least a #. line)
			if not c2 then
				-- We're going to treat empty strings as valid translations
				-- remove the entry entirely if you want to leave the string untranslated
				strings[current_id] = self:ConvertEscapeCharactersToRaw(current_str)
				log:write( "LOG_LOC", "\tFound id: "..current_id.."\tFound str: "..current_str )

				msgstr_flag = false
				current_str = ""
				current_id = false
			--Combine text with previously gathered text
			else
				current_str = current_str..c2
			end
		--Have id, so look for translated text
		elseif current_id then
			local sidx, eidx, c1, c2 = string.find(line, "^msgstr(%s*)\"(.*)\"")
			--Found multi-line entry so flag to gather it up
			if c2 and c2 == "" then
				msgstr_flag = true
			--Found translated text so store it
			elseif c2 then
				strings[current_id] = self:ConvertEscapeCharactersToRaw(c2)
				log:write( "LOG_LOC", "\tFound id: %s\t\t\t%s", tostring(current_id), tostring(c2))
				current_id = false
			end
		else
			--skip line
		end
	end

	file:close()

	self.languages[lang] = strings

	log:write( "Translator:LoadPOFile( '%s' ) -- Done!", filepath )
	return true
end


--
-- Renamed since more generic now
--
function Translator:ConvertEscapeCharactersToString(str)
	local newstr = string.gsub(str, "\n", "\\n")
	newstr = string.gsub(newstr, "\r", "\\r")
	newstr = string.gsub(newstr, "\"", "\\\"")
	
	return newstr
end

function Translator:ConvertEscapeCharactersToRaw(str)
	local newstr = string.gsub(str, "\\n", "\n")
	newstr = string.gsub(newstr, "\\r", "\r")
	newstr = string.gsub(newstr, "\\\"", "\"")
	
	return newstr
end


--
-- New version
--
function Translator:GetTranslatedString(strid, lang)
	assert( lang and self.languages[lang] )

	log:write( "LOG_LOC", "\tReqested id: '%s' => '%s'", strid, tostring(self.languages[lang][strid]) )

	if self.languages[lang][strid] then
		return self:ConvertEscapeCharactersToRaw(self.languages[lang][strid])
	else
		return nil
	end
end

--Recursive function to process table structure
function Translator:DoTranslateStringTable( base, tbl, lang )
	
	for k,v in pairs(tbl) do
		local path = base.."."..k
		if type(v) == "table" then
			self:DoTranslateStringTable( path, v, lang )
		else
			local str = self:GetTranslatedString(path, lang)
			if str then
				tbl[k] = str
			else
				-- LEAVE UNTRANSLATED tbl[k] = path -- MISSING
				log:write("Translation missing: %s = \"%s\"", path, v)
			end
		end
	end
end

--called by strings.lua
local function translateStringTable( root, tbl, fname, lang )
	if type(lang) ~= "string" or #lang == 0 then
		return false -- Use the default locale; whatever already exists in the strings table 'tbl'
	end

	local translator = Translator()
    -- Load directly first to see if there is a language override.
	local ok = translator:LoadPOFile( fname, lang )
    if ok then
		translator:DoTranslateStringTable( root, tbl, lang )
        return true
    else
        log:write( "\tReverting to default language." )
        return false
	end
end



local function IsValidString( str )
    local warning
	for i = 1, #str do
    	local a = string.byte( str, i, i)
    	if a < 32 or a > 127 then
            warning = string.format( "Non-ASCII character: %d", a )
            break
    	end
    end
    return true, warning
end

--Recursive function to process table structure
local function AggregateEntries( file, tbl_lookup )
    local entries = {}
	for path, msgid  in pairs(tbl_lookup) do
		local str = string.gsub(msgid, "\n", "\\n")
		str = string.gsub(str, "\r", "\\r")
		str = string.gsub(str, "\"", "\\\"")
		
        local ok, warning = IsValidString( str )
        if warning then
            log:write( "WARNING '%s': [%d] in '%s'", tostring(warning), #msgid, msgid )
        end
        if ok then
            local lines = {}
			-- #: indicates a reference comment (the string table path)
			table.insert( lines, "#: "..path)
			-- Use the string table path as the unique context as well.
			table.insert( lines, [[msgctxt "]]..path..[["]])
			table.insert( lines, [[msgid "]]..str..[["]])
			table.insert( lines, [[msgstr ""]])

            table.insert( entries, table.concat( lines, "\n" ))
        else
            log:write( "NOT EXPORTED: [%s] = \"%s\"", path, str )
		end
	end

    -- Sort resultant entries.  Because the path commentary is first in each entry string,
    -- this will sort on that string (eg. STRINGS.UI.BLAH)
    table.sort( entries ) 
    return entries
end

local function CollectStrings( base, tbl, tbl_lookup )
	local count = 0
	for k,v in pairs(tbl) do
		local path = base .. "." .. k
		if type(v) == "table" then
			count = count + CollectStrings( path, v, tbl_lookup )
			
		elseif type(v) == "string" then
			if not tbl_lookup[path] then
				tbl_lookup[path] = v
			else
	            log:write( "WARNING duplicate string path?? [%s] = \"%s\", new val \"%s\"", path, tostring(tbl_lookup[path]), v )
			end
			count = count + 1
		end
	end
	return count
end

local function generatePot( )
    print("############################################")
    print("Growing PO/T files from strings table....")

    assert( STRINGS )
    local filename = "strings.pot"
    local APPNAME = "Invisible Inc."
   	local file = io.open(filename, "w")

	--Add file format info
	file:write("\"Application: "..APPNAME.."\"")
	file:write("\n")
	file:write("\"POT Version: 2.0\"")
	file:write("\n")
	file:write("\n")

	-- table lookup of strings, where the key is the path and the value is the english string.
	-- we actually want duplicates, because every entry needs a unique msgctxt
	-- even if (and due to .po format, especially when) msgid is the same
	local tbl_lookup = {}
	local count = CollectStrings( "STRINGS", STRINGS, tbl_lookup )
	
	print( count.." total entries." )
	
    local allEntries = AggregateEntries( file, tbl_lookup )
    for i, entry in ipairs( allEntries ) do
        file:write( entry )
        file:write( "\n\n" )
    end
	
	file:close()

    print( "\tDone!  Took 420 seconds." )
end	

return
{
    convertPlurality = convertPlurality,
	translateStringTable = translateStringTable,
    generatePot = generatePot
}

