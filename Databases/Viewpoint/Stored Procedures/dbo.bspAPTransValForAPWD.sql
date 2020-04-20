SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspAPTransValForAPWD]
 /***********************************************************
 * CREATED BY: MV 11/2/01
 * MODIFIED By: kb 6/24/2 - issue #14160 for notes update
 			kb 6/24/2 - issue #14160 for adding vendor to validation
 *			kb 7/30/2 - issue #18141 - allow processed prepaids
 *			kb 7/31/2 - issue #18149 - compliance checking
 *			GG 09/20/02 - #18522 ANSI nulls
 *			MV 01/15/03 - all invoice compliance - #17821
 *			MV 12/29/04 - #26479 - check if trans already in a workfile
 *			MV 02/07/05 - #27041 - check if trans in another users workfile
 *			DANF 12/19/2005 - #120056 (SQL 9.0 2005)
 *			MV 12/19/06 - #28267 return vendor, InvDate, SortName, CMCo
 *			MV 01/23/07 - #28267 return pay address fields
 *			MV 01/29/07 - #28267 don't validate vendor
 *			MV 04/24/07 - #122337 set APWH complied, PayYN based on Complied
 *			MV 05/29/07 - #28267 return UniqueAttachId and SeparatePayYN
 *			MV 03/13/08 - #127347 - changed bState to varchar(4)
 *			TJL 03/25/08 - #127347 Intl addresses 
 *			DC 2/11/09 - #132186 - Add an APRef field in SL Compliance associated to AP Ref in Accounts payable
 *			GP 6/28/10 - #135813 change bSL to varchar(30) 
 *			TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
 *
 * USAGE:
 * Validates AP Trans # for AP Workfile Detail.  Transaction
 * must exist in the specified month.
 *
 * INPUT PARAMETERS
 *   @apco	AP Company
 *   @mth	Month for transaction
 *   @aptrans	AP Transaction to validate from AP Transaction Header
 *
 * OUTPUT PARAMETERS
 *   @transdesc Transaction description
 *   @msg 	If Error, return error message.
 * RETURN VALUE
 *   0   success
 *   1   fail
 ****************************************************************************************/
  (@apco bCompany, @mth bDate, @aptrans bTrans, @vendorgroup bGroup, @vendor bVendor = null, 
   @payyn bYN output,@unpaidamt bDollar output, @payamt bDollar output,@discdate bDate output,
 	@duedate bDate output, @paycontrol varchar (10) output, @paymethod varchar (1) output,
 	@cmco bCompany output, @cmacct bCMAcct output, @holdyn bYN output,@supplier bVendor output,
 	@apref bAPReference output, @discoffered bDollar output, @disctaken bDollar output,
 	@transnotes varchar(8000) output, @complied bYN output, @vendorout bVendor output,@invdateout bDate output,
	@sortname varchar(15) output, @payaddrseq int output, @payoverrideyn bYN output,@payname varchar(60) output,
	@payaddtlinfo varchar(60) output, @payaddress varchar(60) output, @paycity varchar(30) output,
	@paystate varchar(4) output, @payzip bZip output, @paycountry char(2) output, @separatepayyn bYN output,
	@attachid uniqueidentifier output, @msg varchar(90) output)

 as
 
 set nocount on
 
 declare @rcode int, @source varchar(10), @validcnt int, @validcnt2 int,
 	@inusebatchid int, @openyn bYN, @prepaidyn bYN, @transvendor bVendor,
 	@transvendorgroup bGroup, @invdate bDate,@apline int, @linetype tinyint,
    @rc tinyint, @sl varchar(30), @po varchar(30),@procprepaidyn bYN, @errmsg varchar(90),
	@POSLComply bYN,@DontAllowPaySL bYN,@DontAllowPayPO bYN,@DontAllowPayAllinv bYN,
	@VendorComply bYN
   
 
 select @rcode = 0
 
 if @apco = 0
 	begin
 	select @msg = 'Missing AP Company#', @rcode=1
 	goto bspexit
 	end
 
 -- get APCO flags
	 select @DontAllowPaySL = SLAllowPayYN,@DontAllowPayPO = POAllowPayYN,
	 @DontAllowPayAllinv = AllAllowPayYN from APCO where APCo=@apco 

 if @@rowcount = 0
 	begin
     select @msg = 'Invalid AP Company!', @rcode = 1
     goto bspexit
     end
 
 if @mth is null
 	begin
 	select @msg = 'Missing Expense Month' , @rcode=1
 	goto bspexit
 	end
 
 /* validate trans # */ 
 select @inusebatchid=InUseBatchId,@openyn=OpenYN,@prepaidyn=PrePaidYN, 
   @transvendor = Vendor, @transvendorgroup = VendorGroup, @invdate = InvDate,
   @procprepaidyn = PrePaidProcYN, 
	@msg = Description,@discdate=DiscDate, @duedate=DueDate, @paycontrol=PayControl,
 	@paymethod=PayMethod, @apref=APRef, @cmco=CMCo, @cmacct=CMAcct, @transnotes = Notes, -- issue  #120056
	@payaddrseq=AddressSeq, @payoverrideyn = PayOverrideYN,@payname = PayName,
	@payaddtlinfo = PayAddInfo, @payaddress = PayAddress, @paycity = PayCity,
	@paystate = PayState, @payzip= PayZip, @paycountry = PayCountry, @separatepayyn = SeparatePayYN,@attachid = UniqueAttchID
 	from APTH WITH (NOLOCK) where APCo=@apco and Mth=@mth and APTrans=@aptrans 
 if @@rowcount = 0
 	begin
 	select @msg = 'Invalid transaction!', @rcode=1
 	goto bspexit
 	end
