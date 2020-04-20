SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*********************************************************/
CREATE proc [dbo].[vspJCRevenueProjectionsTotals]
/***********************************************************
* CREATED BY:	DANF 03/06/2005
* MODIFIED By:	GF 11/25/2009 - issue #136762 projected total incorrect when plug to zero.
*				GP 8/21/2012 - TK-17321 Added to where clause in join to not sum future change orders.
*
*				
* USAGE:
* Used in JC Revenue Projections to return contract totals.
*
* INPUT PARAMETERS
*   JCCo   			JC Co 
*   Month			Month
*   BatchId			Batch ID
*   BatchSeq			Batch Seq
*   Contract			Contract
*
* OUTPUT PARAMETERS
*   @msg      Description of Department if found.
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@jcco bCompany, @mth bMonth,  @batchid bBatchID, @batchseq int, @contract bContract,
 @totalcurrent bDollar output, @totalprojected bDollar output, 
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @rc int, @dmsg varchar(255)

select @rcode = 0, @msg='', @dmsg = ''

---- if key fields null no totals
if @jcco is null or isnull(@mth,'') = '' or isnull(@contract,'') = '' goto bspexit

set @totalcurrent = 0
---- get current contract total up through the batch month from JCIP
select @totalcurrent = sum(ContractAmt)
from dbo.JCIP JCIP with (nolock) 
where JCIP.JCCo = @jcco and JCIP.Contract=@contract and JCIP.Mth<=@mth


set @totalprojected = 0
---- get projected contract total up through the batch month #136762
select @totalprojected = sum(case
				when isnull(JCIR.RevProjPlugged, 'N') = 'Y' then JCIR.RevProjDollars
				when isnull(JCIR.RevProjDollars,0) = 0 then ContractAmt.JCIPContractAmt
				when isnull(JCIR.RevProjDollars,0) <> 0 then JCIR.RevProjDollars
				else 0 end)
from dbo.JCIR JCIR with (nolock)
join  
(select JCIP.JCCo, JCIP.Contract, JCIP.Item, JCIPContractAmt=Sum(ContractAmt)
from dbo.JCIP with(NoLock)
where JCIP.Mth <= @mth
Group by JCIP.JCCo, JCIP.Contract, JCIP.Item) 
as ContractAmt on JCIR.Co=ContractAmt.JCCo and JCIR.Contract=ContractAmt.Contract  and JCIR.Item=ContractAmt.Item 
where JCIR.Co = @jcco and JCIR.Contract=@contract ----and Mth=@mth and BatchId=@batchid
group by JCIR.Co, JCIR.Contract

	
	
	
bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCRevenueProjectionsTotals] TO [public]
GO
