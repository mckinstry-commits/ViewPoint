SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspAPHBPostPOSL    Script Date: 8/28/99 9:33:59 AM ******/
   CREATE     procedure [dbo].[bspAPHBPostPOSL]
   /***********************************************************
   * CREATED BY: GG 12/14/98
   * MODIFIED By : GG 01/19/99
   *               GG 12/13/99 - Fixed update to PO Item Received, BO Units and Costs
   *               GR 04/17/00 - Corrected the SL Item InvCost update based on tax type
   *               GG 05/16/00 - Update bSLIT Stored Materials
   *               kb 1/8/2 - issue #15776
   *				GG 08/27/02 - #17135 - don't adjust Backordered on standing PO Items\
   *               kb 10/28/2 - issue #18878 - fix double quotes
   *				GF 08/11/2003 - issue #22112 - performance improvements
   *				MV 12/01/03 - #22664 don't include Misc Amt in Received and Invoiced Cost
   *				MV 12/01/03 - #23061 isnull wrap
   *				ES 03/11/04 - #23061 more isnull wrap
   *				MV 05/26/04 - #24655 - use oldtaxtype, oldtaxamt when updating SLIT InvCost
   *				MV 10/14/04 - #25501 - don't include taxamt when updating InvCost in bSLIT
   *				MV 06/15/06 - #12034 - 6X version of 5x 120215
   *                MV 07/14/08 - #128288 - update Tax Amt to SL
   *				DC 12/30/09 - #130175 - SLIT needs to match POIT
   *				GP 6/28/10 - #135813 change bSL to varchar(30) 
   *				DC 7/6/10 - #140487 - Posting error: APHBPostPOSL - Missing Tax Code when no tax exists in SLIT
   *				GF 09/09/2010 - issue #141031 changed to use function vfDateOnly
   *				MH 04/10/2010 - TK 03565
   *				GF 08/03/2011 - TK-07143 expand PO
   *				MV 08/10/11 - TK-07621 AP project to use POItemLine
   *
   *
   * USAGE:
   * Called from bspAPHBPost procedure to update PO and SL Items
   *
   * INPUT PARAMETERS:
   *   @co             AP Co#
   *   @errorstart     Beginning of error message identifying Seq#
   *   @linetranstype  AP Line transaction type 'A','C', or 'D'
   *   @oldpo          Old PO#
   *   @oldpoitem      Old PO Item
   *   @oldsl          Old Subcontract
   *   @oldslitem      Old SL Item
   *   @oldunits       Old invoiced units
   *   @oldgrossamt    Old gross amount
   *   @oldmisccamt    Old misc amount
   *   @oldmiscyn      Old misc amount paid to vendor, 'Y' or 'N'
   *   @oldtaxamt      Old sales/use tax amount
   *   @po             PO#
   *   @poitem         PO Item
   *   @sl             Subcontract
   *   @slitem         SL Item
   *   @units          Invoiced units
   *   @grossamt       Invoiced amount
   *   @miscamt        Misc amount
   *   @miscyn         Misc amount paid to vendor, 'Y' or 'N'
   *   @taxamt         Sales/use tax amount
   *   @taxtype        0 = use, 1 = sales
   *   @smchange       Change in Stored Matls (from SL Worksheet)
   *
   * OUTPUT PARAMETERS
   *   @errmsg         error message if something went wrong
   *
   * RETURN VALUE:
   *   0               success
   *   1               fail
   *****************************************************/
   (@co bCompany, @errorstart varchar(30), @linetranstype char(1),@oldpo VARCHAR(30), @oldpoitem bItem, @OldPOItemLine INT, @oldsl varchar(30),
    @oldslitem bItem, @oldunits bUnits, @oldgrossamt bDollar, @oldmiscamt bDollar, @oldmiscyn bYN,
    @oldtaxtype int, @oldtaxamt bDollar, @po VARCHAR(30), @poitem bItem, @POItemLine INT, @sl varchar(30), @slitem bItem, @units bUnits,
    @grossamt bDollar,@miscamt bDollar, @miscyn bYN, @taxamt bDollar, @taxtype tinyint, @smchange bDollar,
    @taxbasis bDollar, @oldtaxbasis bDollar, --DC #130175 
    @errmsg varchar(100) output)
   as
   set nocount on

   declare @rcode int, @amt bDollar, @pounits bUnits, @pocost bDollar, @recvyn bYN, @um bUM,
   		@bounits bUnits, @bocost bDollar, @curunits bUnits, @curcost bUnitCost, @origunits bUnits,	
		@origcost bDollar,
		@taxrate bRate, @jccmtdtaxamt bDollar, @gstrate bRate, @taxgroup bGroup, @taxcode bTaxCode,  --DC #130175
		@origdate bDate, @dateposted bDate, @HQTXdebtGLAcct bGLAcct  --DC #130175
   
	SELECT @rcode = 0
	----#141031
	SET @dateposted = dbo.vfDateOnly()
   
   if @errorstart is null	-- #23061
   	begin
   	select @errorstart = isnull(@errorstart, '')
   	end
   
   -- back out amounts from old PO Item
   if @oldpo is not null and @linetranstype in ('C','D')
       begin
       /*select @amt = @oldgrossamt + case @oldmiscyn when 'Y' then @oldmiscamt else 0 end --#22664*/
       -- get UM and Receiving flag from old PO Item
       SELECT @um = i.UM, @recvyn = i.RecvYN, @curunits = l.CurUnits, @curcost = l.CurCost, @origunits=l.OrigUnits, @origcost=l.OrigCost
       FROM dbo.vPOItemLine l (NOLOCK)
       JOIN dbo.bPOIT i(NOLOCK) ON l.POCo=i.POCo AND l.PO=i.PO AND l.POItem=i.POItem
       WHERE l.POCo = @co AND l.PO = @oldpo AND l.POItem = @oldpoitem AND l.POItemLine=@OldPOItemLine
       if @@rowcount = 0
           begin
           select @errmsg = @errorstart + ' Invalid PO: ' + isnull(@oldpo,'') + ' Item: '
               + isnull(convert(varchar(6),@oldpoitem), '')
               + ISNULL(CONVERT(VARCHAR(6),@OldPOItemLine),''), @rcode = 1  
           goto bspexit
           end
        -- set Recvd and BackOrdered updates, updated here only if Item not flagged for 'receiving'
		select @pounits = 0, @pocost = 0, @bounits = 0, @bocost = 0
	  if @recvyn = 'N'
         begin
         select @pounits = case @um when 'LS' then 0 else @oldunits end
         select @pocost = case @um when 'LS' then @oldgrossamt else 0 end
 		--#120234 - use Orig and Cur to determine standing PO
		if @origunits = 0 and @curunits = 0 and @origcost = 0 and @curcost = 0 
			begin
			select @bounits = 0
			select @bocost = 0
			end
		else 
			begin
			select @bounits = @oldunits 
	 		select @bocost = case when @um = 'LS' then @oldgrossamt else 0 end
			-- #17135 don't adjust Backordered on standing PO Items
