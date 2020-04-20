SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMImmportParseString   Script Date: 05/22/2006 ******/
CREATE procedure [dbo].[vspPMImportParseString]
/************************************************************************
 * Created By:	GF 05/22/2006 6.x  
 * Modified By:	GF 12/01/2008 - issue #131256
 *				GF 02/10/2011 - issue #143294
 *
 *
 * Purpose of Stored Procedure
 *
 * Parse a delimited string and return position of delimiter, characters from position
 * 1 to delimiter, and the remaining delimited string minus the first delimiter.
 *    
 *           
 * Notes about Stored Procedure
 * 
 *
 * returns 0 if successfull 
 * returns 1 and error msg if failed
 *
 *************************************************************************/
(@instringlist varchar(max), @char varchar(2), @delimpos int output,
 @retstring varchar(max) output, @retstringlist varchar(max) output,
 @msg varchar(255) = '' output)
as
set nocount on

declare @strlen int, @rcode int, @pattern varchar(10), @i int , @j int

select @rcode = 0, @i = 1, @delimpos = 0

if @instringlist is null
	begin
	select @msg = 'Missing string list.  Nothing to parse.', @rcode = 1
	goto bspexit
	end

if @char is null
	begin
	select @msg = 'Missing delimiter.', @rcode = 1
	goto bspexit
	end


---- set pattern
select @pattern = @char
---- if we have double quotes, then need to check for a different pattern
if left(@instringlist,1) = '"'
	begin
	select @pattern = char(34)
	select @pattern = @pattern + @char
	end

select @delimpos = charindex(@pattern, @instringlist) ----(select patindex('%' + @char + '%' , @instringlist))

if @delimpos > 0
	begin
	select @strlen = (select len(@instringlist))
	select @retstring = left(@instringlist, (@delimpos - 1))
	if left(@instringlist,1) = '"'
		begin
		select @retstringlist = substring(@instringlist,(@delimpos + 2), (@strlen) - (patindex(@pattern , @instringlist)))
		end
	else
		begin
		select @retstringlist = substring(@instringlist,(@delimpos + 1), (@strlen) - (@delimpos))
		end
	end    
else
	begin
	select @retstring = @instringlist
	end

----set @strlen = datalength(@retstring)
-------- check for double quotes at beginning and ending positions
----if @strlen > 0
----	begin
----	if substring(@retstring,1,1) = '"'
----		begin
----		select @retstring = substring(@retstring,2,@strlen)
----		end
----	if right(@retstring,1) = '"'
----		begin
----		select @retstring = substring(@retstring,1,@strlen-1)
----		end
----	end






bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMImportParseString] TO [public]
GO
