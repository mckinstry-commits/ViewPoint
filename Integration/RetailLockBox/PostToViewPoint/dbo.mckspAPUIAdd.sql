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
--    04/26/2014  Created stored procedure
--    05/07/2014  Tested stored procedure
-- **************************************************************

CREATE PROCEDURE [dbo].[mckspAPUIAdd]
	@Company [dbo].[bCompany]
	,@VendorGroup [dbo].[bGroup]
	,@Vendor [dbo].[bVendor]
	,@CollectedInvoiceNumber varchar(15)
	,@Description [dbo].[bDesc]
	,@CollectedInvoiceDate [dbo].[bDate]
	,@CollectedInvoiceAmount [dbo].[bDollar]
	,@CollectedShippingAmount [dbo].[bDollar]
	,@KeyID bigint OUTPUT
	,@UIMonth smalldatetime OUTPUT
	,@UISeq int OUTPUT

AS

SET NOCOUNT ON

DECLARE  @rcode int, @Message varchar(200), @PayMethod char(1), @PayTerms [dbo].[bPayTerms], @CMCo [dbo].[bCompany], 
	@CMAcct [dbo].[bCMAcct], @SeparatePayYN [dbo].[bYN], @V1099YN [dbo].[bYN], @V1099Type varchar(10), @V1099Box tinyint, 
	@PayOverrideYN [dbo].[bYN], @ReviewerGroup varchar(10)

----------------------------------------------
-- Set APUI Variables
----------------------------------------------

SELECT	@rcode = -1
		,@UIMonth = [dbo].[vfFirstDayOfMonth] (@CollectedInvoiceDate)
		,@PayOverrideYN = 'N', @SeparatePayYN = 'N', @ReviewerGroup = NULL

SELECT @CMCo = CMCo, @CMAcct = CMAcct 
	FROM APCO WHERE CMCo = @Company

SELECT @PayTerms = PayTerms, @PayMethod = PayMethod, @V1099YN = V1099YN, @V1099Type = V1099Type, @V1099Box = V1099Box
	FROM APVM WHERE VendorGroup = @VendorGroup AND Vendor = @Vendor

-- Fetch next UI sequence
EXECUTE [dbo].[vspAPUIGetNextSeq] @Company, @UIMonth, @UISeq OUTPUT, @Message OUTPUT

-- Fetch due date
DECLARE @InvoiceDate [dbo].[bDate], @DiscDate [dbo].[bDate], @DueDate [dbo].[bDate], 
	@DiscRate [dbo].[bPct], @PayTermsMsg varchar(60)

EXECUTE [dbo].[bspHQPayTermsDateCalc] @PayTerms, @InvoiceDate, @DiscDate OUTPUT, @DueDate OUTPUT, @DiscRate OUTPUT, @PayTermsMsg OUTPUT

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
	)
VALUES (
	@Company
	,@UIMonth
	,@UISeq
	,@VendorGroup
	,@Vendor
	,@CollectedInvoiceNumber
	,@Description
	,@CollectedInvoiceDate
	,@DueDate
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
	)

	SET @KeyID = SCOPE_IDENTITY()

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