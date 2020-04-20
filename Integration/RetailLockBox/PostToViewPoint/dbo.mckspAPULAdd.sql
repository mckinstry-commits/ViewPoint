SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[mckspAPULAdd]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[mckspAPULAdd]
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
	,@Number varchar(20)
	,@Company [dbo].[bCompany]
	,@UIMonth smalldatetime
	,@UISeq int
	,@VendorGroup [dbo].[bGroup]
	,@Vendor [dbo].[bVendor]
	,@CollectedInvoiceAmount [dbo].[bDollar]
	,@CollectedTaxAmount [dbo].[bDollar]
	,@PayTerms [dbo].[bPayTerms] OUTPUT
	,@FooterKeyID bigint OUTPUT
	
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
	@JCCType [dbo].[bJCCType], @EMCo [dbo].[bCompany], @INCo [dbo].[bCompany], @MatlGroup [dbo].[bGroup], @GLCo [dbo].[bCompany], @GLAcct [dbo].[bGLAcct],  
	@Description [dbo].[bDesc], @UM [dbo].[bUM], @Units [dbo].[bUnits], @UnitCost [dbo].[bUnitCost], @ECM [dbo].[bECM], @MiscYN [dbo].[bYN], @TaxGroup [dbo].[bGroup],  
	@TaxCode [dbo].[bTaxCode], @TaxType tinyint, @MiscAmt [dbo].[bDollar], @TaxBasis [dbo].[bDollar], @TaxAmt [dbo].[bDollar], @Retainage [dbo].[bDollar], 
	@Discount [dbo].[bDollar], @SMCo [dbo].[bCompany], @SMWorkOrder int, @SMScope int, @SMJCCostType [dbo].[bJCCType]

	
----------------------------------------------
-- Set APUL Variables
----------------------------------------------

SELECT	@rcode = 1

SELECT @LineType = CASE WHEN (@RecordType='PO') THEN 6 WHEN (@RecordType='SC') THEN 7 WHEN (@RecordType='RI') THEN 3 END

SELECT @PayType = CASE WHEN (@LineType=6) THEN 1 WHEN (@LineType=7) THEN 2 WHEN (@LineType=3) THEN 1 END

SELECT @MiscYN = 'N', @PO = NULL, @POItem = NULL, @POItemLine = 1, @SL = NULL, @SLItem = NULL, @SLKeyID = NULL, @ECM = NULL, @Units = 0, @UnitCost = 0, @MiscAmt = 0, @Retainage = 0, @Discount = 0

IF (@CollectedInvoiceAmount < 0)
BEGIN
	SET @GrossAmount = @CollectedInvoiceAmount - @CollectedTaxAmount
END
ELSE 
BEGIN
	SET @GrossAmount = CASE WHEN (@CollectedInvoiceAmount > @CollectedTaxAmount) THEN (@CollectedInvoiceAmount - @CollectedTaxAmount) ELSE 0 END 
END

BEGIN TRY

DECLARE @Count int
SET @Count = 0

