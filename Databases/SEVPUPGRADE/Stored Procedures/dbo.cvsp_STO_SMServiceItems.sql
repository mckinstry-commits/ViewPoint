SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].cvsp_STO_SMServiceItems (
		@ToCo			bCompany,
		@FromCo			bCompany,
		@DeleteDataYN	CHAR(1))
AS
/**************************************************************************************************
Copyright:	2013 Coaxis/Viewpoint Construction Software (VCS) 
			The TSQL code in this procedure may not be reproduced, copied, modified,
			or executed without the expressed written consent from VCS.

Project:	Timberline to Viewpoint V6 SM Conversion 
Author:		Chris Lounsbury
Purpose:	Convert Timberline Agreement Equipment to SM Serviceable Items
			
Change Log:

	20130502	CL	Initial Coding	
**************************************************************************************************/
BEGIN TRY
	/******************************************************************
		Declare variables
	******************************************************************/
		DECLARE @MaxID	INT 

	/******************************************************************
		Backup existing table. Format in: table_YYYY MM DD HH MM SS
	******************************************************************/
		DECLARE @SQL VARCHAR(8000) = 'SELECT * INTO vSMServiceItems_',
				@TS	 VARCHAR(30)
				
		SELECT	@TS	 = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(30), GETDATE(), 120), '-', ''), ' ', ''), ':', '')
		SELECT	@SQL = @SQL + @TS + ' FROM vSMServiceItems'
		EXEC	(@SQL)
		
	/******************************************************************
		Modify table attributes
	******************************************************************/	
		ALTER TABLE vSMServiceItems NOCHECK CONSTRAINT ALL
		ALTER TABLE vSMServiceItems DISABLE TRIGGER ALL
		SET IDENTITY_INSERT vSMServiceItems ON
		
	/******************************************************************
		Check Delete flag and remove existing data if required
	******************************************************************/
		IF UPPER(@DeleteDataYN) = 'Y'
		BEGIN
			DELETE vSMServiceItems WHERE SMCo = @ToCo
		END
		
	/******************************************************************
		Perform the conversion
	******************************************************************/
		-- Get last used Primary Key
		SET @MaxID = (SELECT ISNULL(MAX(SMServiceItemID), 0) FROM dbo.vSMServiceItems)

		INSERT	vSMServiceItems (
				SMCo,
				ServiceSite,
				ServiceItem,
				Description,
				ServiceItemSummary,
				Manufacturer,
				Model,
				YearManufactured,
				Location,
				SMServiceItemID,
				Notes,
				Class,
				Type,
				SerialNumber,
				LaborWarranty,
				LaborWarrantyExpDate,
				MaterialWarranty,
				MaterialWarrantyExpDate,
				udTLModel)

		SELECT	SMCo				= @ToCo,
				ServiceSite			= eqp.SERVSITENBR,		
				ServiceItem			= eqp.SYSEQPNBR,
				Description			= LTRIM(RTRIM(ISNULL(mfg.ABBREVIATION, ''))
										+ ' '
										+ RTRIM(ISNULL(typ.DESCRIPTION, ''))),
				ServiceItemSummary	= RTRIM(ISNULL(mfg.ABBREVIATION, ''))
										+ ' '
										+ RTRIM(ISNULL(typ.DESCRIPTION, ''))
										+ ' '
										+ RTRIM(ISNULL(eqp.MODELNBR, ''))
										+ CASE WHEN ISNULL(eqp.SERIALNBR, '') <> ''
											   THEN ' S/N: '
											   ELSE ''
											   END
										+ RTRIM(ISNULL(eqp.SERIALNBR, '')),
				Manufacturer		= RTRIM(ISNULL(mfg.ABBREVIATION, '')),
				Model				= LEFT(RTRIM(ISNULL(eqp.MODELNBR, '')), 20),
				YearManufactured	= eqp.YEAROFMFG,
				Location			= eqp.INSTALLLOC,
				SMServiceItemID		= @MaxID + ROW_NUMBER() OVER (ORDER BY @ToCo, eqp.SYSEQPNBR),
				Notes				= NULL,
				Class				= typ.EQPCLASS,
				Type				= eqp.EQPTYPE,
				SerialNumber		= eqp.SERIALNBR,
				LaborWarranty		= CASE WHEN eqp.INSTALLDATE IS NULL
										   THEN 'N'
										   ELSE 'Y'
										   END,
				LaborWarrantyExpDate= CASE WHEN eqp.INSTALLDATE IS NOT NULL
										   THEN DATEADD(YYYY, 1, eqp.INSTALLDATE)
										   ELSE NULL
										   END,
				MaterialWarranty	= CASE WHEN eqp.WARREXPIRES IS NULL
										   THEN 'N'
										   ELSE 'Y'
										   END,
				MaterialWarrantyExpDate = eqp.WARREXPIRES,
				udTLModel			= ISNULL(eqp.MODELNBR, '')	

		FROM	CV_TL_Source_SM.dbo.SERVSITEEQUIP AS eqp

		LEFT JOIN CV_TL_Source_SM.dbo.MFG AS mfg
			ON	eqp.MFGNBR = mfg.MFGNBR

		JOIN	CV_TL_Source_SM.dbo.EQPTYPE AS typ
			ON	eqp.EQPTYPE = typ.EQPTYPE
		
		
	/******************************************************************
		Reset table attributes
	******************************************************************/	
		SET IDENTITY_INSERT vSMServiceItems OFF
		ALTER TABLE vSMServiceItems CHECK CONSTRAINT ALL;
		ALTER TABLE vSMServiceItems ENABLE TRIGGER ALL;

	/******************************************************************
		Review data
	******************************************************************/	
		SELECT * FROM vSMServiceItems WHERE SMCo = @ToCo
END TRY

BEGIN CATCH
	/******************************************************************
		Reset table attributes
	******************************************************************/	
		SET IDENTITY_INSERT vSMServiceItems OFF
		ALTER TABLE vSMServiceItems CHECK CONSTRAINT ALL;
		ALTER TABLE vSMServiceItems ENABLE TRIGGER ALL;
		
	/******************************************************************
		Error
	******************************************************************/	
		SELECT ERROR_MESSAGE() 
				+ ' at line number ' 
				+ CAST(ERROR_LINE() AS VARCHAR)
END CATCH 
GO
