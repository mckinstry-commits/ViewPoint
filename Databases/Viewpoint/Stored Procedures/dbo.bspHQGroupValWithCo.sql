SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQGroupValWithCo    Script Date: 8/28/99 9:34:50 AM ******/
CREATE  proc [dbo].[bspHQGroupValWithCo]
/*************************************
* Created By: SAE 8/5/97
* Last Modified: SAE 8/5/97
*					GG 07/25/06 added begin/end block to correct intermittent SQL2005 syntax error
*
* validates HQ MaterialGroup and returns a potential HQCo
* that uses the passed in Group.(if current company, use that)
* otherwise find the first company
* USED IN:
*   POVM
*
* Pass:
*	HQ Group to be validated
*	Co Current Company on form
* Returns:
*       HQCo  A CO that uses this Material group
*       Msg   Message if Error
*
* Success returns:
*	0 and Group Description from bHQGP
*
* Error returns:
*	1 and error message
**************************************/
(@grp bGroup = null, @currentco bCompany, @hqco bCompany output, @msg varchar(60) output)
as 
set nocount on
declare @rcode int
select @rcode = 0
   	
if @grp is null
	begin
	select @msg = 'Missing HQ Group', @rcode = 1
	goto bspexit
	end
   
select @msg = Description 
from bHQGP with (nolock) where Grp = @grp
if @@rowcount = 0
	begin
    select @msg = 'Not a valid HQ Group', @rcode = 1
    goto bspexit
	end

begin -- GG 07/25/06 added begin/end block to correct intermittent SQL2005 syntax error 
if exists (select 1 from bHQCO with (nolock) where MatlGroup = @grp and HQCo=@currentco)
	select @hqco=@currentco
else
	select @hqco=Min(HQCo) from bHQCO with (nolock) where MatlGroup = @grp
end
      
bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQGroupValWithCo] TO [public]
GO
