USE [Viewpoint]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[mckspAPUIAdd]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[mckspAPUIAdd]
GO

-- **************************************************************
--  PURPOSE: Adds new APUI record
--    INPUT: Values list (see below)
--   RETURN: ErrCode (0 if successful, 1 if not)
--   AUTHOR: Brian Gannon-McKinley
--  -------------------------------------------------------------
--  HISTORY:
--    12/05/2014  Created stored procedure
--    12/05/2014  Tested stored procedure
--    03/28/2015  Updated stored procedure
-- **************************************************************

CREATE PROCEDURE [dbo].[mckspAPUIAdd]
	@Company [dbo].[bCompany]
	,@UIMonth [dbo].[bMonth]
	,@VendorGroup [dbo].[bGroup]
	,@Vendor [dbo].[bVendor]
	,@CollectedInvoiceNumber varchar(15)
	,@Description [dbo].[bDesc]
	,@Notes varchar(2000)
	,@CollectedInvoiceDate [dbo].[bDate]
	,@CollectedInvoiceAmount [dbo].[bDollar]
	,@CollectedShippingAmount [dbo].[bDollar]
	,@HeaderKeyID bigint OUTPUT
	,@UISeq int OUTPUT

AS

SET NOCOUNT ON

DECLARE  @rcode int, @Message varchar(200), @PayMethod char(1), @PayTerms [dbo].[bPayTerms], @CMCo [dbo].[bCompany], 
	@CMAcct [dbo].[bCMAcct], @SeparatePayYN [dbo].[bYN], @V1099YN [dbo].[bYN], @V1099Type varchar(10), @V1099Box tinyint, 
	@PayOverrideYN [dbo].[bYN], @ReviewerGroup varchar(10), @APBatchProcessedYN [dbo].[bYN]

----------------------------------------------
-- Set APUI Variables
----------------------------------------------

SELECT	@rcode = -1, 
	@PayOverrideYN = 'N', @SeparatePayYN = 'N', @ReviewerGroup = NULL, @APBatchProcessedYN = 'Y'

SELECT @CMCo = CMCo, @CMAcct = CMAcct 
	FROM APCO WHERE CMCo = @Company

SELECT @PayTerms = PayTerms, @PayMethod = PayMethod, @V1099YN = V1099YN, @V1099Type = V1099Type, @V1099Box = V1099Box
	FROM APVM WHERE VendorGroup = @VendorGroup AND Vendor = @Vendor

-- Fetch next UI sequence
EXECUTE [dbo].[vspAPUIGetNextSeq] @Company, @UIMonth, @UISeq OUTPUT, @Message OUTPUT

-- Fetch due date
DECLARE @DiscDate [dbo].[bDate], @DueDate [dbo].[bDate], 
	@DiscRate [dbo].[bPct], @PayTermsMsg varchar(60)

EXECUTE [dbo].[bspHQPayTermsDateCalc] @PayTerms, @CollectedInvoiceDate, @DiscDate OUTPUT, @DueDate OUTPUT, @DiscRate OUTPUT, @PayTermsMsg OUTPUT

----------------------------
-- Save The Record
----------------------------
BEGIN TRY
BEGIN TRANSACTION Trans_addAPUI

INSERT INTO [dbo].[bAPUI] (
	 APCo
	,UIMth
	,UISeq
	,VendorGroup
	,Vendor
	,APRef
	,Description
	,Notes
	,InvDate
	,DueDate
	,InvTotal
	,PayMethod
	,CMCo
	,CMAcct
	,V1099YN
	,V1099Type
	,V1099Box
	,PayOverrideYN
	,SeparatePayYN
	,ReviewerGroup
	,udFreightCost
	,udAPBatchProcessedYN
	)
VALUES (
	@Company
	,@UIMonth
	,@UISeq
	,@VendorGroup
	,@Vendor
	,@CollectedInvoiceNumber
	,@Description
	,@Notes
	,@CollectedInvoiceDate
	,ISNULL(@DueDate, @CollectedInvoiceDate)
	,@CollectedInvoiceAmount
	,ISNULL(@PayMethod,'C')
	,@CMCo
	,@CMAcct
	,ISNULL(@V1099YN,'N')
	,@V1099Type
	,@V1099Box
	,@PayOverrideYN
	,@SeparatePayYN
	,@ReviewerGroup
	,@CollectedShippingAmount
	,@APBatchProcessedYN
	)

	SET @HeaderKeyID = SCOPE_IDENTITY()

COMMIT TRANSACTION Trans_addAPUI
SELECT @rcode=0

END TRY

BEGIN CATCH
	ROLLBACK TRANSACTION Trans_addAPUI
	SELECT @rcode=1
END CATCH

ExitProc:
RETURN(@rcode)

SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO