SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************/
CREATE        procedure [dbo].[bspINPBPost]
/***********************************************************************************
* CREATED:  GR 05/04/00
* Modified: GG 06/14/00 - modified for new Trans Type (Trnsfr In and Trnsfr Out)
*          	GR 06/15/00 - corrected the check on costmethod
*          	GG 06/29/00 - update TransfrLoc in bINDT for transfer trans
*          	GR 09/26/00 - added document attachments code
*          	MV 06/22/01 - Issue 12769 BatchUserMemoUpdate
*          	CMW 04/04/02 - added bHQBC.Notes interface levels update (issue # 16692).
*			GG 04/08/02 - #16702 - remove parameter from bspBatchUserMemoUpdate
*			GG 05/20/02 - #17403 - fix bINDT updates, cleanup
*			GG 06/05/02 - #17403 - fixed Location validation
*			RM 12/23/02 - Cleanup Double Quotes
*          GWC 04/01/04 - #18616 - Re-index Attachments
*                       - added dbo. in front of stored procedure calls
*				GF 01/29/2008 - issue #126923 remmed out user memo update. no IN trans available.
*			GF 01/09/2013 TK-20676 update custom fields from INPB, INPD to INDT
*			GF 01/17/2013 TK-20835 write descriptiont to INDT for the finished material entry
*
*
* USAGE:
* Called from IN Batch Processing form to post a validated
* batch of IN Production entries. 
*
* INPUT PARAMETERS:
*   @co             IN Company
*   @mth            Batch Month
*   @batchid        Batch Id
*   @dateposted     Posting date
*
* OUTPUT PARAMETERS
*   @errmsg         error message if something went wrong
*
* RETURN VALUE:
*   0               success
*   1               fail
**************************************************************************************/
(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null,
 @dateposted bDate = null, @errmsg varchar(255) output)

as
set nocount on

declare @rcode int, @status tinyint, @openinpb tinyint, @openinpd tinyint, 
		@batchseq int, @intrans bTrans, @prodloc bLoc, @finmatl bMatl, @fromloc bLoc, @toloc bLoc,
		@material bMatl, @matlgroup bGroup, @actdate bDate,
		----TK-20835
		@description bItemDesc, @incocostmethod tinyint,
		@glco bCompany, @invglacct bGLAcct, @um bUM, @units bUnits, @unitcost bUnitCost,
		@ecm bECM, @totalcost bDollar, @prodseq int, @comploc bLoc, @compmatl bMatl,
		@compmatlgroup bGroup, @compum bUM, @compunits bUnits, @compunitcost bUnitCost,
		@compecm bECM, @compunitprice bUnitCost, @comppecm bECM, @factor smallint,
		@costmethod tinyint, @stdcost bUnitCost, @stkunitcost bUnitCost,
		@stdecm bECM, @stktotalcost bUnitCost, @stkecm bECM, @usageopt varchar(1), @totalprice bUnitCost,
		@category varchar(10), @compcategory varchar(10), @Notes varchar(256),
		@uniqueattchid UNIQUEIDENTIFIER
		----TK-20676
		,@INPDud_flag char(1), @SQL VARCHAR(MAX), @update VARCHAR(MAX), @join VARCHAR(MAX)
		,@where VARCHAR(MAX), @INPD_KeyId BIGINT


SET @rcode = 0

----TK-20676
-- call bspUserMemoQueryBuild to create update, join, and where clause
-- pass in source and destination. Remember to use views only unless working
-- with a Viewpoint connection.
SET @INPDud_flag = 'N'
exec @rcode = dbo.bspUserMemoQueryBuild @co, @mth, @batchid, 'INPD', 'INDT', @INPDud_flag output,
			@update output, @join output, @where output, @errmsg output
