SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].cvsp_STO_SMPartType (
		@ToCo			bCompany,
		@FromCo			bCompany,
		@DeleteDataYN	CHAR(1))
AS
/**************************************************************************************************
Copyright:	2013 Coaxis/Viewpoint Construction Software (VCS) 
			The TSQL code in this procedure may not be reproduced, copied, modified,
			or executed without the expressed written consent from VCS.

Project:	Timberline to Viewpoint V6 SM Conversion - SM Part Types
Author:		Chris Lounsbury
Purpose:	Flesh out SM Part Types using the converted HQ Material Categories
			
Change Log:

	20130425	CL	Initial Coding	
**************************************************************************************************/
BEGIN TRY
	/******************************************************************
		Declare variables
	******************************************************************/
		DECLARE @MaxID	INT 

	/******************************************************************
		Backup existing table. Format in: table_YYYY MM DD HH MM SS
	******************************************************************/
		DECLARE @SQL VARCHAR(8000) = 'SELECT * INTO vSMPartType_',
				@TS	 VARCHAR(30)
				
		SELECT	@TS	 = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(30), GETDATE(), 120), '-', ''), ' ', ''), ':', '')
		SELECT	@SQL = @SQL + @TS + ' FROM vSMPartType'
		EXEC	(@SQL)
		
	/******************************************************************
		Modify table attributes
	******************************************************************/	
		ALTER TABLE vSMPartType NOCHECK CONSTRAINT ALL
		ALTER TABLE vSMPartType DISABLE TRIGGER ALL
		SET IDENTITY_INSERT vSMPartType ON
		
	/******************************************************************
		Check Delete flag and remove existing data if required
	******************************************************************/
		IF UPPER(@DeleteDataYN) = 'Y'
		BEGIN
			DELETE vSMPartType WHERE SMCo = @ToCo
		END
		
	/******************************************************************
		Perform the conversion
	******************************************************************/
		SET @MaxID = (SELECT ISNULL(MAX(SMPartTypeID), 0) FROM dbo.vSMPartType)

		INSERT	vSMPartType (
				SMPartTypeID,
				SMCo,
				SMPartType,
				Description)
		SELECT	SMPartTypeID = @MaxID + ROW_NUMBER() OVER (ORDER BY @ToCo, mc.Description),
				SMCo		 = @ToCo,
				SMPartType	 = mc.Category,
				Description	 = mc.Description
		FROM	bHQMC AS mc
		JOIN	bHQCO AS co
			ON	mc.MatlGroup = co.MatlGroup
			AND co.HQCo		 = @FromCo

	/******************************************************************
		Reset table attributes
	******************************************************************/	
		SET IDENTITY_INSERT vSMPartType OFF
		ALTER TABLE vSMPartType CHECK CONSTRAINT ALL;
		ALTER TABLE vSMPartType ENABLE TRIGGER ALL;

	/******************************************************************
		Review data
	******************************************************************/	
		SELECT * FROM vSMPartType WHERE SMCo = @ToCo
END TRY

BEGIN CATCH
	/******************************************************************
		Reset table attributes
	******************************************************************/	
		SET IDENTITY_INSERT vSMPartType OFF
		ALTER TABLE vSMPartType CHECK CONSTRAINT ALL;
		ALTER TABLE vSMPartType ENABLE TRIGGER ALL;
		
	/******************************************************************
		Error
	******************************************************************/	
		SELECT ERROR_MESSAGE() 
				+ ' at line number ' 
				+ CAST(ERROR_LINE() AS VARCHAR)
END CATCH
GO
