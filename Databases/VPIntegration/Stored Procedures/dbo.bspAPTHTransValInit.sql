SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPTHTransValInit    Script Date: 8/28/99 9:34:06 AM ******/
   CREATE   proc [dbo].[bspAPTHTransValInit]
   /***********************************************************
    * CREATED BY: KF 10/14/97
    * MODIFIED By : KF 10/14/97
    *                  GG 08/25/99 Removed code to return transaction amounts,
    *                      added Batch month and id as inputs
    *               EN 1/22/00 - expand dimension of @payname, @pbname & @name and include AddnlInfo in validation
    *               EN 6/7/00 - issue #7000 rejection (5/23/2000); added code so if the trans is added to
    *                          payment batch in the grid and the cmacct for the trans is null
    *                          it uses the cmacct from the payment header
    *               GR 11/21/00 - changed datatype from bAPRef to bAPReference
    *               kb 7/25/1 - issue #13670
    *               kb 1/22/2 - issue #15845
    *               kb 10/29/2 - issue #18878 - fix double quotes
    *				ES 03/12/04 - #23061 isnull wrapping
    *				MV #120446 - use vendor addr defaults if no payoverride and addressseq is null
	*				MV 09/17/07 - #27759 - CMRef is OK for ChkType 'M' - Manual
	*				MV 03/13/08 - #127347 - International addresses
	*				DC 02/11/09 - #132186 - Add an APRef field in SL Compliance associated to AP Ref in Accounts payable
	*				MV 10/27/09 - #136019 - don't validate country unless both transaction/vendor and batch seq have a country value.
	*				LS 06/14/10 - #139418 - Allow user to pay older transactions where APTH.PayCountry is null
    *				KK/EN 03/21/12 - B-08103 - Adding validation for CM Account for all pay methods
	*				EN 04/25/12 - TK-13965 - Use APVM address for Credit Service transactions			
	*				KK 04/27/12	- B-09140 - Added back Add'l Info to address for CS
	*				EN 5/2/2012 - B-09241/TK-14618 Correction to fix on 3/21/12 ... moved the added validation to not block other important functions
    *
    * USAGE:
    * Called from the AP Payment Edit program to validate AP Transaction #
    *
    * INPUT PARAMETERS
    * @co              AP Company
    * @mth             Payment Batch month
    * @batchid         Batch ID#
    * @batchseq        Payment Batch Sequence
    * @expmth          Expense month for transaction
    * @aptrans         AP Transaction
    *
    * OUTPUT PARAMETERS
    * @apref           AP Reference
    * @description     Transaction description
    * @invdate         Invoice date
    * @errmsg          error message, or warning if posted to a PO or SL 'out of compliance'
    *  
    * RETURN VALUE
    *   0   success
    *   1   fail
    ****************************************************************************************/
    	(@co bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @batchseq int = null,
        @expmth bMonth, @aptrans bTrans = null, @dfltcmacct bCMAcct,
        @apref bAPReference output, @description bDesc output,
        @invdate bDate output, @nocmacct bYN output, @prepaidyn as bYN output, 
		@errmsg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int, @openamt bDollar, @source bSource, @pocomplianceyn bYN,
   @slcomplianceyn bYN, @apline smallint, @apseq tinyint, @linetype tinyint, @rc int
   
   -- APTH declares
   declare @vendorgroup bGroup, @vendor bVendor, @paymethod char(1), @cmco bCompany, @cmacct bCMAcct,
   @prepaidprocyn bYN, @payoverrideyn bYN, @payname varchar(60), @payaddinfo varchar(60), @payaddress varchar(60),
   @paycity varchar(30), @paystate varchar(4), @payzip bZip, @openyn bYN, @inusemth bMonth, @inusebatchid bBatchID,
   @inpaycontrol bYN, @addtladdrseq int,@paycountry char(2)
   
   -- APPB declares
   declare @pbcmco bCompany, @pbcmacct bCMAcct, @pbpaymethod char(1), @pbcmref bCMRef, @pbchktype varchar(1),
   @pbvendorgroup bGroup, @pbvendor bVendor, @pbname varchar(60), @pbaddinfo varchar(60), @pbaddress varchar(60),
   @pbcity varchar(30), @pbstate varchar(4), @pbzip bZip, @pbsupplier bVendor,@pbcountry char(2)
   
   -- APVM declares
   declare @name varchar(60), @addnlinfo varchar(60), @address varchar(60), @city varchar(30), @state varchar(4),
	 @zip bZip, @country char(2)
   
   select @rcode = 0
   
   -- get AP Transaction info
   select @vendorgroup = VendorGroup, @vendor = Vendor, @apref = APRef,
       @description = Description, @invdate = InvDate, @paymethod = PayMethod,
       @cmco = CMCo, @cmacct = CMAcct, @prepaidyn = PrePaidYN, @prepaidprocyn = PrePaidProcYN,
       @payoverrideyn = PayOverrideYN, @payname = PayName, @payaddinfo = PayAddInfo, @payaddress = PayAddress,
       @paycity = PayCity, @paystate = PayState, @payzip = PayZip, @openyn = OpenYN, @paycountry=PayCountry,
       @inusemth = InUseMth, @inusebatchid = InUseBatchId, @inpaycontrol = InPayControl, @addtladdrseq = AddressSeq
   from bAPTH
   where APCo = @co and Mth = @expmth and APTrans = @aptrans
   if @@rowcount=0
    	begin
    	select @errmsg = 'Transaction not on file!'
		select @rcode=1
    	goto bspexit
    	end
   if @prepaidyn = 'Y' and @prepaidprocyn = 'N'
    	begin
    	select @errmsg = 'Unprocessed PrePaid Transactions cannot be initialized here.', @rcode=1
    	goto bspexit
    	end
   if (@inusemth is not null and @inusemth <> @mth) 
		begin
		select @source = Source from bHQBC
    	where Co = @co and BatchId = @inusebatchid and Mth = @inusemth
    	select @errmsg = 'Transaction already in use by ' +
           isnull(convert(varchar(2),DATEPART(month, @inusemth)), '') + '/' +
           isnull(substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4), '') +
    		' Batch # ' + isnull(convert(varchar(6),@inusebatchid), '') + ' - ' + 
   		'Source: ' + isnull(@source, ''), @rcode = 1  --#23061
    	goto bspexit
		end
	else
		if (@inusebatchid is not null and @inusebatchid <> @batchid)
    	begin
    	select @source = Source from bHQBC
    	where Co = @co and BatchId = @inusebatchid and Mth = @inusemth
    	select @errmsg = 'Transaction already in use by ' +
           isnull(convert(varchar(2),DATEPART(month, @inusemth)), '') + '/' +
           isnull(substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4), '') +
    		' Batch # ' + isnull(convert(varchar(6),@inusebatchid), '') + ' - ' + 
   		'Source: ' + isnull(@source, ''), @rcode = 1  --#23061
    	goto bspexit
    	end
   if @inpaycontrol = 'Y'
    	begin
    	select @errmsg = 'Transaction is currently locked by AP Payment Control', @rcode = 1
    	goto bspexit
    	end
    	
   -- validation when Payment Sequence already exists - payment info and Supplier must match
   
   
   -- check for Payment Batch Header info
   select @pbcmco = CMCo, @pbcmacct = CMAcct, @pbpaymethod = PayMethod, @pbcmref = CMRef,@pbchktype=ChkType,
       @pbvendorgroup = VendorGroup, @pbvendor = Vendor, @pbname = Name, @pbaddinfo = AddnlInfo, @pbaddress = Address,
       @pbcity = City, @pbstate = State, @pbzip = Zip, @pbsupplier = Supplier, @pbcountry=Country
   from bAPPB
   where Co = @co and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq
   if @@rowcount = 1
       begin   -- validation when Payment Sequence already exists - payment info and Supplier must match
       -- get Vendor info
       select @name = Name, @addnlinfo = AddnlInfo, @address = Address, @city = City, @state = State, @zip = Zip, @country=Country
       from bAPVM
       where VendorGroup = @vendorgroup and Vendor = @vendor
       if @@rowcount = 0
           begin
           select @errmsg = 'Missing Vendor: ' + isnull(convert(varchar(8), @vendor), ''), @rcode = 1 --#23061
           goto bspexit
           end
           
 	   --TK-13965 - when pay method is 'Credit Service' set Pay Address info from APVM and Pay Override flag to 'N'
	   IF @paymethod = 'S'
	   BEGIN
		   SELECT	@payname = @name, 
					@payaddinfo = @addnlinfo, -- B-09140 Added
					@payaddress = @address,
					@paycity = @city, 
					@paystate = @state, 
					@payzip = @zip, 
					@paycountry = @country
	   END
	   ELSE IF @payoverrideyn = 'N' AND @addtladdrseq IS NULL  -- use Vendor defaults
	   BEGIN
		   SELECT	@payname = @name, 
					@payaddinfo = @addnlinfo, 
					@payaddress = @address, 
					@paycity = @city, 
					@paystate = @state,
					@payzip = @zip, 
					@paycountry = @country
	   END
   
       -- make sure transaction can be added to this Payment Sequence
       if @cmco <> @pbcmco or (@cmacct <> @pbcmacct and @cmacct is not null and @pbcmacct is not null)
           begin
           select @errmsg = 'Payment Sequence and Transaction CM Co#/CM Account do not match.', @rcode = 1
           goto bspexit
           end
       if @paymethod <> @pbpaymethod
           begin
           select @errmsg = 'Payment Sequence and Transaction payment method do not match.', @rcode = 1
           goto bspexit
           end
       if @pbcmref is not null and @pbchktype <> 'M'
           begin
           select @errmsg = 'Payment Sequence already has been assigned a CM Reference #.', @rcode = 1
           goto bspexit
           end
       -- #139418 Allow payments to older transactions if paycountry is null
	   IF @vendorgroup <> @pbvendorgroup OR @vendor <> @pbvendor OR ISNULL(@payname,'') <> ISNULL(@pbname,'')
           OR ISNULL(@payaddinfo,'') <> ISNULL(@pbaddinfo,'') OR ISNULL(ISNULL(@paycountry,@pbcountry),'')  <> ISNULL(@pbcountry,'')
           OR ISNULL(@payaddress,'') <> ISNULL(@pbaddress,'') OR ISNULL(@paycity,'') <> ISNULL(@pbcity,'')
           OR ISNULL(@paystate,'') <> ISNULL(@pbstate,'') OR ISNULL(@payzip,'') <> ISNULL(@pbzip,'')
			BEGIN
				SELECT @errmsg = 'Payment Sequence and Transaction payment information does not match.', @rcode = 1
				RETURN @rcode
			END
	   if @paycountry is not null and @pbcountry is not null
			begin
			if isnull(@paycountry,'') <> isnull(@pbcountry,'')
				begin
				select @errmsg = 'Payment Sequence and Transaction payment country does not match.', @rcode = 1
				 goto bspexit 
				end
			end


       -- make sure something is open
       select @apline = null, @apseq = null, @openamt = 0
       select @apline = min(APLine)
       from bAPTL where APCo = @co and Mth = @expmth and APTrans = @aptrans
       while @apline is not null
           begin
           select @apseq = min(APSeq)    -- get first sequence for line
           from bAPTD where APCo = @co and Mth = @expmth and APTrans = @aptrans and APLine = @apline
           while @apseq is not null
               begin
               -- do not include if already in Payment Batch Detail
               if not exists(select * from bAPDB where Co = @co and ExpMth = @expmth
                   and APTrans = @aptrans and APLine = @apline and APSeq = @apseq)
                   begin
                   select @openamt = @openamt + isnull(Amount,0)
                   from bAPTD
                   where APCo = @co and Mth = @expmth and APTrans = @aptrans
                       and APLine = @apline and APSeq = @apseq and Status = 1
                       and isnull(Supplier,0) = isnull(@pbsupplier,0) -- must be open and matching Supplier
                   end
               select @apseq = min(APSeq)
               from bAPTD
         where APCo = @co and Mth = @expmth and APTrans = @aptrans and APLine = @apline and APSeq > @apseq
     		    if @@rowcount = 0 select @apseq = null
               end
           select @apline = min(APLine)
           from bAPTL
           where APCo = @co and Mth = @expmth and APTrans = @aptrans and APLine > @apline
           if @@rowcount = 0 select @apline = null
           end
       -- check open amount
       if @openamt = 0
           begin
           select @errmsg = 'Nothing is open on this transaction that matches the Payment Header.', @rcode = 1
           goto bspexit
           end
       end
   else    -- validation with no Payment Batch Sequence
       begin
        -- if @cmacct (cm acct from trans) is null then set a flag saying so cause if we
       --  are initializing from top of form then will ask them the cmaacct to use
       select @nocmacct = 'N'
       if @cmacct is null
           begin
           if @dfltcmacct is null
               begin
               select @nocmacct = 'Y', @rcode = 1, @errmsg = 'CM Account is missing.'
               goto bspexit
               end
           else
               begin
               select @cmacct=@dfltcmacct
               end
           end
       -- check for any open amount
       select @apline = null, @apseq = null, @openamt = 0
       select @apline = min(APLine)
       from bAPTL where APCo = @co and Mth = @expmth and APTrans = @aptrans
       while @apline is not null
           begin
           select @apseq = min(APSeq)    -- get first sequence for line
           from bAPTD where APCo = @co and Mth = @expmth and APTrans = @aptrans and APLine = @apline
           while @apseq is not null
               begin
               -- do not include if already in Payment Batch Detail
               if not exists(select * from bAPDB where Co = @co and ExpMth = @expmth
                   and APTrans = @aptrans and APLine = @apline and APSeq = @apseq)
                   begin
                   select @openamt = @openamt + isnull(Amount,0)
                   from bAPTD
                   where APCo = @co and Mth = @expmth and APTrans = @aptrans
                       and APLine = @apline and APSeq = @apseq and Status = 1  -- must be open
                   end
               select @apseq = min(APSeq)
               from bAPTD
               where APCo = @co and Mth = @expmth and APTrans = @aptrans and APLine = @apline and APSeq > @apseq
     		    if @@rowcount = 0 select @apseq = null
               end
           select @apline = min(APLine)
           from bAPTL
           where APCo = @co and Mth = @expmth and APTrans = @aptrans and APLine > @apline
           if @@rowcount = 0 select @apline = null
           end
       if @openamt = 0
           begin
           if exists(select * from bAPDB where Co = @co and ExpMth = @expmth and
             APTrans = @aptrans)
               begin
               select @inusemth = InUseMth, @inusebatchid = InUseBatchId
                 from bAPTH where APCo = @co and Mth = @expmth and APTrans = @aptrans
               if @inusemth = @mth and @inusebatchid = @batchid
                   begin
                   select @errmsg = 'Transaction is already in use in this batch',@rcode = 1
                   end
               else
                   begin
                   select @errmsg = 'Transaction already in use by ' +
                     isnull(convert(varchar(2),DATEPART(month, @inusemth)), '') + '/' +
                     isnull(substring(convert(varchar(4),DATEPART(year, @inusemth)),3,4), '') +
              		' Batch # ' + isnull(convert(varchar(6),@inusebatchid), ''), @rcode = 1
                   end
               end
           else
               begin
        	    select @errmsg = 'There are no open items to be paid on this transaction', @rcode = 1
    	        goto bspexit
               end
    	    end
       end
   
   -- get PO/SL Compliance flags
   select @pocomplianceyn = POCompChkYN, @slcomplianceyn = SLCompChkYN
   from bAPCO where APCo = @co
   
   -- check Compliance - return warning if 'out of compliance', but treat as a valid transaction
   if @pocomplianceyn = 'Y' or @slcomplianceyn = 'Y'
   	begin
   	select @apline = min(APLine)
       from bAPTL where APCo = @co and Mth = @expmth and APTrans = @aptrans
   	while @apline is not null
   		begin
           select @linetype = LineType
           from bAPTL
           where APCo = @co and Mth = @expmth and APTrans = @aptrans and APLine = @apline
   		if (@linetype = 6 and @pocomplianceyn = 'Y') or (@linetype = 7 and @slcomplianceyn = 'Y')
               begin
     			exec @rc = bspAPComplyCheck @co, @expmth, @aptrans, @apline, @invdate, @apref, @errmsg output  --DC #132186
     			if @rc <> 0
     				begin
                   select @errmsg = 'Warning: Transaction posted to a '
     				if @linetype = 6 select @errmsg = @errmsg + 'PO that is out of compliance.'
                   if @linetype = 7 select @errmsg = @errmsg + 'Subcontract is out of compliance.'
                   end
     			end
     		select @apline = min(APLine)
           from bAPTL
           where APCo = @co and Mth = @expmth and APTrans = @aptrans and APLine > @apline
     		if @@rowcount = 0 select @apline = null
     		end
     	end

   	--CMAccount Validation for all Pay Methods B-08103
	EXEC	@rc = [dbo].[vspAPCOCreditServiceInfoCheck]
			@apco = @co,
			@cmco = @cmco,
			@cmacct = @cmacct,
			@vendorgrp = @vendorgroup,
			@vendor = @vendor,
			@paymethod = @paymethod,
			@msg = @errmsg OUTPUT
	IF @rc = 1 OR @cmacct IS NULL RETURN 1 
	
   
   bspexit:
	--if @rcode = 0 
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPTHTransValInit] TO [public]
GO
