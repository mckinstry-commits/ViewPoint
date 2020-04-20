SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPCMRefVal    Script Date: 8/28/99 9:32:30 AM ******/
    
    
     CREATE         proc [dbo].[bspAPCMRefVal]
     /***********************************************************
      * CREATED BY: kf 9/29/97
      * MODIFIED By : kb 2/11/99
      *                          gh 10/29/99 Added CMAcct to APTD count for variable @apcount
      *                          gh 11/15//99 Changed distinct count on APTD, call #1042550
      *               EN 1/22/00 - expand dimension of @name to 60 and add addnlinfo to return list
      *				MV 7/3/02 - #16368 allow check rev in a prior open month.
      *				MV 10/18/02 - 18878 quoted identifier cleanup
      *				MV 11/26/02 - #18667 added inusemth to err msg.
      *				MV 08/22/03 - #22160 - add PayMethod to @apcount select where clause, added performance enhancements
      *				MV 10/21/03 - #22160 - rej 1 fix - restrict by PayMehod for APPH and CMDT validation
      *				MV 12/30/03 - #23418 - select by CMRefseq / APVoid now uses bspAPCMRefValForVoid 
      *				MV 01/05/04 - #23254 - validate CMRef not in an unprocessed prepaid transaction
      *				ES 03/11/04 - #23061 isnull wrap
	  *				MV 03/11/08 - #127347 International addresses 
      * USAGE:
      *   validates CM Reference in AP Payment History, must
      *   exist here and must be in and open in CM
      *
      * INPUT PARAMETERS
      *   APCo      AP Co
      *   mth
      *   CMCo      CM Co
      *   CMAcct    CM Account
      *   CMRef     The reference
      *   paymethod 'C' for Check
      *   source	 'R' for check reversal
      *
      * OUTPUT PARAMETERS
      *   vendor
      *   name      vendor name
      *   addnlinfo additional info line for vendor
      *   address
      *   city
      *   state
      *   zip
      *   paiddate
      *   paidmth
      *   supplier
      *   paytot
      *   @msg     Error message if invalid,
      * RETURN VALUE
      *   0 Success
      *   1 fail
      *****************************************************/
    
     (@apco bCompany, @mth bMonth, @cmco bCompany = 0, @cmacct bCMAcct=null, @cmref bCMRef, @cmrefseq int=null,
     	@paymethod char(1), @source char(1), @vendor bVendor output, @name varchar(60) output,
     	@addnlinfo varchar(60) output, @address varchar(60) output, @city varchar(30) output, @state varchar(4) output,
     	@zip bZip output, @country char(2) output,@paiddate bDate output, @paidmth bMonth output,
     	@supplier bVendor output, @paytot bDollar output, @msg varchar(100) output)
     as
    
     set nocount on
    
     declare @rcode int, @cleardate bDate, @cmtranstype int, @inusebatchid bBatchID, @appaymethod char(1),
     	@voidyn bYN, @inusemth bMonth, @paymentcount int, @apcount int, @glco bCompany,
     	@lastmthclosed bMonth,@apthco bCompany, @apthmth bMonth, @aptrans int
    
     select @rcode = 0
    
     if @apco is null
     	begin
     	select @msg = 'Missing AP Company!', @rcode = 1
     	goto bspexit
     	end
    
     if @cmco is null
     	begin
     	select @msg = 'Missing CM Company!', @rcode = 1
     	goto bspexit
     	end
     if @cmacct is null
     	begin
     	select @msg = 'Missing CM Account!', @rcode = 1
     	goto bspexit
     	end
     if @cmref is null
     	begin
     	select @msg = 'Missing CM Reference!', @rcode = 1
     	goto bspexit
     	end
   
     if @cmrefseq is null
   	begin
   	select @cmrefseq = 0
   	end 
   
     select @inusemth=APPH.InUseMth, @inusebatchid=APPH.InUseBatchId, @appaymethod=APPH.PayMethod,
     	@vendor=APPH.Vendor, @name=APPH.Name, @addnlinfo=APPH.AddnlInfo, @address=APPH.Address, @city=APPH.City,
     	@state=APPH.State, @zip=APPH.Zip,@country=APPH.Country, @paiddate=APPH.PaidDate, @paidmth=APPH.PaidMth,
     	@supplier=APPH.Supplier, @voidyn=VoidYN, @paytot=APPH.Amount
     	from APPH WITH (NOLOCK) left join APPD WITH (NOLOCK) on APPD.APCo=APPH.APCo and APPD.CMCo=APPH.CMCo 
    	and APPD.CMAcct=APPH.CMAcct	and APPD.PayMethod=APPH.PayMethod and APPD.CMRef=APPH.CMRef and
    	APPD.CMRefSeq=APPH.CMRefSeq and	APPD.EFTSeq=APPH.EFTSeq
    	where APPH.APCo=@apco and APPH.CMCo=@cmco and APPH.CMAcct=@cmacct and
   		 APPH.CMRef=@cmref and APPH.CMRefSeq= @cmrefseq and APPH.PayMethod=@paymethod	
     	/*group by APPH.InUseMth, APPH.InUseBatchId, APPH.PayMethod, APPH.Vendor, APPH.Name, APPH.Address,
     	APPH.City, APPH.State, APPH.Zip, APPH.PaidDate, APPH.PaidMth, APPH.Supplier, APPH.VoidYN*/
    
     if @@rowcount=0
     	begin
     	select @msg='Invalid CM Ref# - not found in AP Payment History!', @rcode=1
     	goto bspexit
     	end
    
     if @source='V'
     	begin
     	if @paidmth<>@mth
     		begin
     		select @msg = 'Paid month must match batch month.', @rcode = 1
     		goto bspexit
     		end
     	end
    
     select @paymentcount=count(*) from APPD WITH (NOLOCK)
     	where APPD.APCo=@apco and CMCo=@cmco and CMAcct=@cmacct and PayMethod=@paymethod 
   		and CMRef=@cmref and CMRefSeq=@cmrefseq
    
     select  @apcount=count(distinct convert(varchar(20),Mth)+convert(varchar(10),APTrans))
    	 from APTD WITH (NOLOCK) where APCo=@apco and CMAcct=@cmacct and CMRef=@cmref
   		 and PayMethod=@paymethod and CMRefSeq=@cmrefseq
    
     if @apcount<>@paymentcount
     	begin
     	select @msg='Some AP transactions paid on this CMRef# are missing.', @rcode=1
     	goto bspexit
     	end
    
     if @inusemth is not null and @inusebatchid is not null
     	begin
     	select @msg='CM Ref# is in use by AP Payment BatchId# ' + isnull(convert(varchar(10),@inusebatchid), '') --#23061
    		+ ' in Month: ' + isnull(convert(varchar(8),@inusemth,1), '')		--#18667
    		+'.', @rcode=1
     	goto bspexit
     	end
    
     if @paymethod<>@appaymethod
     	begin
     	select @msg='AP Payment method does not match specified payment method.', @rcode=1
     	goto bspexit
     	end
    
     if @voidyn='Y' and @source='R'
     	begin
     	select @msg='Check has already been voided', @rcode=1
     	goto bspexit
     	end
   
     if exists(select 1 from APCO WITH (NOLOCK) where APCo = @apco and CMInterfaceLvl = 1)
        begin
         select @cleardate=ClearDate, @inusebatchid=InUseBatchId, @cmtranstype=CMTransType, @glco=GLCo,
         @voidyn=Void
     	  from CMDT WITH (NOLOCK) where CMCo=@cmco and CMAcct=@cmacct and SourceCo=@apco and
         	Source='AP Payment' and CMRef=@cmref and CMRefSeq=@cmrefseq
         if @@rowcount=0
     	  begin
         	select @msg='Invalid CM Ref# - not found in CM!', @rcode=1
     	      goto bspexit
         	end
   	 -- 22160 check CM transtype against paymethod separatly for 'E'FT and 'C'heck
   	 /*if @paymethod = 'E' and not exists (select top 1 1 from bCMDT WITH (NOLOCK) where CMCo=@cmco and
   			CMAcct=@cmacct and SourceCo=@apco and Source='AP Payment' and CMRef=@cmref and CMTransType = 4)
   		begin
   		select @msg='Pay method in AP Payment History and CM do not match!', @rcode=1
     	    goto bspexit
         	end
   	 if @paymethod = 'C' and not exists (select 1 from bCMDT WITH (NOLOCK)where CMCo=@cmco and
   			CMAcct=@cmacct and SourceCo=@apco and Source='AP Payment' and CMRef=@cmref and 
   			CMRefSeq=@cmrefseq and CMTransType = 1)
   		begin
   		select @msg='Pay method in AP Payment History and CM do not match!', @rcode=1
     	    goto bspexit
         	end */
         if (@cmtranstype=1 and @paymethod<>'C')
     	  begin
         	select @msg='Pay method in AP Payment History and CM do not match!', @rcode=1
      	    goto bspexit
         	end
    
        if @voidyn='Y' and @source='R'
     	  begin
        	select @msg='Check has already been voided', @rcode=1
     	  	goto bspexit
         end
    
     if @cleardate is not null
     	begin
     	select @msg='Invalid CM Ref# - has already been cleared in CM!', @rcode=1
     	goto bspexit
     	end
    
     if @inusebatchid is not null
     	begin
     	select @msg='CM Ref# is in use by batch #'+ isnull(convert(varchar(10),@inusebatchid), ''), @rcode=1 --#23061
     	goto bspexit
     	end
    
        end
   
   	/* #23254 - validate CMRef isn't an unprocessed prepaid in bAPTH */
   	select @apthco=APCo,@apthmth=Mth, @aptrans=APTrans
   		from bAPTH where PayMethod='C' and CMCo=@cmco and CMAcct=@cmacct and PrePaidChk=@cmref
  
   			and PrePaidSeq = (@cmrefseq + 1) and PrePaidYN='Y' and PrePaidProcYN='N'
   	if @@rowcount <> 0 
   		begin
   		select @msg='CM Ref# is in an unprocessed prepaid transaction for Co: ' + isnull(convert(varchar(3),@apco), '')
    		+ ' Month: ' + isnull(convert(varchar(8),@apthmth,1), '')
    		+ ' Trans#: ' + isnull(convert(varchar(10),@aptrans), ''),  @rcode=1 --#23061
     		goto bspexit
     		end
    
      -- #16368 allow check reversal on checks in prior open months.
     /*if @source='R'  --on check reversals paidmonth for check must be closed
     	begin
     	select @lastmthclosed=LastMthSubClsd from GLCO where GLCo=@glco
    	if @paidmth>@lastmthclosed
     		begin
    		select @msg='Check Reversal is not valid unless GL Company #' + convert(varchar(15),@glco)
     			+ ' month ' + convert(varchar(2),DATEPART(month, @paidmth)) + '/' +
     		      substring(convert(varchar(4),DATEPART(year, @paidmth)),3,4) + ' is closed.', @rcode=1
     		goto bspexit
     		end
     	end*/
    
     bspexit:
    
     	if @rcode=1
     		begin
     		select @vendor=null, @name=null, @addnlinfo=null, @address=null, @city=null, @state=null, @zip=null, @country=null,
     			@paiddate=null, @paidmth=null, @supplier=null, @paytot=null
     		end
    
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPCMRefVal] TO [public]
GO
