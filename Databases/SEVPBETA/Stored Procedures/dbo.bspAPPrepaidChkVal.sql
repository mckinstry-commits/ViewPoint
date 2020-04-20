SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPrepaidChkVal    Script Date: 8/28/99 9:34:03 AM ******/
   CREATE  proc [dbo].[bspAPPrepaidChkVal]
   /***********************************************************
    * CREATED BY:	kb 1/7/99
    * MODIFIED By : GG 4/30/99
    *				GG 07/29/99 -- Fixed validation on bHQHB to exclude current entry
    *               EN 1/22/00 - expand @sendname, @name & @thname to varchar(60) and include AddnlInfo
    *				kb 10/28/2 - issue #18878 - fix double quotes
    *				ES 03/11/04 - #23061 isnull wrapping
	*				MV 03/13/08 - #127347 - bState datatype
    *
    * USAGE:
    * Called by AP Transaction Entry to validate a Prepaid Check #.
    * CM Reference Sequence is NOT provided (i.e. not entered with prepaid
    * transactions) so validation here is different from Payment Batch
    * validation.
    * Prepaid check # is rejected if it exists in CM, AP Payment
    * History, or an AP Payment batch.
    * Prepaid check # is rejected if it exists in AP Trans or Trans Batch
    * and entered with different payment information.
    *
    * INPUT PARAMETERS:
    *  @apco               AP Company
    *  @mth                Batch Month - expense
    *  @batchid            Batch ID#
    *  @batchseq           Batch Seq#
    *  @cmco               CM Company
    *  @cmacct             CM Account
    *  @prepaidchk         Prepaid Check #
    *  @sendvendorgroup    Vendor Group
    *  @sendvendor         Vendor
    *  @sendname           Payee Name
    *  @sendaddinfo        Payment additional info
    *  @sendaddress        Payment Address
    *  @sendstate          Payment State
    *  @sendzip            Payment Zip Code
    *  @sendpaidmth        Paid month
    *  @sendpaiddate       Paid date
    *
    * OUTPUT PARAMETERS:
    *  @msg                error message
    *
    * RETURN VALUE
    *   0                  success
    *   1                  fail
   *****************************************************/
      	(@apco bCompany = 0, @mth bMonth = null, @batchid bBatchID = 0, @batchseq int = 0,
       @cmco bCompany = 0, @cmacct bCMAcct, @prepaidchk bCMRef, @sendvendorgroup bGroup,
      	@sendvendor bVendor, @sendname varchar(60), @sendaddinfo varchar(60), @sendaddress varchar(60),
      	@sendstate varchar(4), @sendcity varchar(30), @sendzip bZip, @sendpaidmth bMonth,
      	@sendpaiddate bDate, @msg varchar(255) output)
   
   as
   
   set nocount on
   
   declare @rcode int, @name varchar(60), @addnlinfo varchar(60), @address varchar(60), @city varchar(30), @state varchar(4), @zip bZip,
   @expmth bMonth, @aptrans bTrans, @vendorgroup bGroup, @vendor bVendor, @paidmth bMonth, @paiddate bDate,
   @thname varchar(60), @thaddinfo varchar(60), @thaddress varchar(60), @thcity varchar(30), @thstate varchar(4), @thzip bZip,
   @startmsg varchar(255), @expbatchid bBatchID, @expbatchseq int
   
   
   select @rcode = 0
   
   select @startmsg = ''  --#23061
   
   if @cmco = 0
       begin
      	select @msg = 'Missing CM Company#', @rcode = 1
      	goto bspexit
      	end
   if @cmacct is null
      	begin
      	select @msg = 'Missing CM Account', @rcode = 1
      	goto bspexit
      	end
   if @prepaidchk is null
      	begin
      	select @msg = 'Missing check #', @rcode = 1
      	goto bspexit
      	end
   
   -- check CM Detail
   if exists(select * from bCMDT
               where CMCo = @cmco and CMAcct = @cmacct and CMRef = @prepaidchk and CMTransType = 1)  -- hardcoded for checks
       begin
       select @msg = 'This check # already exists in Cash Management.', @rcode = 1
       goto bspexit
       end
   
   -- check AP Payment History
   if exists(select * from bAPPH
               where CMCo = @cmco and CMAcct = @cmacct and PayMethod = 'C' and CMRef = @prepaidchk)
       begin
       select @msg = 'This check # already exists in AP Payment History.', @rcode = 1
       goto bspexit
       end
   
   -- check AP Payment Batch Header
   if exists(select * from bAPPB
               where CMCo = @cmco and CMAcct = @cmacct and PayMethod = 'C' and CMRef = @prepaidchk)
       begin
       select @msg = 'This check # already exists in an AP Payment Batch.', @rcode = 1
       goto bspexit
       end
   
   -- get Vendor info - to compare payment name, additional info, address, etc.
   select @name = Name, @addnlinfo = AddnlInfo, @address = Address, @city = City, @state = State, @zip = Zip
   from bAPVM
   where VendorGroup = @sendvendorgroup and Vendor = @sendvendor
   if @@rowcount = 0
       begin
       select @msg = 'Missing Vendor.', @rcode = 1
       goto bspexit
       end
   
   -- overrides will be null if not used - use Vendor info
   if @sendname is null select @sendname = @name
   if @sendaddinfo is null select @sendaddinfo = @addnlinfo
   if @sendaddress is null select @sendaddress = @address
   if @sendcity is null select @sendcity = @city
   if @sendstate is null select @sendstate = @state
   if @sendzip is null select @sendzip = @zip
   
   -- check AP Transaction Header
   select @expmth = Mth, @aptrans = APTrans, @vendorgroup = VendorGroup, @vendor = Vendor,
       @paidmth = PrePaidMth, @paiddate = PrePaidDate, @thname = PayName, @thaddinfo = PayAddInfo, @thaddress = PayAddress,
       @thcity = PayCity, @thstate = PayState, @thzip = PayZip
   from bAPTH
   where CMCo = @cmco and CMAcct = @cmacct and PrePaidChk = @prepaidchk and InUseMth is null   -- unlocked only
   if @@rowcount <> 0
       begin
       select @startmsg = 'This check # already used on Mth: ' + isnull(convert(varchar(2),@expmth,1), '') 
           + isnull(substring(convert(varchar(8),@expmth,1),6,3), '') + ' Trans#: ' 
   	+ isnull(convert(varchar(12),@aptrans), '') + char(13)  --#23061
       if @vendor <> @sendvendor or @vendorgroup <> @sendvendorgroup
      	    begin
      	    select @msg = @startmsg + 'Posted to Vendor #: ' + isnull(convert(varchar(12),@vendor), ''), @rcode = 1  --#23061
           goto bspexit
      	    end
    	if @paidmth <> @sendpaidmth or @paiddate <> @sendpaiddate
     		begin
      		select @msg = @startmsg + 'Paid in Mth: ' + isnull(convert(varchar(2),@paidmth,1), '') 
               	+ isnull(substring(convert(varchar(8),@paidmth,1),6,3), '') + ' on ' 
   		+ isnull(convert(varchar(8),@paiddate,1), ''), @rcode = 1  --#23061
           goto bspexit
     	 	end
       if @thname is null select @thname = @name
       if @thname <> @sendname
           begin
           select @msg = @startmsg + 'Posted to Vendor ' + isnull(@thname, ''), @rcode = 1  --#23061
           goto bspexit
           end
       if @thaddinfo is null select @thaddinfo = @addnlinfo
       if @thaddress is null select @thaddress = @address
       if @thcity is null select @thcity = @city
       if @thstate is null select @thstate = @state
       if @thzip is null select @thzip = @zip
       if @thaddress <> @sendaddress or @thcity <> @sendcity or @thstate <> @sendstate or @thzip <> @sendzip
        	begin
        	select @msg = @startmsg + 'Posted with different payment address information.', @rcode = 1
           goto bspexit
           end
      	end
   
   -- check AP Header Batch
   select @expmth = Mth, @expbatchid = BatchId, @expbatchseq = BatchSeq, @vendorgroup = VendorGroup, @vendor = Vendor,
       @paidmth = PrePaidMth, @paiddate = PrePaidDate, @thname = PayName, @thaddinfo = PayAddInfo, @thaddress = PayAddress,
       @thcity = PayCity, @thstate = PayState, @thzip = PayZip
   from bAPHB
   where CMCo = @cmco and CMAcct = @cmacct and PrePaidChk = @prepaidchk
       and (Co <> @apco or Mth <> @mth or BatchId <> @batchid or BatchSeq <> @batchseq)    -- exclude current entry
   if @@rowcount <> 0
       begin
       select @startmsg = 'This check # already used on Mth: ' + isnull(convert(varchar(2),@expmth,1), '')
           + isnull(substring(convert(varchar(8),@expmth,1),6,3), '') + ' Batch: ' 
   	+ isnull(convert(varchar(12),@expbatchid), '') + ' Seq#: ' 
   	+ isnull(convert(varchar(12),@expbatchseq), '') + char(13)  --#23061
       if @vendor <> @sendvendor or @vendorgroup <> @sendvendorgroup
      	    begin
      	    select @msg = @startmsg + 'Posted to Vendor #: ' + isnull(convert(varchar(12),@vendor), ''), @rcode = 1  --#23061
           goto bspexit
      	    end
    	if @paidmth <> @sendpaidmth or @paiddate <> @sendpaiddate
     		begin
      		select @msg = @startmsg + 'Paid in Mth: ' + isnull(convert(varchar(2),@paidmth,1), '')
               	+ isnull(substring(convert(varchar(8),@paidmth,1),6,3), '')
               	+ ' on ' + isnull(convert(varchar(8),@paiddate,1), ''), @rcode = 1  --#23061
           goto bspexit
     	 	end
       if @thname is null select @thname = @name
       if @thname <> @sendname
           begin
           select @msg = @startmsg + 'Posted to Vendor ' + isnull(@thname, ''), @rcode = 1  --#23061
           goto bspexit
           end
       if @thaddinfo is null select @thaddinfo = @addnlinfo
       if @thaddress is null select @thaddress = @address
       if @thcity is null select @thcity = @city
       if @thstate is null select @thstate = @state
       if @thzip is null select @thzip = @zip
       if @thaddress <> @sendaddress or @thcity <> @sendcity or @thstate <> @sendstate or @thzip <> @sendzip
        	begin
        	select @msg = @startmsg + 'Posted with different payment address information.', @rcode = 1
   goto bspexit
           end
      	end
   
   bspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPPrepaidChkVal] TO [public]
GO
