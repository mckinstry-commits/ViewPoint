SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspSLItemVal    Script Date: 8/28/99 9:33:41 AM ******/
    CREATE    proc [dbo].[bspSLItemVal]
    /***********************************************************
     * CREATED BY	: kf 5/5/97
     * MODIFIED BY	: kf 10/27/97
     *				  RT 12/03/03 - issue 23061, use isnulls when concatenating strings.
     *					DC 6/25/10 - #135813 - expand subcontract number 
     *
     * USAGE:
     * validates SL item, and flags SL item as inuse
     * an error is returned if any of the following occurs
     *
     * USED IN
     *   SL
     *   AP ENTRY
     *
     * INPUT PARAMETERS
     *   SLCo  SL Co to validate against
     *   SL to validate
     *   SL Item to validate
     *   BatchId
     *   BatchMth
     *
     * OUTPUT PARAMETERS
     *   @msg      error message if error occurs otherwise Description of SL, Vendor,
     *   Vendor group,Vendor Name,BackOrdered
     * RETURN VALUE
     *   0         success
     *   1         Failure
     *****************************************************/    
        (@slco bCompany, @sl VARCHAR(30), --bSL, DC #135813
        @slitem bItem, @BatchId bBatchID, @BatchMth bMonth, @vendor bVendor,
        @origunits bUnits output, @curunits bUnits output, @invunits bUnits output, @origunitcost bUnitCost output,
        @curunitcost bUnitCost output, @origitemtot bDollar output, @curitemtot bDollar output, @invitemtot bDollar output,
    	@origsubtot bDollar output, @cursubtot bDollar output, @invsubtot bDollar output, @msg varchar(100) output)
    as
    
    set nocount on
    
    declare @rcode int, @InUse bBatchID, @InUseMth bMonth, @inuseby bVPUserName, @slvendor bVendor, @source bSource
    select @rcode = 0
    
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
        
    if @slitem is null
    	begin
    	select @msg = 'Missing SL Item#!', @rcode = 1
    	goto bspexit
    	end
    
    select @slvendor=Vendor from SLHD where SLCo=@slco and SL=@sl
    if @slvendor<>@vendor
    	begin
    	select @msg = 'Subcontract is posted to a different vendor', @rcode=1
    	goto bspexit
    	end
    
    select @InUseMth=InUseMth, @InUse=InUseBatchId
    	from SLIT where SLCo = @slco and SL = @sl and SLItem = @slitem
    
    if @@rowcount=0    
    	begin
    	select @msg='SL item does not exist!', @rcode=1
    	goto bspexit    
    	end
        
    if not @InUse is null
    	begin
    	if @InUse=@BatchId and @InUseMth=@BatchMth
    		begin
    		goto itemsuccess
    		end
    	else
    		begin
    		select @source=Source
    	    from HQBC
    		where Co=@slco and BatchId=@InUse and Mth=@InUseMth
    		if @@rowcount<>0
    			begin
    			select @msg = 'Transaction already in use by ' +
    			      isnull(convert(varchar(2),DATEPART(month, @InUseMth)) + '/' +
    			      substring(convert(varchar(4),DATEPART(year, @InUseMth)),3,4),'') +
    				' batch # ' + isnull(convert(varchar(6),@InUse),'') + ' - ' + 'Batch Source: ' + isnull(@source,''),
    				@rcode = 1
    
    			goto bspexit
    		    end
    		else
    		    begin
    			select @msg='Transaction already in use by another batch!', @rcode=1
    			goto bspexit
    		    end
    		end
    	end
        
    itemsuccess:
    select @origsubtot=0, @cursubtot=0, @invsubtot=0
    
    select @msg=Description, @origunits=OrigUnits, @curunits=CurUnits, @invunits=InvUnits, @origunitcost=OrigUnitCost,
    	@curunitcost=CurUnitCost, @origitemtot=OrigCost, @curitemtot=CurCost, @invitemtot=InvCost
    	 from SLIT where SLCo=@slco and SL=@sl and SLItem=@slitem
    
    bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspSLItemVal] TO [public]
GO
