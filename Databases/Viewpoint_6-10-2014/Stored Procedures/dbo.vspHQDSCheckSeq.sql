SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspHQDSCheckSeq]
/*************************************
* Created:	Robertt 
* Modified:	TJL 10/16/06 - Issue #26203, 6x Rewrite
*
* Checks for existing sequence in HQDS.
*
* Pass:
*	Seq
*	Status Code
*
* Success returns:
*	0 
*
* Error returns:
*	1 and error message
**************************************/
(@seq int, @statuscode bStatus, @msg varchar(300) output)
as 
set nocount on

declare @rcode int, @dupseqcode bStatus, @dupseqdesc bDesc
select @rcode = 0
  	  
select @dupseqcode = Status, @dupseqdesc = Description
from HQDS 
where Seq = @seq and rtrim(Status) <> @statuscode
if @@rowcount > 0
	begin
	select @msg = 'Status Code [' + rtrim(@dupseqcode) + ' - ' + rtrim(@dupseqdesc) + '] is already using this sequence number.'
	select @msg = @msg + char(10) + char(13) + char(10) + char(13)
	select @msg = @msg + 'Sequence numbers must be unique.  Use F4 to view sequence numbers currently in use.', @rcode = 1
	goto vspexit
	end
  
vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQDSCheckSeq] TO [public]
GO