-- 	 		select @bounits = case @curunits when 0 then 0 else @oldunits end
-- 	 		select @bocost = case when (@um = 'LS' and @curcost <> 0) then @oldgrossamt else 0 end
			end
         end
   
      	--update bPOIT
      	UPDATE dbo.vPOItemLine
    	SET RecvdUnits = RecvdUnits - @pounits, RecvdCost = RecvdCost - @pocost, /* -
         case @um when 'LS' then case @recvyn when 'N' then case @oldmiscyn when 'Y'
         then @oldmiscamt else 0 end else 0 end else 0 end, --issue #15776 commented out for #22664 */
            BOUnits = BOUnits + @bounits, BOCost = BOCost + @bocost,
            InvUnits = InvUnits - @oldunits, InvCost = InvCost - @oldgrossamt,/*@amt, #22664 */
   		    InvTax = InvTax - @oldtaxamt, InvMiscAmt = InvMiscAmt - @oldmiscamt 
           -- Total and Remaining updated in trigger
     	WHERE POCo = @co and PO = @oldpo and POItem = @oldpoitem AND POItemLine=@OldPOItemLine
       if @@rowcount = 0
           begin
           select @errmsg = @errorstart + ' Unable to update PO: ' + isnull(@oldpo,'') 
				+ ' Item: ' + isnull(convert(varchar(6),@oldpoitem), '')
				+ ' Line: ' + ISNULL(CONVERT(VARCHAR(6),@OldPOItemLine),'') , @rcode = 1  
           goto bspexit
           end
       end
   
   -- update new amounts to new PO Item
   if @po is not null and @linetranstype in ('A','C')
       begin
       /*select @amt = @grossamt + case @miscyn when 'Y' then @miscamt else 0 end #22664 */
       -- get UM and Receiving flag from PO Item
       SELECT @um = i.UM, @recvyn = i.RecvYN, @curunits = l.CurUnits, @curcost = l.CurCost, @origunits=l.OrigUnits, @origcost=l.OrigCost
       --from bPOIT with (nolock)
       FROM dbo.vPOItemLine l (NOLOCK)
       JOIN dbo.bPOIT i (NOLOCK) ON l.POCo=i.POCo AND l.PO=i.PO AND l.POItem=i.POItem 
       WHERE l.POCo = @co AND l.PO = @po AND l.POItem = @poitem AND l.POItemLine = @POItemLine
       if @@rowcount = 0
           begin
           select @errmsg = @errorstart + ' Invalid PO: ' + isnull(@po,'') 
				+ ' Item: ' + isnull(convert(varchar(6),@poitem), '')
				+ ' Line: ' + ISNULL(CONVERT(VARCHAR(6),@POItemLine),''), @rcode = 1  
           goto bspexit
           end
       -- set Recvd and BackOrdered updates, updated here only if Item not flagged for 'receiving'
       select @pounits = 0, @pocost = 0, @bounits = 0, @bocost = 0
       if @recvyn = 'N'
         begin
         select @pounits = case @um when 'LS' then 0 else @units end
         select @pocost = case @um when 'LS' then @grossamt else 0 end
		--#120234 - use Orig and Cur to determine standing PO
 		if @origunits = 0 and @curunits = 0 and @origcost = 0 and @curcost = 0 
			begin
			select @bounits = 0
			select @bocost = 0
			end
		else
			begin
			select @bounits = @units 
	 		select @bocost = case when @um = 'LS' then @grossamt else 0 end
			-- #17135 don't adjust Backordered on standing PO Items
