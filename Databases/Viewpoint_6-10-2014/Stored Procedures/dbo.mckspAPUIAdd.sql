SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
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

DECLARE  @rcode int, @Message varchar(200)
	,@DueDate [dbo].[bDate], @PayMethod char(1), @CMCo [dbo].[bCompany], @CMAcct [dbo].[bCMAcct], @SeparatePayYN [dbo].[bYN], 
	@V1099YN [dbo].[bYN], @V1099Type varchar(10), @V1099Box tinyint, @PayOverrideYN [dbo].[bYN], @ReviewerGroup varchar(10)

----------------------------------------------
-- Set APUI Variables
----------------------------------------------

SELECT	@rcode = -1
		,@UIMonth = [dbo].[vfFirstDayOfMonth] (@CollectedInvoiceDate)
		,@DueDate = DATEADD(day, 30, @CollectedInvoiceDate)
		,@PayMethod = 'E'
		,@CMCo = (SELECT CMCo FROM APCO WHERE CMCo = @Company)
		,@CMAcct = (SELECT CMAcct FROM APCO WHERE CMCo = @Company)
		,@V1099YN = 'Y'
		,@V1099Type = 'MISC'
		,@V1099Box = 7
		,@PayOverrideYN = 'N'
		,@SeparatePayYN = 'N'
		,@ReviewerGroup = NULL
-- Fetch next UI sequence
EXECUTE [dbo].[vspAPUIGetNextSeq] @Company, @UIMonth, @UISeq OUTPUT, @Message OUTPUT


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
	,@PayMethod
	,@CMCo
	,@CMAcct
	,@V1099YN
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
