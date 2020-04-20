SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- **************************************************************
--  PURPOSE: Creates destination folder for AP/AR images imported to Viewpoint
--    INPUT: Values list (see below)
--   RETURN: Varchar
--   AUTHOR: Brian Gannon-McKinley
--  -------------------------------------------------------------
--  HISTORY:
--    05/30/2014  Created function
--    05/30/2014  Tested function
-- **************************************************************

CREATE FUNCTION [dbo].[fnMckCreateImageFolderDestination]
(
	 @Company [dbo].[bCompany]
	,@Module varchar(30)
	,@FormName varchar(30)
	,@ImageFilePath nvarchar(512)
	,@CollectedInvoiceDate datetime
	,@IsStandalone bit
)
RETURNS varchar(max)
AS
BEGIN
		
DECLARE @DateFolderName nvarchar(100), 
		@CompanyName varchar(100)

-- Strip ending slashes from image file path
SELECT @ImageFilePath = (CASE WHEN (RIGHT(@ImageFilePath,1)='\') THEN LEFT(@ImageFilePath,LEN(@ImageFilePath)-1) ELSE @ImageFilePath END)

-- Set date to now if invoice date is null
IF @CollectedInvoiceDate IS NULL
BEGIN
	SELECT @CollectedInvoiceDate = GetDate()
END
-- Create date folder name (format 'MM-yyyy')
SELECT @DateFolderName = RIGHT(CONVERT(NVARCHAR, @CollectedInvoiceDate, 105), 7)

-- Set module and form values when standalone
IF @IsStandalone = 1
	BEGIN
		SELECT @Module = 'No Module', @FormName = 'No Form Name'
	END

-- Set company folder value
SELECT	@CompanyName = 'Company1'
IF @Company > 0
    BEGIN
	 SELECT @CompanyName = 'Company' + CAST(@Company as varchar(max))
    END

DECLARE @ret VARCHAR(max)
SELECT @ret = @ImageFilePath + '\' + @CompanyName + '\' + @Module + '\' + @FormName + '\' + @DateFolderName
RETURN @ret
END
      

GO
