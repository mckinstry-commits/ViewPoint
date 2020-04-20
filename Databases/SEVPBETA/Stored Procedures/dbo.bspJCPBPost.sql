SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/********************************************/
CREATE proc [dbo].[bspJCPBPost]
/****************************************************************************
* CREATED BY: 	GF	04/12/1999
* MODIFIED BY:  GF	04/12/2000
*               GF	10/06/2000	- #10410 & #10738
*				CMW	04/04/2002		- added bHQBC.Notes interface levels update (issue # 16692).
*				GF	10/15/2002	- #19014 - Possible for JCCD records added with no change. Considered if plugged
*								also, then record created. Now checks for change to plug value.
*				GF	02/12/2004	- added UniqueAttchID column to insert into JCCD. Also re-index.
*				TV				- 23061 added isnulls
*				GF	08/15/2005	- issue #29537 changed logic to delete future projections.
*				GF	02/14/2008	- issue #124680 use JCCO.ProjPostForecast when creating JCCD records and only forecast exists
*				GF	03/07/2008	- issue #28469 update JCCP.ProjPlug flag.
*				GP	10/31/2008	- Issue 130576, changed text datatype to varchar(max)
*				GF	01/16/2008	- issue #131828 changed delete for future to only outside current post month.
*				GF	03/29/2009	- issue #129898 projection detail post (JCPR)
*				GF	10/15/2009	- issue #136111 update JCCD user memos from JCPB user memos
*				CHS	01/12/2009	- issue #136309
*				GF 09/12/2010 - issue #141031 changed to use function vfDateOnly
*				AMR 01/17/11 - #142350, making case sensitive by removing unused vars and renaming same named variables-
*				GF 09/26/2012 TK-18139 change update statement for JCPR from JCPD ud column update
*
*			
*
* USAGE:
* 	Posts JCPB batch table to JCCD
*
* INPUT PARAMETERS:
*
*
* OUTPUT PARAMETERS:
*
*
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
*****************************************************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID, @dateposted bDate = null,
 @errmsg varchar(255) output)
as
set nocount on
--#142350 - renaming @notes
declare @rcode int, @opencursor tinyint, @source bSource, @tablename char(20), @seq int,
		@status tinyint, @transtype char(2), @validcnt int, @jctrans bTrans,
		@job bJob, @phasegroup tinyint, @phase bPhase, @costtype bJCCType, @actualdate bDate,
		@um bUM, @postedum bUM, @plugged bYN, @netchange tinyint,

		@projfinalunits bUnits, @projfinalhrs bHrs, @projfinalcost bDollar, @prevprojunits bUnits,
		@prevprojhrs bHrs, @prevprojcost bDollar, @forecastfinalunits bUnits, @forecastfinalhrs bHrs,
		@forecastfinalcost bDollar, @prevforecastunits bUnits, @prevforecasthrs bHrs,
		@prevforecastcost bDollar, @projhours bHrs, @projunits bUnits, @projcost bDollar,
		@forecasthours bHrs, @forecastunits bUnits, @forecastcost bDollar, @oldplugged bYN, 
		@Notes varchar(256), @uniqueattchid uniqueidentifier, @projpostforecast bYN,
		@projjobinmultibatch bYN, @jcpb_oldplugged varchar(1),

		@openjcpd_cursor int, @detseq int, @budgetcode varchar(10), @emco bCompany, @equipment bEquip,
		@prco bCompany, @craft bCraft, @class bClass, @description bItemDesc, @fromdate bDate,
		@todate bDate, @units bUnits, @unithours bHrs, @hours bHrs, @rate bUnitCost,
		@unitcost bUnitCost, @amount bDollar, @NotesCur varchar(max), @jcpd_keyid bigint,
		@jcprud_flag bYN, @join varchar(1000), @where varchar(1000), @update varchar(2000), 
   		@sql nvarchar(4000), @paramsin nvarchar(200), @restrans bTrans, @jcpd_actualdate bDate,
		@employee bEmployee, @detmth bMonth, @quantity bUnits, @jccdud_flag char(1),
		@jccd_update VARCHAR(MAX), @jccd_join VARCHAR(MAX), @jccd_where VARCHAR(MAX),
		@jcpb_keyid bigint


select @rcode = 0, @opencursor = 0, @openjcpd_cursor = 0, @jcprud_flag = 'N', @jccdud_flag = 'N'

-- call bspUserMemoQueryBuild to create update, join, and where clause
-- pass in source and destination. Remember to use views only unless working
-- with a Viewpoint connection.
exec @rcode = dbo.bspUserMemoQueryBuild @co, @mth, @batchid, 'JCPD', 'JCPR', @jcprud_flag output,
			@update output, @join output, @where output, @errmsg output
if @rcode <> 0 set @jcprud_flag = 'N'

----#136111
exec @rcode = dbo.bspUserMemoQueryBuild @co, @mth, @batchid, 'JCPB', 'JCCD', @jccdud_flag output,
			@jccd_update output, @jccd_join output, @jccd_where output, @errmsg output
if @rcode <> 0 set @jccdud_flag = 'N'

---- get JCCO info
select @projpostforecast=ProjPostForecast, @projjobinmultibatch=ProjJobInMultiBatch
from JCCO with (nolock) where JCCo=@co
if @@rowcount = 0
	begin
	select @errmsg = 'Invalid JC Company!', @rcode = 1
	goto bspexit
	end

-- check for date posted
if @dateposted is null
	begin
	select @errmsg = 'Missing posting date!', @rcode = 1
	goto bspexit
	end

-- validate HQ Batch
select @source = 'JC Projctn'
exec @rcode = bspHQBatchProcessVal @co, @mth, @batchid, @source, 'JCPB', @errmsg output, @status output
if @rcode <> 0 goto bspexit

if @status <> 3 and @status <> 4	-- valid - OK to post, or posting in progress
	begin
	select @errmsg = 'Invalid Batch status -  must be valid - OK to post or posting in progress!', @rcode = 1
	goto bspexit
	end

-- set HQ Batch status to 4 (posting in progress)
update bHQBC set Status = 4, DatePosted = @dateposted
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
	goto bspexit
	end

---- set projection detail actual date to JCPB actual date
select @jcpd_actualdate = min(ActualDate)
from bJCPB where Co=@co and Mth=@mth and BatchId=@batchid
if isnull(@jcpd_actualdate,'') = ''
	BEGIN
	----#141031
	set @jcpd_actualdate = dbo.vfDateOnly()
	end


---- declare cursor on JC Projection Batch for posting
declare bcJCPB cursor LOCAL FAST_FORWARD
		for select Job, PhaseGroup, Phase, CostType, ActualDate, ProjFinalUnits, ProjFinalHrs,
				ProjFinalCost, ForecastFinalUnits, ForecastFinalHrs, ForecastFinalCost, Plugged,
				UniqueAttchID, OldPlugged, KeyID
from bJCPB where Co=@co and Mth=@mth and BatchId=@batchid

---- open cursor
open bcJCPB
select @opencursor = 1

---- loop through all rows in this batch
jcpb_posting_loop:
fetch next from bcJCPB into @job, @phasegroup, @phase, @costtype, @actualdate,
		@projfinalunits, @projfinalhrs, @projfinalcost, @forecastfinalunits,
		@forecastfinalhrs, @forecastfinalcost, @plugged, @uniqueattchid, @jcpb_oldplugged,
		@jcpb_keyid

if (@@fetch_status <> 0) goto jcpb_posting_end



---- look for cost type in JCCH - delete current line if not there - issue #136309
if not exists (select 1 from bJCCH with (nolock) where JCCo = @co and Job = @job and PhaseGroup = @phasegroup and Phase = @phase and CostType = @costtype)
	begin
	---- delete current row from cursor
	delete from bJCPB where Co=@co and Mth=@mth and BatchId=@batchid and Job=@job
	and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
	goto jcpb_posting_loop
	end
	

---- get UM from bJCCH
select @um=UM, @postedum=UM, @oldplugged=Plugged
from bJCCH with (nolock) where JCCo=@co and Job=@job and Phase=@phase and CostType=@costtype

if isnull(@jcpb_oldplugged,'') = '' set @jcpb_oldplugged = @oldplugged

begin transaction

---- delete future projections in bJCCD depending on multi open batches allowed #131828
if @projjobinmultibatch = 'Y'
	begin
	delete from bJCCD 
	where JCCo=@co and Job=@job and Phase=@phase and CostType=@costtype
	and PhaseGroup=@phasegroup and Source='JC Projctn' and JCTransType='PF'
	and Mth>@mth
	end
else
	begin
	delete from bJCCD 
	where JCCo=@co and Job=@job and Phase=@phase and CostType=@costtype
	and PhaseGroup=@phasegroup and Source='JC Projctn' and JCTransType='PF'
	---- #29537 below
	and (Mth>@mth or (Mth=@mth and PostedDate>=@dateposted))
	end

---- remove old JCPR projection worksheet detail for future months if any exists
delete from bJCPR
where JCCo=@co and Job=@job and Phase=@phase and CostType=@costtype
and PhaseGroup=@phasegroup and Source='JC Projctn' and JCTransType='PF'
and Mth>@mth


---- get sum of previous projections and forecasts
select @prevprojhrs = isnull(Sum(ProjHours),0), @prevprojunits = isnull(Sum(ProjUnits),0),
		@prevprojcost = isnull(Sum(ProjCost),0), @prevforecasthrs = isnull(Sum(ForecastHours),0),
		@prevforecastunits = isnull(Sum(ForecastUnits),0), @prevforecastcost = isnull(Sum(ForecastCost),0)
from bJCCP where JCCo=@co and Job=@job and PhaseGroup=@phasegroup and Phase=@phase
and CostType=@costtype and Mth<=@mth
if @@rowcount = 0
	begin
	---- no previous projections, so use final
	select @projhours=@projfinalhrs, @projunits=@projfinalunits, @projcost=@projfinalcost,
			@forecasthours=@forecastfinalhrs, @forecastunits=@forecastfinalunits,
			@forecastcost=@forecastfinalcost
	end
else
	begin
	---- calculate projections and forecasts variance
	select @projhours=@projfinalhrs-@prevprojhrs, @projunits=@projfinalunits-@prevprojunits,
			@projcost=@projfinalcost-@prevprojcost, @forecasthours=@forecastfinalhrs-@prevforecasthrs,
			@forecastunits=@forecastfinalunits-@prevforecastunits,
			@forecastcost=@forecastfinalcost-@prevforecastcost
	end

---- check if something to update
select @netchange = 0
if @projhours <> 0 or @projunits <> 0 or @projcost <> 0 set @netchange = 1

---- to update when forecast only exists set @netchange using the @projpostforecast flag
if @projpostforecast = 'Y'
	begin
	if @forecasthours <> 0 or @forecastunits <> 0 or @forecastcost <> 0 set @netchange = 1
	end

---- now need to check old plug from batch to plug and then old from JCCH to plugged
if @projjobinmultibatch <> 'Y'
	begin
	if @plugged = 'Y' and @oldplugged = 'N' set @netchange = 1
	if @plugged = 'N' and @oldplugged = 'Y' set @netchange = 1
	end

if @projjobinmultibatch = 'Y'
	begin
	---- when the JCPB.Plugged = JCPB.OldPlugged then plugged was not changed.
	---- if does not equal then plugged has been changed.
	if @plugged <> @jcpb_oldplugged set @netchange = 1
	---- if the batch old plug does not equal the JCCP plug flag then another batch updated
	---- we want to skip this projection so that the other post is not wiped out.
	if @jcpb_oldplugged <> @oldplugged set @netchange = 0
	end


---- get next available transaction # for JCCD
select @tablename = 'bJCCD'
exec @jctrans = bspHQTCNextTrans @tablename, @co, @mth, @errmsg output
if @jctrans = 0 goto jcpb_posting_error
  
if @netchange = 1
	BEGIN
	---- insert JC Detail
	insert bJCCD (JCCo, Mth, CostTrans, Job, PhaseGroup, Phase, CostType, PostedDate,
			ActualDate, JCTransType, Source, Description, BatchId, InUseBatchId, UM, PostedUM,
			ProjHours, ProjUnits, ProjCost, ForecastHours, ForecastUnits, ForecastCost,
			UniqueAttchID)
	values (@co, @mth, @jctrans, @job, @phasegroup, @phase, @costtype, @dateposted,
			@actualdate, 'PF', 'JC Projctn', null, @batchid, null, @um, @postedum,
			@projhours,	@projunits, @projcost, @forecasthours, @forecastunits, @forecastcost,
			@uniqueattchid)
	if @@rowcount = 0 goto jcpb_posting_error

	---- update bJCCH
	update bJCCH set LastProjDate=@actualdate, Plugged=@plugged
	where JCCo=@co and Job=@job and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype
	if @@rowcount = 0 goto jcpb_posting_error
	---- update bJCCP for batch month #28489
	update bJCCP set ProjPlug=@plugged
	where JCCo=@co and Job=@job and PhaseGroup=@phasegroup and Phase=@phase
	and CostType=@costtype and Mth=@mth
	
	---- UPDATE USER memos #136111
	if @jccdud_flag = 'Y'
		BEGIN
		SET @jccd_join = ' from JCPB b '
		SET @jccd_where = ' where b.KeyID = ' + CONVERT(VARCHAR(20),@jcpb_keyid)
 				+ ' and JCCD.JCCo = ' + convert(varchar(3),@co)
 				+ ' and JCCD.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
 				+ ' and JCCD.CostTrans = ' + CONVERT(VARCHAR(20),@jctrans)
 				
		-- create @sql and execute
		set @sql = @jccd_update + @jccd_join + @jccd_where
		EXEC (@sql)
		----set @paramsin = N'@co tinyint, @mth bMonth, @batchid int, @jctrans int'
		----EXECUTE sp_executesql @sql, @paramsin, @co, @mth, @batchid, @jctrans
		END
	END


---- delete current row from cursor
delete from bJCPB where Co=@co and Mth=@mth and BatchId=@batchid and Job=@job
and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype

commit transaction


---- Refresh indexes for this transaction if attachments exist
if @uniqueattchid is not null
	begin
	exec dbo.bspHQRefreshIndexes null, null, @uniqueattchid, null
	end


goto jcpb_posting_loop


jcpb_posting_error:	-- error occured within transaction - rollback any updates and continue
	rollback transaction
	goto jcpb_posting_loop


jcpb_posting_end:    -- no more rows to process
	if @opencursor = 1
		begin
		close bcJCPB
		deallocate bcJCPB
		set @opencursor = 0
		end
	
---- make sure batch is empty
select @validcnt=count(*) from bJCPB with (nolock)
where Co=@co and Mth=@mth and BatchId=@batchid
if @validcnt <> 0
	begin
	select @errmsg = 'Not all JC Projection batch entries were posted - unable to close batch!', @rcode = 1
	goto bspexit
	end



/****************************************************
* declare cursor on JC Projection Detail for posting
*****************************************************/

