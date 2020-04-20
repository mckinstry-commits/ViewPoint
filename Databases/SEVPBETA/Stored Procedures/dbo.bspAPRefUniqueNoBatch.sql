SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPRefUniqueNoBatch    Script Date: 8/28/99 9:34:04 AM ******/
   CREATE       proc [dbo].[bspAPRefUniqueNoBatch]
   /***********************************************************
    * CREATED BY	: kf 10/24/97
    * MODIFIED BY	: kf 10/24/97
    *                kb 8/29/00 issue #10414
    *                GR 11/21/00 - changed datatype from bAPRef to bAPReference
    *			   MV 08/21/02 - # 18314 expand APRef checking for unapproved invoices
    *			      09/05/02	- #18314 - rej2 fix
    *				 09/18/02 - 18314 - warn or prevent for all levels enhancement
    *              kb 10/29/2 - issue #18878 - fix double quotes
    *		ES 03/12/04 - #23061 isnull wrapping
    *		TJL 03/24/09 - Issue #132867 - ANSI Null evaluating FALSE instead of TRUE
	*		MV 1/27/10 - #136440 - expand mastervendor/sub vendor APRef validation to 
	*						include vendors with no master/sub vendor relationship.
    *
    * USAGE:
    * validates AP Reference to see if it is unique. Is called
    * from APUnappInv.  Checks APHB and APTH
    *
    * INPUT PARAMETERS
    *   APCo      AP Co to validate against
    *   Vendor    Vendor
    *   APRef     Reference to Validate
    *
    * OUTPUT PARAMETERS
    *   @msg      message if Reference is not unique otherwise nothing
    *
    * RETURN VALUE
    *   0         success
    *   1         Failure  'if Fails Address, City, State and Zip are ''
    *****************************************************/
   
       (@apco bCompany = 0,@vendor bVendor, @ref bAPReference,
       @uimth bMonth, @uiseq varchar(20),@vendorgroup bGroup, @msg varchar(200) output )
   as
   
   set nocount on
   
   declare @rcode int, @apcorefunq tinyint, @apvmrefunq tinyint, @refunq tinyint,
   	@mastervendor bVendor, @subvendor bVendor, @co bCompany
   
   select @rcode = 0, @msg = 'AP Unique'
   
   -- get Ref uniqueness level from APVendMaster and APCompany 
   select @apvmrefunq = isnull(APRefUnqOvr,0) from bAPVM where VendorGroup=@vendorgroup and Vendor=@vendor
