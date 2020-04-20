SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPHDRefUnique    Script Date: 8/28/99 9:33:59 AM ******/
     CREATE  proc [dbo].[bspAPHDRefUnique]
     /***********************************************************
      * CREATED BY	: SE 7/9/97
      * MODIFIED BY	: SE 7/9/97
      *              : GR 9/14/99 added a check to see whether the batch transaction type is in add or change mode in header APHB,
      *                           if it is a new one (i.e add mode),
      *                           then checks whether  Ref# exists in batch table(APTH)
      *              : GG 9/20/99 validation changes
      *              : GR 2/2/00  modified validation on APHB to see in all open batches
      *                           and added to check in APUI
      *              : GR 4/06/00 modified the validation on APHB to check in the current month and current batch too
      *              : GR 5/31/00 expanded the validation on APTH to check all open batches (includes payment batches too)
      *              : GR 11/21/00 changed datatype from bAPRef to bAPReference
      *                GG 02/10/01 fix validation on bAPUI - cleanup
      *                GG 03/06/01 - added isnull validation on AP Reference
      *			  : MV 07/30/02 - #15113 expand APRef duplicate checking
      *			  : MV 08/28/02 - #15113 rej-1 fix
      *			  : MV 09/18/02 - 15113 - warn or prevent at all levels enhancement
      *              kb 10/28/2 - issue #18878 - fix double quotes
      *				 MV 03/12/03 - #20703 - default to vendor if no master vendor
      *				 GF 08/07/2003 - issue #22083 - speed improvements
      *				 MV 10/09/03 - 22674 - null @ref causes returned errmsg to be null 
      *				 ES 03/11/04 - #23061 added isnull wrap
	  *				 MV 04/03/07 - #124131 - remove isnull from APRef and @ref in where clauses
      *				MV 10/31/07 - Happy Halloween! #123929 convert(varchar (3), @co) change from varchar 2 to 3
	  *			TJL 03/24/09 - Issue #132867 - ANSI Null evaluating FALSE instead of TRUE
      * USAGE:
      * validates AP Reference to see if it is unique.  Checks APHB, APUI and APTH
      *
      * INPUT PARAMETERS
      *   @apco      AP Company
      *   @mth       Month of batch
      *   @batchid   Batch ID
      *   @seq       Current sequence within batch
      *   @vendor    Vendor
      *   @ref       AP Reference to validate
      *
      * OUTPUT PARAMETERS
      *   @msg      message if Reference is not unique otherwise nothing
      *
      * RETURN VALUE
      *   0         success
      *   1         failure
      *****************************************************/
    
         (@apco bCompany = null,@mth bMonth = null, @batchid bBatchID = null,
          @seq int = null, @vendor bVendor = null, @ref bAPReference = null,
    	 @vendorgroup bGroup, @msg varchar(255) output)
    as
    
    set nocount on
    
    declare @rcode int, @batchseq int, @apmth bMonth, @aptrans int, @batchid2 bBatchID,
         @batchmth bMonth, @uimth bMonth, @uiseq int, @aprefexists varchar(2), @inusemth bMonth,
         @apuimth bMonth, @apuiseq int, @apcorefunq tinyint, @apvmrefunq tinyint, @refunq tinyint,
    	@mastervendor bVendor, @subvendor bVendor, @co bCompany, @chkrev bYN
    
    select @rcode = 0, @msg = 'AP Unique'
    
    --Don't do any AP Ref checking for check reversals
    select @chkrev = ChkRev from bAPHB with (nolock)
    	where Co=@apco and Mth=@mth and BatchId=@batchid and BatchSeq=@seq
    if @chkrev = 'Y' goto bspexit
    
    -- get Ref uniqueness level from APVendMaster and APCompany 
    select @apvmrefunq = APRefUnqOvr from bAPVM with (nolock) where VendorGroup=@vendorgroup and Vendor=@vendor
    select @apvmrefunq = case when @apvmrefunq is null then 0 else @apvmrefunq end
    select @apcorefunq = APRefUnq from bAPCO with (nolock) where APCo=@apco 
    -- use override in bAPVM, else bAPCO 
    select @refunq = case when @apvmrefunq > 0 then @apvmrefunq else @apcorefunq end
    
    /** VENDOR LEVEL CHECKING **/
    if @refunq = 1 	
    BEGIN
    -- check for AP Reference used by this Vendor in any other AP Entry batch
    select @batchseq = BatchSeq, @batchid2 = BatchId, @batchmth = Mth
    from bAPHB with (nolock) 
    where Co = @apco and Vendor = @vendor and ((APRef is null and @ref is null) or (APRef = @ref)) and BatchTransType in ('A','C')
    	and (Mth <> @mth or BatchId <> @batchid or BatchSeq <> @seq) -- exclude current entry
    if @@rowcount > 0
    	begin
         select @msg = ' AP Reference ' + isnull(@ref,'')
    		+ ' already used on Vendor# ' + isnull(convert(varchar(6),@vendor), '')
             	+ ' Mth: ' + isnull(convert(varchar(8),@batchmth,1), '')
    
             	+ ' BatchId#: ' + isnull(convert(varchar(6), @batchid2), '')
    		+ ' Seq#: ' + isnull(convert(varchar(4),@batchseq), ''), @rcode = 1  --#23061
    	goto bspexit
         end
    	
    -- get Unapproved Mth and Seq for current batch entry, may be null
    select @apuimth = UIMth, @apuiseq = UISeq
    from bAPHB with (nolock) where Co = @apco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    
    -- check Unapproved Invoices
    select @uimth = UIMth, @uiseq = UISeq
    from bAPUI with (nolock) 
    where APCo = @apco and Vendor = @vendor and ((APRef is null and @ref is null) or (APRef = @ref))
    	and ((UIMth <> @apuimth or UISeq <> @apuiseq) or @apuimth is null) -- if unapproved, exclude current entry
    if @@rowcount > 0
    	begin
         select @msg = ' AP Reference ' + isnull(@ref,'')
    		+ ' already used on Vendor# ' + isnull(convert(varchar(6),@vendor), '')  
    		+ ' Mth: ' + isnull(convert(varchar(8),@uimth,3), '')
              + ' Seq#: ' + isnull(convert(varchar(4),@uiseq), '')
    		+ ' in AP Unapproved Invoice', @rcode = 1  --#23061
         goto bspexit
         end
    
    -- check AP Transaction Headers not in any batch, and not in the current one (may be in Payment Batch)
    select @apmth = Mth, @aptrans = APTrans
    from bAPTH with (nolock) 
    where APCo = @apco and Vendor = @vendor and ((APRef is null and @ref is null) or (APRef = @ref))
    	and (InUseMth is null or (InUseMth <> @mth or InUseBatchId <> @batchid))
    if @@rowcount > 0
    	begin
         select @msg = ' AP Reference ' + isnull(@ref,'') 
    		+ ' already used on Vendor# ' + isnull(convert(varchar(6),@vendor), '')  
    		+ ' Mth: ' + isnull(convert(varchar(8),@apmth,1), '')
              + ' Trans#: ' + isnull(convert(varchar(6),@aptrans), ''), @rcode = 1 --#23061
         goto bspexit
         end
    END
    
    /** CROSS COMPANY LEVEL CHECKING **/
    if @refunq = 2 	
    BEGIN
    -- check for AP Ref used by this vendor in any other AP Entry batch across all companies in the vendorgroup.
    select @batchseq = BatchSeq, @batchid2 = BatchId, @batchmth = Mth, @co=Co
    from bAPHB with (nolock) 
    where Vendor = @vendor and VendorGroup=@vendorgroup and ((APRef is null and @ref is null) or (APRef = @ref))
    	and BatchTransType in ('A','C')
    	and (Mth <> @mth or BatchId <> @batchid or BatchSeq <> @seq) -- exclude current entry
    if @@rowcount > 0
    	begin
         select @msg = 'AP Reference ' + isnull(@ref,'')
             + ' already used in Company: ' + isnull(convert(varchar(3),@co), '')
    	    + ' Mth: ' + isnull(convert(varchar(8),@batchmth,1), '')
             + ' BatchId#: ' + isnull(convert(varchar(6), @batchid2), '')
    	    + ' Seq#: ' + isnull(convert(varchar(4),@batchseq), ''), @rcode = 1
         goto bspexit
         end
    
    -- get Unapproved Mth and Seq for current batch entry, may be null
    select @apuimth = UIMth, @apuiseq = UISeq
    from bAPHB with (nolock) where Co = @apco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    
    -- check Unapproved Invoices
    select @uimth = UIMth, @uiseq = UISeq,@co=APCo 
    from bAPUI with (nolock) 
    where Vendor = @vendor and VendorGroup=@vendorgroup and ((APRef is null and @ref is null) or (APRef = @ref))
        	and ((UIMth <> @apuimth or UISeq <> @apuiseq) or @apuimth is null) -- if unapproved, exclude current entry
    if @@rowcount > 0
    	begin
         select @msg = 'AP Reference ' + isnull(@ref,'')
    		+ ' already used in Company: ' + isnull(convert(varchar(3),@co), '')
    		+ ' Mth: ' + isnull(convert(varchar(8),@uimth,1), '')
              + ' Seq#: ' + isnull(convert(varchar(4),@uiseq), '')
    		+ ' in AP Unapproved Invoice', @rcode = 1  --#23061
         goto bspexit
         end
    
    -- check AP Transaction Headers not in any batch, and not in the current one (may be in Payment Batch)
    select @apmth = Mth, @aptrans = APTrans, @subvendor=Vendor,@co=APCo
    from bAPTH with (nolock) 
    where Vendor = @vendor and VendorGroup=@vendorgroup and ((APRef is null and @ref is null) or (APRef = @ref))
    	and (InUseMth is null or (InUseMth <> @mth or InUseBatchId <> @batchid))
    if @@rowcount > 0
    	begin
         select @msg = 'AP Reference ' + isnull(@ref,'')
    		+ ' already used in Company: ' + isnull(convert(varchar(3),@co), '')
    		+ ' Mth: ' + isnull(convert(varchar(8),@apmth,1), '')
              + ' Trans#: ' + isnull(convert(varchar(6),@aptrans), ''), @rcode = 1 --#23061
         goto bspexit
         end
    END
    
    /** MASTER VENDOR/SUBVENDOR LEVEL CHECKING **/
    if @refunq = 3		
    BEGIN
    -- check for AP Reference used by mastervendor/subvendors in any other AP Entry batch
    select @mastervendor = MasterVendor from bAPVM with (nolock) where VendorGroup=@vendorgroup and Vendor=@vendor
    if @mastervendor is null	-- check and see if vendor is the mastervendor
    	begin
    	select @mastervendor=@vendor
    	end
    select @batchseq = BatchSeq, @batchid2 = BatchId, @batchmth = Mth, @subvendor=h.Vendor
    from APHB h with (nolock) join APVM m with (nolock) on h.VendorGroup=m.VendorGroup and h.Vendor=m.Vendor
    where (h.Co=@apco and h.VendorGroup=@vendorgroup and ((APRef is null and @ref is null) or (APRef = @ref))
    
    	and  BatchTransType in ('A','C'))
    	and (m.MasterVendor=@mastervendor or h.Vendor=@mastervendor)
    	and (Mth <> @mth or BatchId <> @batchid or BatchSeq <> @seq) -- exclude current entry
    if @@rowcount > 0
    	begin
         select @msg = 'AP Reference ' + isnull(@ref,'')
             	+ ' already used on Mth: ' + isnull(convert(varchar(8),@batchmth,1), '')
              + ' BatchId#: ' + isnull(convert(varchar(6), @batchid2), '')
    		+ ' Seq#: ' + isnull(convert(varchar(4),@batchseq), '')
    		+ ' Vendor: ' + isnull(convert(varchar (5), @subvendor), ''),@rcode=1 --#23061
         goto bspexit
         end
    
    -- get Unapproved Mth and Seq for current batch entry, may be null
    select @apuimth = UIMth, @apuiseq = UISeq
    from bAPHB with (nolock) where Co = @apco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    -- check Unapproved Invoices
    select @uimth = UIMth, @uiseq = UISeq,@subvendor=h.Vendor
    from bAPUI h with (nolock) join bAPVM m with (nolock) on h.VendorGroup=m.VendorGroup and h.Vendor=m.Vendor
    where (h.APCo=@apco and h.VendorGroup=@vendorgroup and ((APRef is null and @ref is null) or (APRef = @ref)))
    	and (m.MasterVendor=@mastervendor or h.Vendor=@mastervendor)
    	and ((UIMth <> @apuimth or UISeq <> @apuiseq) or @apuimth is null) -- if unapproved, exclude current entry
    if @@rowcount > 0
    	begin
         select @msg = 'AP Reference ' + isnull(@ref,'')
             + ' already used on Mth: ' + isnull(convert(varchar(8),@uimth,1), '')
             + ' Seq#: ' + isnull(convert(varchar(4),@uiseq), '')
    	    + ' Vendor: ' + isnull(convert(varchar (5), @subvendor), '')
    	    + ' in AP Unapproved Invoice.' ,@rcode=1  --#23061
         goto bspexit
         end
    
    -- check AP Transaction Headers not in any batch, and not in the current one (may be in Payment Batch)
    select @apmth = Mth, @aptrans = APTrans, @subvendor=h.Vendor
    from bAPTH h with (nolock) join bAPVM m with (nolock) on h.VendorGroup=m.VendorGroup and h.Vendor=m.Vendor
    where (h.APCo=@apco and h.VendorGroup=@vendorgroup and ((APRef is null and @ref is null) or (APRef = @ref)))
    	and (m.MasterVendor=@mastervendor or h.Vendor=@mastervendor)
    	and (InUseMth is null or (InUseMth <> @mth or InUseBatchId <> @batchid)) --exclude current entry
    if @@rowcount > 0
    	begin
    	select @msg = 'AP Reference: ' + isnull(@ref,'') 
    		+ ' already used on Vendor# ' + isnull(convert(varchar(6),@subvendor), '')
    		+ ' Mth: ' + isnull(convert(varchar(8),@apmth,1), '')
              + ' Trans#: ' + isnull(convert(varchar(6),@aptrans), ''), @rcode = 1 --#23061
    	goto bspexit
         end
    END
    
    /* MASTER/SUBVENDOR AND CROSS COMPANY LEVEL CHECKING */
    if @refunq = 4		--if @refunq = 5 
    BEGIN
    select @mastervendor = MasterVendor from bAPVM where VendorGroup=@vendorgroup and Vendor=@vendor
    if @mastervendor is null	-- check and see if vendor is the mastervendor
    	begin
    	select @mastervendor=@vendor
    	end
    -- check for AP Ref used in any other AP Entry batch for master/subvendors in all companies by vendorgroup 
    select @batchseq = BatchSeq, @batchid2 = BatchId, @batchmth = Mth, @subvendor=h.Vendor,@co=h.Co
    from APHB h with (nolock) join APVM m with (nolock) on h.VendorGroup=m.VendorGroup and h.Vendor=m.Vendor
    where (h.VendorGroup=@vendorgroup and ((APRef is null and @ref is null) or (APRef = @ref)) and  BatchTransType in ('A','C'))
    	and (m.MasterVendor=@mastervendor or h.Vendor=@mastervendor)
    	and (Mth <> @mth or BatchId <> @batchid or BatchSeq <> @seq)  -- exclude current entry
    if @@rowcount > 0
    	begin
         select @msg = 'AP Reference ' + isnull(@ref,'')
             + ' already used on Co: ' + isnull(convert(varchar (3), @co), '')
    	    + ' Mth: ' + isnull(convert(varchar(8),@batchmth,1), '')
             + ' BatchId#: ' + isnull(convert(varchar(6), @batchid2), '')
    	    + ' Seq#: ' + isnull(convert(varchar(4),@batchseq), '')
    	    + ' Vendor: ' + isnull(convert(varchar(5),@subvendor), ''), @rcode = 1 --#23061
         goto bspexit
         end
    
    -- get Unapproved Mth and Seq for current batch entry, may be null
    select @apuimth = UIMth, @apuiseq = UISeq
    from bAPHB with (nolock) where Co = @apco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
    -- check Unapproved Invoices
    select @uimth = UIMth, @uiseq = UISeq,@subvendor=h.Vendor, @co=h.APCo
    from bAPUI h with (nolock) join bAPVM m with (nolock) on h.VendorGroup=m.VendorGroup and h.Vendor=m.Vendor
    where (h.VendorGroup=@vendorgroup and ((APRef is null and @ref is null) or (APRef = @ref)))
    	and (m.MasterVendor=@mastervendor or h.Vendor=@mastervendor)
    	and ((UIMth <> @apuimth or UISeq <> @apuiseq) or @apuimth is null) -- if unapproved, exclude current entry
    if @@rowcount > 0
    	begin
         select @msg = 'AP Reference ' + isnull(@ref,'')
    		+ ' already used on Co: ' + isnull(convert(varchar (3), @co), '')
    		+ ' Mth: ' + isnull(convert(varchar(8),@uimth,1), '')
              + ' Seq#: ' + isnull(convert(varchar(4),@uiseq), '')
    		+ ' Vendor: ' + isnull(convert(varchar(5),@subvendor), '')
    	     + ' in AP Unapproved Invoice', @rcode = 1 --#23061
         goto bspexit
         end
    
    -- check AP Transaction Headers not in any batch, and not in the current one (may be in Payment Batch)
    select @apmth = Mth, @aptrans = APTrans, @subvendor=h.Vendor, @co=h.APCo
    from bAPTH h with (nolock) join bAPVM m with (nolock) on h.VendorGroup=m.VendorGroup and h.Vendor=m.Vendor
    where (h.VendorGroup=@vendorgroup and ((APRef is null and @ref is null) or (APRef = @ref)))
    	and (m.MasterVendor=@mastervendor or h.Vendor=@mastervendor)
    	and (InUseMth is null or (InUseMth <> @mth or InUseBatchId <> @batchid))
    if @@rowcount > 0
    	begin
         select @msg = 'AP Reference: ' + isnull(@ref,'') 
    		+ ' already used on Vendor# ' + isnull(convert(varchar(6),@subvendor), '')
    		+ ' Co: ' +  isnull(convert (varchar(3), @co) , '')
    		+ ' Mth: ' + isnull(convert(varchar(8),@apmth,1), '')
              + ' Trans#: ' + isnull(convert(varchar(6),@aptrans), ''), @rcode = 1 --#23061
         goto bspexit
         end
    END
    
    
    
    
    bspexit:
        return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspAPHDRefUnique] TO [public]
GO