if @rcode <> 0 set @INPDud_flag = 'N'
	  

   -- check for Posting Date
   if @dateposted is null
   	begin
   	select @errmsg = 'Missing posting date!', @rcode = 1
   	goto bspexit
   	end
   
   -- validate HQ Batch
   exec @rcode = dbo.bspHQBatchProcessVal @co, @mth, @batchid, 'IN Prod', 'INPB', @errmsg output, @status output
   if @rcode <> 0 goto bspexit
   if @status <> 3 and @status <> 4	-- valid - OK to post, or posting in progress
   	begin
   	select @errmsg = 'Invalid Batch status -  must be ''valid - OK to post'' or ''posting in progress''!', @rcode = 1
   	goto bspexit
   	end
   -- set HQ Batch status to 4 (posting in progress)
   update bHQBC
   set Status = 4, DatePosted = @dateposted
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
   	goto bspexit
   	end
   
   --get IN Company info
   select @glco = GLCo, @usageopt = UsageOpt, @incocostmethod = CostMethod
   from bINCO where INCo = @co
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Invalid IN Company#!', @rcode = 1
   	goto bspexit
   	end
   
   -- create a cursor to process all IN Prodution entries in the batch
   declare INPB_cursor cursor for
   select BatchSeq, ActDate, ProdLoc, MatlGroup, FinMatl, UM, Units, UnitCost, ECM, Description, UniqueAttchID
   from bINPB
   where Co = @co and Mth = @mth and BatchId = @batchid
   
   open INPB_cursor
   select @openinpb = 1	-- set open cursor flag
   
   INPB_cursor_loop:                 -- loop through all the batch entries
   	fetch next from INPB_cursor into @batchseq, @actdate, @prodloc, @matlgroup, @finmatl,
      		@um, @units, @unitcost, @ecm, @description, @uniqueattchid
   
   
       if @@fetch_status <> 0 goto in_posting_end
   
   	-- get Material Category for finished good
   	select @category = Category
   	from bHQMT
   	where MatlGroup = @matlgroup and Material = @finmatl
   	if @@rowcount = 0
   		begin
   		select @errmsg = 'Invalid finished material: ' + @finmatl, @rcode = 1
   		goto bspexit
   		end
       
       begin transaction      -- start a transaction to cover finished material and all of its components
   
       -- create a cursor to process all components for this batch entry
       declare INPD_cursor cursor for
       select ProdSeq, CompLoc, MatlGroup, CompMatl, UM, Units, UnitCost, ECM, UnitPrice, PECM
			----TK-20676
			,KeyID
       from bINPD
       where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
   
       open INPD_cursor
       select @openinpd = 1	-- set open cursor flag
   
   	INPD_cursor_loop:               --loop through all components
   		fetch next from INPD_cursor into
           	@prodseq, @comploc, @compmatlgroup, @compmatl, @compum, @compunits, @compunitcost, @compecm,
               @compunitprice, @comppecm
			   ----tk-20676
			   ,@INPD_KeyId
   
           if @@fetch_status <> 0 goto in_postingdetail_end
   
   		-- get Material Category for component material
           select @compcategory = Category
   		from bHQMT
    		where MatlGroup = @compmatlgroup and Material = @compmatl
   		if @@rowcount = 0
   			begin
   			select @errmsg = 'Invalid component material: ' + @compmatl
   			goto in_posting_error
   			end
   
           /* if production location does not match component source location, component must be sold or transfered to
   		production location prior to production/usage */
           if @prodloc <> @comploc
               begin
               if @usageopt = 'S'   -- treat as 'sale'
               	begin
   
                   -- prepare to add IN Detail to record sale of component from source location 
                            
                   -- component total cost, use unit cost recorded with batch entry
   				select @factor = case @compecm when 'M' then 1000 when 'C' then 100 else 1 end
   				select @totalcost = (@compunits * @compunitcost) / @factor
   				-- component total price, use unit price recorded with batch entry
   				select @factor = case @comppecm when 'M' then 1000 when 'C' then 100 else 1 end
   				select @totalprice = (@compunits * @compunitprice) / @factor
   
                   -- get the Inventory GL Account 
   				select @invglacct = null
                   select @invglacct = InvGLAcct
   				from bINLO		-- check for Location/Category override
                   where INCo = @co and Loc = @comploc and MatlGroup = @compmatlgroup and Category = @compcategory
   				if @invglacct is null	
   					begin			
                     	select @invglacct = InvGLAcct
   					from bINLM		-- if no override, use default from Location
                       where INCo = @co and Loc = @comploc
   					if @@rowcount = 0
   						begin
   						select @errmsg = 'Invalid Location: ' + @prodloc
   						goto in_posting_error
   						end
   					end
   				
   				-- get next available trans# 
       	        exec @intrans = dbo.bspHQTCNextTrans 'bINDT', @co, @mth, @errmsg output
       	        if @intrans = 0 goto in_posting_error
   
   				-- component units stored as positive values, sign must be reversed when recorded as sale in IN Detail
                   insert bINDT (INCo, Mth, INTrans, Loc, Material, MatlGroup, SellToINCo, SellToLoc, ActDate, PostedDate,
   					Source, TransType, PostedUM, PostedUnits, PostedUnitCost, PostECM, PostedTotalCost,
                       StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost, UnitPrice, PECM,
   					TotalPrice, BatchId, GLCo, GLAcct)
                   values (@co, @mth, @intrans, @comploc, @compmatl, @compmatlgroup, @co, @prodloc, @actdate, @dateposted,
   					'IN Prod', 'IN Sale', @compum, -(@compunits), @compunitcost, @compecm, -(isnull(@totalcost, 0)),
                       @compum, -(@compunits), @compunitcost, @compecm, -(isnull(@totalcost, 0)), @compunitprice, @comppecm,
   					-(isnull(@totalprice, 0)), @batchid, @glco, @invglacct)
   				
				----TK-20676 update user memos for usage into INDT from INPD
				if @INPDud_flag = 'Y'
					BEGIN
					SELECT @join = ' from INPD b '
					SELECT @where = ' where b.KeyID = ' + CONVERT(VARCHAR(20),@INPD_KeyId)
 								+ ' and INDT.INCo = ' + convert(varchar(3),@co)
 								+ ' and INDT.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
 								+ ' and INDT.INTrans = ' + CONVERT(VARCHAR(20),@intrans)
					-- create @sql and execute
					SELECT @SQL = @update + @join + @where
					--SELECT @errmsg = @SQL
					--SET @rcode = 1
					--GOTO in_posting_error
					EXEC (@SQL)
					END
   
                   -- prepare to add IN Detail to record purchase of component at production location
                   
   				-- component total cost, using unit price recorded with batch entry
   				select @factor = case @comppecm when 'M' then 1000 when 'C' then 100 else 1 end
   				select @totalcost = (@compunits * @compunitprice) / @factor
   				select @costmethod = null, @stdcost = @compunitprice, @stdecm = @comppecm, @stktotalcost = @totalcost
   
                   -- get Cost Method for component at production location
                   select @costmethod = CostMethod
   				from bINLO where INCo = @co and Loc = @prodloc and MatlGroup = @compmatlgroup and Category = @compcategory
                   if isnull(@costmethod,0) = 0 
                       select @costmethod = CostMethod
   					from bINLM where INCo = @co and Loc = @prodloc
                   if isnull(@costmethod,0) = 0 select @costmethod = @incocostmethod
   
   				-- Standard Cost requires special handling
                   if @costmethod = 3     
   					begin
   					select @stdcost = StdCost, @stdecm = StdECM
   					from bINMT where INCo = @co and Loc = @prodloc and MatlGroup = @compmatlgroup
   						and Material = @compmatl
   					if @@rowcount = 0
   						begin
   						select @errmsg = 'Invalid component material: ' + @compmatl + ' at production location: ' + @prodloc
   						goto in_posting_error
   						end
   					-- calculate standard total cost
   					select @factor = case @stdecm when 'M' then 1000 when 'C' then 100 else 1 end
   					select @stktotalcost = (@compunits * @stdcost) / @factor
   					end
   			
   				 -- get the Inventory GL Account for component at production location
   				select @invglacct = null
                   select @invglacct = InvGLAcct
   				from bINLO		-- check for Location/Category override
                   where INCo = @co and Loc = @prodloc and MatlGroup = @compmatlgroup and Category = @compcategory
   				if @invglacct is null
   					begin				
                     	select @invglacct = InvGLAcct
   					from bINLM		-- if no override, use default from Location
                       where INCo = @co and Loc = @prodloc
   					if @@rowcount = 0
   						begin
   						select @errmsg = 'Invalid Location: ' + @prodloc
   						goto in_posting_error
   						end
   					end
   				
   				-- get next available trans# for 'purchase' at production location
                   exec @intrans = dbo.bspHQTCNextTrans 'bINDT', @co, @mth, @errmsg output
                   if @intrans = 0 goto in_posting_error
   
   				-- component units stored as positive values
   			    insert bINDT (INCo, Mth, INTrans, Loc, Material, MatlGroup, ActDate, PostedDate,
   					Source, TransType, PostedUM, PostedUnits, PostedUnitCost, PostECM, PostedTotalCost,
                       StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost, UnitPrice, PECM,
   					TotalPrice, BatchId, GLCo, GLAcct)
                   values (@co, @mth, @intrans, @prodloc, @compmatl, @compmatlgroup, @actdate, @dateposted,
   					'IN Prod', 'Purch', @compum, @compunits, @compunitprice, @comppecm, isnull(@totalcost, 0),
                       @compum, @compunits, @stdcost, @stdecm, isnull(@stktotalcost, 0), 0, 'E',
   					0, @batchid, @glco, @invglacct)

				-- bINDT insert trigger will update bINMT.QtyOnHand and adjust AvgCost

				----TK-20676 update user memos for usage into INDT from INPD
				if @INPDud_flag = 'Y'
					BEGIN
					SELECT @join = ' from INPD b '
					SELECT @where = ' where b.KeyID = ' + CONVERT(VARCHAR(20),@INPD_KeyId)
 								+ ' and INDT.INCo = ' + convert(varchar(3),@co)
 								+ ' and INDT.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
 								+ ' and INDT.INTrans = ' + CONVERT(VARCHAR(20),@intrans)
					-- create @sql and execute
					SELECT @SQL = @update + @join + @where
					--SELECT @errmsg = @SQL
					--SET @rcode = 1
					--GOTO in_posting_error
					EXEC (@SQL)
					END
            
                   end      -- end of usage option 'sale'

   			if @usageopt = 'T'     -- transfer
                   begin
                   -- prepare to add IN Detail to record transfer of component from source location 
   
   				-- component total cost, use unit cost recorded with batch entry
   				select @factor = case @compecm when 'M' then 1000 when 'C' then 100 else 1 end
   				select @totalcost = (@compunits * @compunitcost) / @factor
   
   				 -- get the Inventory GL Account 
   				select @invglacct = null
                   select @invglacct = InvGLAcct
   				from bINLO		-- check for Location/Category override
                   where INCo = @co and Loc = @comploc and MatlGroup = @compmatlgroup and Category = @compcategory
   				if @invglacct is null	
   					begin			
                     	select @invglacct = InvGLAcct
   					from bINLM		-- if no override, use default from Location
                       where INCo = @co and Loc = @comploc
   					if @@rowcount = 0
   						begin
   						select @errmsg = 'Invalid Location: ' + @prodloc
   						goto in_posting_error
   						end
   					end
   
   				-- get next available trans# 
       	        exec @intrans = dbo.bspHQTCNextTrans 'bINDT', @co, @mth, @errmsg output
       	        if @intrans = 0 goto in_posting_error
   
   				-- component units stored as positive values, sign must be reversed when recorded as 'transfer out' in IN Detail
                   insert bINDT (INCo, Mth, INTrans, Loc, Material, MatlGroup, ActDate, PostedDate,
   					Source, TransType, TrnsfrLoc, PostedUM, PostedUnits, PostedUnitCost, PostECM,
   					PostedTotalCost, StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost,
   					UnitPrice, PECM, TotalPrice, BatchId, GLCo, GLAcct)
                   values (@co, @mth, @intrans, @comploc, @compmatl, @compmatlgroup, @actdate, @dateposted,
   					'IN Prod', 'Trnsfr Out', @prodloc, @compum, -(@compunits), @compunitcost, @compecm,
   					-(isnull(@totalcost, 0)), @compum, -(@compunits), @compunitcost, @compecm, -(isnull(@totalcost, 0)),
   					0, 'E', 0, @batchid, @glco, @invglacct)
   
   				-- bINDT insert trigger will update bINMT.QtyOnHand 
   
   				----TK-20676 update user memos for usage into INDT from INPD
				if @INPDud_flag = 'Y'
					BEGIN
					SELECT @join = ' from INPD b '
					SELECT @where = ' where b.KeyID = ' + CONVERT(VARCHAR(20),@INPD_KeyId)
 								+ ' and INDT.INCo = ' + convert(varchar(3),@co)
 								+ ' and INDT.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
 								+ ' and INDT.INTrans = ' + CONVERT(VARCHAR(20),@intrans)
					-- create @sql and execute
					SELECT @SQL = @update + @join + @where
					--SELECT @errmsg = @SQL
					--SET @rcode = 1
					--GOTO in_posting_error
					EXEC (@SQL)
					END


                   -- prepare to add IN Detail to record 'transfer in' of component at production location
                   
   				-- component total cost, using unit cost recorded with batch entry
   				select @costmethod = null, @stdcost = @compunitcost, @stdecm = @compecm, @stktotalcost = @totalcost
   
                   -- get Cost Method for component at production location
                   select @costmethod = CostMethod
   				from bINLO where INCo = @co and Loc = @prodloc and MatlGroup = @compmatlgroup and Category = @compcategory
                   if isnull(@costmethod,0) = 0 
   					begin
                       select @costmethod = CostMethod
   					from bINLM where INCo = @co and Loc = @prodloc
   					if @@rowcount = 0
   						begin
   						select @errmsg = 'Invalid Location: ' + @prodloc
   						goto in_posting_error
   						end
   					end
                   if isnull(@costmethod,0) = 0 select @costmethod = @incocostmethod
   
                   -- Standard Cost requires special handling
                   if @costmethod = 3     
   					begin
   					select @stdcost = StdCost, @stdecm = StdECM
   					from bINMT where INCo = @co and Loc = @prodloc and MatlGroup = @compmatlgroup
   						and Material = @compmatl
   					if @@rowcount = 0
   						begin
   						select @errmsg = 'Invalid component material: ' + @compmatl + ' at production location: ' + @prodloc
   						goto in_posting_error
   						end
   					-- calculate standard total cost
   					select @factor = case @stdecm when 'M' then 1000 when 'C' then 100 else 1 end
   					select @stktotalcost = (@compunits * @stdcost) / @factor
   					end
   			
   				-- get the Inventory GL Account for component at production location
   				select @invglacct = null
                   select @invglacct = InvGLAcct
   				from bINLO		-- check for Location/Category override
                   where INCo = @co and Loc = @prodloc and MatlGroup = @compmatlgroup and Category = @compcategory
   				if @invglacct is null
   					begin				
                     	select @invglacct = InvGLAcct
   					from bINLM		-- if no override, use default from Location
                       where INCo = @co and Loc = @prodloc
   					if @@rowcount = 0
   						begin
   						select @errmsg = 'Invalid Location: ' + @prodloc
   						goto in_posting_error
   						end
   					end                     
                                
   				-- get next available trans# for 'transfer in' at production location
                   exec @intrans = dbo.bspHQTCNextTrans 'bINDT', @co, @mth, @errmsg output
                   if @intrans = 0 goto in_posting_error
   
   				-- component units stored as positive values
                   insert bINDT (INCo, Mth, INTrans, Loc, Material, MatlGroup, ActDate, PostedDate,
   					Source, TransType, TrnsfrLoc, PostedUM, PostedUnits, PostedUnitCost, PostECM,
   					PostedTotalCost, StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost,
   					UnitPrice, PECM, TotalPrice, BatchId, GLCo, GLAcct)
                   values (@co, @mth, @intrans, @prodloc, @compmatl, @compmatlgroup, @actdate, @dateposted,
   					'IN Prod', 'Trnsfr In', @comploc, @compum, @compunits, @compunitcost, @compecm,
   					isnull(@totalcost, 0), @compum, @compunits, @stdcost, @stdecm, isnull(@stktotalcost, 0),
   					0, 'E', 0, @batchid, @glco, @invglacct)
                           
                -- bINDT insert trigger will update bINMT.QtyOnHand and adjust AvgCost

				----TK-20676 update user memos for usage into INDT from INPD
				if @INPDud_flag = 'Y'
					BEGIN
					SELECT @join = ' from INPD b '
					SELECT @where = ' where b.KeyID = ' + CONVERT(VARCHAR(20),@INPD_KeyId)
 								+ ' and INDT.INCo = ' + convert(varchar(3),@co)
 								+ ' and INDT.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
 								+ ' and INDT.INTrans = ' + CONVERT(VARCHAR(20),@intrans)
					-- create @sql and execute
					SELECT @SQL = @update + @join + @where
					--SELECT @errmsg = @SQL
					--SET @rcode = 1
					--GOTO in_posting_error
					EXEC (@SQL)
					END


                 end       --end of usage option transfer
   			end     -- end of component 'sale/transfer' to procdution location
   
   
   		-- add entry for component 'usage' 
   
   		-- if component source location equals production location, use posted unit cost, else lookup
   		-- current unit cost based on cost method at production location
   		select @stdcost = @compunitcost, @stdecm = @compecm
   
   		if @prodloc <> @comploc
   			begin
   			-- get Cost Method for component at production location
   			select @costmethod = null
   	        select @costmethod = CostMethod
   			from bINLO where INCo = @co and Loc = @prodloc and MatlGroup = @compmatlgroup and Category = @compcategory
   	        if isnull(@costmethod,0) = 0
   				begin
                   select @costmethod = CostMethod
   				from bINLM where INCo = @co and Loc = @prodloc
   				if @@rowcount = 0
   					begin
   					select @errmsg = 'Invalid Location: ' + @prodloc
   					goto in_posting_error
   					end
   				end 
   	        if isnull(@costmethod,0) = 0 select @costmethod = @incocostmethod
   
   			-- get posted unit cost based on cost method
   			select @stdcost = case @costmethod when 1 then AvgCost when 2 then LastCost when 3 then StdCost end,
   				@stdecm = case @costmethod when 1 then AvgECM when 2 then LastECM when 3 then StdECM end
   			from bINMT
   			where INCo = @co and Loc = @prodloc and MatlGroup = @compmatlgroup and Material = @compmatl
   			end
   
   		-- calculate total cost
   		select @factor = case @stdecm when 'M' then 1000 when 'C' then 100 else 1 end
   		select @totalcost = (@compunits * @stdcost) / @factor
   
   		-- get the Inventory GL Account for component at production location
   		select @invglacct = null
           select @invglacct = InvGLAcct
   		from bINLO		-- check for Location/Category override
           where INCo = @co and Loc = @prodloc and MatlGroup = @compmatlgroup and Category = @compcategory
   		if @invglacct is null
   			begin				
             	select @invglacct = InvGLAcct
   			from bINLM		-- if no override, use default from Location
               where INCo = @co and Loc = @prodloc
   			if @@rowcount = 0
   				begin
   				select @errmsg = 'Invalid Location: ' + @prodloc
   				goto in_posting_error
   				end
   			end  
              
   		-- get next available trans# for component 'usage' at production location
           exec @intrans = dbo.bspHQTCNextTrans 'bINDT', @co, @mth, @errmsg output
           if @intrans = 0 goto in_posting_error
   
   		-- component units stored as positive values, sign must be reversed when recorded as 'usage' in IN Detail
           insert bINDT (INCo, Mth, INTrans, Loc, Material, MatlGroup, ActDate, PostedDate, Source,
   			TransType, FinishMatl, PostedUM, PostedUnits, PostedUnitCost, PostECM, PostedTotalCost,
               StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost, UnitPrice, PECM, TotalPrice,
               BatchId, GLCo, GLAcct)
           values (@co, @mth, @intrans, @prodloc, @compmatl, @compmatlgroup, @actdate, @dateposted, 'IN Prod',
               'Usage', @finmatl, @compum, -(@compunits), @stdcost, @stdecm, -(isnull(@totalcost, 0)),
               @compum, -(@compunits), @stdcost, @stdecm, -(isnull(@totalcost, 0)), 0, 'E', 0,
               @batchid, @glco, @invglacct)

		
		----TK-20676 update user memos for usage into INDT from INPD
		if @INPDud_flag = 'Y'
			BEGIN
			SELECT @join = ' from INPD b '
			SELECT @where = ' where b.KeyID = ' + CONVERT(VARCHAR(20),@INPD_KeyId)
 						+ ' and INDT.INCo = ' + convert(varchar(3),@co)
 						+ ' and INDT.Mth = ' + CHAR(39) + convert(varchar(100),@mth) + CHAR(39)
 						+ ' and INDT.INTrans = ' + CONVERT(VARCHAR(20),@intrans)
			-- create @sql and execute
			SELECT @SQL = @update + @join + @where
			--SELECT @errmsg = @SQL
			--SET @rcode = 1
			--GOTO in_posting_error
			EXEC (@SQL)
			END
            

   		--delete component entry from batch
        delete bINPD
   		where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq and ProdSeq = @prodseq
   		if @@rowcount <> 1
   			begin
   			select @errmsg = 'Unable to delete detail batch entry for component!'
   			goto in_posting_error
   			end
   
   		goto INPD_cursor_loop           -- next component
   
   
           in_postingdetail_end:		-- finished with components
   			close INPD_cursor
               deallocate INPD_cursor
               select @openinpd = 0
   
   
   	-- add 'production' entry for finished material
   
   	-- calculate total cost of finished material
   	select @factor = case @ecm when 'M' then 1000 when 'C' then 100 else 1 end
   	select @totalcost = (@units * @unitcost) / @factor
   
   	-- get the Inventory GL Account for component at production location
   	select @invglacct = null
       select @invglacct = InvGLAcct
   	from bINLO		-- check for Location/Category override
       where INCo = @co and Loc = @prodloc and MatlGroup = @matlgroup and Category = @category
   	if @invglacct is null
   		begin				
         	select @invglacct = InvGLAcct
   		from bINLM		-- if no override, use default from Location
           where INCo = @co and Loc = @prodloc
   		if @@rowcount = 0
   			begin
   			select @errmsg = 'Invalid Location: ' + @prodloc
   			goto in_posting_error
   			end
   		end  
   
   	-- get next available trans# for component 'usage' at production location
       exec @intrans = dbo.bspHQTCNextTrans 'bINDT', @co, @mth, @errmsg output
       if @intrans = 0 goto in_posting_error
   
   	-- insert a production tranaction for the finished good
   	insert bINDT (INCo, Mth, INTrans, Loc, Material, MatlGroup, ActDate, PostedDate, Source,
   		TransType, FinishMatl, PostedUM, PostedUnits, PostedUnitCost, PostECM, PostedTotalCost,
   		StkUM, StkUnits, StkUnitCost, StkECM, StkTotalCost, UnitPrice, PECM, TotalPrice,
   		BatchId, GLCo, GLAcct
		----TK-20835
		,Description)
   	values (@co, @mth, @intrans, @prodloc, @finmatl, @matlgroup, @actdate, @dateposted, 'IN Prod',
   		'Prod', null, @um, @units, @unitcost, @ecm, @totalcost,
   		@um, @units, @unitcost, @ecm, @totalcost, 0, 'E', 0,
   		@batchid, @glco, @invglacct
		----TK-20835
		,@description)

	----TK-20676 update IN Transaction in INPB
	UPDATE dbo.bINPB
		SET INTrans = @intrans
	WHERE Co = @co
		AND Mth = @mth
		AND BatchId = @batchid
		AND BatchSeq = @batchseq
	
	----TK-20676 update user memos from INPB to INDT for form 'IN Production'
	exec @rcode = dbo.bspBatchUserMemoUpdate @co, @mth, @batchid, @batchseq, 'IN Production', @errmsg output
	----if @rcode <> 0 goto in_posting_error

                  
