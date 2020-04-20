SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/**********************************************************/
CREATE   proc [dbo].[vspJCProjJCPDGet]
/***********************************************************
* CREATED BY:	GF 04/19/2009 - issue #129898
* MODIFIED BY:	GF 07/15/2009 - issue #134828 - only initialize from JCPR when no records in JCPD for phase cost type
*				GF 10/20/2009 - issue #135995 - bring in resource detail where there is no detail month for from and to dates
*				GF 10/04/2012 TK-18336 corrected join and where clauses for ud update to JCPD from JCPR
*
*
*
* USAGE:
* This procedure is used by the JC Projection Initialize to pull existing
* transactions from bJCPR into bJCPD as new or change.  Will only pull
* projection detail entries not in another batch.
*
* Checks batch info in bHQBC.
* Adds entry to next available Seq# in bJCPR
*
*
* INPUT PARAMETERS
* JCCo			JC Company
* Mth			JC Projections Batch Month
* BatchId		JC Projections Batch Id
* Job			JC Projection Job
* PhaseGroup	JC Phase Group
* Phase			JC Projection Phase
* CostType		JC Projection Cost Type
* @detailinit	flag to indicate whether to load values: 1-with values, 2-without values
*
*
* OUTPUT PARAMETERS
*   @msg
*
* RETURN VALUE
*   0         success
*   1         Failure  'if Fails THEN it fails.
*****************************************************/
(@co bCompany = 0, @mth bMonth = null, @batchid bBatchID = null, @job bJob = null,
 @phasegroup bGroup = 0, @phase bPhase = null , @costtype bJCCType = 0,
 @detailinit tinyint = 0, @errmsg varchar(255) output)
as
set nocount on

declare @rcode int, @retcode int, @status tinyint, @seq int, @errtext varchar(100),
		@count smallint, @transtype char(1), @opencursor tinyint, @jcprud_flag bYN,
		@join nvarchar(max), @where nvarchar(max), @update nvarchar(max),
   		@usermemosql nvarchar(max), @errcount smallint, @batchseq int

declare @restrans bTrans, @jcpr_batchid bBatchID, @inusebatchid bBatchID,
		@resmth bMonth, @detmth bMonth, @batcherrmsg varchar(100)
		
----TK-18336
DECLARE @JCPR_KeyId BIGINT

select @rcode = 0, @opencursor = 0, @jcprud_flag = 'N'

if @detailinit not in (2,3) goto bspexit

---- call bspUserMemoQueryBuild to create update, join, and where clause
---- pass in source and destination. Remember to use views only unless working
---- with a Viewpoint connection.
----TK-18336 
exec @rcode = dbo.bspUserMemoQueryBuild @co, @mth, @batchid, 'JCPR', 'JCPD', @jcprud_flag output,
   			@update output, @join output, @where output, @errmsg output
if @rcode <> 0 goto bspexit

---- get batch sequence for phase cost type
select @batchseq = BatchSeq
from bJCPB a where a.Co=@co and a.Mth=@mth and a.BatchId=@batchid
and Job=@job and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
if @@rowcount = 0 goto bspexit

---- check for detail in JCPD for current batch
if exists(select top 1 1 from bJCPD a where a.Co=@co and a.Mth=@mth and a.BatchId=@batchid
		and Job=@job and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype)
	begin
	goto bspexit
	end

----create_cursor:
---- create cursor on JCPR to insert transactions for phase cost type into JCPD
declare bcJCPR cursor LOCAL FAST_FORWARD
	for select ResTrans, Mth, DetMth
			----TK-18336
			,KeyID
from bJCPR where JCCo=@co and Job=@job and PhaseGroup=@phasegroup
and Phase=@phase and CostType=@costtype and InUseBatchId is NULL
and ((Mth = @mth or DetMth >= @mth)
---- #135995
or (DetMth IS NULL AND FromDate IS NULL AND ToDate IS NULL))

---- open cursor
open bcJCPR
set @opencursor = 1

---- loop through all rows in JCPR cursor and update their info.
jc_insert_loop:
fetch next from bcJCPR into @restrans, @resmth, @detmth
		----TK-18336
		,@JCPR_KeyId