declare bcJCPD cursor LOCAL FAST_FORWARD
		for select TransType, ResTrans, Job, PhaseGroup, Phase, CostType, BudgetCode,
				EMCo, Equipment, PRCo, Craft, Class, Employee, Description, DetMth,
				FromDate, ToDate, Quantity, UM, Units, UnitHours, Hours, Rate, UnitCost,
				Amount, Notes, UniqueAttchID, KeyID
from bJCPD where Co=@co and Mth=@mth and BatchId=@batchid

---- open cursor
open bcJCPD
set @openjcpd_cursor = 1

---- loop through all rows in this batch
JCPD_loop:
fetch next from bcJCPD into @transtype, @restrans, @job, @phasegroup, @phase, @costtype, @budgetcode,
			@emco, @equipment, @prco, @craft, @class, @employee, @description, @detmth,
			@fromdate, @todate, @quantity, @um, @units, @unithours, @hours, @rate,
			@unitcost, @amount, @NotesCur, @uniqueattchid, @jcpd_keyid

if (@@fetch_status <> 0) goto JCPD_end

---- do some clean up
if @emco is null and @equipment is not null set @equipment = null
if @emco is not null and @equipment is null set @emco = null

if @prco is null and @employee is not null set @employee = null
if @prco is null and @craft is not null set @craft = null
if @prco is null and @class is not null set @class = null
if @prco is not null and @craft is null and @employee is null set @prco = null ----#135183

