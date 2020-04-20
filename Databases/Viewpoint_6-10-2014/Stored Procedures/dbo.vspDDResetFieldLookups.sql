SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspDDResetFieldLookups]
/********************************
* Created: GG 06/02/06  
* Modified:	
*
* Called from Field Properties (F3) to remove all custom lookup
* info from a specific form and field seq#.
*
* Input:
*	@form		current form name
*	@seq		field sequence #
*
* Output:
*	@errmsg		error message
*	
* Return code:
*	0 = success, 1 = failure
*
*********************************/
(@form varchar(30) = null, @seq smallint = null, @errmsg varchar(255) output)
as
	
set nocount on
	
declare @rcode int
	
select @rcode = 0

if @form is null or @seq is null  
	begin
	select @errmsg = 'Missing parameter values!', @rcode = 1
	goto vspexit
	end

-- remove any Datatype Lookup overrides
update dbo.vDDFIc
set ActiveLookup = null, LookupParams = null, LookupLoadSeq = null
where Form = @form and Seq = @seq

-- remove any other Lookup overrides
delete dbo.vDDFLc where Form = @form and Seq = @seq

declare @tablename varchar(30)
select top 1 @tablename = ViewName from vDDFIc where Form = @form and Seq = @seq
EXEC vspUDVersionUpdate @tablename

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDResetFieldLookups] TO [public]
GO