-- if @vendor is not null
-- 	begin
-- 	if @transvendor <> @vendor or @transvendorgroup <> @vendorgroup
-- 		begin
-- 		select @msg = 'Transaction posted to a different vendor', @rcode = 1
-- 		goto bspexit
-- 		end
--	else
--		select @vendorout = @vendor
--		select @sortname = (select SortName from APVM where VendorGroup=@vendorgroup and Vendor=@vendor)
-- 	end
 else
	begin
	select @vendorout = @transvendor
	select @sortname = (select SortName from APVM where VendorGroup=@vendorgroup and Vendor=@vendorout)
	end
 
 if @inusebatchid is not null	
 	begin
 	select @msg = 'Transaction already in use!', @rcode=1
 	goto bspexit
 	end
 
 if @openyn = 'N'
 	begin
 	select @msg = 'Transaction is not open to pay!', @rcode=1
 	goto bspexit
 	end
 
 if @prepaidyn = 'Y' and @procprepaidyn = 'N' --issue #18141
 	begin
 	select @msg = 'Transaction is prepaid!', @rcode=1
 	goto bspexit
 	end
 
 if exists (select 1 from bAPWH with (nolock) where APCo=@apco and Mth=@mth and APTrans=@aptrans and UserId <> SYSTEM_USER) 
 	begin
 	select @msg = 'Transaction is in another Workfile!', @rcode=1
 	goto bspexit
 	end
 
 
 /* get values to return */
 select @invdateout = @invdate
 select top 1 @supplier=l.Supplier from bAPTL l with (nolock)
 where l.APCo=@apco and l.Mth=@mth and l.APTrans=@aptrans and isnull(l.Supplier, '') <> '' -- issue  #120056
 
 if not exists (select 1 from bAPWD WITH (NOLOCK)where APCo=@apco and Mth=@mth and APTrans=@aptrans and UserId = SYSTEM_USER)
 	begin
 	select @unpaidamt = sum(Amount) from APTD WITH (NOLOCK) where APCo=@apco and Mth=@mth and APTrans=@aptrans
 		and Status=2
 	
 	select @payamt = sum(Amount), @disctaken = sum(DiscTaken),
   		@discoffered = sum(DiscOffer) from APTD WITH (NOLOCK) where APCo=@apco and Mth=@mth and 
 		APTrans=@aptrans and Status=1
 	
 	select @payamt = isnull(@payamt,0), @disctaken = isnull(@disctaken,0),
   	  @discoffered = isnull(@discoffered,0), @unpaidamt = isnull(@unpaidamt,0)
 
 	-- set the hold and pay flags
 	select @validcnt = (select count (*) from APTD WITH (NOLOCK) where APCo=@apco and Mth=@mth and APTrans=@aptrans and Status <=2)
 	select @validcnt2 = (select count (*) from APTD WITH (NOLOCK) where APCo=@apco and Mth=@mth and APTrans=@aptrans and Status = 2)
 	if @validcnt = @validcnt2 -- all detail recs are on hold
 		begin
 		select @holdyn = 'Y', @payyn = 'N'
 		end
 	else
 		begin
 		select @holdyn = 'N', @payyn = 'Y'
 		end
 	end
 else 
 	begin
 	select @unpaidamt = sum (d.Amount) from bAPWD d WITH (NOLOCK) 
 	  where d.APCo=@apco and d.Mth=@mth and d.APTrans=@aptrans 
 	  and (d.HoldYN='Y' or d.PayYN='N')
 	
 	select @payamt = sum (d.Amount),@disctaken = sum(d.DiscTaken),
   		@discoffered = sum(d.DiscOffered) from bAPWD d WITH (NOLOCK) where 
 		d.APCo=@apco and d.Mth=@mth and d.APTrans=@aptrans and d.PayYN='Y'
 	select @payamt = isnull(@payamt,0), @disctaken = isnull(@disctaken,0),
   	  @discoffered = isnull(@discoffered,0), @unpaidamt = isnull(@unpaidamt,0)
 	end
 
 -- Check Vendor compliance 
 select @VendorComply = 'Y'
 exec @rc = bspAPComplyCheckAll @apco,@transvendorgroup, @transvendor, @invdate,@VendorComply output
 			   	
 -- check PO/SL compliance
 select @POSLComply = 'Y'
 select @apline = min(APLine) from APTL WITH (NOLOCK) where APCo = @apco and Mth = @mth 
   and APTrans = @aptrans and (LineType=6 or LineType=7)
 while @apline is not null
	begin
	select @linetype = LineType from APTL WITH (NOLOCK)
	  where APCo = @apco and Mth = @mth and APTrans = @aptrans and APLine = @apline
	if @linetype=6 or @linetype = 7
	 		begin
      		exec @rc = bspAPComplyCheck @apco, @mth, @aptrans, 
			  @apline, @invdate, @apref, @errmsg output  --DC #132186
	   		if @rc <> 0	
				begin 
				select @POSLComply = 'N', @payyn = 'N' 
				end				
			end			 
	select @apline = min(APLine) from APTL WITH (NOLOCK) where APCo = @apco and Mth = @mth 
	  and APTrans = @aptrans and (LineType=6 or LineType=7) and APLine > @apline
	end

-- set complied flag and payyn flag
	select @complied = case @VendorComply when 'N' then 'N' else @POSLComply end
	if (@VendorComply = 'N' and @DontAllowPayAllinv = 'Y') or
		(@POSLComply = 'N' and @linetype = 6 and @DontAllowPayPO = 'Y') or
		(@POSLComply = 'N' and @linetype = 7 and @DontAllowPaySL = 'Y') 
		begin
		select @payyn='N'
		end	
 
 bspexit:
 	return @rcode




GO
GRANT EXECUTE ON  [dbo].[bspAPTransValForAPWD] TO [public]
GO
