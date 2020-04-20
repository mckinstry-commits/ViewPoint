SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  proc [dbo].[vspPOItemLineValForReceipts]
/***********************************************************
* CREATED BY:	GF 08/21/2011 TK-07165 ??
* MODIFIED BY:
*				JB 12/6/12 Removed the SM line type restriciton.
*
* USED BY
*   PO Receiving
*
*
* USAGE:
* validates PO Item Line, and flags PO Item Line as inuse
* an error is returned if any of the following occurs
*
* INPUT PARAMETERS
* POCo  PO Co to validate against 
* PO to validate
* PO Item to validate
* PO Item Line to validate
* BatchId
* BatchMth
* 
* OUTPUT PARAMETERS
* @itemtype The Purchase orders Item Type
* @Msg      error message if error occurs otherwise Description of PO, Vendor, 
* Vendor group,Vendor Name,BackOrdered
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@POCo bCompany = 0, @PO VARCHAR(30) = NULL, @POItem bItem = NULL, 
 @POItemLine INT = NULL, @BatchId bBatchID = NULL,
 @BatchMth bMonth = NULL, @Source bSource = NULL, 
 @ItemType TINYINT = NULL OUTPUT, @Msg varchar(255) OUTPUT)
AS
SET NOCOUNT ON

DECLARE @rcode int, @InUse bBatchID, @InUseMth bMonth, @InUseBy bVPUserName,
		@RecvYN bYN, @ItemInUseMth bMonth, @ItemInUse bBatchID
		
SET @rcode = 0
   
if @POCo is null
	BEGIN	
	SELECT @Msg = 'Missing PO Company!', @rcode = 1
	GOTO vspexit
	END

if @PO is null
	BEGIN	
	SELECT @Msg = 'Missing PO!', @rcode = 1
	GOTO vspexit
	END

if @POItem is null
	BEGIN
	SELECT @Msg = 'Missing PO Item!', @rcode = 1
	GOTO vspexit
	END

if @POItemLine is null
	BEGIN
	SELECT @Msg = 'Missing PO Item Line!', @rcode = 1
	GOTO vspexit
	END
   
   
---- get PO Item and line info
SELECT  @InUseMth = line.InUseMth, @InUse = line.InUseBatchId,
		@ItemType = line.ItemType, @RecvYN = item.RecvYN,
		@ItemInUseMth = item.InUseMth, @ItemInUse = item.InUseBatchId
FROM dbo.POItemLine line
INNER JOIN dbo.POIT item ON item.POCo=line.POCo AND item.PO=line.PO AND item.POItem=line.POItem
where line.POCo = @POCo 
	AND line.PO = @PO
	AND line.POItem = @POItem
	AND line.POItemLine = @POItemLine
if @@rowcount = 0
   	BEGIN
   	SELECT @Msg = 'PO Item Line does not exist!', @rcode = 1
   	GOTO vspexit
   	END
   
if @Source = 'PO Receipt'
	BEGIN
	IF @RecvYN='N'
		BEGIN
		SELECT @Msg = 'PO Item is not flagged to be received.', @rcode = 1
		GOTO vspexit
		END
	end

---- check if PO item line is in use
IF ISNULL(@InUse,'') <> ''
	BEGIN
	IF @InUse = @BatchId AND @InUseMth = @BatchMth
		BEGIN
		GOTO Item_Success
		END
	ELSE
		BEGIN
   		SELECT @Source = Source
   	    FROM dbo.HQBC
   		WHERE Co = @POCo and Mth = @InUseMth and BatchId = @InUse 
   		if @@ROWCOUNT <> 0
   			BEGIN
   			SELECT @Msg = 'PO Item Line already in use by ' +
				  CONVERT(VARCHAR(2), DATEPART(MONTH, @InUseMth)) + '/' + 
				  SUBSTRING(CONVERT(VARCHAR(4), DATEPART(YEAR, @InUseMth)), 3, 4) + 
				' Batch ID ' + CONVERT(VARCHAR(6), @InUse) + ' -' +
				' Batch Source: ' + @Source, @rcode = 1
   			GOTO vspexit
   			END
   		ELSE
   			BEGIN
   			SELECT @Msg='PO Item line already in use by another batch!', @rcode=1
   			GOTO vspexit	
   			END
   		END
	END
	

---- when line = 1 check if the PO Item is in use
IF @POItemLine > 1 GOTO Item_Success

IF ISNULL(@ItemInUse,'') <> ''
	BEGIN
	IF @ItemInUse = @BatchId AND @ItemInUseMth = @BatchMth
		BEGIN
		GOTO Item_Success
		END
	ELSE
		BEGIN
   		SELECT @Source = Source
   	    FROM dbo.HQBC
   		WHERE Co = @POCo and Mth = @ItemInUseMth and BatchId = @ItemInUse 
   		if @@ROWCOUNT <> 0
   			BEGIN
   			SELECT @Msg = 'PO Item already in use by ' +
				  CONVERT(VARCHAR(2), DATEPART(MONTH, @ItemInUseMth)) + '/' + 
				  SUBSTRING(CONVERT(VARCHAR(4), DATEPART(YEAR, @ItemInUseMth)), 3, 4) + 
				' Batch ID ' + CONVERT(VARCHAR(6), @ItemInUse) + ' -' +
				' Batch Source: ' + @Source, @rcode = 1
   			GOTO vspexit
   			END
   		ELSE
   			BEGIN
   			SELECT @Msg='PO Item already in use by another batch!', @rcode=1
   			GOTO vspexit	
   			END
   		END
	END

   
   
Item_Success:
   
   
   
--SELECT @Msg = Description
--from dbo.POIT
--WHERE POCo = @POCo
--	AND PO = @PO
--	and POItem = @POItem




vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPOItemLineValForReceipts] TO [public]
GO
