SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    procedure [dbo].[bspINMAFill]
/***********************************************************************************
* Created: GG 06/15/00
* Modified: GG 06/28/00 - convert last unit cost to std u/m as needed
*           GG 07/13/00 - fixed average cost, FIFO, and LIFO calcs to used PostedTotalCost instead of StkUnitCost
*           GG 08/01/00 - fixed to eliminate problems with nulls
*           GG 08/02/00 - fixed LIFO sort order
*			GG 10/09/02 - #18848 - include new 'Rec Adj' trans type in calcs
*			GG 12/28/04 - #26447 correct FIFO/LIFO calculations
*			GG 02/03/05 - #27010 correct ending average unit cost 
*			GG 01/25/06 - #119681 - fix dulpicate index in bINRI
*			GF 01/21/2008 - issue #122065 check for reversing entry in INDT, if found skip.
*			GP 05/07/2010 - issue 139494 added reversed entry back to ending totals
*           ECV 11/04/10 - Issue 140082 keep track of reversing entries so they aren't used to reverse more than one transaction.
*			GF 08/02/2012 TK-16814 added a try catch around math to catch arithmetic errors and return to form
*			GF 08/02/2012 TK-16845 when @maendavgcost <=0 use INMT Average Cost
*
*
*
* Called from IN Monthly Reconciliation to initialize bINMA.  Captures beginning
* quanties and values, summarizes monthly activity, and calculates ending quantities
* and values.  Processes all materials for the IN Co# and Month passed.
*
* INPUT PARAMETERS:
*   @inco           IN Company
*   @mth            Month to reconcile
*
* OUTPUT PARAMETERS
*   @errmsg         error message if something went wrong
*
* RETURN VALUE:
*   0               success
*   1               fail
**************************************************************************************/
(@inco tinyint = null, @mth smalldatetime = null, @errmsg varchar(2000) output)
as
set nocount on

declare @rcode int,@glco bCompany, @valmethod tinyint, @lastmthsubclsd bMonth, @openinro tinyint,
		@loc bLoc, @matlgroup bGroup, @material bMatl, @indate bDate, @unitcost bUnitCost, @inmth bMonth,
		@units bUnits, @purchaseqty bUnits, @purchasecost bDollar, @prodqty bUnits, @prodcost bDollar,
		@usageqty bUnits, @usagecost bDollar, @arsalesqty bUnits, @arsalescost bDollar, @arsalesrev bDollar,
		@jcsalesqty bUnits, @jcsalescost bDollar, @jcsalesrev bDollar, @insalesqty bUnits, @insalescost bDollar,
		@insalesrev bDollar, @emsalesqty bUnits, @emsalescost bDollar, @emsalesrev bDollar, @trnsfrinqty bUnits,
		@trnsfrincost bDollar, @trnsfroutqty bUnits, @trnsfroutcost bDollar, @adjqty bUnits, @adjcost bDollar,
		@expqty bUnits, @expcost bDollar, @totalqty bUnits, @totalcost bDollar, @dtlastcost bUnitCost,
		@dtlastecm bECM, @factor smallint, @oldcost bDollar, @inqty bUnits, @totalout bUnits,
		@openinri tinyint, @value bDollar, @riunits bUnits, @totalincost bDollar, @postedtotalcost bDollar,
		@q1 bUnits, @calcunitcost bUnitCost, @source varchar(10), @transtype varchar(10),
		@stkunitcost bUnitCost

-- bINMT declares
declare @openinmt tinyint, @mtlastcost bUnitCost, @mtlastecm bECM, @mtavgcost bUnitCost, @mtavgecm bECM,
		@mtstdcost bUnitCost, @mtstdecm bECM

-- bINMA declares
declare @maendqty bUnits, @maendvalue bDollar, @maendlastcost bUnitCost, @maendlastecm bECM, @maendavgcost bUnitCost,
		@maendavgecm bECM, @maendstdcost bUnitCost, @maendstdecm bECM, @endlastcost bUnitCost, @endlastecm bECM,
		@endavgcost bUnitCost, @endavgecm bECM, @endvalue bDollar

-- bINDT declares
declare @openindt tinyint, @actdate bDate, @stkunits bUnits, @stktotalcost bDollar, @dtum bUM

----TK-16814
DECLARE @errCount INTEGER
SET @errCount = 0
SET @errmsg = ''

