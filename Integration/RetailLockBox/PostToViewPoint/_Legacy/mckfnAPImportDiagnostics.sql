USE [MCK_INTEGRATION]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID (N'[dbo].[mckfnAPImportDiagnostics]', N'IF') IS NOT NULL
	DROP FUNCTION [dbo].[mckfnAPImportDiagnostics]
GO


-- **************************************************************
--  PURPOSE: Fetches diagnostics for Viewpoint AP import
--    INPUT: Values list (see below)
--   RETURN: Table
--   AUTHOR: Brian Gannon-McKinley
--  -------------------------------------------------------------
--  HISTORY:
--    02/09/2015  Created function
--    02/09/2015  Tested function
-- **************************************************************

CREATE FUNCTION [dbo].[mckfnAPImportDiagnostics]
(
	 @FileName varchar(100)
)

RETURNS @Results table(FileName varchar(100), Matched int, Unmatched int, Standalone int, Total int, 
	MissingAttachments int, ImagesNotCopied int)

AS

BEGIN

	DECLARE @Matched int, @Unmatched int, @Standalone int, @Total int, @MissingAttachments int, 
	@ImagesNotCopied int, @MaxKeyID int, @MinKeyID int

	SET @MinKeyID = (SELECT min(KeyID) FROM RLB_AP_ImportData_New WHERE MetaFileName LIKE '' + @FileName + '%')
	SET @MaxKeyID = (SELECT max(KeyID) FROM RLB_AP_ImportData_New WHERE MetaFileName LIKE '' + @FileName + '%')

	SET @Matched = (SELECT count(*) FROM RLB_AP_ImportData_New
		WHERE HeaderKeyID IS NOT NULL AND FooterKeyID IS NOT NULL AND AttachmentID IS NOT NULL
		AND KeyID >= @MinKeyID AND KeyID <= @MaxKeyID)

	SET @Unmatched = (SELECT count(*) FROM RLB_AP_ImportData_New
		WHERE HeaderKeyID IS NOT NULL AND FooterKeyID IS NULL AND AttachmentID IS NOT NULL
		AND KeyID >= @MinKeyID AND KeyID <= @MaxKeyID)

	SET @Standalone = (SELECT count(*) FROM RLB_AP_ImportData_New
		WHERE HeaderKeyID IS NULL AND FooterKeyID IS NULL AND AttachmentID IS NOT NULL
		AND KeyID >= @MinKeyID AND KeyID <= @MaxKeyID)

	SET @Total = (SELECT count(*) FROM RLB_AP_ImportData_New
		WHERE KeyID >= @MinKeyID AND KeyID <= @MaxKeyID)

	SET @MissingAttachments = (SELECT count(*) FROM RLB_AP_ImportData_New
		WHERE HeaderKeyID IS NULL AND FooterKeyID IS NULL AND AttachmentID IS NULL
		AND KeyID >= @MinKeyID AND KeyID <= @MaxKeyID)

	SET @ImagesNotCopied = (SELECT count(*) FROM RLB_AP_ImportData_New 
		WHERE FileCopied IS NULL
		AND KeyID >= @MinKeyID AND KeyID <= @MaxKeyID)

	INSERT INTO @Results(FileName, Matched, Unmatched, Standalone, Total, MissingAttachments, ImagesNotCopied) 
	VALUES (@FileName, @Matched, @Unmatched, @Standalone, @Total, @MissingAttachments, @ImagesNotCopied)

  RETURN
      
END