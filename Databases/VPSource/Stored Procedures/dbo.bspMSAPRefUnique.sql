SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspMSAPRefUnique]
/***********************************************************
* CREATED:	GF 03/04/2005
* MODIFIED: TJL 03/24/09 - Issue #132867 - ANSI Null evaluating FALSE instead of TRUE
*			DAN SO 06/01/09 - Issue #133572 - Added MSWH table checks to 'if @refunq = 2'
*             
* USAGE: called from MS Hauler Worksheets and MS Material Vendor Worksheets.
* validates AP Reference to see if it is unique.  Checks MSWH, MSMH, APHB, APUI and APTH
*
* INPUT PARAMETERS
* @msco			MS Company
* @apco			AP Company
* @mth				Month of batch
* @batchid			Batch ID
* @seq				Current sequence within batch
* @vendorgroup		Haul/Material Vendor Group
* @vendor			Haul/Material Vendor
* @ref				AP Reference to validate
* @source			MS Batch Source (MS HaulPay or MS MatlPay)
*
*
* OUTPUT PARAMETERS
*   @msg      message if Reference is not unique otherwise nothing
*
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/
(@msco bCompany = null, @apco bCompany = null,@mth bMonth = null, @batchid bBatchID = null,
@seq int = null, @vendorgroup bGroup = null, @vendor bVendor = null, @ref bAPReference = null,
@source bSource = null, @msg varchar(255) output)
as
set nocount on
   
   declare @rcode int, @batchseq int, @apmth bMonth, @aptrans int, @batchid2 bBatchID,
   		@batchmth bMonth, @uimth bMonth, @uiseq int, @aprefexists varchar(2), @inusemth bMonth,
   		@apuimth bMonth, @apuiseq int, @apcorefunq tinyint, @apvmrefunq tinyint, @refunq tinyint,
   		@mastervendor bVendor, @subvendor bVendor, @co bCompany
   
   select @rcode = 0, @msg = ''
   
   -- get Ref uniqueness level from APVendMaster and APCompany 
   select @apvmrefunq = APRefUnqOvr from bAPVM with (nolock) where VendorGroup=@vendorgroup and Vendor=@vendor
   select @apvmrefunq = case when @apvmrefunq is null then 0 else @apvmrefunq end
   select @apcorefunq = APRefUnq from bAPCO with (nolock) where APCo=@apco 
   -- use override in bAPVM, else bAPCO 
   select @refunq = case when @apvmrefunq > 0 then @apvmrefunq else @apcorefunq end
   
   -- -- -- VENDOR LEVEL CHECKING
   if @refunq = 1 	
   	BEGIN
   	if @source = 'MS HaulPay'
   		begin
   		-- -- -- check for AP Reference used by this vendor in another MS Haul Batch
   		select @batchseq = BatchSeq, @batchid2 = BatchId, @batchmth = Mth
   		from bMSWH with (nolock) where Co=@msco and HaulVendor=@vendor and isnull(APRef,'') = isnull(@ref,'')
   		and (Mth <> @mth or BatchId <> @batchid or BatchSeq <> @seq) -- exclude current entry
   		if @@rowcount <> 0
   			begin
   			select @msg = ' AP Reference ' + isnull(@ref,'')
   				+ ' already used in MSWH Batch on Vendor: ' + isnull(convert(varchar(6),@vendor), '')
   	          	+ ' Mth: ' + isnull(convert(varchar(8),@batchmth,1), '')
   	          	+ ' BatchId: ' + isnull(convert(varchar(6), @batchid2), '')
   				+ ' Seq#: ' + isnull(convert(varchar(4),@batchseq), ''), @rcode = 1
   			goto bspexit
   			end
   		-- -- -- check for AP Reference used by this vendor in any MS Material Vendor Batch
   		select @batchseq = BatchSeq, @batchid2 = BatchId, @batchmth = Mth
   		from bMSMH with (nolock) where Co=@msco and MatlVendor=@vendor and isnull(APRef,'') = isnull(@ref,'')
   		if @@rowcount <> 0
   			begin
   			select @msg = ' AP Reference ' + isnull(@ref,'')
   				+ ' already used in MSMH Batch on Vendor: ' + isnull(convert(varchar(6),@vendor), '')
   	          	+ ' Mth: ' + isnull(convert(varchar(8),@batchmth,1), '')
   	          	+ ' BatchId: ' + isnull(convert(varchar(6), @batchid2), '')
   				+ ' Seq#: ' + isnull(convert(varchar(4),@batchseq), ''), @rcode = 1
   			goto bspexit
   			end
   		end
   
   	if @source = 'MS MatlPay'
   		begin
   		-- -- -- check for AP Reference used by this vendor in another MS Haul Batch
   		select @batchseq = BatchSeq, @batchid2 = BatchId, @batchmth = Mth
   		from bMSMH with (nolock) where Co=@msco and MatlVendor=@vendor and isnull(APRef,'') = isnull(@ref,'')
   		and (Mth <> @mth or BatchId <> @batchid or BatchSeq <> @seq) -- exclude current entry
   		if @@rowcount <> 0
   			begin
   			select @msg = ' AP Reference ' + isnull(@ref,'')
   				+ ' already used in MSMH Vendor Batch on Vendor: ' + isnull(convert(varchar(6),@vendor), '')
   	          	+ ' Mth: ' + isnull(convert(varchar(8),@batchmth,1), '')
   	          	+ ' BatchId: ' + isnull(convert(varchar(6), @batchid2), '')
   				+ ' Seq#: ' + isnull(convert(varchar(4),@batchseq), ''), @rcode = 1
   			goto bspexit
   			end
   		-- -- -- check for AP Reference used by this vendor in any MS Material Vendor Batch
   		select @batchseq = BatchSeq, @batchid2 = BatchId, @batchmth = Mth
   		from bMSWH with (nolock) where Co=@msco and HaulVendor=@vendor and isnull(APRef,'') = isnull(@ref,'')
   		if @@rowcount <> 0
   			begin
   			select @msg = ' AP Reference ' + isnull(@ref,'')
   				+ ' already used in MSWH Batch on Vendor: ' + isnull(convert(varchar(6),@vendor), '')
   	          	+ ' Mth: ' + isnull(convert(varchar(8),@batchmth,1), '')
   	          	+ ' BatchId: ' + isnull(convert(varchar(6), @batchid2), '')
   				+ ' Seq#: ' + isnull(convert(varchar(4),@batchseq), ''), @rcode = 1
   			goto bspexit
   			end
   		end
   
   	-- -- -- Check AP Batch transactions
   	select @batchseq = BatchSeq, @batchid2 = BatchId, @batchmth = Mth
   	from bAPHB with (nolock) where Co=@apco and Vendor=@vendor and APRef = @ref
   	if @@rowcount <> 0
   		begin
   		select @msg = ' AP Reference ' + isnull(@ref,'')
   				+ ' already used in APHB Batch on Vendor: ' + isnull(convert(varchar(6),@vendor), '')
   	          	+ ' Mth: ' + isnull(convert(varchar(8),@batchmth,1), '')
   	          	+ ' BatchId: ' + isnull(convert(varchar(6), @batchid2), '')
   				+ ' Seq#: ' + isnull(convert(varchar(4),@batchseq), ''), @rcode = 1
   		goto bspexit
   		end
   
   	-- -- -- check AP Posted Transactions
   	select @aptrans = APTrans, @batchmth = Mth
   	from bAPTH with (nolock) where APCo=@apco and Vendor=@vendor and APRef=@ref
   	if @@rowcount <> 0
   		begin
   		select @msg = ' AP Reference ' + isnull(@ref,'')
   				+ ' already used in APTH on transaction: ' + + isnull(convert(varchar(10), @aptrans), '')
   				+ ' Mth: ' + isnull(convert(varchar(8),@batchmth,1), ''), @rcode = 1
   		goto bspexit
   		end
   	
   	-- -- -- Check AP unapproved invoices
   	select @batchseq = UISeq, @batchmth = UIMth
   	from bAPUI with (nolock) where APCo=@apco and Vendor=@vendor and APRef=@ref
   	if @@rowcount <> 0
   		begin
   		select @msg = ' AP Reference ' + isnull(@ref,'')
   				+ ' already used in APUI on Unapproved Invoice: ' + + isnull(convert(varchar(10), @batchseq), '')
   				+ ' Mth: ' + isnull(convert(varchar(8),@batchmth,1), ''), @rcode = 1
   		goto bspexit
   		end
   	END
   
   
   
   
   -- -- -- CROSS COMPANY LEVEL CHECKING
   if @refunq = 2 	
   	BEGIN

	-- ISSUE: #133572
   	if @source = 'MS HaulPay'
   		begin
   		-- -- -- check for AP Reference used by this vendor in another MS Haul Batch
   		select @batchseq = BatchSeq, @batchid2 = BatchId, @batchmth = Mth
   		from bMSWH with (nolock) where HaulVendor=@vendor and VendorGroup = @vendorgroup and isnull(APRef,'') = isnull(@ref,'')
   		and (Mth <> @mth or BatchId <> @batchid or BatchSeq <> @seq) -- exclude current entry
   		if @@rowcount <> 0
   			begin
   			select @msg = ' AP Reference ' + isnull(@ref,'')
   				+ ' already used in MSWH Batch on Vendor: ' + isnull(convert(varchar(6),@vendor), '')
   	          	+ ' Mth: ' + isnull(convert(varchar(8),@batchmth,1), '')
   	          	+ ' BatchId: ' + isnull(convert(varchar(6), @batchid2), '')
   				+ ' Seq#: ' + isnull(convert(varchar(4),@batchseq), ''), @rcode = 1
   			goto bspexit
   			end
   		-- -- -- check for AP Reference used by this vendor in any MS Material Vendor Batch
   		select @batchseq = BatchSeq, @batchid2 = BatchId, @batchmth = Mth
   		from bMSMH with (nolock) where MatlVendor=@vendor and VendorGroup = @vendorgroup and isnull(APRef,'') = isnull(@ref,'')
   		if @@rowcount <> 0
   			begin
   			select @msg = ' AP Reference ' + isnull(@ref,'')
   				+ ' already used in MSMH Batch on Vendor: ' + isnull(convert(varchar(6),@vendor), '')
   	          	+ ' Mth: ' + isnull(convert(varchar(8),@batchmth,1), '')
   	          	+ ' BatchId: ' + isnull(convert(varchar(6), @batchid2), '')
   				+ ' Seq#: ' + isnull(convert(varchar(4),@batchseq), ''), @rcode = 1
   			goto bspexit
   			end
   		end --if @source = 'MS HaulPay'
   
   	if @source = 'MS MatlPay'
   		begin
   		-- -- -- check for AP Reference used by this vendor in another MS Haul Batch
   		select @batchseq = BatchSeq, @batchid2 = BatchId, @batchmth = Mth
   		from bMSMH with (nolock) where MatlVendor=@vendor and VendorGroup = @vendorgroup and isnull(APRef,'') = isnull(@ref,'')
   		and (Mth <> @mth or BatchId <> @batchid or BatchSeq <> @seq) -- exclude current entry
   		if @@rowcount <> 0
   			begin
   			select @msg = ' AP Reference ' + isnull(@ref,'')
   				+ ' already used in MSMH Vendor Batch on Vendor: ' + isnull(convert(varchar(6),@vendor), '')
   	          	+ ' Mth: ' + isnull(convert(varchar(8),@batchmth,1), '')
   	          	+ ' BatchId: ' + isnull(convert(varchar(6), @batchid2), '')
   				+ ' Seq#: ' + isnull(convert(varchar(4),@batchseq), ''), @rcode = 1
   			goto bspexit
   			end
   		-- -- -- check for AP Reference used by this vendor in any MS Material Vendor Batch
   		select @batchseq = BatchSeq, @batchid2 = BatchId, @batchmth = Mth
   		from bMSWH with (nolock) where HaulVendor=@vendor and VendorGroup = @vendorgroup and isnull(APRef,'') = isnull(@ref,'')
   		if @@rowcount <> 0
   			begin
   			select @msg = ' AP Reference ' + isnull(@ref,'')
   				+ ' already used in MSWH Batch on Vendor: ' + isnull(convert(varchar(6),@vendor), '')
   	          	+ ' Mth: ' + isnull(convert(varchar(8),@batchmth,1), '')
   	          	+ ' BatchId: ' + isnull(convert(varchar(6), @batchid2), '')
   				+ ' Seq#: ' + isnull(convert(varchar(4),@batchseq), ''), @rcode = 1
   			goto bspexit
   			end
   		end --if @source = 'MS MatlPay'

   	-- -- -- check for AP Ref used by this vendor in any other AP Entry batch
   	-- -- -- across all companies in the vendorgroup.
   	select @batchseq = BatchSeq, @batchid2 = BatchId, @batchmth = Mth, @co=Co
   	from bAPHB with (nolock) 
   	where Vendor = @vendor and VendorGroup=@vendorgroup and APRef = @ref
   	if @@rowcount > 0
   		begin
   		select @msg = 'AP Reference ' + isnull(@ref,'')
   				+ ' already used in APHB on APCo: ' + isnull(convert(varchar(3),@co), '')
   				+ ' Mth: ' + isnull(convert(varchar(8),@batchmth,1), '')
   				+ ' BatchId: ' + isnull(convert(varchar(6),@batchid2), '')
   				+ ' Seq: ' + isnull(convert(varchar(4),@batchseq), ''), @rcode = 1
   		goto bspexit
   		end
   
   	-- -- -- Check Posted transactions
   	select @aptrans = APTrans, @batchmth = Mth, @co=APCo
   	from bAPTH with (nolock) 
   	where Vendor = @vendor and VendorGroup=@vendorgroup and APRef = @ref
   	if @@rowcount > 0
   		begin
   		select @msg = 'AP Reference ' + isnull(@ref,'')
   				+ ' already used in APTH on APCo: ' + isnull(convert(varchar(3),@co), '')
   				+ ' Mth: ' + isnull(convert(varchar(8),@batchmth,1), '')
   				+ ' APTrans: ' + isnull(convert(varchar(10),@aptrans), ''), @rcode = 1
   		goto bspexit
   		end
   
   	-- -- -- Check unapproved invoices
   	select @batchseq = UISeq, @batchmth = UIMth, @co=APCo
   	from bAPUI with (nolock) 
   	where Vendor = @vendor and VendorGroup=@vendorgroup and APRef = @ref
   	if @@rowcount > 0
   		begin
   		select @msg = 'AP Reference ' + isnull(@ref,'')
   				+ ' already used in APUI on APCo: ' + isnull(convert(varchar(3),@co), '')
   				+ ' Mth: ' + isnull(convert(varchar(8),@batchmth,1), '')
   				+ ' Seq: ' + isnull(convert(varchar(10),@batchseq), ''), @rcode = 1
   		goto bspexit
   		end
   	END --if @refunq = 2 
   
   
   
   -- -- -- MASTER VENDOR/SUBVENDOR LEVEL CHECKING
   if @refunq = 3		
   	BEGIN
   	-- -- -- get master vendor
   	select @mastervendor = MasterVendor
   	from bAPVM with (nolock) where VendorGroup=@vendorgroup and Vendor=@vendor
   	if @mastervendor is null	-- check and see if vendor is the mastervendor
   		begin
   		select @mastervendor=@vendor
   		end
   
   	-- -- -- check for AP Reference used by mastervendor/subvendors in AP Entry batch
   	select @batchseq = h.BatchSeq, @batchid2 = h.BatchId, @batchmth = h.Mth, @subvendor=h.Vendor
   	from bAPHB h with (nolock) join bAPVM m with (nolock) on h.VendorGroup=m.VendorGroup and h.Vendor=m.Vendor
   	where h.Co=@apco and h.VendorGroup=@vendorgroup and isnull(h.APRef,'') = isnull(@ref,'')
   	and (m.MasterVendor=@mastervendor or h.Vendor=@mastervendor)
   	if @@rowcount > 0
   		begin
   		select @msg = 'AP Reference ' + isnull(@ref,'')
   				+ ' already used in APHB on Mth: ' + isnull(convert(varchar(8),@batchmth,1), '')
   				+ ' BatchId: ' + isnull(convert(varchar(6),@batchid2), '')
   				+ ' Seq: ' + isnull(convert(varchar(4),@batchseq), '')
   				+ ' Vendor: ' + isnull(convert(varchar(8),@subvendor), ''),@rcode=1
   		goto bspexit
   		end
   
   	-- -- -- check for AP Reference used by mastervendor/subvendors in AP posted transactions
   	select @aptrans = h.APTrans, @batchmth = h.Mth, @subvendor=h.Vendor
   	from bAPTH h with (nolock) join bAPVM m with (nolock) on h.VendorGroup=m.VendorGroup and h.Vendor=m.Vendor
   	where (h.APCo=@apco and h.VendorGroup=@vendorgroup and isnull(h.APRef,'') = isnull(@ref,''))
   	and (m.MasterVendor=@mastervendor or h.Vendor=@mastervendor)
   	if @@rowcount > 0
   		begin
   		select @msg = 'AP Reference ' + isnull(@ref,'')
   				+ ' already used in APTH on Mth: ' + isnull(convert(varchar(8),@batchmth,1), '')
   				+ ' APTrans: ' + isnull(convert(varchar(10),@aptrans), '')
   				+ ' Vendor: ' + isnull(convert(varchar(8),@subvendor), ''),@rcode=1
   		goto bspexit
   		end
   
   	-- -- -- check for AP Reference used by mastervendor/subvendors in AP unapproved invoices
   	select @batchseq = h.UISeq, @batchmth = h.UIMth, @subvendor=h.Vendor
   	from bAPUI h with (nolock) join bAPVM m with (nolock) on h.VendorGroup=m.VendorGroup and h.Vendor=m.Vendor
   	where (h.APCo=@apco and h.VendorGroup=@vendorgroup and isnull(h.APRef,'') = isnull(@ref,''))
   	and (m.MasterVendor=@mastervendor or h.Vendor=@mastervendor)
   	if @@rowcount > 0
   		begin
   		select @msg = 'AP Reference ' + isnull(@ref,'')
   				+ ' already used in APUI on Mth: ' + isnull(convert(varchar(8),@batchmth,1), '')
   				+ ' UISeq: ' + isnull(convert(varchar(6),@batchseq), '')
   				+ ' Vendor: ' + isnull(convert(varchar(8),@subvendor), ''),@rcode=1
   		goto bspexit
   		end
   	END
   
   
   
   -- -- -- MASTER/SUBVENDOR AND CROSS COMPANY LEVEL CHECKING
   if @refunq = 4
   	BEGIN
   	-- -- -- get master vendor
   	select @mastervendor = MasterVendor
   	from bAPVM with (nolock) where VendorGroup=@vendorgroup and Vendor=@vendor
   	if @mastervendor is null	-- check and see if vendor is the mastervendor
   		begin
   		select @mastervendor=@vendor
   		end
   
   	-- -- -- check for AP Ref used in any AP Entry batch for master/subvendors in all companies by vendorgroup 
   	select @batchseq = h.BatchSeq, @batchid2 = h.BatchId, @batchmth = h.Mth, @subvendor = h.Vendor, @co = h.Co
   	from bAPHB h with (nolock) join bAPVM m with (nolock) on h.VendorGroup=m.VendorGroup and h.Vendor=m.Vendor
   	where h.VendorGroup=@vendorgroup and isnull(h.APRef,'') = isnull(@ref,'')
   	and (m.MasterVendor=@mastervendor or h.Vendor=@mastervendor)
   	if @@rowcount > 0
   		begin
   		select @msg = 'AP Reference ' + isnull(@ref,'')
   				+ ' already used in APHB on APCo: ' + isnull(convert(varchar(3),@co), '')
   				+ ' Mth: ' + isnull(convert(varchar(8),@batchmth,1), '')
   				+ ' BatchId: ' + isnull(convert(varchar(6),@batchid2), '')
   				+ ' Seq: ' + isnull(convert(varchar(4),@batchseq), '')
   				+ ' Vendor: ' + isnull(convert(varchar(8),@subvendor), ''), @rcode = 1
   		goto bspexit
   		end
   
   	-- -- -- Check Posted transactions
   	select @aptrans = h.APTrans, @batchmth = h.Mth, @subvendor = h.Vendor, @co = h.APCo
   	from bAPTH h with (nolock) join bAPVM m with (nolock) on h.VendorGroup=m.VendorGroup and h.Vendor=m.Vendor
   	where (h.VendorGroup=@vendorgroup and isnull(h.APRef,'') = isnull(@ref,''))
   	and (m.MasterVendor=@mastervendor or h.Vendor=@mastervendor)
   	if @@rowcount <> 0
   		begin
   		select @msg = 'AP Reference ' + isnull(@ref, '')
   				+ ' already used in APTH on APCo: ' + isnull(convert(varchar(3),@co), '')
   				+ ' Mth: ' + isnull(convert(varchar(8),@batchmth,1), '')
   				+ ' APTrans: ' + isnull(convert(varchar(10),@aptrans), '')
   				+ ' Vendor: ' + isnull(convert(varchar(10),@subvendor), ''), @rcode = 1
   		goto bspexit
   		end
   
   	-- -- -- check unapproved invoices
   	select @batchseq = h.UISeq, @batchmth = h.UIMth, @subvendor = h.Vendor, @co = h.APCo
   	from bAPUI h with (nolock) join bAPVM m on h.VendorGroup=m.VendorGroup and h.Vendor=m.Vendor
   	where (h.VendorGroup=@vendorgroup and isnull(h.APRef,'') = isnull(@ref,''))
   	and (m.MasterVendor=@mastervendor or h.Vendor=@mastervendor)
   	if @@rowcount <> 0
   		begin
   		select @msg = 'AP Reference ' + isnull(@ref, '') 
   				+ ' already used in APUI on APCo: ' + isnull(convert(varchar(3),@co), '')
   				+ ' Mth: ' + isnull(convert(varchar(8),@batchmth,1), '')
   				+ ' Invoice: ' + isnull(convert(varchar(4),@batchseq), '')
   				+ ' Vendor: ' + isnull(convert(varchar(10),@subvendor), ''), @rcode = 1
   		goto bspexit
   		end
   	END
   
   
   
   
   bspexit:
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspMSAPRefUnique] TO [public]
GO