SET @rcode = 0

---- Issue 140082 Create a temporary table variable to store reversing transactions that have been used.
DECLARE @INDTtemp TABLE (KeyID bigint);
DECLARE @KeyID bigint

--get IN Company info
   select @glco = GLCo, @valmethod = ValMethod
   from bINCO where INCo = @inco
   if @@rowcount = 0
       begin
       select @errmsg = 'Not a valid IN Company!', @rcode = 1
       goto bspexit
       end
   --validate GL Co# and check for open month
   select @lastmthsubclsd = LastMthSubClsd from bGLCO where GLCo = @glco
   if @@rowcount = 0
       begin
       select @errmsg = 'Not a valid GL Company!', @rcode = 1
       goto bspexit
       end
   if @mth <= @lastmthsubclsd
       begin
       select @errmsg = 'Not an open month within the subledgers in the IN GL Company!', @rcode = 1
       goto bspexit
       end
   
   -- check for unposted IN batches
   if exists(select top 1 1 from bHQBC where Co = @inco and Mth <= @mth and TableName like 'IN%' and Status < 5)
      begin
      select @errmsg = 'One or more unposted IN Batches still exist for this or an earlier month!', @rcode = 1
      goto bspexit
      end
   
   --remove existing entries in bINMA for current or later months - reconcilation for later months must be rerun
   delete bINMA where INCo = @inco and Mth >= @mth
   
   --use a cursor to rollback any 'outs' tracked in bINRO for current or later months
   declare INRO_cursor cursor for
   select Loc, MatlGroup, Material, InDate, UnitCost, InMth, Units
   from bINRO
   where INCo = @inco and OutMth > = @mth
   
   open INRO_cursor
   select @openinro = 1
   
   INRO_loop:
       fetch next from INRO_cursor into @loc, @matlgroup, @material, @indate, @unitcost, @inmth, @units
   
       if @@fetch_status = -1 goto INRO_end
       if @@fetch_status <> 0 goto INRO_loop
   
       -- add 'out' units back into bINRI
       update bINRI set Units = Units + @units
       where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
           and InDate = @indate and UnitCost = @unitcost and InMth = @inmth
       if @@rowcount = 0
           begin
           insert bINRI (INCo, Loc, MatlGroup, Material, InDate, UnitCost, InMth, Units)
           values (@inco, @loc, @matlgroup, @material, @indate, @unitcost, @inmth, @units)
           end
   
       delete bINRO where current of INRO_cursor
   
       goto INRO_loop
   
   INRO_end:
       close INRO_cursor
       deallocate INRO_cursor
       select @openinro = 0
   
   -- remove bINRI or bINRO entries with 'ins' in current or later month
   delete bINRO where INCo = @inco and InMth >= @mth
   delete bINRI where INCo = @inco and InMth >= @mth
   
   /* finished with initial validation and rollbacks required to rerun this process */



   -- use a cursor to process all Materials in bINMT
   declare INMT_cursor cursor for
   select Loc, MatlGroup, Material, LastCost, LastECM, AvgCost, AvgECM, StdCost, StdECM
   from bINMT where INCo = @inco
   
   open INMT_cursor
   select @openinmt = 1

   INMT_loop:
       fetch next from INMT_cursor into
           @loc, @matlgroup, @material, @mtlastcost, @mtlastecm, @mtavgcost, @mtavgecm, @mtstdcost, @mtstdecm
       if @@fetch_status = -1 goto INMT_end
       if @@fetch_status <> 0 goto INMT_loop
   
