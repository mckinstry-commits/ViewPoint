DECLARE @Job bJob
SELECT @Job = ' 10187-002'

declare PBcur cursor for
select Co, Mth, BatchId, BatchSeq, Job, PhaseGroup, Phase, CostType, (OrigEstHours - ActualHours) As HoursRem
from 
	JCPB
where Co=1 
	and Job=@Job  --' 10187-002' 
	AND (OrigEstHours - ActualHours) > 0
	--AND OrigEstHours =0
for read only

declare @vCo bCompany
declare @vJob bJob
declare @vMth bMonth
declare @vBatchId int
declare @vBatchSeq int
declare @vDetSeq int
--declare @vJob bJob
declare @vPhaseGroup int
declare @vPhase bPhase
declare @vCostType int
declare @StartDate Date, @EndDate Date
Declare @Duration INT, @counter INT, @ActualCost bDollar, @vAmount bDollar, @HoursRem decimal, @vHours decimal

declare @rcnt int
select @rcnt = 0, @vDetSeq=0

declare @vspreadMonth Date
declare @vspreadEnd Date
declare @vspreadMth1 bMonth
declare @DayWeek INT, @EndDay INT

	
		select @StartDate = udProjStart, @EndDate = udProjEnd from JCJM where JCCo=1 and Job=@Job
		Select @Duration = ((datediff(WEEK,(case when @StartDate is null then @vMth else @StartDate end)
							,(case when @EndDate is null then @vMth else @EndDate end)))+1)

		SELECT @DayWeek = DATEPART(dw, @StartDate)
		IF @DayWeek = 1
			BEGIN
				 SET @StartDate = DATEADD(Day,-6,@StartDate)
			END
		ELSE
			BEGIN
				 SET @StartDate = DATEADD(Day,(2 - @DayWeek),@StartDate)
			END
		SELECT @EndDay  = DATEPART(dw, @EndDate)
		If @DayWeek = 1
			BEGIN
				SET @Duration = @Duration + 1
			END
		If @EndDay = 1
			BEGIN
				SET @Duration = @Duration - 1
			END

OPEN PBcur
FETCH PBcur INTO @vCo, @vMth, @vBatchId, @vBatchSeq, @vJob, @vPhaseGroup, @vPhase, @vCostType, @HoursRem

while @@FETCH_STATUS=0
begin
	select @rcnt=@rcnt+1

	SELECT @vHours = @HoursRem/@Duration

	select @vspreadMonth = @StartDate
	
	if @rcnt = 1
	begin
		select @vDetSeq=coalesce(max(DetSeq),0) from JCPD where Co = @vCo and Mth = @vMth and BatchId = @vBatchId and BatchSeq = @vBatchSeq
	
	end

	select @vDetSeq = @vDetSeq + 1

	--	print  
	--	cast(@vBatchSeq as varchar(10)) + '/'
	--+	cast(@vDetSeq as varchar(10)) + ' '
	--+	cast(@vCo as varchar(10)) + '.'
	--+	cast(@vJob as varchar(10)) + '.'
	--+	cast(@vPhase as varchar(10)) + '.'
	--+	cast(@vCostType as varchar(10)) + '.' 
	--+	cast(@ActualCost as varchar(10)) + '.' 
	--+	cast(@Duration as varchar(10)) + '.' 

	SELECT @counter = 0
	
	while @counter < @Duration 
	BEGIN
		
		SELECT @vspreadEnd = dateadd(Day,6,@vspreadMonth)
		SELECT @vspreadMth1 = dbo.vfFirstDayOfMonth(@vspreadEnd)
		
		exec sp_executesql N'insert INTO JCPD ([Co],[DetSeq],[Mth],[BatchId],[BatchSeq],[Source],[JCTransType],[TransType],[ResTrans],[Job],[PhaseGroup],[Phase],[CostType],[BudgetCode],[EMCo],[Equipment],[PRCo],[Craft],[Class],[Employee],[Description],[DetMth],[FromDate],[ToDate],[Quantity],[Units],[UM],[UnitHours],[Hours],[Rate],[UnitCost],[Amount],[Notes]) values 
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
		,@Craft=NULL
		,@Class=NULL
		,@Employee=NULL
		,@Description='Auto-Spread'
		,@DetMth = @vspreadMth1 
		,@FromDate= @vspreadMonth
		,@ToDate=@vspreadEnd
		,@Quantity=0
		,@Units=0
		,@UM='HRS'
		,@UnitHours=0
		,@Hours=@vHours
		,@Rate=0
		,@UnitCost=0
		,@Amount=0
		,@Notes=NULL

		select @vspreadMonth=DATEADD(Week,1,@vspreadMonth), @vDetSeq=@vDetSeq+1, @counter = @counter+1
	end

	/*;with sum_cte as
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
		--,	ProjFinalHrs = sum_cte.ProjFinalHrs
		,	ProjFinalCost = sum_cte.ProjFinalCost
		from
			sum_cte
		where		
			JCPB.Mth=sum_cte.Mth
		and JCPB.BatchId=sum_cte.BatchId
		and JCPB.Co=sum_cte.Co
		and JCPB.BatchSeq=sum_cte.BatchSeq*/
		--group by
		--	JCPD.Mth
		--and JCPD.BatchId
		--and JCPD.Co
		--and JCPD.BatchSeq

	fetch PBcur into @vCo, @vMth, @vBatchId, @vBatchSeq, @vJob, @vPhaseGroup, @vPhase, @vCostType, @HoursRem

end

close PBcur
deallocate PBcur
go

--delete JCPD where Job=' 10187-002' and Mth='2/1/2016'

--delete JCPR where Job=' 10187-002' and Mth='2/1/2016'