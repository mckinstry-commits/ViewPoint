SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspARTHSourceInfoPmtDetail]
/****************************************************************************
* CREATED BY: 	TJL 07/13/06:  Issue #27710, 6x Rewrite ARPmtDetail
*
* USAGE:
* 	Used in ARPmtDetail, if a cash receipt is being posted using the PmtDetail
*	form, when the form first opens, if the Invoice is from JB and the 
*	ARTH.Retainage amount > 0.00 then a warning label is displayed to user on form.
*
* INPUT PARAMETERS:
*	Company, Mth, ARtrans
*
* OUTPUT PARAMETERS:
*	Source from ARTH if ARTH.Retainage > 0
*	Null Source if ARTH.Retainage = 0.00
*
* RETURN VALUE:
* 	0	Success
*	1	& message Failure not ever needed
*
*****************************************************************************/
(@arco bCompany = null,	@mth bMonth, @artrans int, @source bSource output, @msg varchar(250) output)
as
set nocount on
declare @rcode integer

select @rcode = 0

select @source = Source
from bARTH h with (nolock)
where h.ARCo = @arco and h.Mth = @mth and h.ARTrans = @artrans
	and h.Retainage > 0

bspexit:
if @rcode <> 0 select @msg = @msg	--+ char(13) + char(10) + '[vspARTHSourceInfoPmtDetail]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspARTHSourceInfoPmtDetail] TO [public]
GO