----TK-16814
BEGIN TRY
	
       -- get ending info from last month's Activity (if exists)
       select @maendqty = null, @maendvalue = null, @maendlastcost = null, @maendlastecm = null, @maendavgcost = null,
           @maendavgecm = null, @maendstdcost = null, @maendstdecm = null
       select @maendqty = EndQty, @maendvalue = EndValue, @maendlastcost = EndLastCost, @maendlastecm = EndLastECM,
           @maendavgcost = EndAvgCost, @maendavgecm = EndAvgECM, @maendstdcost = EndStdCost, @maendstdecm = EndStdECM
       from bINMA
       where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material and Mth = dateadd(month, -1, @mth) -- Mth=(Select max(Mth) from bINMA where Mth < @mth and INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material) 
   
       -- summarize current month's activity from IN Detail
       select @purchaseqty = sum(case TransType when 'Purch' then StkUnits else 0 end),
           @purchasecost = sum(case TransType when 'Purch' then StkTotalCost else 0 end),
           @prodqty = sum(case TransType when 'Prod' then StkUnits else 0 end),
           @prodcost = sum(case TransType when 'Prod' then StkTotalCost else 0 end),
           @usageqty = sum(case TransType when 'Usage' then StkUnits else 0 end),
           @usagecost = sum(case TransType when 'Usage' then StkTotalCost else 0 end),
           @arsalesqty = sum(case TransType when 'AR Sale' then StkUnits else 0 end),
           @arsalescost = sum(case TransType when 'AR Sale' then StkTotalCost else 0 end),
           @arsalesrev = sum(case TransType when 'AR Sale' then TotalPrice else 0 end),
           @jcsalesqty = sum(case TransType when 'JC Sale' then StkUnits else 0 end),
           @jcsalescost = sum(case TransType when 'JC Sale' then StkTotalCost else 0 end),
           @jcsalesrev = sum(case TransType when 'JC Sale' then TotalPrice else 0 end),
           @insalesqty = sum(case TransType when 'IN Sale' then StkUnits else 0 end),
           @insalescost = sum(case TransType when 'IN Sale' then StkTotalCost else 0 end),
           @insalesrev = sum(case TransType when 'IN Sale' then TotalPrice else 0 end),
           @emsalesqty = sum(case TransType when 'EM Sale' then StkUnits else 0 end),
   
           @emsalescost = sum(case TransType when 'EM Sale' then StkTotalCost else 0 end),
           @emsalesrev = sum(case TransType when 'EM Sale' then TotalPrice else 0 end),
           @trnsfrinqty = sum(case TransType when 'Trnsfr In' then StkUnits else 0 end),
           @trnsfrincost = sum(case TransType when 'Trnsfr In' then StkTotalCost else 0 end),
           @trnsfroutqty = sum(case TransType when 'Trnsfr Out' then StkUnits else 0 end),
           @trnsfroutcost = sum(case TransType when 'Trnsfr Out' then StkTotalCost else 0 end),
           @adjqty = sum(case TransType when 'Adj' then StkUnits else 0 end),	-- 'Rec Adj' should always have 0.00 units
           @adjcost = sum(case when TransType in ('Adj','Rec Adj') then StkTotalCost else 0 end),
           @expqty = sum(case TransType when 'Exp' then StkUnits else 0 end),
           @expcost = sum(case TransType when 'Exp' then StkTotalCost else 0 end),
           @totalqty = sum(StkUnits), @totalcost = sum(StkTotalCost),
           -- total posted cost of all ins, used for average cost calcs
           @totalincost = sum(case when TransType in ('Purch','Prod','Trnsfr In','Adj') then PostedTotalCost else 0 end),
   			@totalout = isnull(sum(case when StkUnits < 0 then -1 * StkUnits else 0 end),0)	-- reverse sign for positive total units out
       from bINDT
       where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material and Mth = @mth
   
       -- get material's last unit cost from IN Detail - limit to purchases and transfer ins
       select @dtlastcost = null, @dtlastecm = null
       select top 1 @dtlastcost = (PostedTotalCost / StkUnits), @dtlastecm = 'E'   -- express in std u/m
       from bINDT
       where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material and Mth = @mth
           and TransType in ('Purch','Trnsfr In') and StkUnits <> 0
       order by ActDate desc
   
        -- last bINDT posted cost overrides previous month's bINMA, which overrides bINMT
       select @endlastcost = isnull(isnull(@dtlastcost,@maendlastcost),@mtlastcost)
       select @endlastecm = isnull(isnull(@dtlastecm,@maendlastecm),@mtlastecm)
   

	----TK-16845 calculate ending average unit cost
	select @factor = CASE ISNULL(@maendavgecm, ISNULL(@mtavgecm,'E'))
					WHEN 'C' THEN 100 WHEN 'M' THEN 1000 ELSE 1 END
	---- month's beginning value
	SELECT @oldcost = (ISNULL(@maendqty,0) * 
			CASE WHEN ISNULL(@maendavgcost,0) <= 0 THEN ISNULL(@mtavgcost,0)
			ELSE ISNULL(@maendavgcost,0)
			END) / @factor
	--select @oldcost = (isnull(@maendqty,0) * (isnull(@maendavgcost,isnull(@mtavgcost,0)) / @factor)) -- month's beginning value
       
	select @inqty = isnull(@purchaseqty,0) + isnull(@prodqty,0) + isnull(@trnsfrinqty,0) + isnull(@adjqty,0)          -- qty of month's 'ins'
       
	---- #27010 correct ending average cost 
	select @endavgcost =
			---- both begin qty and begin qty + in qty are > 0
			CASE WHEN ISNULL(@maendqty,0) > 0 AND (ISNULL(@maendqty,0) + @inqty) > 0 
				 ---- use a blended calculation
				 THEN ((@oldcost + ISNULL(@totalincost,0)) / (ISNULL(@maendqty,0) + @inqty)) * @factor
				 ---- begin qty is <= 0, but in qty is > 0 
				 WHEN @inqty > 0	
				 ---- calculate from 'ins' only
				 THEN (ISNULL(@totalincost,0) / @inqty) * @factor
				 ---- can't calculate for other conditions so use begin avg cost
				 ELSE ISNULL(@maendavgcost, ISNULL(@mtavgcost,0))
				 END

   	select @endavgecm = case @factor when 100 then 'C' when 1000 then 'M' else 'E' end
   
       -- calculate ending value based on valuation method
       if @valmethod = 0   -- No method - use posted amounts
           begin
           select @endvalue = isnull(@maendvalue,0) + isnull(@totalcost,0)
           end
       if @valmethod = 1   -- Average
           begin
           select @factor = case @endavgecm when 'C' then 100 when 'M' then 1000 else 1 end
           select @endvalue = ((isnull(@maendqty,0) + isnull(@totalqty,0)) * @endavgcost) / @factor
           end
       if @valmethod in (2,3)  -- FIFO,LIFO
			begin
			-- if beginning qty is negative, include it with total 'outs' to relieve 'ins' 
			if isnull(@maendqty,0) < 0 select @totalout = @totalout + (-1 * isnull(@maendqty,0)) -- reverse sign to keep total out positive
			
			-- add all 'ins' for the month to bINRI
			declare INDT_cursor cursor for
			select ActDate, PostedTotalCost, StkUnits, Source, TransType, StkUnitCost
			from bINDT where INCo = @inco and Mth = @mth and Loc = @loc and MatlGroup = @matlgroup and Material = @material
			and StkUnits > 0	-- ignore trans type, include all 'ins'
			
			open INDT_cursor
			select @openindt = 1

			INDT_loop:
			fetch next from INDT_cursor into @actdate, @postedtotalcost, @stkunits, @source, @transtype, @stkunitcost
			IF @@fetch_status = -1 GOTO INDT_end
			IF @@fetch_status <> 0 GOTO INDT_loop

			---- #137851 only look for reversing entry when @stkunits <> 0
			IF @stkunits <> 0
				BEGIN
				---- Issue 140082
				SET @KeyID = NULL
				---- issue #122065 - look for a reversing entry that matches exactly, if found skip
				SELECT TOP 1 @KeyID = bINDT.KeyID FROM bINDT WITH (NOLOCK)
							LEFT JOIN @INDTtemp AS INDTtemp ON INDTtemp.KeyID = bINDT.KeyID
							WHERE INDTtemp.KeyID IS NULL
							AND bINDT.INCo = @inco 
							AND bINDT.Mth=@mth 
							AND bINDT.Loc=@loc
							AND bINDT.MatlGroup=@matlgroup 
							AND bINDT.Material=@material 
							AND bINDT.Source=@source
							AND bINDT.TransType=@transtype 
							AND bINDT.StkUnitCost=@stkunitcost 
							AND bINDT.StkUnits = @stkunits * -1
				IF (NOT @KeyID IS NULL)
					BEGIN
					---- Issue 140082 Add the reversing entry in table variable so it won't be used again.					
					INSERT @INDTtemp VALUES (@KeyID)
					
					SELECT @totalout = @totalout - @stkunits --139494
					GOTO INDT_loop
					END
				END
				
			---- #119681 - use calculated unit cost to avoid rounding issues
			select @calcunitcost = (@postedtotalcost / @stkunits)

			-- update IN Reconciliation In
			update bINRI set Units = Units + @stkunits
			where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
			and InDate = @actdate and InMth = @mth and UnitCost = @calcunitcost -- express in std u/m
			if @@rowcount = 0
				begin
				insert bINRI (INCo, Loc, MatlGroup, Material, InDate, UnitCost, InMth, Units)
				values (@inco, @loc, @matlgroup, @material, @actdate, @calcunitcost, @mth, @stkunits)
				end
			goto INDT_loop

			INDT_end:
				close INDT_cursor
				deallocate INDT_cursor
				select @openindt = 0

           if @valmethod = 2   -- FIFO
               begin
               -- use a cursor to process all 'outs'
               declare INRI_cursor scroll cursor for	-- must be a scroll cursor to fetch first later on
               select InDate, UnitCost, InMth, Units
               from bINRI where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
               order by InDate, UnitCost, InMth    -- oldest 'in' date first
               end
   
           if @valmethod = 3   -- LIFO
               begin
               -- use a cursor to process all 'outs'
               declare INRI_cursor scroll cursor for 	-- must be a scroll cursor to fetch first later on
               select InDate, UnitCost, InMth, Units
               from bINRI where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
               order by InDate desc, UnitCost, InMth   -- latest 'in' date first
               end
   
           open INRI_cursor
           select @openinri = 1, @value = 0
   
           INRI_loop:	-- relieve 'ins' using total 'outs' based on FIFO/LIFO order
               if @totalout = 0 goto calc_end_value	-- no more 'outs' to process
   
               fetch next from INRI_cursor into @indate, @unitcost, @inmth, @riunits
               if @@fetch_status <> 0 goto calc_end_value
   
               if @totalout >= @riunits
                   begin
                   select @units = @riunits
                   delete bINRI where current of INRI_cursor   -- all 'ins' have been relieved for this entry, delete it
                   end
               else
                   begin
                   select @units = @totalout
                   update bINRI set Units = Units - @units    -- update remaining 'ins'
                   where current of INRI_cursor
                   end
               -- record outs in bINRO - needed for rollback if reconciliation is rerun
               update bINRO set Units = Units + @units
               where INCo = @inco and Loc = @loc and MatlGroup = @matlgroup and Material = @material
                   and OutMth = @mth and InDate = @indate and UnitCost = @unitcost and InMth = @inmth
               if @@rowcount = 0
                   insert bINRO (INCo, Loc, MatlGroup, Material, OutMth, InDate, UnitCost, InMth, Units)
                   values (@inco, @loc, @matlgroup, @material, @mth, @indate, @unitcost, @inmth, @units)
   
               select @totalout = @totalout - @units           -- adjust remaining 'out' units
   
               goto INRI_loop
   
           calc_end_value:   -- finished relieving total 'outs' for FIFO/LIFO processing
   			select @q1 = isnull(@maendqty,0) + isnull(@totalqty,0), @endvalue = 0	-- ending qty for the month, may be < 0.00
   		
   			if @q1 = 0 goto INRI_end	-- if ending qty = 0.00 then ending value = 0.00
   			
   			if @q1 < 0 		-- if ending qty < 0.00 then use last cost * ending qty
   				begin
       			select @factor = case @endlastecm when 'C' then 100 when 'M' then 1000 else 1 end
   				select @endvalue = (@q1 * @endlastcost) / @factor
   				goto INRI_end
   				end
   
   			-- reset INRI cursor for 2nd pass to calculate value of positive ending quantity
   			-- process in reverse order from which 'outs' were relieved
   			fetch last from INRI_cursor into @indate, @unitcost, @inmth, @riunits
           	if @@fetch_status <> 0 goto INRI_end
           	if @@fetch_status = 0 goto check_qty
   			
   			INRI_loop1:
               	fetch prior from INRI_cursor into @indate, @unitcost, @inmth, @riunits
               	if @@fetch_status <> 0 goto INRI_end
   
   				check_qty:
   					if @q1 = 0 goto INRI_end
   
   				select @units = case when @q1 >= @riunits then @riunits else @q1 end
               	select @endvalue = @endvalue + (@unitcost * @units)   -- accumulate ending value 
               	select @q1 = @q1 - @units           -- adjust remaining units
   
               	goto INRI_loop1
   
           	INRI_end:   -- finished valuing ending qty for FIFO/LIFO 
   				close INRI_cursor
               	deallocate INRI_cursor
               	select @openinri = 0
   		end
   
       if @valmethod = 4   -- Standard
           begin
           select @factor = case isnull(@mtstdecm,'E') when 'C' then 100 when 'M' then 1000 else 1 end
           select @endvalue = ((isnull(@maendqty,0) + isnull(@totalqty,0)) * isnull(@mtstdcost,0)) / @factor
           end
   
       -- finished with Ending Value calculations
   
       -- add Activity entry using last month's info to initialize Beginning values
       insert bINMA (INCo, Loc, MatlGroup, Material, Mth, BeginQty, BeginValue, BeginLastCost, BeginLastECM,
           BeginAvgCost, BeginAvgECM, BeginStdCost, BeginStdECM, PurchaseQty, PurchaseCost, ProdQty, ProdCost,
           UsageQty, UsageCost, ARSalesQty, ARSalesCost, ARSalesRev, JCSalesQty, JCSalesCost, JCSalesRev,
           INSalesQty, INSalesCost, INSalesRev, EMSalesQty, EMSalesCost, EMSalesRev, TrnsfrInQty, TrnsfrInCost,
           TrnsfrOutQty, TrnsfrOutCost, AdjQty, AdjCost, ExpQty, ExpCost, EndQty, EndValue, EndLastCost, EndLastECM,
           EndAvgCost, EndAvgECM, EndStdCost, EndStdECM)
       values (@inco, @loc, @matlgroup, @material, @mth, isnull(@maendqty,0), isnull(@maendvalue,0),
           isnull(@maendlastcost,0), isnull(@maendlastecm,'E'), isnull(@maendavgcost,0), isnull(@maendavgecm, 'E'),
           isnull(@maendstdcost, 0), isnull(@maendstdecm, 'E'),  isnull(@purchaseqty,0), isnull(@purchasecost,0),
           isnull(@prodqty,0), isnull(@prodcost,0), isnull(@usageqty,0), isnull(@usagecost,0), isnull(@arsalesqty,0),
           isnull(@arsalescost,0), isnull(@arsalesrev,0), isnull(@jcsalesqty,0), isnull(@jcsalescost,0),
           isnull(@jcsalesrev,0), isnull(@insalesqty,0), isnull(@insalescost,0), isnull(@insalesrev,0),
           isnull(@emsalesqty,0), isnull(@emsalescost,0), isnull(@emsalesrev,0), isnull(@trnsfrinqty,0),
           isnull(@trnsfrincost,0), isnull(@trnsfroutqty,0), isnull(@trnsfroutcost,0), isnull(@adjqty,0),
           isnull(@adjcost,0), isnull(@expqty,0), isnull(@expcost,0), isnull(@maendqty,0) + isnull(@totalqty,0),
           @endvalue, @endlastcost, @endlastecm,  @endavgcost, @endavgecm, isnull(@mtstdcost,0), isnull(@mtstdecm,'E'))

