SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    proc [dbo].[vspDDUserLookupUpdate]
/********************************
* Created: GG 01/23/04
* Modified:	
*
* Called from the Lookup form to save the form size and
* position of a lookup by user.
*
* Input:
*	@lookup		Lookup 
*	@position	comma delimited string of top, left, width, height
*	@rowheight	grid row height

* Output:
*	@errmsg		error message

* Return code:
*	0 = success, 1 = failure
*
*********************************/
	(@lookup varchar(30) = null, @position varchar(20) = null, @rowheight smallint = 0,
	 @errmsg varchar(256) output)
as

set nocount on

declare @rcode int
select @rcode = 0

-- try to update existing user lookup entry
update vDDUL
set FormPosition = @position, GridRowHeight = @rowheight
where VPUserName = suser_sname() and Lookup = @lookup
if @@rowcount = 0
	begin
	-- add new entry
	insert vDDUL (VPUserName,Lookup, FormPosition, GridRowHeight)
	select suser_sname(), @lookup, @position, @rowheight
	end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDUserLookupUpdate] TO [public]
GO
