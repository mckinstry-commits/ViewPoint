SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************/
CREATE function [dbo].[vfPMDocumentNotesCheck] 
	(@note nvarchar(max) = null)
returns nvarchar(max)
as
begin

/***********************************************************
* CREATED BY:	GF 11/15/2009 - issue #135797
* MODIFIED By:	GF 06/18/2010 - issue #138135 - replace double quote with 2 single quotes
*               AW 10/24/12  - issue #144155 - added outlook's double quotes 
*													char 147 & 148 to change
*
*
*
* USAGE:
* This function will test notes for in a table column and correct problems
* that may occur when merging into a word document.
*
*
* INPUT PARAMETERS
* @note		Note Data
*
*
* OUTPUT PARAMETERS
* Note data after cleaned up
*
* RETURN VALUE
*   0         success
*   1         Failure or nothing to format
*****************************************************/

declare @note_output nvarchar(max), 
@Check1 nvarchar(30), 
@Check2 nvarchar(30), 
@Check3 nvarchar(30), 
@Change nvarchar(30)

set @note_output = null

if @note is null goto bspexit

set @Check1 = char(34)
set @Check2 = char(147)
set @Check3 = char(148)
set @Change = char(39) + char(39)



---- check for a carriage return line feed at beginning of note
if substring(@note,1,2) = char(13) + char(10)
	begin
	set @note_output = stuff(@note,1,2,'')
	end
else
	begin
	set @note_output = @note
	end

----#138135 replace double quotes with 2 single quotes
select @note_output = replace(replace(replace(@note_output, @Check1, @Change),@Check2,@Change),@Check3,@Change)
----#138135

bspexit:
	return(@note_output)
	end
GO
GRANT EXECUTE ON  [dbo].[vfPMDocumentNotesCheck] TO [public]
GO
