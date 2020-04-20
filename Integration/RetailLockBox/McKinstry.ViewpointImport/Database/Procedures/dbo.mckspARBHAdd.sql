USE [Viewpoint]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[mckspARBHAdd]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[mckspARBHAdd]
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
	,@CheckNumber char(10)
	,@Description [dbo].[bDesc]
	,@TransactionDate smalldatetime
	,@CheckDate smalldatetime
	,@CheckAmount [dbo].[bDollar]
	,@DepositNumber [dbo].[bCMRef]
	,@Notes varchar(max)
	,@KeyID bigint OUTPUT

AS

SET NOCOUNT ON

DECLARE  @rcode int, 
	@BatchSeq int, @TransType char(1), @ARTrans [dbo].[bTrans], @Source [dbo].[bSource], @ARTransType char(1), 
	@RecType tinyint, @JCCo [dbo].[bCompany], @Contract [dbo].[bContract], 
	@CustRef varchar(20), @InvoiceNumber char(10), @CustPO varchar(20), @MSCo [dbo].[bCompany], 
	@DueDate [dbo].[bDate], @DiscDate [dbo].[bDate], @AppliedMth [dbo].[bMonth], 
	@AppliedTrans [dbo].[bTrans], @CMCo [dbo].[bCompany], @CMAcct [dbo].[bCMAcct],
	@DepositSeed varchar(9), @PayTerms [dbo].[bPayTerms]



----------------------------------------------
-- Set APUI Variables
----------------------------------------------

SELECT	@rcode = -1
		,@TransType = 'A'
		,@ARTrans = NULL
		,@Source = 'AR Receipt'
		,@ARTransType = 'P'
		,@RecType = NULL
		,@JCCo = NULL
		,@Contract = NULL
		,@CustRef = NULL
		,@InvoiceNumber = NULL
		,@CustPO = NULL
		,@MSCo = NULL
		,@DueDate = NULL
		,@DiscDate = NULL
		,@AppliedMth = NULL
		,@AppliedTrans = NULL
		,@CMCo = 1 -- CM Company is always 1 for RLB
		,@CMAcct = 4 -- CM Account is always '4750 KeyBank' for RLB deposits
		,@PayTerms = NULL

DECLARE @BatchSeqResult AS Table (Seq int)
INSERT INTO @BatchSeqResult EXEC [dbo].[bspGetNextBatchSeq] @Company, @UIMonth, @BatchId
SELECT @BatchSeq = Seq FROM @BatchSeqResult
	

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
	,@InvoiceNumber
	,@CheckNumber	
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
	,@DepositNumber
	,@CheckAmount
	,@PayTerms	
	,@Notes
	)

	SET @KeyID = SCOPE_IDENTITY()

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

SET ANSI_NULLS ON 
GO