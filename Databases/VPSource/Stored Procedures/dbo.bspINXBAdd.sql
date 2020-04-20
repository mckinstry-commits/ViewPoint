
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   procedure [dbo].[bspINXBAdd]
   /***********************************************************
    * Created: GG 04/16/02
    * Modified: TRL 09/07/06 changed success with message to 7 for VP 6 from 2
    *			TRL 06/25/07 added interim fix from issue 123111
	*			GP 10/24/08 - Issue 130207, changed @desc from bDesc to bItemDesc.
	*			GF TFS-00000 need to consider MO items with units, no unit cost for close if rem flag = 'N'
	*
	*
    * Uage:
    * 	Called by IN MO Close program to add or remove Material Orders
    *	from a MO Close batch.
    *
    * Inputs:
    *	@co				IN Co#
    *	@mth			Batch month
    *	@batchid		Batch ID#
    *	@xjcco			JC Co# to restrict
    *	@xjob			Job to restrict
    *	@beginmo		Beginning MO#
    *	@endmo			Ending MO#
    *	@addordelete	A = add, D = delete all, R = delete range
    *	@remflag		Y = include even if MO has remaining units,
    *					N = exclude if MO has remaining units (unless Status = 1)
    *	@closedate		Close date - recorded as actual date when batch is posted
    *
    * Outputs:
    *   @errmsg      	error message 
    *
    * Return code:
    *   @rcode			0 = success, 1 = error, 7 = success with message
    *  
    *****************************************************/
   	(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null,
   	 @xjcco bCompany = null, @xjob bJob = null, @beginMO bMO = null, @endMO bMO = null,
   	 @addordelete char(1) = null, @remflag bYN = null, @closedate bDate = null, @errmsg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int, @mo bMO, @description bItemDesc, @jcco bCompany, @job bJob, @orderdate bDate,
   	@orderedby varchar(10), @status tinyint, @openINMOcursor tinyint, @openINMIcursor tinyint,
   	@moitem bItem, @unitprice bUnitCost, @ecm bECM, @taxgroup bGroup, @taxcode bTaxCode,
   	@remainunits bUnits, @remaincost bDollar, @itemcost bDollar, @taxrate bRate, @seq int,
   	@factor smallint, @rc tinyint, @cnt INT
	----TFS-00000
	,@MO_RemainUnits bUnits
	  
   
   select @rcode = 0
   
   if @co is null or @mth is null or @batchid is null
   	begin
   		select @errmsg = 'Missing IN Co#, Month, and/or Batch ID#!', @rcode = 1
   		goto bspexit
   	end
   if @addordelete not in ('A','D','R')
   	begin
   		select @errmsg = 'Invalid action, must be ''A'',''D'', or ''R''!', @rcode = 1
   		goto bspexit
   	end
   if @closedate is null
   	begin
   		select @errmsg = 'Missing Close Date!', @rcode = 1
   		goto bspexit
   	end
   
   -- delete all entries in batch
   if @addordelete = 'D'
   	begin
   		delete dbo.INXB
   		where Co = @co and Mth = @mth and BatchId = @batchid
   		goto bspexit
   	end
   
   -- delete range from batch
   if @addordelete = 'R'
   	begin
   		delete dbo.INXB
  		where Co = @co and Mth = @mth and BatchId = @batchid
		--Issue  123111 VP6 change, defaults loaded in from INMOClose form
		and MO >= @beginMO and MO <= @endMO
   		--and  MO >= case when IsNull(@beginMO,'')='' then MO else @beginMO end 
		--and MO <= case when IsNull(@endMO,'')='' then MO else @endMO end 
   		goto bspexit
   	end
   
   -- use a cursor to find MOs meeting minimum criteria
   declare bcINMO cursor for
   select MO, Description, JCCo, Job, OrderDate, OrderedBy, Status
   from dbo.INMO with(nolock)
   where INCo = @co and InUseMth is null and InUseBatchId is null	-- skip if already in a batch
   	and Status in (0,1) 
	--Issue  123111 VP6 change, defaults loaded in from INMOClose form
	and JCCo = case when @xjcco = 0 then JCCo else @xjcco end 
	and Job = case when @xjob = ' ' then Job else @xjob end 
	and MO >= @beginMO and MO <= @endMO

   
   open bcINMO
   select @openINMOcursor = 1, @cnt = 0
   
   INMO_loop:
   	fetch next from bcINMO into @mo, @description, @jcco, @job, @orderdate, @orderedby, @status
   
   	if @@fetch_status <> 0 goto INMO_end
   	
   	-- use a cursor on MO Items 
   	declare bcINMI cursor for
   	select MOItem, UnitPrice, ECM, TaxGroup, TaxCode, RemainUnits from dbo.INMI with(nolock)
   	where INCo = @co and MO = @mo and RemainUnits <> 0
   
   	open bcINMI
   	select @openINMIcursor = 1, @remaincost = 0
	----TFS-00000
	SET @MO_RemainUnits = 0
   
   	INMI_loop:
   		fetch next from bcINMI into @moitem, @unitprice, @ecm, @taxgroup, @taxcode, @remainunits
   
   		if @@fetch_status <> 0 goto INMI_end
   
   		select @factor = case @ecm when 'M' then 1000 when 'C' then 100 else 1 end
   		select @itemcost = (@remainunits * @unitprice) / @factor
   
   		if @itemcost <> 0 and @taxcode is not null
   			begin
   			-- get current tax rate and include in remaining cost
   			exec @rc = dbo.bspHQTaxRateGet @taxgroup, @taxcode, @closedate, @taxrate output, @msg = @errmsg output
   			if @rc <> 0 goto INMI_loop	-- skip if invalid tax code
   			
   			select @itemcost = @itemcost * (1 + @taxrate)
   			end 
   
   		select @remaincost = @remaincost + @itemcost

		----TFS-00000 if no unit cost then no remaining cost, track MO remaining units
		----we do not care if the units are for different units of measure, just are there any
		IF @unitprice = 0 AND @remainunits <> 0 AND @itemcost = 0
			BEGIN
			SET @MO_RemainUnits = @MO_RemainUnits + @remainunits
			END          

   		goto INMI_loop
   
   	INMI_end:	-- finished with all Items
   		close bcINMI
   		deallocate bcINMI
   		select @openINMIcursor = 0
   
   		if @remflag = 'N' and @remaincost <> 0 and @status = 0 goto INMO_loop	-- skip
   
		----TFS-00000 check MO remaining units - skip
		IF @remflag = 'N' AND @MO_RemainUnits <> 0 AND @status = 0 GOTO INMO_loop

   		-- add MO to Close Batch
   		select @seq = isnull(max(BatchSeq),0)+ 1 from dbo.INXB with(nolock)
   		where Co = @co and Mth = @mth and BatchId = @batchid
   
   		insert dbo.INXB (Co, Mth, BatchId, BatchSeq, MO, JCCo, Job, Description, OrderDate, OrderedBy,
   			RemainCost, CloseDate)
   		values(@co, @mth, @batchid, @seq, @mo, @jcco, @job, @description, @orderdate, @orderedby,
   			@remaincost, @closedate)
   		
   		-- insert trigger will lock MO Header
   
   		select @cnt = @cnt + 1	-- # of MOs added to close batch
   
   		goto INMO_loop
   
   	INMO_end:
   		close bcINMO
   		deallocate bcINMO
   		select @openINMOcursor = 0
   		select @rcode = 7, @errmsg = dbo.vfToString(@cnt) + ' - Material Orders added to Close Batch.'
   
   bspexit:
   	if @openINMIcursor = 1
   		begin
   		close bcINMI
   		deallocate bcINMI
   		end
   	if @openINMOcursor = 1
   		begin
   		close bcINMO
   		deallocate bcINMO
   		end
   	
 --  	if @rcode = 1 select @errmsg
   	return @rcode

GO

GRANT EXECUTE ON  [dbo].[bspINXBAdd] TO [public]
GO
