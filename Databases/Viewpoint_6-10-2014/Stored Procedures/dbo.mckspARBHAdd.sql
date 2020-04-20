SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- **************************************************************
--  PURPOSE: Adds new ARBH record
--    INPUT: Values list (see below)
--   RETURN: ErrCode (0 if successful, 1 if not)
--   AUTHOR: Brian Gannon-McKinley
--  -------------------------------------------------------------
--  HISTORY:
--    05/20/2014  Created stored procedure
--    05/20/2014  Tested stored procedure
-- **************************************************************

CREATE PROCEDURE [dbo].[mckspARBHAdd]
	@Company [dbo].[bCompany]
	,@UIMonth smalldatetime
	,@BatchId [dbo].[bBatchID]
	,@CustGroup [dbo].[bGroup]
	,@Customer [dbo].[bCustomer]
	,@Description [dbo].[bDesc]
	,@TransactionDate smalldatetime
	,@OriginalAmount [dbo].[bDollar]
	,@Notes varchar(max)

AS

SET NOCOUNT ON

DECLARE  @rcode int, 
	@BatchSeq int, @TransType char(1), @ARTrans [dbo].[bTrans], @Source [dbo].[bSource], @ARTransType char(1), 
	@RecType tinyint, @JCCo [dbo].[bCompany], @Contract [dbo].[bContract], 
	@CustRef varchar(20), @CustPO varchar(20), @Invoice char(10), @CheckNo char(10), @MSCo [dbo].[bCompany], 
	@DueDate [dbo].[bDate], @DiscDate [dbo].[bDate], @CheckDate [dbo].[bDate], @AppliedMth [dbo].[bMonth], 
	@AppliedTrans [dbo].[bTrans], @CMCo [dbo].[bCompany], @CMAcct [dbo].[bCMAcct], @CMDeposit [dbo].[bCMRef],
	@PayTerms [dbo].[bPayTerms]



----------------------------------------------
-- Set APUI Variables
----------------------------------------------

SELECT	@rcode = -1
		,@TransType = 'A'
		,@ARTrans = NULL
		,@Source = 'AR Invoice'
		,@ARTransType = 'P'
		,@RecType = NULL
		,@JCCo = NULL
		,@Contract = NULL
		,@CustRef = NULL
		,@CustPO = NULL
		,@Invoice = NULL
		,@CheckNo = NULL
		,@MSCo = NULL
		,@DueDate = NULL
		,@DiscDate = NULL
		,@CheckDate= NULL
		,@AppliedMth = NULL
		,@AppliedTrans = NULL
		,@CMCo = (SELECT CMCo FROM ARCO WHERE ARCo = @Company)
		,@CMAcct = (SELECT CMAcct FROM ARCO WHERE ARCo = @Company)
		,@CMDeposit = (SELECT [dbo].[fnMckFormatWithLeading]('xxxx', ' ', 10))
		,@PayTerms = NULL

EXECUTE @BatchSeq = [dbo].[bspGetNextBatchSeq] @Company, @UIMonth, @BatchId
		

----------------------------
-- Save The Record
----------------------------
BEGIN TRY
BEGIN TRANSACTION Trans_addARBH

INSERT INTO [dbo].[bARBH] (
	 Co
	,Mth	
	,BatchId	
	,BatchSeq	
	,TransType	
	,ARTrans	
	,Source	
	,ARTransType	
	,CustGroup	
	,Customer	
	,RecType	
	,JCCo	
	,Contract	
	,CustRef	
	,CustPO	
	,Invoice	
	,CheckNo	
	,Description	
	,MSCo	
	,TransDate	
	,DueDate	
	,DiscDate	
	,CheckDate	
	,AppliedMth	
	,AppliedTrans	
	,CMCo	
	,CMAcct	
	,CMDeposit	
	,CreditAmt	
	,PayTerms	
	,Notes
	)
VALUES (
	 @Company
	,@UIMonth	
	,@BatchId	
	,@BatchSeq	
	,@TransType	
	,@ARTrans	
	,@Source	
	,@ARTransType	
	,@CustGroup	
	,@Customer	
	,@RecType	
	,@JCCo	
	,@Contract	
	,@CustRef	
	,@CustPO	
	,@Invoice	
	,@CheckNo	
	,@Description	
	,@MSCo	
	,@TransactionDate	
	,@DueDate	
	,@DiscDate	
	,@CheckDate	
	,@AppliedMth	
	,@AppliedTrans	
	,@CMCo	
	,@CMAcct	
	,@CMDeposit	
	,@OriginalAmount
	,@PayTerms	
	,@Notes
	)

COMMIT TRANSACTION Trans_addARBH
SELECT @rcode=0

END TRY


BEGIN CATCH
	ROLLBACK TRANSACTION Trans_addARBH
	SELECT @rcode=1
END CATCH


ExitProc:
RETURN(@rcode)

SET QUOTED_IDENTIFIER OFF 
GO
