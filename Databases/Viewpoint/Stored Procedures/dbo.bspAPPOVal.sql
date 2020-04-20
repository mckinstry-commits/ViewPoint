SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPPOVal    Script Date: 8/28/99 9:34:03 AM ******/
   CREATE  proc [dbo].[bspAPPOVal]
   /***********************************************************
    * CREATED BY	: SAE 9/28/97
    * MODIFIED BY	: kb 3/11/99 gr 5/14/99
    *              : GR 04/05/00 corrected the check for compliance
    *              kb 10/28/2 - issue #18878 - fix double quotes
    *			 	MV 11/11/02 - #18037 return AddressSeq
    *				GF 07/09/2003 - #21682 - speed improvements
    *				MV 07/26/06 - #27765 APEntryDetail 6X recode - if no AddressSeq return null
    *				AMR 01/12/11 - #142350 - making case sensitive by removing @inusemth that is not used 
    *				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
    *
    * USED IN:
    *   APEntry
    *   APPOInit
    *
    * USAGE:
    * validates PO, returns PO Description, Vendor, and Vendor Description and
    * an error is returned if po is in use or if CompChk flag is true in APCO and
    * po is out of compliance
    *
    * INPUT PARAMETERS
    *   POCo  	PO Co to validate against
    *   PO    	to validate
    *   Batch      Batch we're currently in
    *   Month      Month of batch
    *   InvDate	Invoice date to check compliance against
    *
    * OUTPUT PARAMETERS
    *   @complied whether or not PO is in Compliance
    *   @payterms PayTerms for POCo and Po
    *	@addressseq the PayAddressSeq from bPOHD
    *   @msg      error message if error occurs otherwise Description of PO
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/
   
       (@poco bCompany = 0, @po varchar(30) = null, @BatchId bBatchID=null, @BatchMth bMonth=null,
        @invdate bDate=null, @vendor bVendor, @complied bYN output, @payterms bPayTerms output,
   	@addressseq tinyint = null output, @msg varchar(100) output)
   as
   
   set nocount on
   --#142350 - removing unused differenct cased variable
   DECLARE @rcode int,
    @InUse bBatchID,
    @InUseMth bMonth,
    @povendor bVendor,
    @inuseby bVPUserName,
    @status tinyint,
    @source bSource
   
   select @rcode = 0, @complied='Y'
   select @InUse=null
   
   if @poco is null
   	begin
   
   	select @msg = 'Missing PO Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @po is null
   	begin
   
   	select @msg = 'Missing PO!', @rcode = 1
   	goto bspexit
   	end
   
   
   select @InUse=InUseBatchId, @InUseMth=InUseMth, @status=Status, @povendor=Vendor,
   	   @addressseq = PayAddressSeq --isnull(PayAddressSeq,0) 
   from POHD with (nolock)	where POCo = @poco and PO = @po
   if @@rowcount=0
   	begin
   	select @msg = 'PO not on file!', @rcode = 1
   	goto bspexit
   	end
   if @status<>0
   	begin
   	select @msg = 'PO not open!', @rcode = 1
   	goto bspexit
   	end
   if @povendor<>@vendor
   	begin
   	select @msg = 'Invoice Vendor does not match the Vendor on this Purchase order!', @rcode=1
   	goto bspexit
   	end
   
   
   if @BatchId is not null
   	begin
   	if not @InUse is null
   	   begin
   
   	    if @InUse=@BatchId and @InUseMth=@BatchMth
   	       goto ponotinuse
   
   	    select @source=Source
   	       from HQBC with (nolock)
   	       where Co=@poco and Mth=@InUseMth and BatchId=@InUse 
   	    if @@rowcount<>0
   	       begin
   			if @BatchId = 0 and @BatchMth='1/1/1' and @source='AP Entry' goto ponotinuse
   			else
   			select @msg = 'PO already in use by ' +
   		      convert(varchar(2),DATEPART(month, @InUseMth)) + '/' +
   		      substring(convert(varchar(4),DATEPART(year, @InUseMth)),3,4) +
   			' batch # ' + convert(varchar(6),@InUse) + ' - ' + 'Batch Source: ' + @source, @rcode = 1
   			goto bspexit
   	       end
   	    else
   	       select @msg='PO already in use by another batch!', @rcode=1
       	   goto bspexit
   	   end
   	end
   
   
   
   ponotinuse:
   
   -- check compliance
   if exists (select 1 from bPOCT p with (nolock), bHQCP h with (nolock)
   			where p.CompCode = h.CompCode and POCo=@poco and PO=@po and p.Verify='Y' and
   			((CompType = 'F' and Complied = 'N') or (CompType = 'D' and ((@invdate > ExpDate) or ExpDate is null))))
   		select @complied='N'
   
   
   
   select 	@msg=POHD.Description, @payterms=POHD.PayTerms
   		from POHD with (nolock)	where POCo = @poco and PO = @po
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPPOVal] TO [public]
GO
