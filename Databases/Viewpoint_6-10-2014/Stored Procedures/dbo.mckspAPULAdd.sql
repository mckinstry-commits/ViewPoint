SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- **************************************************************
--  PURPOSE: Adds new APUL record
--    INPUT: Values list (see below)
--   RETURN: ErrCode (0 if successful, 1 if not)
--   AUTHOR: Brian Gannon-McKinley
--  -------------------------------------------------------------
--  HISTORY:
--    04/26/2014  Created stored procedure
--    05/16/2014  Tested stored procedure
-- **************************************************************

CREATE PROCEDURE [dbo].[mckspAPULAdd]
	@RecordType nvarchar(30)
	,@CollectedInvoiceNumber varchar(15)
	,@Company [dbo].[bCompany]
	,@UIMonth smalldatetime
	,@UISeq int
	,@VendorGroup [dbo].[bGroup]
	,@CollectedInvoiceAmount [dbo].[bDollar]
	,@CollectedTaxAmount [dbo].[bDollar]
	
AS

SET NOCOUNT ON

-- Common variables
DECLARE  @rcode int, @Line smallint, @LineType tinyint, @ItemType tinyint, @GrossAmount [dbo].[bDollar]
-- PO variables
DECLARE @PO varchar(30), @POItem [dbo].[bItem], @PayType tinyint, @POItemLine int
-- Subcontract variables
DECLARE @SL varchar(30), @SLItem [dbo].[bItem], @SLKeyID bigint
-- Detail record variables
DECLARE @JCCo [dbo].[bCompany], @Job [dbo].[bJob], @PhaseGroup [dbo].[bGroup], @Phase [dbo].[bPhase], 
	@JCCType [dbo].[bJCCType], @GLCo [dbo].[bCompany], @GLAcct [dbo].[bGLAcct], @Description [dbo].[bItemDesc], 
	@UM [dbo].[bUM], @UnitCost [dbo].[bUnitCost], @ECM [dbo].[bECM], @MiscYN [dbo].[bYN], @TaxGroup [dbo].[bGroup], @TaxCode [dbo].[bTaxCode], 
	@MiscAmt [dbo].[bDollar], @TaxBasis [dbo].[bDollar], @TaxAmt [dbo].[bDollar], @Retainage [dbo].[bDollar], @Discount [dbo].[bDollar]

	
----------------------------------------------
-- Set APUL Variables
----------------------------------------------

SELECT	@rcode = 1

SELECT @LineType = CASE WHEN (@RecordType='PO') THEN 6 WHEN (@RecordType='SC') THEN 7 END

SELECT @PayType = CASE WHEN (@LineType=6) THEN 1 WHEN (@LineType=7) THEN 2 END

SELECT @MiscYN = 'N', @PO = NULL, @POItem = NULL, @POItemLine = 1, @SL = NULL, @SLItem = NULL, @SLKeyID = NULL, @UnitCost = 0, @MiscAmt = 0, @Retainage = 0, @Discount = 0

SELECT @GrossAmount = CASE WHEN (@CollectedInvoiceAmount > @CollectedTaxAmount) THEN (@CollectedInvoiceAmount - @CollectedTaxAmount) ELSE 0 END 

BEGIN TRY

DECLARE @Count int
SET @Count = 0
	
----------------------------
-- Save PO Records
----------------------------
IF @LineType = 6
BEGIN
	IF (SELECT COUNT(*) FROM POHD WHERE POCo = @Company AND udMCKPONumber = @CollectedInvoiceNumber) > 0
	BEGIN
		BEGIN TRANSACTION Trans_addAPUL

		SET @Line = 0
		DECLARE @GetPO CURSOR

		SET @GetPO = CURSOR FOR
		SELECT PO.PO, PO.POItem, ISNULL(PO.PayType, 1), PO.ItemType, PO.JCCo, PO.Job, PO.PhaseGroup, PO.Phase, PO.JCCType, PO.GLCo, PO.GLAcct, 
		PO.Description, PO.UM, ISNULL(PO.CurECM, 'E'), PO.TaxGroup, PO.TaxCode
		FROM   POIT PO
		WHERE PO.POCo = @Company AND PO.PO = (SELECT PO FROM POHD WHERE POCo = @Company AND udMCKPONumber = @CollectedInvoiceNumber)

		OPEN @GetPO
			FETCH NEXT
			FROM @GetPO INTO @PO, @POItem, @PayType, @ItemType, @JCCo, @Job, @PhaseGroup, @Phase, @JCCType, @GLCo, @GLAcct, @Description, @UM, @ECM, @TaxGroup, @TaxCode
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @Line = @Line + 1
				INSERT INTO [dbo].[bAPUL] (
					APCo
					,Line
					,UIMth
					,UISeq
					,LineType
					,VendorGroup
					,GrossAmt
					,MiscAmt
					,MiscYN
					,TaxBasis
					,TaxAmt
					,PO
					,POItem
					,POItemLine
					,PayType
					,ItemType
					,JCCo
					,Job
					,PhaseGroup
					,Phase
					,JCCType
					,GLCo
					,GLAcct
					,Description
					,UM
					,UnitCost
					,ECM
					,TaxGroup
					,TaxCode
					,Retainage
					,Discount
					)
				VALUES (
					@Company
					,@Line
					,@UIMonth
					,@UISeq
					,@LineType
					,@VendorGroup
					,(CASE WHEN (@Line = 1) THEN @GrossAmount ELSE 0 END)
					,@MiscAmt
					,@MiscYN
					,(CASE WHEN (@Line = 1) THEN @GrossAmount ELSE 0 END)
					,(CASE WHEN (@Line = 1) THEN @CollectedTaxAmount ELSE 0 END)
					,@PO
					,@POItem
					,@POItemLine
					,@PayType
					,@ItemType
					,@JCCo
					,@Job
					,@PhaseGroup
					,@Phase
					,@JCCType
					,@GLCo
					,@GLAcct
					,@Description
					,@UM
					,@UnitCost
					,@ECM
					,@TaxGroup
					,@TaxCode
					,@Retainage
					,@Discount
					)
				FETCH NEXT
				FROM @GetPO INTO @PO, @POItem, @PayType, @ItemType, @JCCo, @Job, @PhaseGroup, @Phase, @JCCType, @GLCo, @GLAcct, @Description, @UM, @ECM, @TaxGroup, @TaxCode
			END

		CLOSE @GetPO
		DEALLOCATE @GetPO

		COMMIT TRANSACTION Trans_addAPUL
		SELECT @rcode=0

	END
