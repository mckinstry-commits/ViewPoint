SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspAPLBValSL    Script Date: 8/28/99 9:36:01 AM ******/
    CREATE    procedure [dbo].[bspAPLBValSL]
    /*********************************************
     * Created: GG 6/5/99
     * Modified: GG 06/28/99
     *           GH 08/27/99 Made 'sl in use by another batch' error more descriptive
     *             GG 11/13/99 - Added output param for CurUnitCost
     *             GG 02/03/00 - Changed UM validation to allow 'LS' if posted UM does not match SLIT UM
     *                             added for Stored Material updates from SL
     *				3/15/00- added a validation for NULL values in slinusemth and slinusebatchid.
     *             kb 10/28/2 - issue #18878 - fix double quotes
     *				ES 03/11/04 -#23061 isnull wrapping
	 *				MV 07/?/08 - #128288 - SL VAT Tax Codes
	 *				MV 12/11/08 - #131385 - if taxcode is null don't zero out taxrate
	 *				MV 02/04/10 - #136500 - bspHQTaxRateGetAll added NULL output param
	 *				LS 06/02/10 - #139487 - Don't allow zero Unit Cost for Non-Lump Sum
	 *				GP 6/28/10 - #135813 change bSL to varchar(30)
	 *				MV 10/25/11 - TK-09243 - bspHQTaxRateGetAll added NULL output param
     *				
     * Usage:
     *  Called from the AP Transaction Batch validation procedure (bspAPLBVal)
     *  to validate SL Item information.
     *
     * Input:
     *  @apco       AP/PO Co#
     *  @mth        Batch month
     *  @batchid    Batch Id
     *  @sl         Subcontract
     *  @slitem     Subcontract Item
     *  @jcco       JC Co# - Job item
     *  @job        Job
     *  @phase      Phase
     *  @jcctype    JC Cost Type
     *  @um         Unit of measure
     *  @sltotyn    Allow invoice amount to exceed item amount flag
     *
     * Output:
     *  @slitemtype        Item type
     *  @slcurunitcost     Current unit cost
     *  @errmsg            Error message
     *
     * Return:
     *  0           success
     *  1           error
     *************************************************/
   
        @apco bCompany, @mth bMonth, @batchid bBatchID, @sl varchar(30), @slitem bItem, @jcco bCompany, @job bJob,
        @phase bPhase, @jcctype bJCCType, @um bUM, @sltotyn bYN, @slitemtype tinyint output,
        @slcurunitcost bUnitCost output,@sltaxgroup bGroup output, @sltaxcode bTaxCode output,
        @sltaxrate bRate output,@slGSTrate bRate output, @errmsg varchar(255) output
   
    as
   
    set nocount on
   
    declare @rcode int, @slstatus tinyint, @slinusemth bMonth, @slinusebatchid bBatchID,
    @slum bUM, @sljcco bCompany, @sljob bJob, @slphase bPhase, @sljcct bJCCType, @msg varchar(255),
    @sltaxtype int,@dbtGLAcct bGLAcct
   
    select @rcode = 0
   
    -- validate SL Header
    select @slstatus = Status, @slinusemth = InUseMth, @slinusebatchid = InUseBatchId
    from bSLHD
    where SLCo = @apco and SL = @sl
    if @@rowcount = 0
        begin
        select @errmsg = ' Invalid Subcontract: ' + isnull(@sl, ''), @rcode = 1 --#23061
        goto bspexit
        end
    if @slstatus <> 0   -- status must be open
        begin
        select @errmsg = ' Subcontract: ' + isnull(@sl, '') + ' is not open!', @rcode = 1 --#23061
        goto bspexit
      	end
   if @slinusemth is not  NULL or  @slinusebatchid is not Null  
   begin
    	if @slinusemth <> @mth or @slinusebatchid <> @batchid
        	begin
        	select @errmsg = ' Subcontract: ' + isnull(@sl, '') + ' is already in use by batch ' + 
   			isnull(convert(varchar(6),@slinusebatchid), '') + ' ' +
                           isnull(convert(varchar(2),datepart(month,@slinusemth)), '')+ '/' + 
   			isnull(substring(convert(varchar(8),@slinusemth,1),7,8), '') +
                           '!', @rcode = 1  --#23061
        	goto bspexit
      	end
   end
                                              
    -- validate SL Item
    select @sljcco = JCCo, @slitemtype = ItemType, @sljob = Job, @slphase = Phase, @sljcct = JCCType,
       @slum = UM, @slcurunitcost = CurUnitCost, @sltaxtype=TaxType,@sltaxgroup=TaxGroup,@sltaxcode=TaxCode
    from bSLIT                                                  
    where SLCo = @apco and SL = @sl and SLItem = @slitem
    if @@rowcount = 0
        begin
        select @errmsg = ' Invalid Subcontract: ' + isnull(@sl, '') + ' Item:' + 
   			isnull(convert(varchar(6),@slitem), ''), @rcode = 1 
        goto bspexit
      	end
    -- match posted info with SL Item
    if @sljcco <> @jcco or @sljob <> @job or @slphase <> @phase or @sljcct <> @jcctype
       or (@slum <> @um and @um <> 'LS')
        begin
        select @errmsg = ' Does not match setup information on Subcontract: ' + isnull(@sl, '') + 
   			' Item:' + isnull(convert(varchar(6),@slitem), '')  --#23061
        select @rcode = 1
        goto bspexit
      	end
   
    -- make sure invoiced total doesn't exceed total for item
    if @sltotyn = 'N'
        begin
        exec @rcode = bspAPSLItemTotalVal @apco, @mth, @batchid, @sl, @slitem, 'E', 0, null, null,@msg output
      	if @rcode <> 0
   
            begin
      		select @errmsg = '- ' + @msg, @rcode = 1
      	  	goto bspexit
   
      		end
        end
        
    -- validate Unit Cost isn't Zero for everything except Lump Sum (LS) Units of Measurement #139487
  --  IF @slum <> 'LS' AND @slcurunitcost = 0
  --  BEGIN
		--SET @errmsg = ' Unit Cost is zero in Subcontract ' + isnull(@sl, '') + ' Item '
		--	+ isnull(convert(varchar(5),@slitem), '') 
		--	+ '. Please update the Unit Cost to a non-zero amount in SL.'
		--SET @rcode = 1
		--RETURN @rcode 
  --  END

    --validate Tax Code
    if @sltaxcode is not null
        begin
        -- 128288 use bspHQTaxRateGetAll to return sltaxrate, slGSTtaxrate, debit GST GLAcct 
	    exec @rcode = bspHQTaxRateGetAll @sltaxgroup, @sltaxcode, null, null, @sltaxrate output, @slGSTrate output,
		    null,null,null, @dbtGLAcct output,null,null, null, NULL, NULL
   	    if @rcode <> 0
            begin
      		    select @errmsg = '- ' + isnull(@msg,''),@sltaxrate = 0, @rcode = 1
      	  	    goto bspexit
            end
        --if there is no debit GL Acct for GST then don't return a gst taxrate
        if @dbtGLAcct is null select @slGSTrate = 0
        end
--   else
--   	    select @sltaxrate = 0,@slGSTrate = 0	--131385
   
    bspexit:
        return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspAPLBValSL] TO [public]
GO