--   select @apvmrefunq = case when @apvmrefunq is null then 0 else @apvmrefunq end
   select @apcorefunq = APRefUnq from bAPCO where APCo=@apco 
   -- use override in bAPVM, else bAPCO 
   select @refunq = case when @apvmrefunq > 0 then @apvmrefunq else @apcorefunq end
   
   /** VENDOR & CO LEVEL CHECKING **/
   if @refunq = 1 	--or @refunq = 2 
   BEGIN
   --Check Batch transactions
   select @rcode=1, @msg='Reference: '+ isnull(@ref, '') + ' is also on an invoice in Mth: ' 
   	+ convert(varchar(2),Month(Mth))
	+ '/' + substring(convert(varchar(4),Year(Mth)),3,2) +
	 ' Batch Id: ' + isnull(convert(varchar(10),BatchId), '')
         from bAPHB
         where Co=@apco and Vendor=@vendor and APRef=@ref  --#23061
   	
   --Check Posted transactions
   select @rcode=1, @msg='Reference ' + isnull(@ref, '') + ' already on transaction ' 
   	+ isnull(convert(varchar(10), APTrans), '')
   	+ ' Mth: ' + convert(varchar(2),Month(Mth))
	+ '/' + substring(convert(varchar(4),Year(Mth)),3,2) 
     	from bAPTH
   	where APCo=@apco and Vendor=@vendor and APRef=@ref  --@23061
   	
   --Check other unapproved invoices
   if isnumeric(@uiseq)=1
       begin
       select @rcode=1, @msg=' Reference ' + isnull(@ref, '') + ' already on unapproved invoice: '
         + isnull(convert(varchar(10), UISeq), '')  + ' for month: ' + convert(varchar(2),Month(UIMth))
		 + '/' + substring(convert(varchar(4),Year(UIMth)),3,2)
         from bAPUI where APCo=@apco and Vendor=@vendor and APRef=@ref
         and (UIMth <> @uimth or UISeq <> @uiseq)  --#23061
   	goto bspexit
      end
   else
       begin
       select @rcode=1, @msg='Reference ' + isnull(@ref, '') + ' already on another unapproved invoice '
         + isnull(convert(varchar(10), UISeq), '')  + ' for month - ' + convert(varchar(2),Month(UIMth))
		 + '/' + substring(convert(varchar(4),Year(UIMth)),3,2)
         from bAPUI where APCo=@apco and Vendor=@vendor and APRef=@ref  --#23061
   	goto bspexit
       end
   
   END
   
   /** VENDOR BY CROSS COMPANY LEVEL CHECKING **/
   if @refunq = 2	--if @refunq = 3 
   BEGIN
   --Check Batch transactions
   select @rcode=1, @msg='Reference '+ isnull(@ref, '') + ' is also on an invoice in Company: ' 
   	+ isnull(convert(varchar(3),Co), '') + ' Mth: ' + convert(varchar(2),Month(Mth))
		 + '/' + substring(convert(varchar(4),Year(Mth)),3,2) 
		 + ' Batch Id: ' + isnull(convert(varchar(10),BatchId), '')
         from bAPHB
         where Vendor=@vendor and VendorGroup=@vendorgroup and APRef=@ref  --#23061
   	
   --Check Posted transactions
   select @rcode=1, @msg='Reference ' + isnull(@ref, '') + ' already in Company: ' 
   	+ isnull(convert(varchar(3),APCo) , '')
   	+ ' transaction: ' + isnull(convert(varchar(10), APTrans), '')
   	+ ' Mth: ' + convert(varchar(2),Month(Mth))
	+ '/' + substring(convert(varchar(4),Year(Mth)),3,2)
     	from bAPTH
   	where Vendor=@vendor and VendorGroup=@vendorgroup and APRef=@ref  --#23061
   	
   --Check other unapproved invoices
   if isnumeric(@uiseq)=1
       begin
       select @rcode=1, @msg=' Reference ' + isnull(@ref, '') + ' already on unapproved invoice: '
         + isnull(convert(varchar(10), UISeq), '')+ ' for Company: ' + isnull(convert(varchar(3),APCo), '')
   		 + ' Mth: ' + convert(varchar(2),Month(UIMth))
		 + '/' + substring(convert(varchar(4),Year(UIMth)),3,2)
         from bAPUI 
   
   	 where Vendor=@vendor and VendorGroup=@vendorgroup and APRef=@ref
   	 and (UIMth <> @uimth or UISeq <> @uiseq)   --#23061
   	goto bspexit
      end
   else
       begin
       select @rcode=1, @msg='Reference ' + isnull(@ref, '') + ' already on unapproved invoice: '
         + isnull(convert(varchar(10), UISeq), '')+ ' for Company: ' + isnull(convert(varchar(3),APCo), '')
   		 + ' Mth: ' + convert(varchar(2),Month(UIMth))
		 + '/' + substring(convert(varchar(4),Year(UIMth)),3,2)
         from bAPUI
   	 where Vendor=@vendor and VendorGroup=@vendorgroup and APRef=@ref  --#23061
   	goto bspexit
       end
   
   END
   
   /** MASTER VENDOR/SUBVENDOR LEVEL CHECKING **/
   if @refunq = 3	
   BEGIN
   -- get mastervendor
   select @mastervendor = MasterVendor from bAPVM where VendorGroup=@vendorgroup and Vendor=@vendor
   if @mastervendor is null	-- check and see if vendor is the mastervendor
   	begin
   	if exists (select * from bAPVM where VendorGroup=@vendorgroup and MasterVendor=@vendor)
   		begin
   		select @mastervendor=@vendor
   		end
   	end
   --Check Batch transactions
   select @rcode=1, @msg='Reference '+ isnull(@ref, '') + ' is also on an invoice in Mth: ' 
   	+ convert(varchar(2),Month(Mth))
	+ '/' + substring(convert(varchar(4),Year(Mth)),3,2)
	+ ' Batch Id: ' + isnull(convert(varchar(10),h.BatchId), '')
   	+ ' Vendor: ' + isnull(convert(varchar(10),h.Vendor), '')
        from APHB h join APVM m on h.VendorGroup=m.VendorGroup and h.Vendor=m.Vendor
   	where h.Co=@apco and h.VendorGroup=@vendorgroup and isnull(APRef,'') = isnull(@ref,'')
   	and (m.MasterVendor=@mastervendor or h.Vendor=@mastervendor or h.Vendor=@vendor)  --#23061
   	
   --Check Posted transactions
   select @rcode=1, @msg='Reference ' + isnull(@ref, '') + ' already on transaction: ' 
   	+ isnull(convert(varchar(10), APTrans), '')
   	+ ' Mth: ' + convert(varchar(2),Month(Mth))
	+ '/' + substring(convert(varchar(4),Year(Mth)),3,2)
	+ ' Vendor: ' + isnull(convert(varchar(10),h.Vendor), '')
     	from bAPTH h join bAPVM m on h.VendorGroup=m.VendorGroup and h.Vendor=m.Vendor
   	where (h.APCo=@apco and h.VendorGroup=@vendorgroup and isnull(APRef,'') = isnull(@ref,''))
   	and (m.MasterVendor=@mastervendor or h.Vendor=@mastervendor or h.Vendor=@vendor)  --#23061
   	
   --Check other unapproved invoices
   if isnumeric(@uiseq)=1
       begin
       select @rcode=1, @msg=' Reference ' + isnull(@ref, '') + ' already on unapproved invoice: '
        + isnull(convert(varchar(10), UISeq), '')  + ' for Mth: ' + convert(varchar(2),Month(UIMth))
		+ '/' + substring(convert(varchar(4),Year(UIMth)),3,2)
   		+ ' Vendor: ' + isnull(convert(varchar(10),h.Vendor), '')
        from bAPUI h join bAPVM m on h.VendorGroup=m.VendorGroup and h.Vendor=m.Vendor
   	where (h.APCo=@apco and h.VendorGroup=@vendorgroup and isnull(APRef,'') = isnull(@ref,''))
   	and (m.MasterVendor=@mastervendor or h.Vendor=@mastervendor or h.Vendor=@vendor)
   	and (UIMth <> @uimth or UISeq <> @uiseq)  --#23061
   	goto bspexit
      end
   else
       begin
       select @rcode=1, @msg='Reference ' + isnull(@ref, '') + ' already on unapproved invoice: '
         + isnull(convert(varchar(10), UISeq), '')  + ' for Mth: ' + convert(varchar(2),Month(UIMth))
		 + '/' + substring(convert(varchar(4),Year(UIMth)),3,2)
   		 + ' Vendor: ' + isnull(convert(varchar(10),h.Vendor), '')
         from bAPUI h join bAPVM m on h.VendorGroup=m.VendorGroup and h.Vendor=m.Vendor
   	where (h.APCo=@apco and h.VendorGroup=@vendorgroup and isnull(APRef,'') = isnull(@ref,''))
   	and (m.MasterVendor=@mastervendor or h.Vendor=@mastervendor or h.Vendor=@vendor)  --#23061
   	goto bspexit
       end
   
   END
   
   /* MASTER/SUBVENDOR AND CROSS COMPANY LEVEL CHECKING */
   if @refunq = 4		--if @refunq = 5 
   BEGIN
   select @mastervendor = MasterVendor from bAPVM where VendorGroup=@vendorgroup and Vendor=@vendor
   if @mastervendor is null	-- check and see if vendor is the mastervendor
   	begin
   	if exists (select * from bAPVM where VendorGroup=@vendorgroup and MasterVendor=@vendor)
   		begin
   		select @mastervendor=@vendor
   		end
   	end
   --Check Batch transactions
   select @rcode=1, @msg='Reference '+ isnull(@ref, '') + ' is also on an invoice in Company: ' 
   	+ isnull(convert(varchar(3),Co), '') + ' in Mth: ' + convert(varchar(2),Month(Mth))
	+ '/' + substring(convert(varchar(4),Year(Mth)),3,2)
	+ ' Batch Id: ' + isnull(convert(varchar(10),h.BatchId), '')
   	+ ' Vendor: ' + isnull(convert(varchar(10),h.Vendor), '')
        from APHB h join APVM m on h.VendorGroup=m.VendorGroup and h.Vendor=m.Vendor
   	where h.VendorGroup=@vendorgroup and isnull(APRef,'') = isnull(@ref,'')
   	and (m.MasterVendor=@mastervendor or h.Vendor=@mastervendor or h.Vendor=@vendor)  --#23061
   	
   --Check Posted transactions
   select @rcode=1, @msg='Reference ' + isnull(@ref, '') + ' already on transaction: ' 
   	+ isnull(convert(varchar(10), APTrans), '') + ' Mth: ' + convert(varchar(2),Month(Mth))
	+ '/' + substring(convert(varchar(4),Year(Mth)),3,2)
	+ ' Vendor: ' + isnull(convert(varchar(10),h.Vendor), '')
   	+ ' Company: ' + isnull(convert(varchar(3),APCo), '')
     	from bAPTH h join bAPVM m on h.VendorGroup=m.VendorGroup and h.Vendor=m.Vendor
   	where (h.VendorGroup=@vendorgroup and isnull(APRef,'') = isnull(@ref,''))
   	and (m.MasterVendor=@mastervendor or h.Vendor=@mastervendor or h.Vendor=@vendor)  --#23061
   	
   
   --Check other unapproved invoices
   if isnumeric(@uiseq)=1
       begin
       select @rcode=1, @msg=' Reference ' + isnull(@ref, '') + ' already on unapproved invoice: '
        + isnull(convert(varchar(10), UISeq), '')  + ' for Mth: ' + convert(varchar(2),Month(UIMth))
		+ '/' + substring(convert(varchar(4),Year(UIMth)),3,2)
   		+ ' Vendor: ' + convert(varchar(10),h.Vendor) + ' Company: ' + convert(varchar(3),APCo)
        from bAPUI h join bAPVM m on h.VendorGroup=m.VendorGroup and h.Vendor=m.Vendor
   	where (h.VendorGroup=@vendorgroup and isnull(APRef,'') = isnull(@ref,''))
   	and (m.MasterVendor=@mastervendor or h.Vendor=@mastervendor or h.Vendor=@vendor)
   	and (UIMth <> @uimth or UISeq <> @uiseq)    				--#23061
   	goto bspexit
      end
   else
       begin
       select @rcode=1, @msg='Reference ' + isnull(@ref, '') + ' already on unapproved invoice: '
         + isnull(convert(varchar(10), UISeq), '') + ' for Mth: ' + convert(varchar(2),Month(UIMth))
		 + '/' + substring(convert(varchar(4),Year(UIMth)),3,2)
   		 + ' Vendor: ' + convert(varchar(10),h.Vendor)+ ' Company: ' + convert(varchar(3),APCo)
         from bAPUI h join bAPVM m on h.VendorGroup=m.VendorGroup and h.Vendor=m.Vendor
   	where (h.VendorGroup=@vendorgroup and isnull(APRef,'') = isnull(@ref,''))
   	and (m.MasterVendor=@mastervendor or h.Vendor=@mastervendor or h.Vendor=@vendor)			--#23061
   	goto bspexit
       end
   
   END
   
   bspexit:
   	return @rcode



GO
GRANT EXECUTE ON  [dbo].[bspAPRefUniqueNoBatch] TO [public]
GO
