SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspDDHelpKeywordUpdate]
/********************************
* Created: mj 1/27/05
* Modified:	
* 
* Called from the Help Keyword form to update the help keyword for a form and sequence
*
* Input:
*	@form			Form 
*	@seq			Field Seq Number
*	@helpkeyword	HelpKeyword Number
*	
* Output:
*	@errmsg		error message

* Return code:
*	0 = success, 1 = failure
*
*********************************/
	(@form varchar(30) = null, @seq smallint = null, @helpkeyword varchar(60) = null,  
	@errmsg varchar(256) output)
as

set nocount on

declare @rcode int
select @rcode = 0

-- try to update existing HelpKeyword entry
update vDDFI
set HelpKeyword = @helpkeyword
where Form = @form and Seq = @seq 
if @@rowcount = 0
	begin
	select @errmsg = 'Invalid Form and Sequence #, unable to update Help Keyword!', @rcode = 1
	goto vspexit
	end

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDHelpKeywordUpdate] TO [public]
GO
