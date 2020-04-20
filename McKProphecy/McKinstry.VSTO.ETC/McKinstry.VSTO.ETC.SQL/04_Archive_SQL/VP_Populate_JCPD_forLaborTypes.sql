
declare pbcur cursor for
select Co, Mth, BatchId, BatchSeq, Job, PhaseGroup, Phase, CostType
from 
	JCPB
where
	Co=1 and Job='104495-001' and CostType=1
for read only


declare @vCo bCompany
declare @vMth bMonth
declare @vBatchId int
declare @vBatchSeq int
declare @vDetSeq int
declare @vJob bJob
declare @vPhaseGroup int
declare @vPhase bPhase
declare @vCostType int

declare @rcnt int
select @vDetSeq=0,@rcnt = 0

declare @vspreadMonth bMonth


open pbcur
fetch pbcur into @vCo, @vMth, @vBatchId, @vBatchSeq, @vJob, @vPhaseGroup, @vPhase, @vCostType

while @@FETCH_STATUS=0
begin
	select @rcnt=@rcnt+1

	if @rcnt = 1
	begin
		select @vDetSeq=coalesce(max(DetSeq),0) from JCPD where Co=@vCo and Mth=@vMth and BatchId=@vBatchId and BatchSeq=@vBatchSeq
	end

	select @vDetSeq=@vDetSeq+1

	print  
		cast(@vBatchSeq as varchar(10)) + '/'
	+	cast(@vDetSeq as varchar(10)) + ' '
	+	cast(@vCo as varchar(10)) + '.'
	+	cast(@vJob as varchar(10)) + '.'
	+	cast(@vPhase as varchar(10)) + '.'
	+	cast(@vCostType as varchar(10)) 

	select @vspreadMonth=@vMth
	
	while @vspreadMonth <= dateadd(month,6,@vMth)
	begin

		exec sp_executesql N'insert JCPD ([Co],[DetSeq],[Mth],[BatchId],[BatchSeq],[Source],[JCTransType],[TransType],[ResTrans],[Job],[PhaseGroup],[Phase],[CostType],[BudgetCode],[EMCo],[Equipment],[PRCo],[Craft],[Class],[Employee],[Description],[DetMth],[FromDate],[ToDate],[Quantity],[Units],[UM],[UnitHours],[Hours],[Rate],[UnitCost],[Amount],[Notes]) values 
		(@Co,@DetSeq,@Mth,@BatchId,@BatchSeq,@Source,@JCTransType,@TransType,@ResTrans,@Job,@PhaseGroup,@Phase,@CostType,@BudgetCode,@EMCo,@Equipment,@PRCo,@Craft,@Class,@Employee,@Description,@DetMth,@FromDate,@ToDate,@Quantity,@Units,@UM,@UnitHours,@Hours,@Rate,@UnitCost,@Amount,@Notes)',N'@BatchSeq int,@Co tinyint,@DetSeq int,@Mth datetime,@BatchId int,@Source varchar(10),@JCTransType varchar(2),@TransType varchar(1),@ResTrans int,@Job varchar(10),@PhaseGroup tinyint,@Phase varchar(20),@CostType int,@BudgetCode varchar(8000),@EMCo tinyint,@Equipment varchar(8000),@PRCo tinyint,@Craft varchar(4),@Class varchar(5),@Employee int,@Description varchar(3),@DetMth datetime,@FromDate datetime,@ToDate datetime,@Quantity float,@Units float,@UM varchar(3),@UnitHours float,@Hours float,@Rate float,@UnitCost float,@Amount float,@Notes varchar(8000)'
		,@BatchSeq=@vBatchSeq
		,@Co=@vCo
		,@DetSeq=@vDetSeq
		,@Mth=@vMth
		,@BatchId=@vBatchId
		,@Source='JC Projctn'
		,@JCTransType='PB'
		,@TransType='A'
		,@ResTrans=NULL
		,@Job=@vJob
		,@PhaseGroup=@vPhaseGroup
		,@Phase=@vPhase
		,@CostType=@vCostType
		,@BudgetCode=NULL
		,@EMCo=NULL
		,@Equipment=NULL
		,@PRCo=1
		,@Craft='0001'
		,@Class='501PC'
		,@Employee=NULL
		,@Description='MIS'
		,@DetMth=@vspreadMonth
		,@FromDate=NULL
		,@ToDate=NULL
		,@Quantity=0
		,@Units=0
		,@UM='HRS'
		,@UnitHours=1
		,@Hours=50
		,@Rate=75
		,@UnitCost=0
		,@Amount=3750
		,@Notes=NULL

		;with sum_cte as
		(
		select
		  JCPD.Mth
		, JCPD.BatchId
		, JCPD.Co
		, JCPD.BatchSeq
		, sum(Hours) as ProjFinalHrs
		, sum(Amount) as ProjFinalCost
		from
			JCPD
		where
			JCPD.Mth=@vMth
		and JCPD.BatchId=@vBatchId
		and JCPD.Co=@vCo
		and JCPD.BatchSeq=@vBatchSeq
		group by
		  JCPD.Mth
		, JCPD.BatchId
		, JCPD.Co
		, JCPD.BatchSeq
		) 
		update JCPB set 
			Plugged='Y'
		,	ProjFinalHrs = sum_cte.ProjFinalHrs
		,	ProjFinalCost = sum_cte.ProjFinalCost
		from
			sum_cte
		where		
			JCPB.Mth=sum_cte.Mth
		and JCPB.BatchId=sum_cte.BatchId
		and JCPB.Co=sum_cte.Co
		and JCPB.BatchSeq=sum_cte.BatchSeq
		--group by
		--	JCPD.Mth
		--and JCPD.BatchId
		--and JCPD.Co
		--and JCPD.BatchSeq

		select @vspreadMonth=DATEADD(month,1,@vspreadMonth), @vDetSeq=@vDetSeq+1
	end

	fetch pbcur into @vCo, @vMth, @vBatchId, @vBatchSeq, @vJob, @vPhaseGroup, @vPhase, @vCostType

end

close pbcur
deallocate pbcur
go

--delete JCPD where BatchId=20 and Mth='2/1/2016'