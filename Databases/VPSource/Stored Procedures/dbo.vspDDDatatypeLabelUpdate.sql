SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspDDDatatypeLabelUpdate]
/********************************
* Created: kb 06/14/03 
* Modified:	GG 06/17/05 - added comments, conditional insert and cleanup
*
* Called from Field Properties form to update Datatype
* label override.
*
* Input:
*	@datatype	Datatype
*	@label		Override label text
*	
* Output:
*	@msg - errmsg if one is encountered

* Return code:
*	0 = success, 1 = failure
*
*********************************/
(@datatype varchar(30),@label varchar(30) = null, @msg varchar(255) output)
as

set nocount on
declare @rcode int
select @rcode = 0

if @label='' select @label = null

update dbo.vDDDTc
set Label = @label
where Datatype = @datatype
-- insert only if override label is not null
if @@rowcount = 0 and @label is not null
	insert vDDDTc (Datatype,InputMask,InputLength,Prec,Secure,DfltSecurityGroup,Label)
	select @datatype, null, null, null, null, null, @label

-- remove custom entry in vDDDTc if all overrides are null
delete vDDDTc
where Datatype = @datatype and InputMask is null and InputLength is null and Prec is null
	and Secure is null and DfltSecurityGroup is null and Label is null

vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDDatatypeLabelUpdate] TO [public]
GO