---- insert detail transaction
if @transtype = 'A'
	begin

	begin transaction

	---- get next available transaction # for JCPR
	select @tablename = 'bJCPR'
	exec @restrans = bspHQTCNextTrans @tablename, @co, @mth, @errmsg output
	if @restrans = 0 goto JCPD_error
	   
	---- insert JC Projection Detail
	insert bJCPR (JCCo, Mth, ResTrans, Job, PhaseGroup, Phase, CostType, PostedDate,
			ActualDate, JCTransType, Source, BudgetCode, EMCo, Equipment, PRCo, Craft,
			Class, Employee, Description, DetMth, FromDate, ToDate, Quantity, UM,
			Units, UnitHours, Hours, Rate, UnitCost, Amount, BatchId, InUseBatchId,
			Notes, UniqueAttchID)
	select @co, @mth, @restrans, @job, @phasegroup, @phase, @costtype, @dateposted,
			@jcpd_actualdate, 'PF', 'JC Projctn', @budgetcode, @emco, @equipment, @prco, @craft,
			@class, @employee, @description, @detmth, @fromdate, @todate, isnull(@quantity,0),
			@um, isnull(@units,0), isnull(@unithours,0), isnull(@hours,0), isnull(@rate,0),
			isnull(@unitcost,0), isnull(@amount,0), @batchid, null, @NotesCur, @uniqueattchid
 	if @@rowcount <> 1
 		begin
 		select @errmsg = 'Unable to insert JC Projection Detail entry.', @rcode = 1
 		goto JCPD_error
 		end
     
	if @jcprud_flag = 'Y'
		BEGIN
		----TK-18139
		SET @join = ' from JCPD b '
		SET @where = ' where b.KeyID = ' + CONVERT(VARCHAR(20),@jcpd_keyid)
 				+ ' and JCPR.JCCo = ' + convert(varchar(3),@co)
 				+ ' and JCPR.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
 				+ ' and JCPR.ResTrans = ' + CONVERT(VARCHAR(20),@restrans)
		-- create @sql and execute
		set @sql = @update + @join + @where
		EXEC (@sql)
		-- update where clause with ResTrans, create @sql and execute
		--set @sql = @update + @join + @where + ' and b.ResTrans = ' + convert(varchar(10), @restrans) + ' and JCPR.ResTrans = ' + convert(varchar(10),@restrans)
		--set @paramsin = N'@co tinyint, @mth bMonth, @batchid int, @restrans int'
		--EXECUTE sp_executesql @sql, @paramsin, @co, @mth, @batchid, @restrans
		end
   
 	---- remove current Transaction from batch
 	delete bJCPD where KeyID = @jcpd_keyid
 	if @@rowcount = 0
 		begin
 		select @errmsg = 'Unable to remove JC Projection Detail Batch entry.', @rcode = 1
 		goto JCPD_error
 		end

	commit transaction
   
   	---- Refresh indexes for this transaction if attachments exist
   	if @uniqueattchid is not null
   		begin
   		exec dbo.bspHQRefreshIndexes null, null, @uniqueattchid, null
   		end

 	goto JCPD_loop
 	end


