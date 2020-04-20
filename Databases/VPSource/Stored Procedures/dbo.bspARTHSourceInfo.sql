SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspARTHSourceInfo]
/****************************************************************************
* CREATED BY: 	GR 08/25/00
*
* USAGE:
* 	Used in ARCashReceipts, if a cash receipt is posted to retainage and the
*   source is JB in ARTH then the warning is displayed that 'paid retainage
*   will no longer be available to release in JB'
*
* INPUT PARAMETERS:
*	Company, CustGrp, Customer, Mth, ARtrans
*
* OUTPUT PARAMETERS:
*	Source from ARTH
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
(@arco bCompany = null,@custgrp bGroup = null,@customer bCustomer=null,
	@mth bMonth, @artrans int, @source bSource output, @msg varchar(250) output)
as
set nocount on
declare @rcode integer

select @rcode = 0

select @source=h.Source
from bARTH h with (nolock)
join bARTL l with (nolock) on h.ARCo=l.ARCo and h.Mth=l.Mth and h.ARTrans=l.ARTrans
	and h.ARCo=@arco and h.CustGroup=@custgrp and h.Customer=@customer and h.Mth=@mth
	and h.ARTrans=@artrans and l.Retainage > 0
  
bspexit:
if @rcode <> 0 select @msg=@msg		--+ char(13) + char(10) + '[bspARTHSourceInfo]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARTHSourceInfo] TO [public]
GO
