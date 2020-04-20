SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************/
CREATE   proc [dbo].[vspJCPDInsertExisting]
/***********************************************************
* CREATED BY:	GF 04/08/2009
* MODIFIED BY:	GF 10/04/2012 TK-18336 corrected join and where clauses for ud update to JCPD from JCPR
*
*
* USAGE:
* This procedure is used by the JC Projection Detail Entry to pull existing
* transactions from bJCPR into bJCPD for editing.  Will only pull
* projection detail entries not in another batch, that meet all restrictions
*
* Checks batch info in bHQBC.
* Adds entry to next available Seq# in bJCPR
*
*
* INPUT PARAMETERS
* JCCo		JC Company
* Mth		JC Projections Batch Month
* BatchId	JC Projections Batch Id
* Job		JC Projection Job
* @budgetcodestart	starting budget code, may be null
* @budgetcodeend	ending budget code, may be null
* @xtrans		JCPR Transaction
* @markfordelete	Mark transactions added to batch for delete
*
*
* OUTPUT PARAMETERS
*   @msg
*
* RETURN VALUE
*   0         success
*   1         Failure  'if Fails THEN it fails.
*****************************************************/
(@co bCompany, @mth bDate, @batchid bBatchID, @job bJob, 
 @xtrans bTrans = null, @check_budget bYN = 'N', @budgetcodestart varchar(10) = null,
 @budgetcodeend varchar(10) = null, @markfordelete bYN = 'N', 
 @errmsg varchar(255) output)
as
set nocount on


declare @rcode int, @retcode int, @status tinyint, @seq int, @errtext varchar(100),
		@count smallint, @transtype char(1), @opencursor tinyint, @jcprud_flag bYN,
		@join varchar(2000), @where varchar(2000), @update varchar(2000),
   		@usermemosql varchar(8000), @errcount smallint

declare @restrans bTrans, @jcpr_batchid bBatchID, @jcpr_phase bPhase, @jcpr_costtype bJCCType,
		@jcpr_budgetcode varchar(10), @jcpr_emco bCompany, @jcpr_equipment bEquip,
		@jcpr_prco bCompany, @jcpr_craft bCraft, @jcpr_class bClass, @jcpr_employee bEmployee,
		@inusebatchid bBatchID, @batchseq int, @batcherrmsg varchar(100)
		
----TK-18336
DECLARE @JCPR_KeyId BIGINT

select @rcode = 0, @opencursor = 0, @jcprud_flag = 'N'

---- set tranaction type based on mark for delete flag
if @markfordelete='Y'
	begin
	select @transtype='D'
	end
else
	begin
	select @transtype='C'
	end

---- call bspUserMemoQueryBuild to create update, join, and where clause
---- pass in source and destination. Remember to use views only unless working
---- with a Viewpoint connection.
exec @rcode = dbo.bspUserMemoQueryBuild @co, @mth, @batchid, 'JCPR', 'JCPD', @jcprud_flag output,
   			@update output, @join output, @where output, @errmsg output
if @rcode <> 0 goto bspexit

---- validate HQ Batch
exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'JC Projctn', 'JCPB', @errtext output, @status output
if @rcode <> 0
	begin
	select @errmsg = @errtext, @rcode = 1
	goto bspexit
	end
if @status <> 0
	begin
	select @errmsg = 'Invalid Batch status -  must be ''open''!', @rcode = 1
	goto bspexit
	end


---- create cursor on JCPR to insert transactions into JCPD
declare bcJCPR cursor LOCAL FAST_FORWARD
	for select ResTrans, BatchId, Phase, CostType, BudgetCode, EMCo,
			Equipment, PRCo, Craft, Class, Employee, InUseBatchId
			----TK-18336
			,KeyID
from JCPR where JCCo=@co and Mth=@mth and Job=@job

---- open cursor
open bcJCPR
select @opencursor = 1

---- loop through all rows in MSTD cursor and update their info.
jc_insert_loop:
fetch next from bcJCPR into @restrans, @jcpr_batchid, @jcpr_phase, @jcpr_costtype, @jcpr_budgetcode,
			@jcpr_emco, @jcpr_equipment, @jcpr_prco, @jcpr_craft, @jcpr_class,
			@jcpr_employee, @inusebatchid
			----TK-18336
			,@JCPR_KeyId

if @@fetch_status <> 0 goto jc_insert_end

