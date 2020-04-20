SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPOItemPOCDClosedCheck    Script Date:  ******/
CREATE proc [dbo].[vspPOItemPOCDClosedCheck]
/***********************************************************
* CREATED BY: 		DC  04/25/08  #128037
* MODIFIED By :		GF 7/27/2011 - TK-07144 changed to varchar(30)
*
* USAGE:
* Checks POCD joined to HQBC to see if the PO was closed
*	and its backordered amounts were set to zero
*
* INPUT PARAMETERS
*   @co		PO Company
*	@po		PO #
*	@poitem	PO Item
*
* OUTPUT PARAMETERS
*   @msg      error message 
*
* RETURN VALUE
*   0         success
*   1         Failure
******************************************************************/ 
  
(@co bCompany, @po VARCHAR(30), @poitem bItem, @msg varchar(255) output)
as
  
set nocount on
  
declare @rcode int
  
select @rcode = 0
  
if @co is null
	begin
	select @msg = 'Missing PO Company!', @rcode = 1
	goto vspexit
	end

if @po is null
	begin
	select @msg = 'Missing PO Number!', @rcode = 1
	goto vspexit
	end

if @poitem is null
	begin
	select @msg = 'Missing PO Item Number!', @rcode = 1
	goto vspexit
	end

if exists (
		SELECT 1
		FROM POCD with (nolock) 
		JOIN HQBC on HQBC.Co = POCD.POCo and HQBC.Mth = POCD.Mth and HQBC.BatchId = POCD.BatchId
		WHERE POCD.POCo = @co and POCD.PO = @po and POItem = @poitem
			AND HQBC.Source = 'PO Close')
	BEGIN
		SELECT @msg = 'This PO was closed and its backordered amounts were set to zero.  You cannot edit this item.', @rcode = 1
		GOTO vspexit
	END
		
  
vspexit:
  	
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPOItemPOCDClosedCheck] TO [public]
GO
