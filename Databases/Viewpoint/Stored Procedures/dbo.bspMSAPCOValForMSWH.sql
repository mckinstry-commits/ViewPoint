SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************/
   CREATE   proc [dbo].[bspMSAPCOValForMSWH]
   /*************************************
   * Created By:   GF 12/02/2004
   * Modified By:  DANF 07/19/07 Changed reference of DDUP table to view
   *
   *
   *
   * validates AP Company number selected from MS Hauler Payments. Must be a valid AP Company
   * from bAPCo and the VendorGroup for this company must match the vendor group for MSCO.APCo
   * and vendor group for any existing rows in MSWH. Also the APCO.GLExpInterfaceLvl must be the
   * same between companies.
   *
   *
   *
   * Pass:
   * MS Company
   * AP Company
   * UserName
   *
   * Success returns:
   * VendorGroup		AP Vendor Group
   * PayCategoryYN		AP Company Using Pay Category Flag
   * OverridePaytype	AP Company override pay type flag
   * ExpPayType		AP Expense Pay Type
   * PayCategory		AP Pay Category
   * CMCO				AP Company CMCo
   * CMACCT			AP Company CM ACCT
   *
   *	0 and Company name from HQCo
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany = 0, @apco bCompany = 0, @mth bMonth = null, @batchid bBatchID = null, 
    @userid bVPUserName = null, @vendorgroup bGroup output, @paycategoryyn bYN output, 
    @overridepaytype bYN output, @exppaytype tinyint output, @paycategory int output,
    @cmco bCompany output, @cmacct bGLAcct output, @aprefunqyn bYN output,
    @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @ms_vendorgroup bGroup, @ap_vendorgroup bGroup, @apcopaycategory int,
   		@ms_glexpinterfacelvl tinyint, @ap_glexpinterfacelvl tinyint, @ms_apco bCompany
   
   select @rcode = 0
   
   if @msco = 0
   	begin
   	select @msg = 'Missing MS Company number', @rcode = 1
   	goto bspexit
   	end
   
   if @apco = 0
   	begin
   	select @msg = 'Missing AP Company number', @rcode = 1
   	goto bspexit
   	end
   
   -- -- -- get MS AP Vendor group from HQCO and validate
   select @ms_vendorgroup = bHQCO.VendorGroup, @ms_apco = bMSCO.APCo
   from bMSCO join bHQCO on bHQCO.HQCo=bMSCO.APCo
   where bMSCO.MSCo=@msco
   if @@rowcount = 0
   	begin
   	select @msg = 'Invalid AP Company assigned to MS Company, not found in HQ.', @rcode = 1
   	goto bspexit
   	end
   
   -- -- -- get MS AP GL Expense Interface level
   select @ms_glexpinterfacelvl = GLExpInterfaceLvl
   from bAPCO where APCo=@ms_apco
   if @@rowcount = 0
   	begin
   	select @msg = 'Unable to retrieve data from AP Company.', @rcode = 1
   	goto bspexit
   	end
   
   -- -- -- get AP Vendor Group from HQCO and validate company
   select @ap_vendorgroup = bHQCO.VendorGroup, @paycategoryyn = bAPCO.PayCategoryYN,
   		@overridepaytype = bAPCO.OverridePayType, @exppaytype = bAPCO.ExpPayType,
   		@apcopaycategory = bAPCO.PayCategory, @cmco = bAPCO.CMCo, @cmacct = bAPCO.CMAcct,
   		@ap_glexpinterfacelvl = bAPCO.GLExpInterfaceLvl, @aprefunqyn = bAPCO.APRefUnqYN
   from bAPCO join bHQCO on bHQCO.HQCo=bAPCO.APCo
   where bAPCO.APCo=@apco
   if @@rowcount = 0
   	begin
   	select @msg = 'Not a valid AP Company', @rcode = 1
   	goto bspexit
   	end
   
   -- -- -- match vendor groups
   if @ap_vendorgroup <> @ms_vendorgroup
   	begin
   	select @msg = 'AP Vendor Group does not match MS AP Vendor Group.', @rcode = 1
   	goto bspexit
   	end
   
   -- -- -- match GL Expense Interface levels
   if @ap_glexpinterfacelvl <> @ms_glexpinterfacelvl
   	begin
   	select @msg = 'AP GL Expense Interface Level: ' + convert(varchar(3),@ap_glexpinterfacelvl) +
   				  ' does not match the MS AP GL Expense Interface Level: ' + convert(varchar(3),@ms_glexpinterfacelvl) + ' !'
   	select @rcode = 1
   	goto bspexit
   	end
   
   -- -- -- check existing rows in MSWH to make sure that the vendor group matches @ap_vendorgroup
   -- -- -- do not want to mix vendor groups
   if exists(select top 1 1 from bMSWH where Co=@msco and Mth=@mth and BatchId=@batchid
   				and VendorGroup<>@ap_vendorgroup)
   	begin
   	select @msg = 'MSWH Vendor Group does not match Vendor Group for AP Company.', @rcode = 1
   	goto bspexit
   	end
   
   set @vendorgroup = @ap_vendorgroup
   
   
   -- get paytypes from bAPPC if using pay category
   if @paycategoryyn='Y'
   	begin
   	--User Profile default Pay Category
   	if @userid is not null
   		begin
   		select @paycategory = PayCategory from dbo.DDUP WITH (NOLOCK)
      	where rtrim(ltrim(VPUserName))=rtrim(ltrim(@userid))
   		if isnull(@paycategory,0)> 0
   			begin
   			select @exppaytype=ExpPayType from bAPPC WITH (NOLOCK) 
   			where APCo=@apco and PayCategory=@paycategory 
   			if @@rowcount = 0
   				set @paycategory = null
   			else
   				goto bspexit
   			end
   		end
   	else
   		begin
   		set @paycategory = null --if DDUP returns 0 paycategory clear it
   		end
    		
   	--Pay Category default in bAPCO 
   	if isnull(@apcopaycategory,0)> 0
   		begin
   		select @exppaytype=ExpPayType from bAPPC WITH (NOLOCK)
   		where APCo=@apco and PayCategory=@apcopaycategory 
   		if @@rowcount = 0
   			set @paycategory = null
   		else
   			set @paycategory=@apcopaycategory
   		end
   	else
   		begin
   		set @paycategory = null --if APCO returns 0 paycategory clear it
   		end
    	end
    
   
   
   
   
   
   
   
   bspexit:
       if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSAPCOValForMSWH] TO [public]
GO
