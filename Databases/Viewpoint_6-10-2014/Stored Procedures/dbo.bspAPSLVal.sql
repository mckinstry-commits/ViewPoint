SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPSLVal    Script Date: 8/28/99 9:34:05 AM ******/
   CREATE    proc [dbo].[bspAPSLVal]
   /***********************************************************
    * CREATED BY	: SE 10/1/97
    * MODIFIED BY	: EN 5/5/99 gr 5/14/99
    *              kb 10/29/2 - issue #18878 - fix double quotes
    *				ES 03/12/04 0 #23061 isnull wrapping
    *				MV 11/01/04 - #26038 - allow SL in APEntry and Unapproved at same time
    *				DC 02/10/09 - #132186 - Add an APRef field in SL Compliance associated to AP Ref in Accounts payable
    *				GP 6/28/10 - #135813 change bSL to varchar(30) 
    *
    * USAGE:
    * validates SL, returns SL Description, Vendor, and Vendor Description and flag SL as inuse
   
    * an error is returned if any of the following occurs
    * Returns weather or not Subcontract is in compliance.
    *
    * INPUT PARAMETERS
    *   SLCo  	PO Co to validate against
    *   SL 	to validate
    *   Invdate  	Date to validate compliance against
    *
    * OUTPUT PARAMETERS
    *   @complied weather or not subcontract is in compliance
    *   @payterms PayTerms for given POCo and Po if Po not in use
    *   @msg      error message if error occurs otherwise Description of SL, Vendor,
    *   Vendor group, and Vendor Name
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/   
	(@slco bCompany = 0, @sl varchar(30) = null, @BatchId bBatchID=null, @BatchMth bMonth=null,@invdate bDate = null,
	@vendor bVendor, 
	@apref bAPReference, --DC #132186
	@complied bYN ='Y' output, @payterms bPayTerms output, @msg varchar(200) output)
	
   as
   
   set nocount on
   
   declare @rcode int, @InUse bBatchID, @InUseMth bMonth, @source bSource, @status tinyint, @slvendor bVendor
   
   
   select @rcode = 0, @complied='Y'
   select @InUse=null
   
   if @slco is null
   	begin
   	select @msg = 'Missing SL Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @sl is null
   	begin
   
   	select @msg = 'Missing SL!', @rcode = 1
   	goto bspexit
   	end
   
   select @InUse=InUseBatchId, @InUseMth=InUseMth, @status=Status, @slvendor=Vendor from SLHD
   	where SLCo = @slco and SL = @sl
   if @@rowcount=0
   	begin
   	select @msg = 'SL not on file!', @rcode = 1
   	goto bspexit
   	end
   if @status<>0
   	begin
   	select @msg = 'SL not open!', @rcode = 1
   	goto bspexit
   	end
   if @BatchId is not null
   	begin
   	if not @InUse is null
   	   begin
   	    if @InUse=@BatchId and @InUseMth=@BatchMth
   	       goto slinthisbatch
   
   	    select @source=Source
   	       from HQBC
   	       where Co=@slco and BatchId=@InUse and Mth=@InUseMth
   	    if @@rowcount<>0
   	       begin
   			-- SL can be in AP Entry and Unapproved at the same time
   			if @BatchId = 0 and @BatchMth='1/1/1' and @source='AP Entry' goto slinthisbatch 
   			else
   			select @msg = 'SL already in use by ' +
   		      isnull(convert(varchar(2),DATEPART(month, @InUseMth)), '') + '/' +
   		      isnull(substring(convert(varchar(4),DATEPART(year, @InUseMth)),3,4), '') +
   			' batch # ' + isnull(convert(varchar(6),@InUse), '') + ' - ' + 
   			'Batch Source: ' + isnull(@source, ''), @rcode = 1  --#23061
   			goto bspexit
   	       end
   	    else
   	       	select @msg='SL already in use by another batch!', @rcode=1
   			goto bspexit
   	   end
   	end
   
   slinthisbatch:
   if @slvendor<>@vendor
   	begin
   	select @msg='Subcontract is posted to another vendor', @rcode=1
   	goto bspexit
   	end
   
   --slinthisbatch:
   /*check compliance */
   /*if exists (select * from bSLCT where SLCo=@slco and SL=@sl and Verify='Y' and
             (( ExpDate is null and Complied='N') or (ExpDate is not null and @invdate > ExpDate)))
       select @complied='N'*/
   
   /* DC #132186
       if exists (select * from bSLCT p, bHQCP h where p.CompCode = h.CompCode and SLCo=@slco and SL=@sl and p.Verify='Y' and
             ((CompType = 'F' and Complied = 'N') or (CompType = 'D' and ((@invdate > ExpDate) or ExpDate is null))))
       select @complied='N'
   *************/
   
	IF EXISTS(select 1 FROM bSLCT p	JOIN bHQCP h on p.CompCode = h.CompCode	WHERE p.SLCo=@slco and 
				p.SL=@sl and p.Verify='Y' and (p.APRef is null or p.APRef = @apref) and
			((h.CompType = 'F' and p.Complied = 'N') or (h.CompType = 'D' and ((@invdate > p.ExpDate) or p.ExpDate is null))))
		SELECT @complied='N'
   
   select 	@msg=bSLHD.Description, @payterms=bSLHD.PayTerms
   		from bSLHD
   		where SLCo = @slco and SL= @sl
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPSLVal] TO [public]
GO