----------------------------
-- Save RI Records
----------------------------
IF @LineType = 3
BEGIN
	IF (SELECT COUNT(*) FROM APRL WHERE APCo = @Company AND InvId = @Number AND VendorGroup = @VendorGroup AND Vendor = @Vendor) > 0
	BEGIN
		BEGIN TRANSACTION Trans_addAPUL

		SET @PayTerms = (SELECT PayTerms FROM APRH WHERE APCo = @Company AND InvId = @Number AND VendorGroup = @VendorGroup AND Vendor = @Vendor)

		SET @Line = 0
		DECLARE @GetRI CURSOR

		SET @GetRI = CURSOR FOR
		SELECT ISNULL(RI.PayType, 1), RI.ItemType, RI.JCCo, RI.Job, RI.PhaseGroup, RI.Phase, RI.JCCType, RI.EMCo, RI.INCo, RI.MatlGroup, RI.GLCo, RI.GLAcct, 
		RI.Description, RI.UM, ISNULL(RI.Units, 0), ISNULL(RI.UnitCost, 0), RI.ECM, RI.MiscYN, RI.TaxGroup, RI.TaxCode, RI.TaxType
		FROM APRL RI
		WHERE RI.APCo = @Company AND RI.InvId = @Number AND RI.VendorGroup = @VendorGroup AND RI.Vendor = @Vendor

		OPEN @GetRI
			FETCH NEXT
			FROM @GetRI INTO @PayType, @ItemType, @JCCo, @Job, @PhaseGroup, @Phase, @JCCType, @EMCo, @INCo, @MatlGroup, @GLCo, @GLAcct, @Description, @UM, @Units, @UnitCost, @ECM, @MiscYN, @TaxGroup, @TaxCode, @TaxType
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
					,PayType
					,ItemType
					,JCCo
					,Job
					,PhaseGroup
					,Phase
					,JCCType
					,EMCo
					,INCo
					,MatlGroup
					,GLCo
					,GLAcct
					,Description
					,UM
					,Units
					,UnitCost
					,ECM
					,TaxGroup
					,TaxCode
					,TaxType
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
					,@PayType
					,@ItemType
					,@JCCo
					,@Job
					,@PhaseGroup
					,@Phase
					,@JCCType
					,@EMCo
					,@INCo
					,@MatlGroup
					,@GLCo
					,@GLAcct
					,@Description
					,@UM
					,(CASE WHEN (@UM = 'LS') THEN 0 ELSE @Units END)
					,(CASE WHEN (@UM = 'LS') THEN 0 ELSE @UnitCost END)
					,(CASE WHEN (@UM = 'LS') THEN NULL ELSE @ECM END)
					,@TaxGroup
					,@TaxCode
					,@TaxType
					,@Retainage
					,@Discount
					)
				FETCH NEXT
				FROM @GetRI INTO @PayType, @ItemType, @JCCo, @Job, @PhaseGroup, @Phase, @JCCType, @EMCo, @INCo, @MatlGroup, @GLCo, @GLAcct, @Description, @UM, @Units, @UnitCost, @ECM, @MiscYN, @TaxGroup, @TaxCode, @TaxType
			END

		CLOSE @GetRI
		DEALLOCATE @GetRI

		COMMIT TRANSACTION Trans_addAPUL
		SELECT @rcode=0

	END
END
	