if @@fetch_status <> 0 goto jc_insert_end

---- if the resource month is earlier that the batch month and we have detail for the batch month
---- do not add, has already been initialized.
IF @resmth < @mth AND EXISTS(SELECT TOP 1 1 FROM dbo.bJCPR WITH (NOLOCK) where JCCo=@co
		and Job=@job and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
		AND Mth > @resmth)
	BEGIN
	GOTO jc_insert_loop
	END
	
---- if initializing for the same month as the JCPR month
---- then we are pulling transaction into batch for change.
if @resmth = @mth
	begin
	---- get next available sequence # for this batch
	select @seq = isnull(max(DetSeq),0)+1
	from JCPD with (nolock)
	where Co=@co and Mth=@mth and BatchId=@batchid

	---- add JCPD transaction to batch
	insert into bJCPD (Co, Mth, BatchId, BatchSeq, DetSeq, Source, JCTransType, TransType, ResTrans,
			Job, PhaseGroup, Phase, CostType, BudgetCode, EMCo, Equipment, PRCo, Craft, Class,
			Employee, Description, DetMth, FromDate, ToDate, Quantity, UM, Units, UnitHours, Hours, Rate, UnitCost, Amount, Notes,
			OldTransType, OldJob, OldPhaseGroup, OldPhase, OldCostType, OldBudgetCode, OldEMCo,
			OldEquipment, OldPRCo, OldCraft, OldClass, OldEmployee, OldDescription, OldDetMth,
			OldFromDate, OldToDate, OldQuantity, OldUM, OldUnits, OldUnitHours, OldHours,
			OldRate, OldUnitCost, OldAmount, UniqueAttchID)
	select @co, @mth, @batchid, @batchseq, @seq, r.Source, r.JCTransType, 'C', r.ResTrans,
			@job, @phasegroup, @phase, @costtype, r.BudgetCode, r.EMCo, r.Equipment, r.PRCo,
			r.Craft, r.Class, r.Employee, r.Description, r.DetMth, r.FromDate, r.ToDate,
			r.Quantity, r.UM,
			Units = case when @detailinit = 2 then r.Units else 0 end,
			UnitHours = case when @detailinit = 2 then r.UnitHours else 0 end,
			Hours = case when @detailinit = 2 then r.Hours else 0 end,
			Rate = case when @detailinit = 2 then r.Rate else 0 end,
			UnitCost = case when @detailinit = 2 then r.UnitCost else 0 end,
			Amount = case when @detailinit = 2 then r.Amount else 0 end,
			r.Notes, 'C', @job, @phasegroup, @phase, @costtype, r.BudgetCode, r.EMCo, r.Equipment,
			r.PRCo, r.Craft, r.Class, r.Employee, r.Description, r.DetMth, r.FromDate, r.ToDate,
			r.Quantity, r.UM, r.Units, r.UnitHours, r.Hours, r.Rate, r.UnitCost, r.Amount,
			r.UniqueAttchID
	from bJCPR r with (nolock)
	where r.JCCo = @co and r.Mth = @resmth and r.ResTrans = @restrans
	if @@rowcount <> 1
		begin
		select @errmsg = 'Unable to add entry to JC Projection Detail Batch!', @rcode = 1
		goto bspexit
		end

	if @jcprud_flag = 'Y'
		BEGIN
		----TK-18336
		SET @join = ' from JCPR b '
		SET @where = ' where b.KeyID = ' + CONVERT(VARCHAR(20),@JCPR_KeyId)
 				+ ' and JCPD.Co = ' + convert(varchar(3),@co)
 				+ ' and JCPD.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
 				+ ' and JCPD.BatchId = ' +  CONVERT(VARCHAR(20),@batchid)
 				+ ' and JCPD.ResTrans = ' + CONVERT(VARCHAR(20),@restrans)
		-- create @sql and execute
		set @usermemosql = @update + @join + @where
		
		SELECT dbo.vfToString(@usermemosql)
		
		EXEC (@usermemosql)
		--set @usermemosql = @update + @join + @where + ' and b.ResTrans = ' + convert(varchar(10), @restrans) + ' and JCPR.ResTrans = ' + convert(varchar(10),@restrans)
		--exec sp_executesql @usermemosql
		end
		
	goto jc_insert_loop
	end