----TK-16814
END TRY
BEGIN CATCH
	-- RETURN FAILURE --
	SET @errCount = @errCount + 1
	---- limit error message to first 5
	IF @errCount < 6
		BEGIN
		SET @errmsg = @errmsg + ERROR_MESSAGE() + ' - Location: ' + dbo.vfToString(@loc)
				+ ' Material: ' + dbo.vfToString(@material) + CHAR(13) + CHAR(10)
		END
	GOTO INMT_loop --- loop back to next location material and continue initialize
END CATCH
----TK-16814

goto INMT_loop  -- next material
   
INMT_end:
	close INMT_cursor
	deallocate INMT_cursor
	select @openinmt = 0

---- TK-16814
IF @errCount > 0
	BEGIN
	SET @errmsg = @errmsg + ' ' + dbo.vfToString(@errCount) + ' location material records could not be initialized.'
	END



   bspexit:
       if @openinro = 1
           begin
           close INRO_cursor
           deallocate INRO_cursor
           end
       if @openinmt = 1
           begin
           close INMT_cursor
           deallocate INMT_cursor
           end
       if @openindt = 1
           begin
           close INDT_cursor
           deallocate INDT_cursor
           end
       if @openinri = 1
           begin
           close INRI_cursor
           deallocate INRI_cursor
           end
   
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMAFill] TO [public]
GO
