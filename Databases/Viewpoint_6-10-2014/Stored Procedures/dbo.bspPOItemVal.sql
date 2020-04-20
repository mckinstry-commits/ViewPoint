SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPOItemVal    Script Date: 8/28/99 9:33:09 AM ******/
   CREATE  proc [dbo].[bspPOItemVal]
   /***********************************************************
    * CREATED BY	: kf 3/24/97
    * MODIFIED BY	: kf 3/24/97
    *					GF 07/09/2003 - #21682 speed improvements
	*					DC 06/02/08  - #127180 Add the Auto Add PO Item to the PO Change Order batch program 
	*					GF 7/27/2011 - TK-07144 changed to varchar(30) 
    *
    * USED BY
    *   PO ChangeOrders
    *   PO Receiving
    *   AP Entry
    *
    *
    * USAGE:
    * validates PO item, and flags PO item as inuse
    * an error is returned if any of the following occurs
    *
    * INPUT PARAMETERS
    *   POCo  PO Co to validate against 
    *   PO to validate
    *   PO Item to validate
    *   BatchId
    *   BatchMth
    * 
    * OUTPUT PARAMETERS
    *   @itemtype The Purchase orders Item Type
    *   @msg      error message if error occurs otherwise Description of PO, Vendor, 
    *   Vendor group,Vendor Name,BackOrdered
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
       (@poco bCompany = 0, @po VARCHAR(30) = null, @poitem bItem=null, 
   	@BatchId bBatchID=null, @BatchMth bMonth=null, @source bSource, @vendor bVendor=null, 
   	@itemtype bItem output, 
	@poitemexist bYN output,  --DC #127180
	@msg varchar(100) output )
   as
   
   set nocount on
   
   declare @rcode int, @InUse bBatchID, @InUseMth bMonth, @inuseby bVPUserName, @recvyn bYN, @povendor bVendor
   select @rcode = 0
	select @poitemexist = 'Y'  --DC #127180
   
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
   
   
   if @poitem is null
   	begin
   	select @msg = 'Missing PO Item#!', @rcode = 1
   	goto bspexit
   	end
   
   
   select @InUseMth=POIT.InUseMth, @InUse=POIT.InUseBatchId, @recvyn=RecvYN, @itemtype=ItemType, @povendor=POHD.Vendor
   from POIT with (nolock)
   join POHD with (nolock) on POHD.POCo=POIT.POCo and POHD.PO=POIT.PO
   where POIT.POCo = @poco and POIT.PO = @po and POItem = @poitem
   if @@rowcount=0
   	begin
   	select @msg='PO item does not exist!', @rcode=1, @poitemexist = 'N'  --DC #127180
   	goto bspexit
   	end
   
   if @source='AP Entry'
   	begin
   	if @vendor<>@povendor
   		begin
   		select @msg='Vendor does not match PO Vendor!'/*, @rcode=1*/
   		goto bspexit
   		end
   	end
   
   if @source='PO Receipt'
   	begin
   	if @recvyn='N'
   		begin
   		select @msg='Item is not flagged to be received.', @rcode=1
   		goto bspexit
   		end
   	end
   
   if not @InUse is null
   	begin
   	if @InUse=@BatchId and @InUseMth=@BatchMth
   		begin
   			goto itemsuccess
   		end
   	else			
   		select @source=Source
   	    from HQBC with (nolock)
   		where Co=@poco and Mth=@InUseMth and BatchId=@InUse 
   		if @@rowcount<>0
   			begin
   			select @msg = 'PO item already in use by ' +
   			      convert(varchar(2),DATEPART(month, @InUseMth)) + '/' + 
   			      substring(convert(varchar(4),DATEPART(year, @InUseMth)),3,4) + 
   				' batch # ' + convert(varchar(6),@InUse) + ' - ' + 'Batch Source: ' 
   				+ @source, @rcode = 1
   			goto bspexit
   			end
   		else
   			begin
   			select @msg='PO item already in use by another batch!', @rcode=1
   			goto bspexit	
   			end
   	end
   
   itemsuccess:
   
   select @msg=Description from POIT with (nolock) where POCo=@poco and PO=@po and POItem=@poitem
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOItemVal] TO [public]
GO