-- remove current Transaction from batch
delete bINPB where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
if @@rowcount = 0
	begin
	select @errmsg = 'Unable to remove IN Production Batch entry!'
	goto in_posting_error
	end


commit transaction		-- commit transactions for all components and finished material


--Refresh indexes for this transaction if attachments exist
if @uniqueattchid is not null
	begin
	exec dbo.bspHQRefreshIndexes null, null, @uniqueattchid, null
	end


goto INPB_cursor_loop     -- next batch seq


in_posting_error:
	rollback transaction
	select @rcode = 1
	goto bspexit

in_posting_end:
	close INPB_cursor
	deallocate INPB_cursor
	select @openinpb = 0


-- GL update
exec @rcode= dbo.bspINPBPostGL @co, @mth, @batchid, @dateposted, @errmsg output
if @rcode <> 0 goto bspexit
   
   -- make sure all GL Distributions have been processed
   if exists(select 1 from bINPG where INCo = @co and Mth = @mth and BatchId = @batchid)
   	begin
       select @errmsg = 'Not all GL distributions were posted - unable to close the batch!', @rcode = 1
       goto bspexit
       end
   
   -- make sure all production detail entries have been processed
   if exists(select 1 from bINPD where Co = @co and Mth = @mth and BatchId = @batchid)
   	begin
       select @errmsg = 'Not all Component entries were processed - unable to close the batch!', @rcode = 1
       goto bspexit
       end
   
   -- make sure all production entries have been processed
   if exists(select 1 from bINPB where Co = @co and Mth = @mth and BatchId = @batchid)
       begin
       select @errmsg = 'Not all Production entries were processed - unable to close the batch!', @rcode = 1
       goto bspexit
       end
   
   -- set interface levels note string
   select @Notes = Notes
   from bHQBC
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @Notes is NULL select @Notes='' else select @Notes=@Notes + char(13) + char(10)
   select @Notes=@Notes +
       'GL Production Interface Level set at: ' + convert(char(1), a.GLProdInterfaceLvl) + char(13) + char(10)
   from bINCO a where INCo = @co
   
   -- delete HQ Close Control entries
   delete bHQCC where Co = @co and Mth = @mth and BatchId = @batchid
   
   -- set HQ Batch status to 5 (posted)
   update bHQBC
   set Status = 5, DateClosed = getdate(), Notes = convert(varchar(max),@Notes)
   where Co = @co and Mth = @mth and BatchId = @batchid
   if @@rowcount = 0
   	begin
   	select @errmsg = 'Unable to update HQ Batch Control information!', @rcode = 1
   	goto bspexit
   	end



bspexit:
	if @openinpd = 1
		begin
		close INPD_cursor
		deallocate INPD_cursor
		end

	if @openinpb = 1
		begin
		close INPB_cursor
		deallocate INPB_cursor
		end

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINPBPost] TO [public]
GO
