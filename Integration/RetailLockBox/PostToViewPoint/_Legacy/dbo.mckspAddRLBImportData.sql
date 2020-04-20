USE MCK_INTEGRATION
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[mckspAddRLBImportData]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[mckspAddRLBImportData]
GO

-- **************************************************************
--  PURPOSE: Adds new RLB Import Data record
--    INPUT: Values list (see below)
--   RETURN: ErrCode (0 if successful, 1 if not)
--   AUTHOR: Brian Gannon-McKinley
--  -------------------------------------------------------------
--  HISTORY:
--    12/11/2014  Created stored procedure
--    12/11/2014  Tested stored procedure
-- **************************************************************

CREATE PROCEDURE [dbo].[mckspAddRLBImportData]
	@MetaFileName varchar(100) = NULL
	,@RecordType varchar(30) = NULL
	,@Company tinyint = NULL
	,@Number varchar(30) = NULL
	,@VendorGroup tinyint = NULL
	,@Vendor int = NULL
	,@VendorName varchar(60) = NULL
	,@TransactionDate datetime = NULL
	,@JCCo tinyint = NULL
	,@Job varchar(10) = NULL
	,@JobDescription varchar(60) = NULL
	,@Description varchar(30) = NULL
	,@DetailLineCount int = NULL
	,@TotalOrigCost numeric(12,2) = NULL
	,@TotalOrigTax numeric(12,2) = NULL
	,@RemainingAmount numeric(12,2) = NULL
	,@RemainingTax numeric(12,2) = NULL
	,@CollectedInvoiceDate smalldatetime = NULL
	,@CollectedInvoiceNumber varchar(50) = NULL
	,@CollectedTaxAmount numeric(12,2) = NULL
	,@CollectedShippingAmount numeric(12,2) = NULL
	,@CollectedInvoiceAmount numeric(12,2) = NULL
	,@CollectedImage varchar(255) = NULL
	,@HeaderKeyID bigint = NULL
	,@FooterKeyID bigint = NULL
	,@AttachmentID int = NULL
	,@UniqueAttachmentID uniqueidentifier = NULL
	,@AttachmentFilePath varchar(512) = NULL
	,@FileCopied bit = NULL
	,@Notes varchar(512) = NULL

AS

SET NOCOUNT ON

DECLARE  @rcode int

----------------------------------------------
-- Set Variables
----------------------------------------------

SELECT	@rcode = -1

----------------------------------------------
-- Validate Attachment Inputs
----------------------------------------------

IF  @UniqueAttachmentID = '00000000-0000-0000-0000-000000000000'
    BEGIN
	 SET @UniqueAttachmentID = NULL
    END
IF  @HeaderKeyID <= 0
    BEGIN
	 SET @HeaderKeyID = NULL
    END
IF  @FooterKeyID <= 0
    BEGIN
	 SET @FooterKeyID = NULL
    END
IF  @AttachmentID <= 0
    BEGIN
	 SET @AttachmentID = NULL
    END

----------------------------
-- Save The Record
----------------------------
BEGIN TRY
BEGIN TRANSACTION Trans_addRLBImportData

INSERT INTO [dbo].[RLB_AP_ImportData_New] (
	MetaFileName
	,RecordType
	,Company
	,Number
	,VendorGroup
	,Vendor
	,VendorName
	,TransactionDate
	,JCCo
	,Job
	,JobDescription
	,Description
	,DetailLineCount
	,TotalOrigCost
	,TotalOrigTax
	,RemainingAmount
	,RemainingTax
	,CollectedInvoiceDate
	,CollectedInvoiceNumber
	,CollectedTaxAmount
	,CollectedShippingAmount
	,CollectedInvoiceAmount
	,CollectedImage
	,HeaderKeyID
	,FooterKeyID
	,AttachmentID
	,UniqueAttachmentID
	,AttachmentFilePath
	,FileCopied
	,Notes
	)
VALUES (
	@MetaFileName
	,@RecordType
	,@Company
	,@Number
	,@VendorGroup
	,@Vendor
	,@VendorName
	,@TransactionDate
	,@JCCo
	,@Job
	,@JobDescription
	,@Description
	,@DetailLineCount
	,@TotalOrigCost
	,@TotalOrigTax
	,@RemainingAmount
	,@RemainingTax
	,@CollectedInvoiceDate
	,@CollectedInvoiceNumber
	,@CollectedTaxAmount
	,@CollectedShippingAmount
	,@CollectedInvoiceAmount
	,@CollectedImage
	,@HeaderKeyID
	,@FooterKeyID
	,@AttachmentID
	,@UniqueAttachmentID
	,@AttachmentFilePath
	,@FileCopied
	,@Notes
	)

COMMIT TRANSACTION Trans_addRLBImportData
SELECT @rcode=0

END TRY

BEGIN CATCH
	ROLLBACK TRANSACTION Trans_addRLBImportData
	SELECT @rcode=1
END CATCH

ExitProc:
RETURN(@rcode)

SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO