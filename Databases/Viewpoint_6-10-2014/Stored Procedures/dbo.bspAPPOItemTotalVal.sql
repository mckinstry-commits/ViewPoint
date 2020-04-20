SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPOItemTotalVal    Script Date: 8/28/99 9:34:02 AM ******/
CREATE                  proc [dbo].[bspAPPOItemTotalVal]
/********************************************************
* CREATED BY: 	SE	10/07/1997
* MODIFIED BY:  GG	06/22/1999
*               kb	10/28/2002	- issue #18878 - fix double quotes
*				MV	09/09/2003	- #22315 add check of total PO invoiced amounts
*				MV	12/01/2003	- #22664 - don't include misc amt in PO check
*				MV	12/23/2003	- #23405 limit total PO check to regular POs 
*				MV	01/06/2004	- #23406 limit total PO check to regular POs
*				MV	01/29/2004	- #23583 back out check of total PO invoiced amounts
*				ES	03/11/2004	- #23061 isnull wrapping
*				MV	08/11/2004	- #25032 - rewrote this sp to add back the check of total
*				   current cost of the PO and add check of invoiced units against received units.
*				DC  02/26/2008	- #30154 - POIT REMAINING COSTS INCORRECT DUE TO ROUNDING ON 1ST AP TRANS
*				MV	08/15/2008	- #128646 - use abs value to check invoiced exceeds received.
*				MV	01/13/2009	- #131710 - restored check of 'LS' PO Item check
*				TRL	07/27/2011	- TK-07143  Expand bPO parameters/varialbles to varchar(30)
*				MV	08/08/2011	- TK07237 - AP project to use POItemLine - add new level of validation at the POItemLine level
*				CHS	08/26/2011	- TK-07960 add PO Item Line
*				MV  08/31/11	- TK-08096 - Unapproved amounts fix
*
* USAGE:
* 	Called by AP to check that the user is not invoicing more than the
*   current total cost of the PO Item, or the current total cost of the PO. If the
*	PO Item is flagged for receiving, check that the invoiced units or cost do not
*	exceed the received units or cost (for LS).
*
* INPUT PARAMETERS:
*	@co             AP/PO Company #
*   @mth            Batch month
*   @batchid        Batch Id
*   @po             Purchase Order
*   @poitem         PO Item
*   @source         'U' = Unapproved Invoices, 'E' = AP Trans entry, 'B' = Batch Validation
*   @uiseq          Unapproved Invoice Sequence #
*   @line           Current line # of Unapproved or Transaction Entry
*   @amt            Amount to be invoiced with current line
*	@units		    Units to be invoiced with the current line
*
* OUTPUT PARAMETERS:
*	@msg         Error message
*
* RETURN VALUE:
* 	0               Invoiced <= Current Total Cost
*	1               Invoiced > Current Total Cost
**********************************************************/
(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null,
	@po varchar(30) = null, @poitem bItem = null, @POItemLine INT = NULL, @source varchar(1) = null, @uiseq smallint = null,
	@line smallint = null, @amt bDollar = null, @units bUnits, @msg varchar(500) output)
	
   as
   
   set nocount on
   
   declare @rcode int, @poinvcost bDollar, @pocurrcost bDollar, @freightnew bDollar, @freightold bDollar,
   @newgross bDollar, @oldgross bDollar, @oldpogross bDollar, @freightpoold bDollar,@newpogross bDollar,
   @freightponew bDollar, @pototalcurcost bDollar, @pototalinvcost bDollar,@recvdunits bUnits,@recvdcost bDollar,
   @um bUM, @recvyn bYN, @pototyn bYN, @invexceedrecvdyn bYN, @invexceedrecvdItemLineyn bYN, 
   @oldunits bUnits, @newunits bUnits,@poinvunits bUnits,
   @poitemtotyn bYN, @uigross bDollar, @uiunits bUnits, @newgross2 bDollar, @oldgross2 bDollar, @uigross2 bDollar,
   @poinvcost2 bDollar, @POItemLineTotYN bYN,@poitunitcost bUnitCost, @ucchanged bit, @poitecm as bECM,
   @POItemLineInvCost bDollar, @POItemLineCurCost bDollar, @OldItemLineGross bDollar, @NewItemLineGross bDollar,
   @UIItemLineGross bDollar, @recvdItemLineunits bUnits, @recvdItemLinecost bDollar, @poinvcostItemLine bDollar,
   @poinvunitsItemLine bUnits, @oldunitsItemLine bUnits, @oldgrossItemLine bDollar, @newunitsItemLine bUnits,
   @newgrossItemLine bDollar, @uiunitsItemLine bUnits, @uigrossItemLine bDollar
   
   select @rcode = 0, @msg=''
	select @ucchanged = 0
      
   if @source not in ('E','U','B')
       begin
       select @msg = 'Invalid source.  Must be (E),(U) or (B)!', @rcode = 1
       goto bspexit
       end
   
   if not exists (select 1 from bPOIT with (nolock)where POCo = @co and PO = @po and POItem = @poitem)
   	 begin
        select @msg = 'Purchase Order: ' + @po +  ' not found!', @rcode=1
        goto bspexit
        end	
   
   -- get APCO flags
   SELECT @pototyn=POTotYN, 
		@poitemtotyn=POItemTotYN, 
		@invexceedrecvdyn=InvExceedRecvdYN,
		@invexceedrecvdItemLineyn=InvExceedRecvdLineYN,	
		@POItemLineTotYN=POItemLineTotYN
   FROM dbo.bAPCO with (nolock)
   WHERE APCo=@co
   
   --DC #30154 --Check to see if unit cost has changed
	SELECT @ucchanged = 1
	FROM bAPLB with (nolock)
	WHERE Co = @co and Mth = @mth and BatchId = @batchid and PO = @po and POItem = @poitem
		and (UnitCost <> @poitunitcost or ECM <> @poitecm)

	--DC #30154
	SELECT @ucchanged = 1
	FROM bAPTL with (nolock)
	WHERE APCo = @co and PO = @po and POItem = @poitem
		and (UnitCost <> @poitunitcost or ECM <> @poitecm)
	
		
   --PO level Invoiced and Current totals - exclude standing POs
    select @pototalcurcost = isnull(sum(CurCost), 0), @pototalinvcost = isnull(sum(InvCost), 0)
    from bPOIT with (nolock)
    where POCo= @co and PO = @po and CurCost <> 0	
   
   -- PO Item level Invoiced and Current totals - exclude standing POs
   select @poinvcost = InvCost, @pocurrcost=CurCost, 
		@poitunitcost = OrigUnitCost, @poitecm = OrigECM --DC #30154
   from bPOIT with (nolock)
   where POCo = @co and PO = @po and POItem = @poitem and CurCost <> 0
   
   -- PO Item Line level invoiced and current totals - exclude standing POs
   SELECT @POItemLineInvCost = InvCost, @POItemLineCurCost = CurCost
   FROM dbo.vPOItemLine
   WHERE POCo=@co AND PO=@po AND POItem=@poitem AND POItemLine=@POItemLine and CurCost <> 0 
   
   -- TK-07960
   -- PO Item Line level Received Units, Received Cost - include standing POs
   select @recvdItemLineunits=RecvdUnits, 
		@recvdItemLinecost=RecvdCost, 
		@poinvcostItemLine=InvCost,
		@poinvunitsItemLine=InvUnits
   from vPOItemLine with (nolock)
   where POCo = @co 
		and PO = @po 
		and POItem = @poitem 
		and POItemLine = @POItemLine
   
   
   -- PO Item level Received Units, Received Cost - include standing POs
   select @recvdunits=RecvdUnits, @recvdcost=RecvdCost, @um=UM, @recvyn=RecvYN, @poinvcost2=InvCost,
   		@poinvunits=InvUnits
   from bPOIT with (nolock)
   where POCo = @co and PO = @po and POItem = @poitem --and RecvYN='Y'  DC #30154
  
      
   if @source in ('E', 'B')    -- AP Entry or AP batch validation
   	begin
   	-- PO level - PO old amounts from changed and deleted entries 
   	select @oldpogross = isnull(sum(OldGrossAmt),0)
   	from bAPLB l with (nolock) --join bPOIT i with (nolock) on l.Co=i.POCo and l.OldPO = i.PO and l.POItem=i.POItem 
   	where Co = @co and Mth = @mth and BatchId = @batchid
           and l.OldPO = @po and BatchTransType in ('C','D') and @pocurrcost <> 0 -- exclude standing POs
   
   	-- PO level - PO new amounts from added and changed entries 
   	select @newpogross = isnull(sum(GrossAmt),0) 
   	from bAPLB l with (nolock) --join bPOIT i with (nolock) on l.Co=i.POCo and l.PO = i.PO and l.POItem=i.POItem
   	where Co = @co and Mth = @mth and BatchId = @batchid and APLine <> isnull(@line,0) -- skip current line
           and l.PO = @po and BatchTransType in ('C','A') and @pocurrcost <> 0 -- exclude standing POs
   	
   	-- PO Item level - PO Item old amounts from changed and deleted entries
   	select @oldgross = isnull(sum(OldGrossAmt),0) 
   	from bAPLB a with (nolock) 
   	--join bPOIT p with (nolock) on a.Co=p.POCo and a.PO=p.PO and a.POItem=p.POItem
   	where Co = @co and Mth = @mth and BatchId = @batchid
           and OldPO = @po and OldPOItem = @poitem and BatchTransType in ('C','D') and @pocurrcost <> 0 -- exclude standing POs
   
   	-- PO Item level - PO Item new amounts from added and changed entries
   	select @newgross = isnull(sum(GrossAmt),0)
   	from bAPLB a with (nolock) 
   	--join bPOIT p with (nolock) on a.Co=p.POCo and a.PO=p.PO and a.POItem=p.POItem
   	where Co = @co and Mth = @mth and BatchId = @batchid and APLine <> isnull(@line,0) -- skip current line
           and a.PO = @po and a.POItem = @poitem and BatchTransType in ('C','A') and @pocurrcost <> 0 -- exclude standing POs
           
     -- PO Item Line level - PO Item Line old amounts from changed and deleted entries
    SELECT @OldItemLineGross = ISNULL(SUM(OldGrossAmt),0)
    FROM dbo.bAPLB a 
    --JOIN dbo.vPOItemLine p ON a.Co=p.POCo AND a.PO=p.PO AND a.POItem=p.POItem AND a.POItemLine=p.POItemLine
    WHERE Co = @co AND Mth = @mth AND BatchId = @batchid AND OldPO = @po AND OldPOItem = @poitem AND OldPOItemLine=@POItemLine
		AND BatchTransType in ('C','D') AND @POItemLineCurCost <> 0 -- exclude standing POs
		
	-- PO Item Line level - PO Item Line new amounts from added and changed entries
	SELECT @NewItemLineGross = ISNULL(SUM(GrossAmt),0)
    FROM dbo.bAPLB a 
    --JOIN dbo.vPOItemLine p ON a.Co=p.POCo AND a.PO=p.PO AND a.POItem=p.POItem AND a.POItemLine=p.POItemLine
        WHERE Co = @co AND Mth = @mth AND BatchId = @batchid AND APLine <> isnull(@line,0) -- skip current line
		AND a.PO = @po AND a.POItem = @poitem AND a.POItemLine=@POItemLine
		AND BatchTransType in ('C','A') and @POItemLineCurCost <> 0 -- exclude standing POs
   
   	-- get invoiced units, cost from AP Entry for regular and standing PO flagged for receiving 
   	--if @recvyn='Y' --DC #30154
   		--begin
   		
   		    -- TK-07960
   			-- Old Units and New Units for PO Item Line
     		-- PO Item level - old units, cost from changed and deleted entries
   			select @oldunitsItemLine = isnull(sum(OldUnits),0), @oldgrossItemLine = isnull(sum(OldGrossAmt),0)
   			from bAPLB with (nolock) 
   			where Co = @co 
   				and Mth = @mth 
   				and BatchId = @batchid 
   				and OldPO = @po 
   				and OldPOItem = @poitem 
   				and OldPOItemLine = @POItemLine
   				and BatchTransType in ('C','D') 
   				
   		    -- TK-07960   
   			-- PO Item level - new unit, cost from added and changed entries
   			select @newunitsItemLine = isnull(sum(Units),0), @newgrossItemLine = isnull(sum(GrossAmt),0)
      		from bAPLB with (nolock) 
			where Co = @co 
				and Mth = @mth 
				and BatchId = @batchid 
				and APLine <> isnull(@line,0) -- skip current line
				and PO = @po 
				and POItem = @poitem 
   				and POItemLine = @POItemLine				
				and BatchTransType in ('C','A')  			
   			  			
   			
   			-- PO Item level - old units, cost from changed and deleted entries
   			select @oldunits = isnull(sum(OldUnits),0), @oldgross2 = isnull(sum(OldGrossAmt),0)
   			from bAPLB with (nolock) 
   			where Co = @co and Mth = @mth and BatchId = @batchid and OldPO = @po and OldPOItem = @poitem and BatchTransType in ('C','D') 
   
   			-- PO Item level - new unit, cost from added and changed entries
   			select @newunits = isnull(sum(Units),0), @newgross2 = isnull(sum(GrossAmt),0)
      		from bAPLB with (nolock) 
			where Co = @co and Mth = @mth and BatchId = @batchid and APLine <> isnull(@line,0) -- skip current line
				and PO = @po and POItem = @poitem and BatchTransType in ('C','A') 
   		--end
   end
   
   
    if @source = 'U'    -- Unapproved Invoices
   begin
   	-- AP Entry amounts
   -- PO level - PO old amounts from changed and deleted entries 
   	select @oldpogross = isnull(sum(OldGrossAmt),0) 
   	from bAPLB l with (nolock)  
   	where Co = @co and l.OldPO = @po and BatchTransType in ('C','D') and @pocurrcost <> 0 -- exclude standing POs
   
   	-- PO level - PO new amounts from added and changed entries 
   	select @newpogross = isnull(sum(GrossAmt),0) 
   	from bAPLB l with (nolock) --join bPOIT i with (nolock) on l.Co=i.POCo and l.PO = i.PO and l.POItem=i.POItem
   	where Co = @co and l.PO = @po and BatchTransType in ('C','A') and @pocurrcost <> 0 -- exclude standing POs	
   	
   	-- PO Item level - PO Item old amounts from changed and deleted entries
   	select @oldgross = isnull(sum(OldGrossAmt),0) 
   	from bAPLB a with (nolock) 
   	--join bPOIT p with (nolock) on a.Co=p.POCo and a.PO=p.PO and a.POItem=p.POItem
   	where Co = @co and OldPO = @po and OldPOItem = @poitem and BatchTransType in ('C','D') and @pocurrcost <> 0 -- exclude standing POs
   
   	-- PO Item level - PO Item new amounts from added and changed entries
   	select @newgross = isnull(sum(GrossAmt),0)
   	from bAPLB a with (nolock) --join bPOIT p with (nolock) on a.Co=p.POCo and a.PO=p.PO and a.POItem=p.POItem
   	where Co = @co and a.PO = @po and a.POItem = @poitem and BatchTransType in ('C','A') and @pocurrcost <> 0 -- exclude standing POs
   
   	-- PO Item level - Unapproved amounts
    select @uigross = isnull(sum(GrossAmt),0)
   	from bAPUL l with (nolock) --join bPOIT i with (nolock) on l.APCo=i.POCo and l.PO = i.PO and l.POItem = i.POItem
   	where APCo = @co and l.PO = @po and l.POItem = @poitem and @pocurrcost <> 0 -- skip standing POs
   	and (UIMth <> @mth or UISeq <> @uiseq or Line <> isnull(@line,0)) -- skip current line
   	-- add AP Entry and Unapproved gross amounts together
   	select @newgross = isnull(@newgross, 0) + isnull(@uigross,0)
   	
   	-- PO Item Line level - PO Item Line old amounts from changed and deleted entries
    SELECT @OldItemLineGross = ISNULL(SUM(OldGrossAmt),0)
    FROM dbo.bAPLB a 
    --JOIN dbo.vPOItemLine p ON a.Co=p.POCo AND a.PO=p.PO AND a.POItem=p.POItem AND a.POItemLine=p.POItemLine
    WHERE Co = @co AND OldPO = @po AND OldPOItem = @poitem AND OldPOItemLine=@POItemLine
		AND BatchTransType in ('C','D') AND @POItemLineCurCost <> 0 -- exclude standing POs
		
	-- PO Item Line level - PO Item Line new amounts from added and changed entries
	SELECT @NewItemLineGross = ISNULL(SUM(GrossAmt),0)
    FROM dbo.bAPLB a 
    WHERE Co = @co AND a.PO = @po AND a.POItem = @poitem AND a.POItemLine=@POItemLine
		AND BatchTransType in ('C','A') and @POItemLineCurCost <> 0 -- exclude standing POs
		
	-- PO Item Line level - Unapproved amounts
	SELECT @UIItemLineGross = ISNULL(SUM(GrossAmt),0)
	FROM dbo.bAPUL l
	--JOIN dbo.vPOItemLine p ON l.APCo=p.POCo AND l.PO=p.PO AND l.POItem=l.POItem AND l.POItemLine=p.POItemLine
	WHERE APCo=@co AND l.PO=@po AND l.POItem=@poitem AND l.POItemLine=@POItemLine AND @POItemLineCurCost <> 0  -- skip standing POs
	AND (UIMth <> @mth OR UISeq <> @uiseq OR Line <> ISNULL(@line,0)) -- skip current line
    -- add AP Entry and Unapproved gross amounts together
    SELECT @NewItemLineGross = ISNULL(@NewItemLineGross,0) + ISNULL(@UIItemLineGross,0)
    
   	-- Get Received Units
   	--if @recvyn='Y'  --DC #30154
   		--begin
   		
   			-- TK-07960
   			-- PO Item Line level Old and New units
   			select @oldunitsItemLine = isnull(sum(OldUnits),0), @oldgrossItemLine = isnull(sum(OldGrossAmt),0)
   			from bAPLB with (nolock) 
   			where Co = @co 
   				and Mth = @mth 
   				and BatchId = @batchid 
   				and OldPO = @po 
   				and OldPOItem = @poitem 
   				and OldPOItemLine = @POItemLine
   				and BatchTransType in ('C','D') 
   				
   		    -- TK-07960   
   			-- PO Item level - new unit, cost from added and changed entries
   			select @newunitsItemLine = isnull(sum(Units),0), @newgrossItemLine = isnull(sum(GrossAmt),0)
      		from bAPLB with (nolock) 
			where Co = @co 
				and Mth = @mth 
				and PO = @po 
				and POItem = @poitem 
   				and POItemLine = @POItemLine				
				and BatchTransType in ('C','A')  	      			
   			
   		
   			-- PO Item level - old units, cost from changed and deleted entries
   			select @oldunits = isnull(sum(OldUnits),0), @oldgross2 = isnull(sum(OldGrossAmt),0)
   			from bAPLB with (nolock) 
   			where Co = @co 
   				and Mth = @mth 
   				and BatchId = @batchid 
   				and OldPO = @po 
   				and OldPOItem = @poitem 
   				and BatchTransType in ('C','D') 
   
   			-- PO Item level - new unit, cost from added and changed entries
   			select @newunits = isnull(sum(Units),0), @newgross2 = isnull(sum(GrossAmt),0)
      		from bAPLB with (nolock) 
			where Co = @co 
				and PO = @po 
				and POItem = @poitem 
				and BatchTransType in ('C','A') 
			
			
			-- TK-07960
			-- PO Item Line level units, cost from unapproved
   			select @uiunitsItemLine = isnull(sum(Units),0), @uigrossItemLine=isnull(sum(GrossAmt),0) 
   			from bAPUL l with (nolock) 
   			where APCo = @co 
   				and PO = @po 
   				and POItem = @poitem 
 				and POItemLine = @POItemLine	   				
				and (UIMth <> @mth or UISeq <> @uiseq or Line <> isnull(@line,0)) -- skip current line
   			
   			-- add AP Entry and Unapproved units, gross 
   			select @newunitsItemLine = isnull(@newunitsItemLine,0) + isnull(@uiunitsItemLine,0),
   				@newgrossItemLine = isnull(@newgrossItemLine,0) + isnull(@uigrossItemLine,0)			

   
			-- PO Item level - units, cost from unapproved po lines
   			select @uiunits = isnull(sum(Units),0), @uigross2=isnull(sum(GrossAmt),0) 
   			from bAPUL l with (nolock) 
   			where APCo = @co and PO = @po and POItem = @poitem 
   			and (UIMth <> @mth or UISeq <> @uiseq or Line <> isnull(@line,0)) -- skip current line
   			-- add AP Entry and Unapproved units, gross 
   			select @newunits = isnull(@newunits,0) + isnull(@uiunits,0),
   				@newgross2 = isnull(@newgross2,0) + isnull(@uigross2,0)
   
   		--end
   end
   
   
   -- Receiving warning/error messages - check if invoiced units or cost exceed received units or cost
   if @recvyn='Y'
   begin	
    -- Evaluate Received Costs against invoiced costs    
    
    -- TK-07960
    -- PO Item Line level
   	if @um='LS' and abs(((@newgrossItemLine - isnull(@oldgrossItemLine,0)) + isnull(@amt,0) + @poinvcostItemLine)) > abs(isnull(@recvdItemLinecost,0))
   		begin
   		if @source = 'B' and @invexceedrecvdItemLineyn='N'	-- return err msg to batch validation
   			begin
   			select @msg = @msg + 'Item Line Invoiced Cost exceeds Received Cost. ', @rcode=1
   			goto bspexit
   			end
   		if @source <> 'B'	-- return warning to form validation
   			begin
   			select @msg = @msg + 'Item Line Invoiced Cost exceeds Received Cost. ' + CHAR(13)
   			if  @source = 'E' and @invexceedrecvdItemLineyn='N' select @rcode=1	-- return err to APEntry if exceed flag = N
   			end
   		end   
    
    
    -- PO Item Level	
   	if @um='LS' and abs(((@newgross2 - isnull(@oldgross2,0)) + isnull(@amt,0) + @poinvcost2)) > abs(isnull(@recvdcost,0))
   		begin
   		if @source = 'B' and @invexceedrecvdyn='N'	-- return err msg to batch validation
   			begin
   			select @msg = @msg + 'Item Invoiced Cost exceeds Received Cost. ', @rcode=1
   			goto bspexit
   			end
   		if @source <> 'B'	-- return warning to form validation
   			begin
   			select @msg = @msg + 'Item Invoiced Cost exceeds Received Cost. ' + CHAR(13)
   			if  @source = 'E' and @invexceedrecvdyn='N' select @rcode=1	-- return err to APEntry if exceed flag = N
   			end
   		end   	
   	
   	
   	-- Evaluate received units against invoiced units
    -- TK-07960
   	-- PO Item Line level
   	if @um<>'LS' and abs(((@newunitsItemLine - isnull(@oldunitsItemLine,0)) + isnull(@units,0) + @poinvunitsItemLine)) > abs(isnull(@recvdItemLineunits,0))
   		begin
   		if @source = 'B' and @invexceedrecvdItemLineyn='N'	-- return err msg to batch validation
   			begin
   			select @msg = @msg + 'Item Line Invoiced Units exceed Received Units. ', @rcode=1
   			goto bspexit
   			end
   		if @source <> 'B'	-- return warning to form validation
   			begin
   			select @msg = @msg + 'Item Line Invoiced Units exceed Received Units. ' + CHAR(13)
   			if  @source = 'E' and @invexceedrecvdItemLineyn='N' select @rcode=1	-- return err to APEntry if exceed flag = N
   			end
   		end   	   	
   	
   	
   	-- PO Item level
   	if @um<>'LS' and abs(((@newunits - isnull(@oldunits,0)) + isnull(@units,0) + @poinvunits)) > abs(isnull(@recvdunits,0))
   		begin
   		if @source = 'B' and @invexceedrecvdyn='N'	-- return err msg to batch validation
   			begin
   			select @msg = @msg + 'Item Invoiced Units exceed Received Units. ', @rcode=1
   			goto bspexit
   			end
   		if @source <> 'B'	-- return warning to form validation
   			begin
   			select @msg = @msg + 'Item Invoiced Units exceed Received Units. ' + CHAR(13)
   			if  @source = 'E' and @invexceedrecvdyn='N' select @rcode=1	-- return err to APEntry if exceed flag = N
   			end
   		end
   	
   end
   
	--DC #30154
	IF (@ucchanged = 1) or (@um<>'LS' and abs(((@newunits - isnull(@oldunits,0)) + isnull(@units,0) + @poinvunits)) > abs(isnull(@recvdunits,0)))
		or (@um='LS')
	BEGIN
		-- PO Item Line warning/error message - check if PO item line's total Current Cost has been exceeded - skip if standing PO Item 
		IF (ABS(((@NewItemLineGross - @OldItemLineGross) + isnull(@amt,0) + @POItemLineInvCost)) > ABS(@POItemLineCurCost)) AND ABS(@POItemLineCurCost)>0
		BEGIN
			IF @source = 'B' AND @POItemLineTotYN = 'N' -- Exceed flag is set to No so return err to batch validation
			BEGIN
			SELECT @msg = @msg + 'Invoiced amounts exceed PO Item Line''s current cost. ', @rcode=1
			GOTO bspexit
			END
			
			IF @source <> 'B' -- return warning to form validation
			BEGIN
				SELECT @msg= @msg + 'Invoiced amounts exceed PO Item Line''s current cost. ' + CHAR(13)
			END
		END
		
		-- PO Item warning/error message - check if PO item's total Current Cost has been exceeded - skip if standing PO Item
		if (abs(((@newgross - @oldgross) + isnull(@amt,0) + @poinvcost)) > abs(@pocurrcost)) and abs(@pocurrcost) > 0
		begin
			if @source = 'B' and @poitemtotyn = 'N'	-- return err to batch validation if exceed flag = N
				begin
					select @msg = @msg + 'Invoiced amounts exceed PO Item''s current cost. ', @rcode=1
					goto bspexit
				end
			if @source <> 'B'	-- return warning to form validation
				begin
					select @msg= @msg + 'Invoiced amounts exceed PO Item''s current cost. ' + CHAR(13)
				end
		end

		-- PO warning/error message - check if PO's total current cost has been exceeded - skip if standing PO Item
		if (abs(((@newpogross - @oldpogross) + isnull(@amt,0) + @pototalinvcost)) > abs(@pototalcurcost)) and abs(@pocurrcost) > 0
		begin
			if @source = 'B' and @pototyn = 'N' -- return err to batch validation if exceed flag = N
				begin	
					select @msg = @msg + 'Invoiced amounts exceed PO''s current cost. ', @rcode=1
					goto bspexit
				end
			if @source <> 'B'	-- return warning to form validation
				begin
					select @msg= @msg + 'Invoiced amounts exceed PO''s current cost. ' + CHAR(13) 
				end
		end
	END
   
   
   bspexit:
   	-- if we have a warning/err message then add the PO and Item
   	If @msg <> '' 
   		select @msg = @msg + 'For PO: ' + ltrim(isnull(@po, '')) + ' Item: ' + ltrim(isnull(convert(varchar(5),@poitem), ''))
   	else
   		select @msg = ''
   
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspAPPOItemTotalVal] TO [public]
GO
