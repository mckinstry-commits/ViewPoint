SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspSLContractInfoGet    Script Date: 11/6/06  ******/
   CREATE    proc [dbo].[vspSLContractInfoGet]
   /*******************************************************************
    * CREATED : DC  11/06/06
    * MODIFIED:  DC 6/27/08 - #128435 - Add taxes to SL
	*				DC 7/8/09 - #134205 - SL Change Order - Add JC Committed Tax to SLCD
	*				DC 12/30/09 - #130175 - SLIT needs to match POIT
	*				DC 1/18/09 - #135730 - SL Change Order Entry Totals not summing correctly
	*				DC 5/28/10 - #122288 - Changes to tax rate storage.
	*				DC 6/29/10 - #135813 - expand subcontract number
	*				GF 09/05/2010 - issue #141031 use function vfDateOnly
	*
    *
    * Used by SL Change Order form to return Subcontract information and amounts for display.
    * Subcontract totals include entries within current batch.
    *
    * INPUT PARAMETERS
    *    @slco        SL Co#
    *    @sl          SL to validate
    *    @batchid     Batch #
    *    @mth         Batch Month
    *    @batchseq    Batch Seq#
    *
    * OUTPUT PARAMETERS
    *    @vendor       Vendor#
    *    @vendorname   Vendor Name
    *    @vendorgroup  Vendor Group
    *    @origtot      Original total cost
    *    @curtot       Current total cost (includes entries Change Order batch)
    *    @invtot       Invoviced total
    *    @remtot       Total remaining cost (current - invoiced)
    *    @job          Job from SL Header
    *    @jcco         JC Co#
	*	@curtax			
	*	@invtax			
	*	@remtax
	*	@origtax
	*	@chgtotax
    *    @msg          Subcontract description or error message
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *******************************************************************/   
       (@slco bCompany, @sl VARCHAR(30), --bSL, DC # 135813
       @batchid bBatchID, @mth bMonth, @batchseq int,
		@slitem bItem, --DC #128435
        @vendor bVendor output, @vendorname varchar(30) output, @vendorgroup bGroup output,
        @origtot bDollar output, @curtot bDollar output, @invtot bDollar output, @remtot bDollar output,
        @job bJob output, @jcco bCompany output, 
		@slitcurtax bDollar = null output,  --DC #128435
		@slitinvtax bDollar = null output,  --DC #128435
		@slitremtax bDollar = null output,  --DC #128435
		@slitorigtax bDollar = null output, --DC #128435
		@chgtotax bDollar = null output,  --DC #128435
		@msg varchar(255) output)

   as   
   set nocount on
   
   declare @rcode int, @inusebatchid bBatchID, @inusemth bMonth, @inuseby bVPUserName,
       @status tinyint, @source bSource, 
		@taxgroup bGroup, @taxcode bTaxCode, @taxrate bRate, --DC #128435
		@taxphase bPhase, @taxjcct bJCCType, @dateposted bDate, @chgdate bDate, --DC #128435
		@slitcurcost bDollar, @slitinvcost bDollar, --DC #128435
		@slitorigcost bDollar, @origtax bDollar, @curtax bDollar, @invtax bDollar,   --DC #128435
		@chgtojccmtdtax bDollar, @slcbchangecurcost bDollar, @HQTXdebtGLAcct bGLAcct, -- DC #134205
		@gstrate bRate, @pstrate bRate  -- DC #134205		
		
	select @rcode = 0
	select @taxcode = null, @taxrate = 0
	---- #141031
	set @dateposted = dbo.vfDateOnly()
	
	SELECT @pstrate = 0  --DC #130175

	if @slco is null
   		begin
   		select @msg = 'Missing SL Company!', @rcode = 1
   		goto bspexit
   		end
   
	if @sl is null
   		begin   
   		select @msg = 'Missing SL!', @rcode = 1
   		goto bspexit
   		end
      
	if @slitem is null
   		begin
   		select @msg = 'Missing SL Item#!', @rcode = 1
   		goto bspexit
   		end
   
   -- get Vendor Name
   select @vendorname = Name
   from bAPVM
   where VendorGroup = @vendorgroup and Vendor = @vendor
   if @@rowcount = 0 select @vendorname = 'Missing'
   
   -- get total costs from SL Items
   select @origtot= isnull(sum(OrigCost),0), @curtot = isnull(sum(CurCost),0),
       @invtot= isnull(sum(InvCost),0),
		@origtax = isnull(sum(OrigTax),0), @curtax = isnull(sum(CurTax),0), --DC #128435
		@invtax = isnull(sum(InvTax),0) --DC #128435
   from bSLIT
   where SLCo = @slco and SL = @sl

	-- Get SLIT values  DC #128435
	SELECT @slitcurcost=CurCost,@slitinvcost=InvCost,@slitorigcost=OrigCost,
		@taxcode = TaxCode, @taxgroup = TaxGroup, @slitorigtax = OrigTax,
		@taxrate = TaxRate, @gstrate = GSTRate  --DC #130175  
	FROM bSLIT with (nolock) 
	WHERE SLCo=@slco and SL=@sl and SLItem=@slitem

	--DC #128435
   select @chgdate = ActDate, @slcbchangecurcost = ChangeCurCost
   from bSLCB
   where Co = @slco and Mth = @mth and BatchId = @batchid and SL = @sl and SLItem = @slitem

 	-- if @chgdate is null use today's date DC #128435
 	if isnull(@chgdate,'') = '' select @chgdate = @dateposted

	--DC #128435
   	-- get tax rate based on change order date
    IF not @taxcode is null
		BEGIN
		--DC #130175
		exec @rcode = vspHQTaxRateGet @taxgroup, @taxcode, @chgdate, NULL, NULL, NULL, NULL, 
			NULL, NULL, NULL, NULL, @HQTXdebtGLAcct output, NULL, NULL, NULL, @msg output
				
		SELECT @pstrate = (case when @HQTXdebtGLAcct is null then 0 else @taxrate - @gstrate end)	 --(case when @gstrate = 0 then 0 else @taxrate - @gstrate end)									
		
     	END
	   
	--DC #134205
	IF @HQTXdebtGLAcct is null
		BEGIN
		/* When @pstrate = 0:  Either Standard US, VAT SingleLevel using GST only, or VAT MultiLevel GST/PST with PST set to 0.00 tax rate.  
		   In any case:
		   a)  @taxrate is the correct value.  
		   b)  Standard US:	Credit GLAcct and Credit Retg GLAcct are present
		   c)  VAT:  Credit GLAcct, Credit Retg GLAcct, Debit GLAcct, and Debit Retg GLAcct are present */
		SELECT @chgtojccmtdtax = @slcbchangecurcost * @taxrate
		END
	ELSE
		BEGIN
		/* VAT MultiLevel:  Breakout GST and PST for proper GL distribution. */
		IF @taxrate <> 0
			BEGIN
			SELECT @chgtojccmtdtax = @slcbchangecurcost * @pstrate
			END
		END
	   	   
   -- add new Change Order entries to current amounts
   -- restrictions on unit cost change allow us to track total cost change w/in Change Order
   select @curtot = @curtot + isnull(sum(ChangeCurCost),0)
   from bSLCB
   where Co = @slco and Mth = @mth and BatchId = @batchid and SL = @sl and BatchTransType = 'A'
   
   -- correct for Change Orders being modified in batch
   select @curtot = @curtot + isnull(sum(-OldCurCost + ChangeCurCost),0)
   from bSLCB
   where Co = @slco and Mth = @mth and BatchId = @batchid and SL = @sl and BatchTransType = 'C'
   
   -- back out Change Orders flagged for deletion in batch
   select @curtot = @curtot - isnull(sum(OldCurCost),0)
   from bSLCB
   where Co = @slco and Mth = @mth and BatchId = @batchid and SL = @sl and BatchTransType = 'D'

   -- add new Change Order entries to current amounts
   -- restrictions on unit cost change allow us to track total cost change w/in Change Order
   select @slitcurcost = @slitcurcost + isnull(sum(ChangeCurCost),0)
   from bSLCB
   where Co = @slco and Mth = @mth and BatchId = @batchid and SL = @sl and SLItem = @slitem and BatchTransType = 'A'
   
   -- correct for Change Orders being modified in batch
   select @slitcurcost = @slitcurcost + isnull(sum(-OldCurCost + ChangeCurCost),0)
   from bSLCB
   where Co = @slco and Mth = @mth and BatchId = @batchid and SL = @sl and SLItem = @slitem and BatchTransType = 'C'
   
   -- back out Change Orders flagged for deletion in batch
   select @slitcurcost = @slitcurcost - isnull(sum(OldCurCost),0)
   from bSLCB
   where Co = @slco and Mth = @mth and BatchId = @batchid and SL = @sl and SLItem = @slitem and BatchTransType = 'D'

	/* Calculate taxes DC #128435 */
	select @slitcurtax = @slitcurcost * @taxrate
	select @slitinvtax = @slitinvcost * @taxrate
	select @slitremtax = @slitcurtax - @slitinvtax

	--Get total costs with taxes  DC #128435
	select @origtot = @origtot + (@origtot * @taxrate) 
	select @curtot = @curtot + (@curtot * @taxrate)
	select @invtot = @invtot + (@invtot * @taxrate)
	/*  DC #135730
	select @origtot = @origtot + @origtax
	select @curtot = @curtot + @curtax
	select @invtot = @invtot + @invtax
	*/
	-- calculate remaining cost including Change Orders in batch
	select @remtot = @curtot - @invtot
	SELECT @chgtotax = @slcbchangecurcost * @taxrate	--DC #134205
	
	--select @chgtotax = @slitcurtax - @slitorigtax 

	update bSLCB
	Set ChgToTax = @chgtotax,
		ChgToJCCmtdTax = @chgtojccmtdtax  --DC #134205
	Where Co = @slco and Mth = @mth and BatchId = @batchid and SL = @sl and SLItem = @slitem
   
   bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspSLContractInfoGet] TO [public]
GO
