SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Stored Procedure dbo.bspPOItemValForPOCB    Script Date: 8/28/99 9:33:09 AM ******/
CREATE proc [dbo].[bspPOItemValForPOCB]
/***********************************************************
* CREATED BY:	GF 04/16/2011 TK-04292
* MODIFIED BY:	GF 7/27/2011 - TK-07144 changed to varchar(30) 
*
* USED BY
*   PO ChangeOrders
*
* USAGE:
* validates PO item, and flags PO item as inuse.
* returns next available POCONum for default.
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
(@POCo bCompany = 0, @PO VARCHAR(30) = null, @POItem bItem=null, 
 @BatchId bBatchID=null, @BatchMth bMonth=null, @Source bSource, @Vendor bVendor=null, 
 @ItemType bItem output, @POItemExists bYN output, @POCONum smallint = NULL output,
 @msg varchar(255) output)
as
set nocount on
   
declare @rcode int, @InUse bBatchID, @InUseMth bMonth, @InUseBy bVPUserName,
		@RecvYN bYN, @POVendor bVendor, @ItemDesc bItemDesc
		
SET @rcode = 0
SET @POItemExists = 'Y'

if @POCo is null
	begin
	select @msg = 'Missing PO Company!', @rcode = 1
	goto bspexit
	end

if @PO is null
	begin
	select @msg = 'Missing PO!', @rcode = 1
	goto bspexit
	end

if @POItem is null
	begin
	select @msg = 'Missing PO Item#!', @rcode = 1
	goto bspexit
	end

-- validate SL Item and get info
SELECT @InUseMth=POIT.InUseMth, @InUse=POIT.InUseBatchId, @RecvYN=RecvYN,
		@ItemType=ItemType, @POVendor=POHD.Vendor, @ItemDesc=POIT.Description
FROM dbo.POIT
INNER JOIN dbo.POHD on POHD.POCo=POIT.POCo and POHD.PO=POIT.PO
WHERE POIT.POCo = @POCo and POIT.PO = @PO and POItem = @POItem
if @@rowcount = 0
	begin
	select @msg='PO item does not exist!', @rcode=1, @POItemExists = 'N'
	goto bspexit
	end
   
if @Source='AP Entry'
	begin
	if @Vendor <> @POVendor
		begin
		select @msg='Vendor does not match PO Vendor!'
		goto bspexit
		end
	end

if @Source='PO Receipt'
	begin
	if @RecvYN='N'
		begin
		select @msg='Item is not flagged to be received.', @rcode=1
		goto bspexit
		end
	end
   
---- get current or next available Change Order #
select @POCONum = POCONum
from dbo.bPOCB
where Co = @POCo and Mth = @BatchMth and BatchId = @BatchId and PO = @PO
if @@rowcount = 0
	begin
 	select @POCONum = isnull(max(POCONum),0) + 1
	from dbo.bPOCD where POCo = @POCo and PO = @PO
 	end


SET @msg = @ItemDesc


if not @InUse is null
	begin
	if @InUse=@BatchId and @InUseMth=@BatchMth
		BEGIN
		GOTO bspexit
		END
else			
	select @Source = Source
    from dbo.HQBC with (nolock)
	where Co=@POCo and Mth=@InUseMth and BatchId=@InUse 
	if @@rowcount <> 0
		begin
		select @msg = 'PO item already in use by ' +
		      convert(varchar(2),DATEPART(month, @InUseMth)) + '/' + 
		      substring(convert(varchar(4),DATEPART(year, @InUseMth)),3,4) + 
			' batch # ' + convert(varchar(6),@InUse) + ' - ' + 'Batch Source: ' 
			+ @Source, @rcode = 1
		goto bspexit
		end
	else
		begin
		select @msg='PO item already in use by another batch!', @rcode=1
		goto bspexit	
		end
end
   



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPOItemValForPOCB] TO [public]
GO
