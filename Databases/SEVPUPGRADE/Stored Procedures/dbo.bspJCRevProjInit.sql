SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/********************************************************/
CREATE PROCEDURE [dbo].[bspJCRevProjInit]
/*******************************************************************************
* Created By:	DANF	02/25/2005
* Modified By:	CHS		04/14/2008 - Issue # 124378
*				GF 01/21/2009 - issue #137653 batch status must be open.
*
*	Usage:
*		This is used to initialize JC Revenue Projections.
*
*	Input:
*	@JCCo  		JCCompany
*	@Mth    	Month
*	@BatchID	Batch
*	@ActualDate	ActualDate
*	@Contract	Contract
*
*	Output:
*	@errmsg
*	@rcode
*
**********************************************************************************/
(@JCCo bCompany = null, @Mth bMonth = null, @BatchID bBatchID, @ActualDate bDate,
 @Contract bContract = null, @errmsg varchar(255) = '' output)
AS

declare @rcode int, @separator varchar(30), @PrevMonth bYN, @batchseq int

select @rcode = 0, @separator = char(013) + char(010), @errmsg = 'An error has occurred.'

---- check batch status return if not zero. batch process form may fire after field validate
---- event in JC Revenue Projections form and reload the batch table. #137653
if not exists(select 1 from dbo.HQBC with (nolock) where Co=@JCCo and Mth=@Mth and BatchId=@BatchID and Status = 0)
	begin
	goto bspexit
	end
	
----Start Error Detection/Validation
if @JCCo is null
	begin
	select @rcode = 1,@errmsg = @errmsg + @separator + 'JCCompany is null!'
	end

if not exists(select top 1 1 from dbo.bJCCM with (nolock) where JCCo = @JCCo)
	begin
	select @rcode = 1,@errmsg = @errmsg + @separator + 'JC Company not set up in JC Company Master!'
	end

if not exists(select top 1 1 from dbo.bJCCM with (nolock) where JCCo = @JCCo and Contract = @Contract)
	begin
	select @rcode = 1,@errmsg = @errmsg + @separator + 'JC Contract not set up in JC Company Master!'
	end

if isnull(@Mth,'') = ''
	begin
	select @rcode = 1,@errmsg = @errmsg + @separator + 'Invalid Month!'
	end

if isnull(@ActualDate,'') = ''
	begin
	select @rcode = 1,@errmsg = @errmsg + @separator + 'Invalid Date!'
	end

if not exists(select top 1 1 from dbo.HQBC with (nolock) where Co = @JCCo and Mth = @Mth  and BatchId=@BatchID)
	begin
	select @rcode = 1,@errmsg = @errmsg + @separator + 'HQ Batch is not set up!'
	end

--End error detection/Validation
if @rcode <> 0 goto bspexit

-- Initialize JCIR for Revenue Projections
select @batchseq=isnull(max(BatchSeq),0) from bJCIR with (nolock)
where Co=@JCCo and Mth=@Mth and BatchId=@BatchID

insert dbo.bJCIR (Co, Mth, BatchId, Contract, Item, Department, ActualDate, RevProjUnits,
		RevProjDollars, PrevRevProjUnits, PrevRevProjDollars, RevProjPlugged, BatchSeq)

select @JCCo, @Mth, @BatchID, i.Contract, i.Item, i.Department, @ActualDate, 

	ISNULL((select sum(ProjUnits)
	from dbo.bJCIP ip with (nolock)
	where ip.JCCo = @JCCo and ip.Contract=@Contract and ip.Item=i.Item and ip.Mth<@Mth),0)
	+
	ISNULL((select sum(ProjUnits)
	from dbo.bJCID dt with (nolock)
	where dt.JCCo = @JCCo and dt.Contract=@Contract and dt.Item=i.Item and dt.Mth=@Mth and dt.ActualDate<=@ActualDate),0), -- RevProjUnits

	ISNULL((select sum(ProjDollars)
	from dbo.bJCIP ip with (nolock)
	where ip.JCCo = @JCCo and ip.Contract=@Contract and ip.Item=i.Item and ip.Mth<@Mth),0)
	+
	ISNULL((select sum(ProjDollars)
	from dbo.bJCID dt with (nolock)
	where dt.JCCo = @JCCo and dt.Contract=@Contract and dt.Item=i.Item and dt.Mth=@Mth and dt.ActualDate<=@ActualDate),0), -- RevProjDollars

	ISNULL((select sum(ProjUnits)
	from dbo.bJCIP ip with (nolock)
	where ip.JCCo = @JCCo and ip.Contract=@Contract and ip.Item=i.Item and ip.Mth<@Mth),0)
	+
	ISNULL((select sum(ProjUnits)
	from dbo.bJCID dt with (nolock)
	where dt.JCCo = @JCCo and dt.Contract=@Contract and dt.Item=i.Item and dt.Mth=@Mth and dt.ActualDate<@ActualDate),0), -- PrevRevProjUnits

	ISNULL((select sum(ProjDollars)
	from dbo.bJCIP ip with (nolock)
	where ip.JCCo = @JCCo and ip.Contract=@Contract and ip.Item=i.Item and ip.Mth<@Mth),0)
	+
	ISNULL((select sum(ProjDollars)
	from dbo.bJCID dt with (nolock)
	where dt.JCCo = @JCCo and dt.Contract=@Contract and dt.Item=i.Item and dt.Mth=@Mth and dt.ActualDate<@ActualDate),0), -- PrevRevProjDollars

	ISNULL(i.ProjPlug,'N'), --RevProjPlugged

	@batchseq + ROW_NUMBER() OVER(ORDER BY i.Contract ASC) --BatchSeq

from dbo.JCCI i with (nolock)
where i.JCCo = @JCCo and i.Contract=@Contract and
not exists ( select 1 from dbo.bJCIR b with (nolock) where b.Co = i.JCCo and b.Mth =@Mth
		and b.BatchId = @BatchID and b.Contract=i.Contract and b.Item = i.Item)

---- if we already have a batch check to make sure we have departments.
if exists(select top 1 1 from dbo.JCIR where Department is null)
	begin
	update dbo.JCIR set Department = i.Department
	from dbo.JCIR b join dbo.JCCI i with (nolock) on i.JCCo=b.Co and i.Contract=b.Contract and i.Item=b.Item
	where b.Co = @JCCo and b.Mth =@Mth and b.BatchId = @BatchID and b.Department is null
	end



if @rcode = 0
	begin
	set @errmsg = ''
	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCRevProjInit] TO [public]
GO