---- update existing transaction
if @transtype = 'C'
	begin

	begin transaction

	update bJCPR set PostedDate=@dateposted, ActualDate=@jcpd_actualdate, BudgetCode=@budgetcode,
			EMCo=@emco, Equipment=@equipment, PRCo=@prco, Craft=@craft, Class=@class,
			Employee=@employee, Description=@description, DetMth=@detmth, FromDate=@fromdate,
			ToDate=@todate, Quantity=isnull(@quantity,0), UM=@um, Units=isnull(@units,0),
			UnitHours=isnull(@unithours,0), Hours=isnull(@hours,0), Rate=isnull(@rate,0),
			UnitCost=isnull(@unitcost,0), Amount=isnull(@amount,0), BatchId=@batchid,
			InUseBatchId = null, Notes = @NotesCur
	where JCCo=@co and Mth=@mth and ResTrans=@restrans
 	if @@rowcount <> 1
 		begin
 		select @errmsg = 'Unable to update JC Projection Detail entry.', @rcode = 1
 		goto JCPD_error
 		end
     
	if @jcprud_flag = 'Y'
		BEGIN
		----TK-18139
		SET @join = ' from JCPD b '
		SET @where = ' where b.KeyID = ' + CONVERT(VARCHAR(20),@jcpd_keyid)
 				+ ' and JCPR.JCCo = ' + convert(varchar(3),@co)
 				+ ' and JCPR.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
 				+ ' and JCPR.ResTrans = ' + CONVERT(VARCHAR(20),@restrans)
		-- create @sql and execute
		set @sql = @update + @join + @where
		EXEC (@sql)
		-- update where clause with ResTrans, create @sql and execute
		--set @sql = @update + @join + @where + ' and b.ResTrans = ' + convert(varchar(10), @restrans) + ' and JCPR.ResTrans = ' + convert(varchar(10),@restrans)
		--set @paramsin = N'@co tinyint, @mth bMonth, @batchid int, @restrans int'
		--EXECUTE sp_executesql @sql, @paramsin, @co, @mth, @batchid, @restrans
		end
   
 	---- remove current Transaction from batch
 	delete bJCPD where KeyID = @jcpd_keyid
 	if @@rowcount = 0
 		begin
 		select @errmsg = 'Unable to remove JC Projection Detail Batch entry.', @rcode = 1
 		goto JCPD_error
 		end

	commit transaction
   
   	---- Refresh indexes for this transaction if attachments exist
   	if @uniqueattchid is not null
   		begin
   		exec dbo.bspHQRefreshIndexes null, null, @uniqueattchid, null
   		end

 	goto JCPD_loop
 	end