-- 			select @bounits = case @curunits when 0 then 0 else @units end
--  			select @bocost = case when (@um = 'LS' and @curcost <> 0) then @grossamt else 0 end
			end
         end
  
      	--update bPOIT
		UPDATE dbo.vPOItemLine
		SET RecvdUnits = RecvdUnits + @pounits, RecvdCost = RecvdCost + @pocost, /* +
         case @um when 'LS' then case @recvyn when 'N' then case @miscyn when 'Y'
         then @miscamt else 0 end else 0 end else 0 end, --issue #15776  commented out for #22664*/
            BOUnits = BOUnits - @bounits, BOCost = BOCost - @bocost,
            InvUnits = InvUnits + @units, InvCost = InvCost + @grossamt, /*@amt,#22664 */
   		    InvTax = InvTax + @taxamt, InvMiscAmt = isnull(InvMiscAmt,0) + isnull(@miscamt,0)
           -- Total and Remaining updated in trigger
    	where POCo = @co and PO = @po and POItem = @poitem AND POItemLine=@POItemLine
       if @@rowcount = 0
           begin
           select @errmsg = @errorstart + ' Unable to update PO: '+ isnull(@po,'') 
				+ ' Item: ' + isnull(convert(varchar(6),@poitem), '')
				+ ' Line: ' + ISNULL(CONVERT(VARCHAR(6),@POItemLine),''), @rcode = 1  
           goto bspexit
           end
       end
   
   -- back out old amounts from SL Item
   if @oldsl is not null and @linetranstype in ('C','D')
       begin
       --DC #130175  
       SELECT @taxrate = TaxRate, @gstrate = GSTRate, @taxgroup = TaxGroup, @taxcode = TaxCode 
       FROM bSLIT with (nolock)
       Where SLCo = @co and SL = @oldsl and SLItem = @oldslitem
       
       --DC #130175
       SELECT @origdate = OrigDate
       FROM bSLHD with (nolock)
       WHERE SLCo = @co and SL = @oldsl
       
 		-- if @origdate is null use today's date
 		IF isnull(@origdate,'') = '' select @origdate = @dateposted       
       
		--DC #140487
		IF isnull(@taxcode,'') = ''  
			BEGIN
			SELECT @jccmtdtaxamt = 0
			END
		ELSE
			BEGIN       
			--DC #130175
			exec @rcode = vspHQTaxRateGet @taxgroup, @taxcode, @origdate, NULL, NULL, NULL, NULL, 
				NULL, NULL, NULL, NULL, @HQTXdebtGLAcct output, NULL, NULL, NULL, @errmsg output						
	              
			SELECT @jccmtdtaxamt = @oldgrossamt * (case when @HQTXdebtGLAcct is null then @taxrate else @taxrate - @gstrate end)  --DC #130175
			END
			
   		-- #24655
   		select @amt = @oldgrossamt 
   -- 		+ case @oldtaxtype when '1' then @oldtaxamt else 0 end -- commented out for #25501
   --     select @amt = @oldgrossamt /*+ case @oldmiscyn when 'Y' then @oldmiscamt else 0 end #22664 */
   --                   + case @taxtype when '1' then *@taxamt else 0 end 
      	update bSLIT
    	set InvUnits = InvUnits - @oldunits, InvCost = InvCost - @amt, InvTax = isnull(InvTax,0) - @oldtaxamt,
    		JCRemCmtdTax = JCRemCmtdTax + @jccmtdtaxamt  --DC #130175
     	where SLCo = @co and SL = @oldsl and SLItem = @oldslitem
       if @@rowcount = 0
           begin
           select @errmsg = @errorstart + ' Unable to update Subcontract: ' + isnull(@oldsl,'') + ' Item: '
               + isnull(convert(varchar(6),@oldslitem), ''), @rcode = 1  --#23061
           goto bspexit
           end
       end
   
   -- add new amounts to SL Item
   if @sl is not null and @linetranstype in ('A','C')
       begin
       
       --DC #130175  
       SELECT @taxrate = TaxRate, @gstrate = GSTRate, @taxgroup = TaxGroup, @taxcode = TaxCode  
       FROM bSLIT with (nolock)
       Where SLCo = @co and SL = @sl and SLItem = @slitem  

       --DC #130175
       SELECT @origdate = OrigDate
       FROM bSLHD with (nolock)
       WHERE SLCo = @co and SL = @sl 
       
 		-- if @origdate is null use today's date
 		IF isnull(@origdate,'') = '' select @origdate = @dateposted       

		--DC #140487
		IF isnull(@taxcode,'') = ''  
			BEGIN
			SELECT @jccmtdtaxamt = 0
			END
		ELSE
			BEGIN
			--DC #130175
			exec @rcode = vspHQTaxRateGet @taxgroup, @taxcode, @origdate, NULL, NULL, NULL, NULL, 
				NULL, NULL, NULL, NULL, @HQTXdebtGLAcct output, NULL, NULL, NULL, @errmsg output						                         
	       
			SELECT @jccmtdtaxamt = @grossamt * (case when @HQTXdebtGLAcct is null then @taxrate else @taxrate - @gstrate end)  --DC #130175
			END       
              
       select @amt = @grossamt /* case @miscyn when 'Y' then @miscamt else 0 end #22664 */
   --                   + case @taxtype when '1' then @taxamt else 0 end -- commented out for issue #25501
      	update bSLIT
    	set InvUnits = InvUnits + @units, InvCost = InvCost + @amt, StoredMatls = StoredMatls + @smchange,
			InvTax = isnull(InvTax,0) + @taxamt,
			JCRemCmtdTax = JCRemCmtdTax - @jccmtdtaxamt  --DC #130175
     	where SLCo = @co and SL = @sl and SLItem = @slitem
       if @@rowcount = 0
           begin
           select @errmsg = @errorstart + ' Unable to update Subcontract: ' + isnull(@sl,'') + ' Item: ' 
   		+ isnull(convert(varchar(6),@slitem), ''), @rcode = 1  --#23061
           goto bspexit
           end
       end         
   
   bspexit:
       return @rcode






GO
GRANT EXECUTE ON  [dbo].[bspAPHBPostPOSL] TO [public]
GO
