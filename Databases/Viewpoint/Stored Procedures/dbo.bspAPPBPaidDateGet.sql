SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspAPPBPaidDateGet]
/********************************************************
* CREATED BY: 	MV 11/26/03
* MODIFIED BY:  KK 04/10/12 - B-09140 Added paymethod Credit Service to return Paid Date
*									  Refactored as per Standard Best Practice
*		 
*              
* USAGE:
* 		Retrieves the Paid Date from the EFT or Credit Service payments for the 
*       batch and month passed in for AP Payment Posting.
*       Used by Pay Edit to run the EFT Remittance Report or the Credit Service Remittance Report
*
* USED IN:
*       Pay Edit
*
* INPUT PARAMETERS:
*		CO
*       Mth
*       BatchId
*		Paymethod 'E' or 'S'
*
* OUTPUT PARAMETERS:
*	    Returns the Paid Date
*	    Error Message, if one
*
* RETURN VALUE:
* 	0 = Success
*	1 = Failure + Message
*
**********************************************************/

(@co  bCompany, 
 @mth bMonth, 
 @batchid bBatchID,
 @paymethod char(1))

AS
SET NOCOUNT ON

DECLARE @rcode int,
		@msg varchar (255)
		
IF @co IS NULL
BEGIN
	SELECT @msg = 'Missing AP Company'
	RETURN 1
END
   
IF @mth IS NULL
BEGIN
	SELECT @msg = 'Missing Month'
	RETURN 1
END
   
IF @batchid IS NULL
BEGIN
	SELECT @msg = 'Missing BatchId'
	RETURN 1
END

IF @paymethod = 'E'
BEGIN   
	SELECT 'PaidDate' = (SELECT TOP 1 PaidDate FROM bAPPB 
					 WHERE Co=@co 
					       AND Mth=@mth 
					       AND BatchId=@batchid 
					       AND PayMethod='E')
END

ELSE IF @paymethod = 'S'
BEGIN 
SELECT 'PaidDate' = (SELECT TOP 1 PaidDate FROM bAPPB 
					 WHERE Co=@co 
					       AND Mth=@mth 
					       AND BatchId=@batchid 
					       AND PayMethod='S')
END
   
RETURN 0

GO
GRANT EXECUTE ON  [dbo].[bspAPPBPaidDateGet] TO [public]
GO
