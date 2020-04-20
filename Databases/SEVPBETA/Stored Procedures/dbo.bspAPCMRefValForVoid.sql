SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE          proc [dbo].[bspAPCMRefValForVoid]
/***********************************************************
* CREATED BY: MV 12/29/03
*	MODIFIED By :	MV 08/22/03 - #22160 - check CM transtype against paymethod separatly 
*  					ES 03/11/04 - #23061 isnull wrap
*					MV 03/01/05 - #27220 - select by cmco and paidmth for paymethod count
*					MV 07/27/05 - #29300 - added warning if check has been reversed.
*					MV 03/11/08 - #127347 International addresses 
*					KK 04/25/12 - B-08618 Added pay method 'S' for the Credit Service enhancement
*                         
* USAGE:
*   validates CM Reference in AP Payment History, must
*   exist here and must be in and open in CM. Returns name and
*   address for display on CMRefSeq or EFTSeq passed in. So Void
*	displays correct info for CM Ref or EFT seq where there are
*   multiple sequences for a check or EFT.
*
* INPUT PARAMETERS
*   APCo		AP Co
*   mth
*   CMCo		CM Co
*   CMAcct		CM Account
*   CMRef		The reference
*   CMReqSeq	The check cmref seq #
*   EFTSeq		The EFT seq
*   paymethod	'E' if EFT, 'C' if Check, 'S' if Credit Service
*   source		'V'(void), 
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
     
(@apco bCompany, 
 @mth bMonth, 
 @cmco bCompany = 0, 
 @cmacct bCMAcct = null, 
 @cmref bCMRef,
 @cmrefseq int = null, 
 @eftseq int = null, 
 @paymethod char(1), 
 @source char(1),
 @vendor bVendor OUTPUT,
 @name varchar(60) OUTPUT,
 @addnlinfo varchar(60) OUTPUT, 
 @address varchar(60) OUTPUT,
 @city varchar(30) OUTPUT, 
 @state varchar(4) OUTPUT,
 @zip bZip OUTPUT, 
 @country char(2) OUTPUT, 
 @paiddate bDate OUTPUT,
 @paidmth bMonth OUTPUT,
 @supplier bVendor OUTPUT, 
 @paytot bDollar OUTPUT, 
 @msg varchar(100) OUTPUT)

AS 
SET NOCOUNT ON
     
DECLARE @rcode int, 
		@cleardate bDate, 
		@cmtranstype int, 
		@inusebatchid bBatchID, 
		@appaymethod char(1),
      	@voidyn bYN, 
      	@inusemth bMonth, 
      	@paymentcount int, 
      	@apcount int, 
      	@glco bCompany,
      	@lastmthclosed bMonth, 
      	@chkrevseq int,
      	@chkrevmth bMonth
     
SELECT @rcode = 0
      
      if @cmrefseq is null
    	begin
    	select @cmrefseq = 0
    	end
    
      if @eftseq is null
    	begin
    	select @eftseq = 0
    	end
    
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

-- get Payment Info from APPH (payment header) B-08618 - reworked to include paymethod "S"
SELECT @inusemth = InUseMth, 
	   @inusebatchid = InUseBatchId, 
	   @appaymethod = PayMethod,
	   @vendor = Vendor, 
	   @name = Name, 
	   @addnlinfo = AddnlInfo, 
	   @address = Address, 
	   @city = City,
	   @state = State, 
	   @zip = Zip,
	   @country = Country, 
	   @paiddate = PaidDate, 
	   @paidmth = PaidMth,
	   @supplier = Supplier, 
	   @voidyn = VoidYN,
	   @paytot = Amount
FROM APPH WITH (NOLOCK) 
WHERE APCo = @apco 
	  AND CMCo = @cmco 
	  AND CMAcct = @cmacct 
	  AND CMRef = @cmref 
	  AND CMRefSeq = @cmrefseq -- Always 0 for EFT/Credit Service payments
	  AND EFTSeq = @eftseq -- Always 0 for Check/Credit Service payments
	  AND PayMethod = @paymethod 
IF @@ROWCOUNT = 0
BEGIN
	SELECT @msg = 'Invalid CM Ref# - not found in AP Payment History!', @rcode = 1
	GOTO bspexit
END
     
     if @source='V'
      	begin
      	if @paidmth <> @mth
      		begin
      		select @msg = 'Paid month must match batch month.', @rcode = 1
      		goto bspexit
      		end
      	end

-- get record counts from APPD and APTD B-08618
SELECT @paymentcount = COUNT(*) 
FROM APPD WITH (NOLOCK)
WHERE APPD.APCo = @apco 
	  AND CMCo = @cmco 
	  AND CMAcct = @cmacct 
	  AND PayMethod = @paymethod 
	  AND CMRef = @cmref 
	  AND CMRefSeq = @cmrefseq -- Always 0 for EFT/Credit Service payments
	  AND EFTSeq = @eftseq -- Always 0 for Check/Credit Service payments

SELECT @apcount = COUNT(DISTINCT CONVERT(varchar(20),Mth) + CONVERT(varchar(10),APTrans))
FROM APTD WITH (NOLOCK) 
WHERE PaidMth = @paidmth
	  AND CMCo = @cmco 
	  AND CMAcct = @cmacct
	  AND PayMethod = @paymethod --#27220 select on cmco and paidmth
	  AND CMRef = @cmref 
	  AND CMRefSeq = @cmrefseq -- Always 0 for EFT/Credit Service payments
	  AND EFTSeq = @eftseq -- Always 0 for Check/Credit Service payments

      -- compare counts to see if there are missing transactions between APPD and APTD
      if @apcount<>@paymentcount
      	begin
      	select @msg='Some AP transactions paid on this CMRef# are missing.', @rcode=1
      	goto bspexit
      	end
     
      if @inusemth is not null and @inusebatchid is not null
      	begin
      	select @msg='CM Ref# is in use by AP Payment BatchId# ' + isnull(convert(varchar(10),@inusebatchid), '') --#23061
     		+ ' in Month: ' + isnull(convert(varchar(8),@inusemth,1), '')		--#18667
     		+ '.', @rcode=1
      	goto bspexit
      	end
     
      if @paymethod<>@appaymethod
      	begin
      	select @msg='AP Payment method does not match specified payment method.', @rcode=1
      	goto bspexit
      	end
     
    
      if exists(select top 1 1 from bAPCO WITH (NOLOCK) where APCo = @apco and CMInterfaceLvl = 1)
         begin
          select @cleardate=ClearDate, @inusebatchid=InUseBatchId, @cmtranstype=CMTransType, @glco=GLCo,
          @voidyn=Void
      	  from bCMDT WITH (NOLOCK) where CMCo=@cmco and CMAcct=@cmacct and SourceCo=@apco and
          	Source='AP Payment' and CMRef=@cmref and CMRefSeq= case @paymethod when 'C' then @cmrefseq else 0 end
          if @@rowcount=0
      	  begin
          	select @msg='Invalid CM Ref# - not found in CM!', @rcode=1
      	      goto bspexit
    	  end
    	
     	 -- 22160 check CM transtype against paymethod separatly for 'E'FT or Credit 'S'ervice, and 'C'heck B-08618
    	 IF @paymethod IN ('E','S') AND @cmtranstype <> 4
    		begin
    		select @msg='Pay method in AP Payment History and CM do not match!', @rcode=1
      	    goto bspexit
          	end
          	
    	 if @paymethod = 'C' and @cmtranstype <> 1
    		begin
    		select @msg='Pay method in AP Payment History and CM do not match!', @rcode=1
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
    
    	-- warn if this check has already been reversed in a later month 
    	 if exists(select top 1 1 from bAPPH where APCo = @apco and CMCo = @cmco and CMAcct = @cmacct
    	     and PayMethod = 'C' and CMRef = @cmref and CMRefSeq <> @cmrefseq and ChkType='P')
    	     begin
    	     select @msg = 'AP Payment History indicates this check may already have been reversed.', @rcode=1
   		 goto bspexit
    	     end
     
   	-- warn if this check is an unprocessed prepaid from a check reversed in a later month
     	 if exists(select top 1 1 from bAPTH where APCo = @apco and CMCo = @cmco and CMAcct = @cmacct
    	     and PayMethod = 'C' and PrePaidChk = @cmref and PrePaidSeq <> @cmrefseq and PrePaidYN ='Y' and PrePaidProcYN='N')
    	     begin
    	     select @msg = 'AP Transaction indicates this may be an unprocessed prepaid check reversed in a later month.', @rcode=1
       	 goto bspexit
    	     end
   
bspexit:
     
IF @rcode=1
BEGIN
	SELECT @vendor = NULL, 
			@name = NULL, 
			@addnlinfo = NULL, 
			@address = NULL, 
			@city = NULL, 
			@state = NULL, 
			@zip = NULL, 
			@country = NULL,
			@paiddate = NULL, 
			@paidmth = NULL, 
			@supplier = NULL, 
			@paytot = NULL
END
     
RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPCMRefValForVoid] TO [public]
GO
