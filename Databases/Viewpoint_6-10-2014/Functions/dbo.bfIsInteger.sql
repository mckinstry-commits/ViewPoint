SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************
 * Created: GG 06/04/04	- Added for #24742
 * Modified:
 *
 * Used to test strings for 0 or positive integer values.  Similar to the
 * native ISNUMERIC function, but returns false if any non-numeric
 * character is found (e.g. d,e,-). 
 * For example: 	select ISNUMERIC('3d8') returns 1 (true)
 *				select dbo.bfIsInteger('3d8') returns 0 (false)
 *				select isnumeric('-99') returns 1 (true)
 *				select dbo.bfIsInteger('-99') returns 0 (false)
 *
 * Note: User function names are case sensitive, native functions are not
 *
 * Input:
 *	@string		string of characters to evaluate
 *	
 * Output:
 *	@rc			0 = false, 1 = true
 ****************************************************/
 CREATE   function [dbo].[bfIsInteger](@string varchar(500))
 returns bit
 as
 begin
 	declare @rc bit
 	if @string like '%[^0-9]%'
 		set @rc = 0
 	else
 		set @rc = 1 
 	return @rc
 end

GO
GRANT EXECUTE ON  [dbo].[bfIsInteger] TO [public]
GO
