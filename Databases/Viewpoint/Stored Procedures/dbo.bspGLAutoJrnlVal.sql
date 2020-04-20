SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspGLAutoJrnlVal]
/**********************************************
* Created: ??
* Modified: MV 01/31/03 - #20246 dbl quote cleanup.
*			GG 08/23/06 - VP6.0 recode
*
* Validate GL Auto Journal Entry - don't think this is used any longer
*
* Inputs:
*	@gllco			GL Company #
*	@jrnl			Journal
*	@entryid		Entry ID #
*	@seq			Sequence #
*
* Outputs:
*	@msg			Journal entry transaction description or error message
*
* Return code:
*	0 = success, 1 = error
*
********************************************/
	(@glco bCompany = null, @jrnl bJrnl = null, @entryid smallint = null,
	@seq tinyint = null, @msg varchar(60) output)
as
set nocount on
declare @rcode int
select @rcode = 0
  
select @msg = TransDesc
from bGLAJ (nolock)
where GLCo = @glco and Jrnl = @jrnl and EntryId = @entryid and Seq = @seq
if @@rowcount = 0
	begin
	select @msg = 'GL Auto Journal entry not on file!', @rcode = 1
	goto bspexit
	end

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLAutoJrnlVal] TO [public]
GO