if @inusebatchid is not null
	begin
	select @batcherrmsg = 'Transaction: ' + convert(varchar(8),@restrans) + ' already in use by Batch Id: ' + convert(varchar(6),@inusebatchid) + '.'
	select @errcount = @errcount + 1
	goto jc_insert_loop
	end

if @xtrans is not null 
	begin
	if @xtrans <> @restrans goto jc_insert_loop
	end

---- range of budget codes
if @check_budget = 'Y'
	begin
	---- if we have a begin and end range of budget codes must have @jcpr_budgetcode
	if isnull(@budgetcodestart,'') <> '' and isnull(@budgetcodeend,'') <> ''
		begin
		if isnull(@jcpr_budgetcode,'') = '' goto jc_insert_loop
		---- begin
		if @jcpr_budgetcode < @budgetcodestart goto jc_insert_loop
		---- end
		if @jcpr_budgetcode > @budgetcodeend goto jc_insert_loop
		end
	else
		begin
		---- begin budget code may be empty
		if isnull(@budgetcodestart,'') <> '' and isnull(@jcpr_budgetcode,'') <> ''
			begin
			if @jcpr_budgetcode < @budgetcodestart goto jc_insert_loop
			end
		---- end ticket may be empty
		if isnull(@budgetcodeend,'') <> '' and isnull(@jcpr_budgetcode,'') <> ''
			begin
			if @jcpr_budgetcode > @budgetcodeend goto jc_insert_loop
			end
		end
	end


---- check JCPB batch and verify that phase and cost type exist in batch
---- get batch seq from JCPB if not found do not add JCPR to JCPD
select @batchseq = BatchSeq
from bJCPB with (nolock)
where Co=@co and Mth=@mth and BatchId=@batchid and Job=@job
and Phase=@jcpr_phase and CostType=@jcpr_costtype
if @@rowcount = 0 goto jc_insert_loop


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

select @co, @mth, @batchid, @batchseq, @seq, Source, JCTransType, @transtype, ResTrans,
		@job, PhaseGroup, Phase, CostType, BudgetCode, EMCo, Equipment, PRCo, Craft, Class,
		Employee, Description, DetMth, FromDate, ToDate, Quantity, UM, Units, UnitHours,
		Hours, Rate, UnitCost, Amount, Notes, @transtype, @job, PhaseGroup, Phase, CostType,
		BudgetCode, EMCo, Equipment, PRCo, Craft, Class, Employee, Description, DetMth,
		FromDate, ToDate, Quantity, UM, Units, UnitHours, Hours, Rate, UnitCost, Amount,
		UniqueAttchID
from JCPR with (nolock)
where JCCo = @co and Mth = @mth and ResTrans = @restrans
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
			+ ' and JCPD.ResTrans = ' + CONVERT(VARCHAR(20),@restrans)
	-- create @sql and execute
	set @usermemosql = @update + @join + @where
	EXEC (@usermemosql)
	--set @usermemosql = @update + @join + @where + ' and b.ResTrans = ' + convert(varchar(10), @restrans) + ' and JCPR.ResTrans = ' + convert(varchar(10),@restrans)
	--exec (@usermemosql)
	end

select @count = @count + 1
goto jc_insert_loop


jc_insert_end:
if @count=0
	begin
	select @errmsg = 'No transactions were found to add to batch.', @rcode=1
	if @errcount = 1 and @batcherrmsg is not null
		begin
		select @errmsg = @errmsg + char(13) + char(10) + @batcherrmsg
		goto bspexit
		end
	if @errcount <> 0
		begin
		select @errmsg = @errmsg + char(13) + char(10) + convert(varchar(8),@errcount) + ' transactions could not be added to this batch.'
		end
	end
else
	begin
	select @errmsg = convert(varchar(8),@count) + ' transactions have been added to this batch.'
	if @errcount = 1 and @batcherrmsg is not null
		begin
		select @errmsg = @errmsg + char(13) + char(10) + @batcherrmsg
		goto bspexit
		end
	if @errcount <> 0
		begin
		select @errmsg = @errmsg + char(13) + char(10) + convert(varchar(8),@errcount) + ' transactions could not be added to this batch.'
		end
	end



bspexit:
	if @opencursor = 1
		begin
		close bcJCPR
		deallocate bcJCPR
		end
   
	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspJCPDInsertExisting] TO [public]
GO
