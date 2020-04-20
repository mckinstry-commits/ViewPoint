SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspSLVal    Script Date: 8/28/99 9:33:42 AM ******/
   CREATE    proc [dbo].[bspSLVal]
   /*******************************************************************
    * CREATED : kf 5/5/97
    * MODIFIED: kb 3/11/99
    *           GR 1/24/00 corrected the calculation of subcontract remaining total
    *		     TV 04/18/01 Errormsg returning wrong issue 11828
    *           GG 07/14/01 cleanup for #13968
    *			 RT 12/03/03 - issue 23061, use isnulls when concatenating strings.
	*			DC 4/25/07 - 6.x Re-code,  Added JCGLCo, and Phase Group to the output params
	*			DC 08/13/08 - #128435 - Add Taxes to SL
	*			DC 06/25/10 - #135813 - expand subcontract number
	*			GF 12/13/2011 TK-10941 phase group is for the JCCo
	*
    *
    * Used by SL Change Order form to validate Subcontract and retrieve amounts for display.
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
	*	 @jcglco		JC Companies GL Company
	*	 @phasegroup	JC Phase Group from bHQCO
	*	 @origdate		OrigDate from bSLHD
	*	 @taxgroup		TaxGroup from HQCO
    *    @msg          Subcontract description or error message
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *******************************************************************/   
       (@slco bCompany, @sl VARCHAR(30), --bSL, DC #135813
       @batchid bBatchID, @mth bMonth, @batchseq int,
        @vendor bVendor output, @vendorname varchar(30) output, @vendorgroup bGroup output,
        @origtot bDollar output, @curtot bDollar output, @invtot bDollar output, @remtot bDollar output,
        @job bJob output, @jcco bCompany output, @jcglco bCompany output, @phasegroup bGroup output,
        @origdate bDate output, @taxgroup bGroup output,  --DC #128435 
		@msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int, @inusebatchid bBatchID, @inusemth bMonth, @inuseby bVPUserName,
       @status tinyint, @source bSource,
       @origtax bDollar, @curtax bDollar, @invtax bDollar   --DC #128435
   
   select @rcode = 0
   
   if @slco is null
		begin
    	select @msg = 'Missing SL Company!', @rcode = 1
    	goto bspexit
    	end
   if @sl is null
    	begin
    	select @msg = 'Missing Subcontract!', @rcode = 1
    	goto bspexit
    	end
   
   -- only allow SL to be changed on new entries
   if exists(select 1 from bSLCB where Co = @slco and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
       and BatchTransType in ('C','D') and SL <> @sl)
   		begin
		select @msg = 'Cannot change Subcontract on a previously posted Change Order', @rcode = 1
     	goto bspexit
     	end
   
   -- validate Subcontract and get info
   select @jcco = JCCo, @job = Job, @msg = Description, @vendorgroup = VendorGroup, @vendor = Vendor,
       @status = Status, @inusemth = InUseMth, @inusebatchid = InUseBatchId,
		@origdate = OrigDate --DC #128435
   from bSLHD
   where SLCo = @slco and SL = @sl
   if @@rowcount = 0
    	begin
    	select @msg = 'Subcontract not on file!', @rcode = 1
    	goto bspexit
    	end
   if @status <> 0
    	begin
    	select @msg = 'Subcontract not open!', @rcode = 1
    	goto bspexit
    	end

	/***  DC 6.x recode changes ***/
	--Get GL Company for the JC Company
   select @jcglco = GLCo from bJCCO with (nolock) where JCCo = @jcco

	--Get Phase Group for the sl company
   ----select @phasegroup = PhaseGroup from bHQCO with (nolock) where HQCo = @slco
   ----TK-10941
   SELECT @phasegroup = PhaseGroup FROM bHQCO WITH (NOLOCK) WHERE HQCo = @jcco
	/***  END DC 6.x recode Changes ***/
	
	--DC #128435  Get Tax Group for the JC Company
	select @taxgroup = TaxGroup from bHQCO with (nolock) where HQCo = @jcco

   -- make sure SL is not locked by another batch
   if @inusebatchid is not null and (@inusebatchid <> @batchid or @inusemth <> @mth)
   		begin
		select @inuseby = InUseBy, @source = Source
      	from bHQBC
   		where Co = @slco and BatchId = @batchid and Mth = @mth
   		select @msg = 'Subcontract already in use by ' + convert(varchar(2),DATEPART(month, @inusemth)) + '/'
           + substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4) + ' Batch # ' + convert(varchar(6),@inusebatchid)
           + ' - ' + 'Batch Source: ' + @source, @rcode = 1
		select @msg = isnull(@msg,'Subcontract already in use.')
   		goto bspexit
     	end
   
   -- get Vendor Name
   select @vendorname = Name
   from bAPVM with (nolock)
   where VendorGroup = @vendorgroup and Vendor = @vendor
   if @@rowcount = 0 select @vendorname = 'Missing'
    
   -- get total costs from SL Items
   select @origtot= isnull(sum(OrigCost),0), @curtot = isnull(sum(CurCost),0),
       @invtot= isnull(sum(InvCost),0),
		@origtax = isnull(sum(OrigTax),0), @curtax = isnull(sum(CurTax),0), --DC #128435
		@invtax = isnull(sum(InvTax),0) --DC #128435
   from bSLIT with (nolock)
   where SLCo = @slco and SL = @sl
      
   -- add new Change Order entries to current amounts
   -- restrictions on unit cost change allow us to track total cost change w/in Change Order
   select @curtot = @curtot + isnull(sum(ChangeCurCost),0)
   from bSLCB with (nolock)
   where Co = @slco and Mth = @mth and BatchId = @batchid and SL = @sl and BatchTransType = 'A'
   
   -- correct for Change Orders being modified in batch
   select @curtot = @curtot + isnull(sum(-OldCurCost + ChangeCurCost),0)
   from bSLCB with (nolock)
   where Co = @slco and Mth = @mth and BatchId = @batchid and SL = @sl and BatchTransType = 'C'
   
   -- back out Change Orders flagged for deletion in batch
   select @curtot = @curtot - isnull(sum(OldCurCost),0)
   from bSLCB with (nolock)
   where Co = @slco and Mth = @mth and BatchId = @batchid and SL = @sl and BatchTransType = 'D'

	--Get total costs with taxes  DC #128435
	select @origtot = @origtot + @origtax
	select @curtot = @curtot + @curtax
	select @invtot = @invtot + @invtax
   
   -- calculate remaining cost including Change Orders in batch
   select @remtot = @curtot - @invtot
   
   bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLVal] TO [public]
GO