---- delete existing transaction
if @transtype = 'D'
	begin

	begin transaction

	---- remove current Transaction from batch - this must be done before the JCPR entry
	---- is deleted so that the delete trigger on bJCPD can unlock the transaction
 	delete bJCPD where KeyID = @jcpd_keyid
 	if @@rowcount = 0
		begin
		select @errmsg = 'Unable to remove JC Projection Detail Batch entry.', @rcode = 1
		goto JCPD_error
		end

	---- remove JCPR Transaction
	delete bJCPR where JCCo = @co and Mth = @mth and ResTrans = @restrans
	if @@rowcount <> 1
		begin
		select @errmsg = 'Unable to remove JC Projection Detail Transaction entry.', @rcode = 1
		goto JCPD_error
		end

	commit transaction

	goto JCPD_loop
	end




JCPD_error:	---- error occured within transaction - rollback any updates and continue
	rollback transaction
	goto JCPD_loop

JCPD_end:
	if @openjcpd_cursor = 1
		begin
		close bcJCPD
		deallocate bcJCPD
		set @openjcpd_cursor = 0
		end

---- make sure batch is empty
select @validcnt=count(*) from bJCPD with (nolock)
where Co=@co and Mth=@mth and BatchId=@batchid
if @validcnt <> 0
	begin
	select @errmsg = 'Not all JC Projection Batch Detail entries (JCPD) were posted - unable to close batch!', @rcode = 1
	goto bspexit
	end