---- if initializing for an earlier month in JCPR then
---- we must have a detail month that we will initialize
---- and add to the batch as a new transaction
---- #135995
if @detmth > @mth OR @detmth IS null
	begin
	---- get next available sequence # for this batch
	select @seq = isnull(max(DetSeq),0)+ 1
	from bJCPD with (nolock)
	where Co=@co and Mth=@mth and BatchId=@batchid

	---- add JCPD transaction to batch
	insert into bJCPD (Co, Mth, BatchId, BatchSeq, DetSeq, Source, JCTransType, TransType, ResTrans,
			Job, PhaseGroup, Phase, CostType, BudgetCode, EMCo, Equipment, PRCo, Craft, Class,
			Employee, Description, DetMth, FromDate, ToDate, Quantity, UM, Units, UnitHours, Hours,
			Rate, UnitCost, Amount, Notes, OldTransType, OldJob, OldPhaseGroup, OldPhase, OldCostType,
			OldBudgetCode, OldEMCo, OldEquipment, OldPRCo, OldCraft, OldClass, OldEmployee,
			OldDescription, OldDetMth, OldFromDate, OldToDate, OldQuantity, OldUM, OldUnits,
			OldUnitHours, OldHours, OldRate, OldUnitCost, OldAmount, UniqueAttchID)
	select @co, @mth, @batchid, @batchseq, @seq, r.Source, r.JCTransType, 'A', null,
			@job, @phasegroup, @phase, @costtype, r.BudgetCode, r.EMCo, r.Equipment, r.PRCo,
			r.Craft, r.Class, r.Employee, r.Description, r.DetMth, r.FromDate, r.ToDate,
			r.Quantity, r.UM,
			Units = case when @detailinit = 2 then r.Units else 0 end,
			UnitHours = case when @detailinit = 2 then r.UnitHours else 0 end,
			Hours = case when @detailinit = 2 then r.Hours else 0 end,
			Rate = case when @detailinit = 2 then r.Rate else 0 end,
			UnitCost = case when @detailinit = 2 then r.UnitCost else 0 end,
			Amount = case when @detailinit = 2 then r.Amount else 0 end,
			r.Notes, 'A', r.Job, r.PhaseGroup, r.Phase, r.CostType, r.BudgetCode, r.EMCo, r.Equipment,
			r.PRCo, r.Craft, r.Class, r.Employee, r.Description, r.DetMth, r.FromDate, r.ToDate,
			r.Quantity, r.UM, r.Units, r.UnitHours, r.Hours, r.Rate, r.UnitCost, r.Amount, null
	from bJCPR r with (nolock)
	where r.JCCo = @co and r.Mth = @resmth and r.ResTrans = @restrans
	if @@rowcount <> 1
		begin
		select @errmsg = 'Unable to add entry to JC Projection Detail Batch!', @rcode = 1
		goto bspexit
		end

	if @jcprud_flag = 'Y'
		BEGIN
		----TK-18336
		SET @join = ' from JCPR b '
		SET @where = ' where b.KeyID = ' + CONVERT(VARCHAR(20),@JCPR_KeyId)
 				+ ' and JCPD.Co = ' + convert(varchar(3),@co)
 				+ ' and JCPD.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
 				+ ' and JCPD.BatchId = ' +  CONVERT(VARCHAR(20),@batchid)
 				+ ' and JCPD.ResTrans = ' + CONVERT(VARCHAR(20),@restrans)
		-- create @sql and execute
		set @usermemosql = @update + @join + @where
		SELECT dbo.vfToString(@usermemosql)
		
		EXEC (@usermemosql)
		--set @usermemosql = @update + @join + @where + ' and b.ResTrans = ' + convert(varchar(10), @restrans) + ' and JCPR.ResTrans = ' + convert(varchar(10),@restrans)
		--exec sp_executesql @usermemosql
		end
	end
	
----select @count = @count + 1
goto jc_insert_loop


jc_insert_end:


bspexit:
	if @opencursor = 1
		begin
		close bcJCPR
		deallocate bcJCPR
		end
   
	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspJCProjJCPDGet] TO [public]
GO
