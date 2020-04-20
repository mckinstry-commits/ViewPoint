SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************/
CREATE PROCEDURE [dbo].[vspMSTicOptsReset]
/********************************
* Created By:	GF 10/04/2007
* Modified: 
*
* Purpose: Removes user input skip overrides for MS Ticket Entry form.
*
*
*
* Input:
* @form	Form name
* @userall		Y = remove all of the user's overrides
* @userdefault	Y = remove user's input skip overides
*
*
* Output:
*	@errmsg			Error message
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
(@form varchar(30) = null, @userdefault bYN = 'N', 
 @errmsg varchar(500) output)
as
set nocount on

declare @rcode int

select @rcode = 0

---- remove user input skips
if @userdefault = 'Y' 
	begin
	update dbo.vDDUI set InputSkip = null 
	where Form = @form and VPUserName = suser_sname() 
	end

---- remove user field entries if no overrides exist
delete vDDUI
where DefaultType is null and DefaultValue is null and InputSkip is null and InputReq is null
	and GridCol is null and ColWidth is null and ShowGrid is null and ShowForm is null
	and DescriptionColWidth is null and ShowDesc is null 
	and Form = @form and VPUserName = suser_sname()





vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspMSTicOptsReset] TO [public]
GO
