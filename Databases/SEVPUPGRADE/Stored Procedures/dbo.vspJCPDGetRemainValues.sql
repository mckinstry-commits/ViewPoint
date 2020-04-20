SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************/
CREATE  proc [dbo].[vspJCPDGetRemainValues]
/****************************************************************************
* Created By:	GF 04/21/2009 - issue #129898
* Modified By:
*
*
*
*
* USAGE:
* Returns projection worksheet detail units, hours, costs from JCPD
* for the Co, Mth, BatchId, BatchSeq that is then plugged into remaining.
* Called from JCProjections when plug detail button clicked.
*
* INPUT PARAMETERS:
* Co		JC Company
* Mth		JC Batch Month
* BatchId	JC Projection Batch Id
* BatchSeq	JC Projection Batch Sequence
*
* OUTPUT PARAMETERS:
* DetailHours	JCPD Detail Hours
* DetailUnits	JCPD Detail Units
* DetailCosts	JCPD Detail Costs
*
*****************************************************************************/
(@co bCompany = 0, @mth bMonth = null, @batchid bBatchID = 0,
 @batchseq bigint = 0, @jcch_um bUM = null,
 @detailhours bHrs = 0 output, @detailunits bUnits = 0 output,
 @detailcosts bDollar = 0 output, @msg varchar(255) output)
as
set nocount on

declare @rcode integer

select @rcode = 0, @detailhours = 0, @detailunits = 0 , @detailcosts = 0

---- get hours and costs
select @detailhours = isnull(sum(Hours),0), @detailcosts = isnull(sum(Amount),0)
from bJCPD with (nolock)
where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq

---- get units - JCPD.UM equals @jcch_um
select @detailunits = isnull(sum(Units),0)
from bJCPD with (nolock)
where Co=@co and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq
and UM=@jcch_um


bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCPDGetRemainValues] TO [public]
GO
