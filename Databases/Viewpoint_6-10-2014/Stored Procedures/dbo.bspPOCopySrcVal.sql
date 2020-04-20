SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPOCopySrcVal   Script Date: 03/12/2003 ******/
   CREATE proc [dbo].[bspPOCopySrcVal]
   /***********************************************************
    * Created By:	GF 03/12/2003
    * Modified By:  TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
    *
    *
    *
    * USAGE:
    * validates source PO to insure not exist in POHB, POIB batch. Returns needed info for copy.
    *
    * INPUT PARAMETERS
    *  POCo      PO Co to validate against
    *  PO        PO to Validate
    *  Mth       Batch Month
    *  BatchId   Batch ID
    *
    * OUTPUT PARAMETERS
    *	@vendor
    *	@name
    *	@jcco
    *	@job
    *	@jobdesc
    *	@inco
    *	@location
    *	@locdesc
    *	@shiploc
    *	@pohdud_flag	Flag for POHD user memos. 'Y' if ud column exists in POHD
    *	@poitud_flag	Flag for POIT user memos. 'Y' if ud column exists in POIT
    *	@poitwotypes	Flag for existing POIT WO Items. 'Y' if exist.
    *	@poiteqtypes	Flag for existing POIT Eq Items. 'Y' if exist.
    *	@woemco			Source WO EM company used as default.
    *	@wo				Source WO used as default.
    *	@eqemco			Source Equipment EM company used as default.
    *	@equip			Source Equipment used as default.
    *	
    *  @msg      error message if error occurs otherwise Description of PO
    * RETURN VALUE
    *   0         success
    *   1         Failure  'if Fails Address, City, State and Zip are ''
    *****************************************************/
   (@poco bCompany = Null, @po varchar(30) = null, @mth bMonth = null, @batchid bBatchID = null,
    @vendor bVendor output, @name varchar(60) output, @jcco bCompany output, @job bJob output,
    @jobdesc varchar(30) output, @inco bCompany output, @location bLoc output, @locdesc varchar(30) output,
    @shiploc varchar(10) output, @pohdud_flag bYN output, @poitud_flag bYN output, @poitwotypes bYN output,
    @poiteqtypes bYN output, @woemco bCompany output, @wo bWO output, @eqemco bCompany output,
    @equip bEquip output, @desc bDesc output, @orderedby varchar(10) output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @validcnt int, @vendorgroup bGroup, @status tinyint
   
   select @rcode = 0, @pohdud_flag = 'N', @poitud_flag = 'N', @poitwotypes = 'N', @poiteqtypes = 'N'
   
   if @poco is null
   	begin
   	select @msg = 'Missing PO Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @po is null
   	begin
   	select @msg = 'Missing Source PO!', @rcode = 1
   	goto bspexit
   	end
   
   
   -- validate source PO not used in another PO batch
   select @rcode=1, @msg='PO '+ @po + ' is in use by batch Month:' + substring(convert(varchar(12),Mth,3),4,5) + ' ID:' + convert(varchar(10),BatchId)
   from bPOHB with (nolock) where Co=@poco and PO=@po
   if @@rowcount <> 0 goto bspexit
   
   -- validate source PO
   select @vendorgroup=VendorGroup, @vendor=Vendor, @jcco=JCCo, @job=Job, @inco=INCo, @location=Loc,
   	   @shiploc=ShipLoc, @msg=Description, @status=Status, @desc=Description, @orderedby=OrderedBy
   from bPOHD where POCo=@poco and PO=@po
   if @@rowcount = 0
   	begin
   	select @msg = 'PO ' + @po + ' missing in POHD!', @rcode = 1
   	goto bspexit
   	end
   if @status = 3
   	begin
   	select @msg = 'PO ' + @po + ' status is pending!', @rcode = 1
   	goto bspexit
   	end
   
   -- get vendor info
   select @name=Name from bAPVM with (nolock) where VendorGroup=@vendorgroup and Vendor=@vendor
   
   -- get Job info
   select @jobdesc=Description from bJCJM with (nolock) where JCCo=@jcco and Job=@job
   
   -- get Location info
   select @locdesc=Description from bINLM with (nolock) where INCo=@inco and Loc=@location
   
   -- set the user memo flags for the tables that have user memos
   if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bPOHD'))
   	select @pohdud_flag = 'Y'
   if exists(select name from syscolumns where name like 'ud%' and id = object_id('dbo.bPOIT'))
   	select @poitud_flag = 'Y'
   
   -- check for work order items
   select top 1 @woemco=PostToCo, @wo=WO
   from bPOIT with (nolock) where POCo=@poco and PO=@po and ItemType=5
   if @@rowcount <> 0 select @poitwotypes = 'Y'
   -- check for equipment items
   select top 1 @eqemco=PostToCo, @equip=Equip
   
   
   from bPOIT with (nolock) where POCo=@poco and PO=@po and ItemType=4
   if @@rowcount <> 0 select @poiteqtypes = 'Y'
   
   
   
   
   bspexit:
       if @rcode<>0 select @msg=@msg + char(13) + char(10) + '[bspPOCopySrcVal]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOCopySrcVal] TO [public]
GO
