USE [Viewpoint]
GO
/****** Object:  StoredProcedure [dbo].[bspJCIRPost]    Script Date: 5/12/2016 10:32:54 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[bspJCIRPost]
   /****************************************************************************
   * CREATED BY: 	DANF 0
   * MODIFIED BY:	GP 10/31/08	- Issue 130576, changed text datatype to varchar(max)
   *				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-
   *				SCOTTP 04/28/2014 TFS-78280 Support PM Revenue Projections. Pass in parameter for Source.
   *				SCOTTP 04/07/2104 TFS-79613 Set field flag in JCID for whether records posted originated from PM Revenue Projections.
   *				AJW 07/31/2014 TFS-86887 Post custom fields from PM Rev Proj if applicable.
   *                MCK: JZ  05/13/2016 - Update Revenue Projection Detail on Save with no overal projection change.
   *
   * USAGE:
   * 	Posts JCIR batch table to JCID
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
(
  @co bCompany,
  @mth bMonth,
  @batchid bBatchID,
  @dateposted bDate = NULL,
  @source bSource,
  @errmsg varchar(255) OUTPUT
)
AS 
SET NOCOUNT ON
--   #142350 removing , @uniqueattchid uniqueidentifier
DECLARE @rcode int,
		@postingSource bSource,
		@pmRevenueProjectionYN bYN,
		@opencursor tinyint,		
		@tablename char(20),
		@status tinyint,
		@validcnt int,
		@jctrans bTrans,
		@oldplugged bYN,
		@um bUM,
		@postedum bUM,
		@plugged bYN,
		@netchange tinyint,
		@Notes varchar(256)

declare @Contract bContract, @Item bContractItem, @ActualDate bDate, 
	@RevProjUnits bUnits, @RevProjDollars bDollar, 
	@PrevRevProjUnits bUnits, @PrevRevProjDollars bDollar, 
	@RevProjPlugged bYN, @UniqueAttchID uniqueidentifier,
	@projunits bUnits, @projdollars bDollar,
	@prevprojunits bUnits, @prevprojdollars bDollar, @SourceKeyID bigint,
	@jcidud_flag char(1),@jcid_update VARCHAR(MAX), @jcid_join VARCHAR(MAX), @jcid_where VARCHAR(MAX),
	@jcir_keyid bigint,@pmjcprud_flag char(1),@sql nvarchar(4000)
	 	

select @rcode=0, @pmjcprud_flag = 'N', @jcidud_flag = 'N'

-- Hard Code JC source to always be JC RevProj for projection reporting
select @postingSource = 'JC RevProj'

-- set flag for whether records to post originated from PM Revenue Projections
if @source = 'PMRevProj'
	begin
		select @pmRevenueProjectionYN = 'Y'

		-- call bspUserMemoQueryBuild to create update
		exec @rcode = dbo.bspUserMemoQueryBuild @co, @mth, @batchid, 'PMRevenueProjection', 'JCID', @pmjcprud_flag output,
					@jcid_update output, @jcid_join output, @jcid_where output, @errmsg output
		if @rcode <> 0 set @pmjcprud_flag = 'N'
	end
else
	begin
		select @pmRevenueProjectionYN = null

		-- call bspUserMemoQueryBuild to create update
		exec @rcode = dbo.bspUserMemoQueryBuild @co, @mth, @batchid, 'JCIR', 'JCID', @jcidud_flag output,
					@jcid_update output, @jcid_join output, @jcid_where output, @errmsg output
		if @rcode <> 0 set @jcidud_flag = 'N'
	end

-- set open cursor flags to false
select @opencursor = 0

if @co is null
 	begin
   select @errmsg = 'Missing JC Company!', @rcode = 1
   goto bspexit
   end

-- check for date posted
if @dateposted is null
 	begin
 	select @errmsg = 'Missing posting date!', @rcode = 1
 	goto bspexit
 	end

-- validate HQ Batch
exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, @source, 'JCIR', @errmsg output, @status output
if @rcode <> 0 goto bspexit

if @status <> 3 and @status <> 4	-- valid - OK to post, or posting in progress
 	begin
   select @errmsg = 'Invalid Batch status -  must be valid - OK to post or posting in progress!', @rcode = 1
 	goto bspexit
 	end

-- set HQ Batch status to 4 (posting in progress)
update dbo.bHQBC
 set Status = 4, DatePosted = @dateposted
 where Co = @co and Mth = @mth and BatchId = @batchid
 if @@rowcount = 0
 	begin
 	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
 	goto bspexit
 	end

-- declare cursor on JC Projection Batch for posting
declare bcJCIR cursor local fast_forward for
select 	Contract, Item, ActualDate, 
	RevProjUnits, RevProjDollars, 
	PrevRevProjUnits, PrevRevProjDollars, 
	RevProjPlugged, UniqueAttchID, KeyID, SourceKeyID
from bJCIR where Co=@co and Mth=@mth and BatchId=@batchid

-- open cursor
open bcJCIR
select @opencursor = 1

-- loop through all rows in this batch
JCIR_posting_loop:
fetch next from bcJCIR into 
	@Contract, @Item, @ActualDate, 
	@RevProjUnits, @RevProjDollars, 
	@PrevRevProjUnits, @PrevRevProjDollars, 
	@RevProjPlugged, @UniqueAttchID, @jcir_keyid, @SourceKeyID

if (@@fetch_status <> 0) goto JCIR_posting_end

begin transaction

-- get UM from bJCCI
select @um=UM, @postedum=UM, @oldplugged=ProjPlug
from bJCCI where JCCo=@co and Contract=@Contract and Item=@Item

-- delete future projections in bJCID
delete from dbo.bJCID 
where JCCo=@co and Contract=@Contract and Item=@Item and Mth>=@mth 
and TransSource=@postingSource and JCTransType='RP'and ActualDate>=@ActualDate

--ProjUnits, ProjDollars, ProjPlug, @RevProjUnits, @RevProjDollars
-- get sum of previous projections and forecasts
select @prevprojunits = isnull(Sum(ProjUnits),0),
      @prevprojdollars = isnull(Sum(ProjDollars),0)
from dbo.bJCIP where JCCo=@co and Contract=@Contract and Item=@Item and Mth<=@mth
if @@rowcount = 0
   begin
   -- no previous projections, so use final
   select 	@projunits=@RevProjUnits, 
		@projdollars=@RevProjDollars
   end
else
   begin
   -- calculate projections and forecasts variance
   select @projunits=@RevProjUnits-@prevprojunits,
          @projdollars=@RevProjDollars-@prevprojdollars
   end

-- check if something to update
select @netchange = 0
if @projunits <> 0 or @projdollars <> 0 select @netchange = 1
-- -- if abs(@forecasthours) + abs(@forecastunits) + abs(@forecastcost) <> 0 select @netchange = 1 --ignore forecast
if @RevProjPlugged = 'Y' and @oldplugged = 'N' select @netchange = 1
if @RevProjPlugged = 'N' and @oldplugged = 'Y' select @netchange = 1

-- get next available transaction # for JCCD
select @tablename = 'bJCID'
exec @jctrans = bspHQTCNextTrans @tablename, @co, @mth, @errmsg output
if @jctrans = 0 goto JCIR_posting_error

if @netchange = 1
BEGIN
   -- insert JC Detail

		insert dbo.bJCID (JCCo, Mth, ItemTrans, Contract, Item, PostedDate, ActualDate, JCTransType,
			TransSource, Description, BatchId, GLCo, GLTransAcct, GLOffsetAcct,
			ReversalStatus, BilledUnits, BilledAmt, ARCo, ARInvoice, ARCheck, UniqueAttchID, SrcJCCo,
		ProjUnits, ProjDollars, PMRevenueProjection)

   	values	(@co, @mth, @jctrans, @Contract, @Item, @dateposted, @ActualDate, 'RP',
   			@postingSource, null, @batchid, null, null, null,
				0, 0, 0, null, null, null, @UniqueAttchID, null,
			@projunits, @projdollars, @pmRevenueProjectionYN)

   if @@rowcount = 0 goto JCIR_posting_error

   -- update bJCCI LastProjPlug
   update dbo.bJCCI set ProjPlug=@RevProjPlugged
   where JCCo=@co and Contract=@Contract and Item=@Item
   if @@rowcount = 0 goto JCIR_posting_error

   -- update bJCIP LastProjPlug
   update dbo.bJCIP set ProjPlug=@RevProjPlugged
   where JCCo=@co and Contract=@Contract and Item=@Item and Mth = @mth 
   if @@rowcount = 0 goto JCIR_posting_error
   --Update Custom Fields
   	if @jcidud_flag = 'Y'
		BEGIN
		SET @jcid_join = ' from JCIR b '
		SET @jcid_where = ' where b.KeyID = ' + CONVERT(VARCHAR(20),@jcir_keyid)
 				+ ' and JCID.JCCo = ' + convert(varchar(3),@co)
 				+ ' and JCID.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
 				+ ' and JCID.ItemTrans = ' + CONVERT(VARCHAR(20),@jctrans)
 				
		-- create @sql and execute
		set @sql = @jcid_update + @jcid_join + @jcid_where
		EXEC (@sql)
		END
	if @pmjcprud_flag = 'Y'
		BEGIN
		SET @jcid_join = ' from PMRevenueProjection b '
		SET @jcid_where = ' where b.KeyID = ' + CONVERT(VARCHAR(20),@SourceKeyID)
 				+ ' and JCID.JCCo = ' + convert(varchar(3),@co)
 				+ ' and JCID.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
 				+ ' and JCID.ItemTrans = ' + CONVERT(VARCHAR(20),@jctrans)
 				
		-- create @sql and execute
		set @sql = @jcid_update + @jcid_join + @jcid_where
		EXEC (@sql)
		END

END
-- ========================================================================
-- Changes to bspJCIRPost for project Prophecy
-- Author:		Ziebell, Jonathan
-- Create date: 05/12/2016
-- Description:	When There is 0 Net Change in the Projected Project Total, the Database Triggers on JCID will not execute,
--              therefore the elow insert into budJCIPD will need to be run.
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
ELSE
IF @netchange = 0
	BEGIN
		--DELETE FROM budJCIPD
		--Check for existing Revenue Project Detail Rows for the current Month, If old rows for current month found, Delete them.
		DELETE FROM budJCIPD 
		WHERE Co = @co
			AND Contract = @Contract
			AND Item = @Item
			AND Mth =  @mth

--INSERT INTO budJCIPD
-- Check for Revenue Project Details Rows, If rows on budJCIRD rows are found, insert them into budJCIPD
		SET IDENTITY_INSERT budJCIPD ON
		INSERT INTO budJCIPD ( Co, Contract, FromDate, Item, Mth, ProjDollars, ProjUnits, ToDate, UniqueAttchID, KeyID)
			SELECT	s.Co
				,	s.Contract
				,	s.FromDate
				,	s.Item
				,	s.Mth
				,	s.ProjDollars
				,	s.ProjUnits
				,   s.ToDate
				,	s.UniqueAttchID
				,	s.KeyID
			FROM budJCIRD s
			WHERE s.Co = @co 
				AND s.BatchId =  @batchid 
				AND s.Contract = @Contract
				AND s.Item = @Item
				AND s.Mth = @mth
			SET IDENTITY_INSERT budJCIPD OFF

END




-- delete current row from cursor
delete from dbo.bJCIR where Co=@co and Mth=@mth and BatchId=@batchid and Contract=@Contract
and Item=@Item

commit transaction


--Refresh indexes for this transaction if attachments exist
if @UniqueAttchID is not null
begin
exec dbo.bspHQRefreshIndexes null, null, @UniqueAttchID, null
end

goto JCIR_posting_loop

JCIR_posting_error:	-- error occured within transaction - rollback any updates and continue
   rollback transaction
   goto JCIR_posting_loop

JCIR_posting_end:    -- no more rows to process
  -- make sure batch is empty
  select @validcnt=count(*) from dbo.bJCIR
  where Co=@co and Mth=@mth and BatchId=@batchid
  if @validcnt <> 0
     begin
     select @errmsg = 'Not all JC Projection batch entries were posted - unable to close batch!', @rcode = 1
 	  goto bspexit
 	  end

   -- set interface levels note string
   select @Notes=Notes from dbo.bHQBC
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
   select @Notes=@Notes +
       'GL Cost Interface Level set at: ' + isnull(convert(char(1), a.GLCostLevel),'') + char(13) + char(10) +
       'GL Revenue Interface Level set at: ' + isnull(convert(char(1), a.GLRevLevel),'') + char(13) + char(10) +
       'GL Close Interface Level set at: ' + isnull(convert(char(1), a.GLCloseLevel),'') + char(13) + char(10) +
       'GL Material Interface Level set at: ' + isnull(convert(char(1), a.GLMaterialLevel),'') + char(13) + char(10)
   from dbo.bJCCO a where JCCo=@co

  -- delete HQ Close Control entries
  delete dbo.bHQCC where Co=@co and Mth=@mth and BatchId=@batchid

  -- set HQ Batch status to 5 (posted)
  update dbo.bHQBC
  set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
  where Co = @co and Mth = @mth and BatchId = @batchid
       if @@rowcount = 0
 		begin
 		select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
 		goto bspexit
 		end

bspexit:
   if @opencursor = 1
 	   begin
 	   close bcJCIR
 	   deallocate bcJCIR
 	   end

return @rcode

