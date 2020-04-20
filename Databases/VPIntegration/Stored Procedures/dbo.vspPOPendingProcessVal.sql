SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/*****************************************/
CREATE proc [dbo].[vspPOPendingProcessVal]
/***********************************************************
* Created By:	GF 05/11/2012 TK-14878 validate Pending PO for processing
* Modified By:
*
* Usage:
* PM Pending PO when the process button is clicked. This procedure will
* validate the pending purchase order to see if already processed
* and if not is the pending purchase order already in a 'PO Entry' batch.
*
* INPUT PARAMETERS
* POCo		to validate
* PO		to validate
* 
* OUTPUT PARAMETERS
* @InUseMth		Pending PO Batch Month or null
* @InUse		Pending PO Batch Id or null
* @ErrMsg      error message if error occurs
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/ 
(@POCo bCompany = 0, @PO VARCHAR(30) = NULL
 ,@InUseMth bMonth = NULL OUTPUT
 ,@InUse bBatchID = NULL OUTPUT
 ,@ErrMsg varchar(255) output)
 
AS
SET NOCOUNT ON

   
declare @rcode int,
		@InUseBy bVPUserName, @Source bSource

SET @rcode = 0
SET @InUse = NULL
SET @InUseMth = NULL

if @POCo IS NULL
	BEGIN
	SELECT @ErrMsg = 'Missing PO Company!', @rcode = 1
	GOTO vspexit
	END
   
if @PO IS NULL
	BEGIN
	SELECT @ErrMsg = 'Missing PO!', @rcode = 1
	GOTO vspexit
	END
	
---- check if the pending purchase order exists in POHD
IF EXISTS(SELECT 1 FROM dbo.bPOHD WHERE POCo=@POCo AND PO=@PO)
	BEGIN
	SELECT @ErrMsg = 'Invalid PO, already exists as an actual PO in POHD.', @rcode = 1
	GOTO vspexit
	END
	
---- check if the pending po exists in a valid PO Entry Batch
SELECT  @InUseMth	  = POHB.Mth
		,@InUse		  = POHB.BatchId
		,@InUseBy	  = HQBC.InUseBy
		,@Source	  = HQBC.Source
FROM dbo.bPOHB POHB
JOIN dbo.bHQBC HQBC ON HQBC.Co = POHB.Co AND HQBC.BatchId = POHB.BatchId
WHERE POHB.Co = @POCo
	AND POHB.PO = @PO
	AND HQBC.Status < 5

IF @@ROWCOUNT <> 0
	BEGIN
	SET @ErrMsg = 'Pending PO is already in an existing PO batch '
				+ CONVERT(VARCHAR(2), DATEPART(MONTH, @InUseMth)) + '/'
				+ SUBSTRING(CONVERT(VARCHAR(4), DATEPART(YEAR, @InUseMth)),3, 4)
				+ ' Batch Id: ' + dbo.vfToString(@InUse) + ' - '
				+ ' In Use By: ' + dbo.vfToString(@InUseBy) + ' - '
				+ ' Batch Source: ' + dbo.vfToString(@Source)
	SET @rcode = 7 ----success conditional
	GOTO vspexit
	END


 
 
   		
vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPOPendingProcessVal] TO [public]
GO