END

----------------------------
-- Save Subcontract Records
----------------------------
IF @LineType = 7
BEGIN
	IF (SELECT COUNT(*) FROM SLIT SL WHERE SL.SLCo = @Company AND SL.SL = @CollectedInvoiceNumber) > 0
	BEGIN
		BEGIN TRANSACTION Trans_addAPUL

		SET @Line = 0
		DECLARE @GetSL CURSOR

		SET @GetSL = CURSOR FOR
		SELECT SL.SL, SL.KeyID, SL.SLItem, SL.ItemType, SL.JCCo, SL.Job, SL.PhaseGroup, SL.Phase, SL.JCCType, SL.GLCo, SL.GLAcct, 
		SL.Description, SL.UM, SL.TaxGroup, SL.TaxCode
		FROM   SLIT SL
		WHERE SL.SLCo = @Company AND SL.SL = @CollectedInvoiceNumber

		OPEN @GetSL
			FETCH NEXT
			FROM @GetSL INTO @SL, @SLKeyID, @SLItem, @ItemType, @JCCo, @Job, @PhaseGroup, @Phase, @JCCType, @GLCo, @GLAcct, @Description, @UM, @TaxGroup, @TaxCode
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @Line = @Line + 1
				INSERT INTO [dbo].[bAPUL] (
					APCo
					,Line
					,UIMth
					,UISeq
					,LineType
					,VendorGroup
					,GrossAmt
					,MiscAmt
					,MiscYN
					,TaxBasis
					,TaxAmt
					,SL
					,SLKeyID
					,SLItem
					,PayType
					,ItemType
					,JCCo
					,Job
					,PhaseGroup
					,Phase
					,JCCType
					,GLCo
					,GLAcct
					,Description
					,UM
					,UnitCost
					,TaxGroup
					,TaxCode
					,Retainage
					,Discount
					)
				VALUES (
					@Company
					,@Line
					,@UIMonth
					,@UISeq
					,@LineType
					,@VendorGroup
					,(CASE WHEN (@Line = 1) THEN @GrossAmount ELSE 0 END)
					,@MiscAmt
					,@MiscYN
					,(CASE WHEN (@Line = 1) THEN @GrossAmount ELSE 0 END)
					,(CASE WHEN (@Line = 1) THEN @CollectedTaxAmount ELSE 0 END)
					,@SL
					,@SLKeyID
					,@SLItem
					,@PayType
					,@ItemType
					,@JCCo
					,@Job
					,@PhaseGroup
					,@Phase
					,@JCCType
					,@GLCo
					,@GLAcct
					,@Description
					,@UM
					,@UnitCost
					,@TaxGroup
					,@TaxCode
					,@Retainage
					,@Discount
					)
				FETCH NEXT
				FROM @GetSL INTO @SL, @SLKeyID, @SLItem, @ItemType, @JCCo, @Job, @PhaseGroup, @Phase, @JCCType, @GLCo, @GLAcct, @Description, @UM, @TaxGroup, @TaxCode
			END

		CLOSE @GetSL
		DEALLOCATE @GetSL

		COMMIT TRANSACTION Trans_addAPUL
		SELECT @rcode=0
	END
END

END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION Trans_addAPUL
	  SELECT @rcode=1
END CATCH

ExitProc:
RETURN(@rcode)

SET QUOTED_IDENTIFIER OFF 
GO