---- set interface levels note string
select @Notes=Notes from bHQBC with (nolock)
where Co = @co and Mth = @mth and BatchId = @batchid
if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
select @Notes=@Notes +
	'GL Cost Interface Level set at: ' + isnull(convert(char(1), a.GLCostLevel),'') + char(13) + char(10) +
	'GL Revenue Interface Level set at: ' + isnull(convert(char(1), a.GLRevLevel),'') + char(13) + char(10) +
	'GL Close Interface Level set at: ' + isnull(convert(char(1), a.GLCloseLevel),'') + char(13) + char(10) +
	'GL Material Interface Level set at: ' + isnull(convert(char(1), a.GLMaterialLevel),'') + char(13) + char(10)
from bJCCO a where JCCo=@co

---- delete HQ Close Control entries
delete bHQCC where Co=@co and Mth=@mth and BatchId=@batchid

---- set HQ Batch status to 5 (posted)
update bHQBC set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
where Co = @co and Mth = @mth and BatchId = @batchid
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
	goto bspexit
	end



bspexit:
	if @opencursor = 1
		begin
		close bcJCPB
		deallocate bcJCPB
		end

	if @openjcpd_cursor = 1
		begin
		close bcJCPD
		deallocate bcJCPD
		end

	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCPBPost] TO [public]
GO