----------------------------
-- Save PO Records
----------------------------
IF @LineType = 6
BEGIN
	IF (SELECT COUNT(*) FROM POHD WHERE POCo = @Company AND (udMCKPONumber = @Number OR PO = @Number)) > 0
	BEGIN
		BEGIN TRANSACTION Trans_addAPUL

		SET @PayTerms = (SELECT PayTerms FROM POHD WHERE POCo = @Company AND (udMCKPONumber = @Number OR PO = @Number))

		SET @Line = 0
		DECLARE @GetPO CURSOR

		SET @GetPO = CURSOR FOR
		SELECT PO.PO, PO.POItem, ISNULL(PO.PayType, 1), PO.ItemType, PO.JCCo, PO.Job, PO.PhaseGroup, PO.Phase, PO.JCCType, PO.GLCo, PO.GLAcct, 
		PO.Description, PO.UM, ISNULL(PO.RemUnits,0), ISNULL(PO.CurUnitCost,0), PO.CurECM, PO.TaxGroup, PO.TaxCode, PO.TaxType, PO.SMCo, PO.SMWorkOrder, PO.SMScope, PO.SMJCCostType
		FROM   POIT PO
		WHERE PO.POCo = @Company AND PO.PO = (SELECT PO FROM POHD WHERE POCo = @Company AND (udMCKPONumber = @Number OR PO = @Number))

		OPEN @GetPO
			FETCH NEXT
			FROM @GetPO INTO @PO, @POItem, @PayType, @ItemType, @JCCo, @Job, @PhaseGroup, @Phase, @JCCType, @GLCo, @GLAcct, @Description, @UM, @Units, @UnitCost, @ECM, @TaxGroup, @TaxCode, @TaxType, @SMCo, @SMWorkOrder, @SMScope, @SMJCCostType
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
					,Units
					,UnitCost
					,ECM
					,TaxGroup
					,TaxCode
					,TaxType
					,Retainage
					,Discount
					,SMCo
					,SMWorkOrder
					,Scope
					,SMJCCostType
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
					,(CASE WHEN (@UM = 'LS') THEN 0 ELSE @Units END)
					,(CASE WHEN (@UM = 'LS') THEN 0 ELSE @UnitCost END)
					,(CASE WHEN (@UM = 'LS') THEN NULL ELSE @ECM END)
					,@TaxGroup
					,@TaxCode
					,@TaxType
					,@Retainage
					,@Discount
					,@SMCo
					,@SMWorkOrder
					,@SMScope
					,@SMJCCostType
					)
				FETCH NEXT
				FROM @GetPO INTO @PO, @POItem, @PayType, @ItemType, @JCCo, @Job, @PhaseGroup, @Phase, @JCCType, @GLCo, @GLAcct, @Description, @UM, @Units, @UnitCost, @ECM, @TaxGroup, @TaxCode, @TaxType, @SMCo, @SMWorkOrder, @SMScope, @SMJCCostType
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
	IF (SELECT COUNT(*) FROM SLIT SL WHERE SL.SLCo = @Company AND SL.SL = @Number) > 0
	BEGIN
		BEGIN TRANSACTION Trans_addAPUL

		SET @PayTerms = (SELECT PayTerms FROM SLHD WHERE SLCo = @Company AND SL = @Number)

		SET @Line = 0
		DECLARE @GetSL CURSOR

		SET @GetSL = CURSOR FOR
		SELECT SL.SL, SL.KeyID, SL.SLItem, SL.ItemType, SL.JCCo, SL.Job, SL.PhaseGroup, SL.Phase, SL.JCCType, SL.GLCo, SL.GLAcct, 
		SL.Description, SL.UM, ISNULL(SL.CurUnits,0), ISNULL(SL.CurUnitCost,0), SL.TaxGroup, SL.TaxCode, SL.TaxType
		FROM   SLIT SL
		WHERE SL.SLCo = @Company AND SL.SL = @Number

		OPEN @GetSL
			FETCH NEXT
			FROM @GetSL INTO @SL, @SLKeyID, @SLItem, @ItemType, @JCCo, @Job, @PhaseGroup, @Phase, @JCCType, @GLCo, @GLAcct, @Description, @UM, @Units, @UnitCost, @TaxGroup, @TaxCode, @TaxType
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
					,Units
					,UnitCost
					,ECM
					,TaxGroup
					,TaxCode
					,TaxType
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
					,(CASE WHEN (@UM = 'LS') THEN 0 ELSE @Units END)
					,(CASE WHEN (@UM = 'LS') THEN 0 ELSE @UnitCost END)
					,(CASE WHEN (@UM = 'LS') THEN NULL ELSE @ECM END)
					,@TaxGroup
					,@TaxCode
					,@TaxType
					,@Retainage
					,@Discount
					)
				FETCH NEXT
				FROM @GetSL INTO @SL, @SLKeyID, @SLItem, @ItemType, @JCCo, @Job, @PhaseGroup, @Phase, @JCCType, @GLCo, @GLAcct, @Description, @UM, @Units, @UnitCost, @TaxGroup, @TaxCode, @TaxType
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
	  GOTO ExitProc
END CATCH

SET @FooterKeyID = (SELECT KeyID FROM APUL WHERE APCo = @Company AND UIMth = @UIMonth AND UISeq = @UISeq)

ExitProc:
RETURN(@rcode)

SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO