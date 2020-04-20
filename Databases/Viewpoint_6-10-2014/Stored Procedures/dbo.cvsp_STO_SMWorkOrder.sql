SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[cvsp_STO_SMWorkOrder] (
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
Purpose:	Converts Timberline SM Work Orders into Viewpoint SM Work Orders
			
Change Log:  

	20130510	CL	Initial Coding	
	20130530	MG	Modified Lead Technician so that it pulls the Viewpoint Employee/Technician 
					number not TL number
**************************************************************************************************/
BEGIN TRY
	/******************************************************************
		Declare variables
	******************************************************************/
		DECLARE @MaxID	INT 

	/******************************************************************
		Backup existing table. Format in: table_YYYY MM DD HH MM SS
	******************************************************************/
		DECLARE @SQL VARCHAR(8000) = 'SELECT * INTO vSMWorkOrder_',
				@TS	 VARCHAR(30)
				
		SELECT	@TS	 = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(30), GETDATE(), 120), '-', ''), ' ', ''), ':', '')
		SELECT	@SQL = @SQL + @TS + ' FROM vSMWorkOrder'
		EXEC	(@SQL)
		
	/******************************************************************
		Modify table attributes
	******************************************************************/	
		ALTER TABLE vSMWorkOrder NOCHECK CONSTRAINT ALL
		ALTER TABLE vSMWorkOrder DISABLE TRIGGER ALL
		SET IDENTITY_INSERT vSMWorkOrder ON
		
	/******************************************************************
		Check Delete flag and remove existing data if required
	******************************************************************/
		IF UPPER(@DeleteDataYN) = 'Y'
		BEGIN
			DELETE vSMWorkOrder WHERE SMCo = @ToCo
		END
		
	/******************************************************************
		Perform the conversion
	******************************************************************/
		-- Get last used Primary Key
		SET @MaxID = (SELECT ISNULL(MAX(SMWorkOrderID), 0) FROM vSMWorkOrder)

		INSERT	vSMWorkOrder (
				SMWorkOrderID,
				SMCo,
				WorkOrder,
				CustGroup,
				Customer,
				ServiceSite,
				Description,
				ServiceCenter,
				RequestedDate,
				RequestedTime,
				EnteredDateTime,
				EnteredBy,
				RequestedBy,
				ContactName,
				ContactPhone,
				IsNew,
				Notes,
				WOStatus,
				LeadTechnician,
				RequestedByPhone,
				JCCo,
				Job,
				CostingMethod
				-- ud fields?  Dave has added a lot
				)

		SELECT 	SMWorkOrderID		= @MaxID + ROW_NUMBER() OVER (ORDER BY @ToCo),
				SMCo				= @ToCo,
				WorkOrder			= tl_wo.WRKORDNBR,
				CustGroup			= vp_co.CustGroup,
				Customer			= tl_wo.ARCUST,
				ServiceSite			= tl_wo.SERVSITENBR,
				Description			= tl_wo.NAME,
				ServiceCenter		= vp_site.DefaultServiceCenter,
				RequestedDate		= tl_wo.CALLDATE,
				RequestedTime		= tl_wo.CALLTIME,
				EnteredDateTime		= tl_wo.DATEENTER,
				EnteredBy			= tl_wo.ENTERBY,
				RequestedBy			= NULL,
				ContactName			= tl_wo.CONTACT,
				ContactPhone		= NULL,
				IsNew				= 0,
				Notes				= tl_wo.COMMENTS,
				WOStatus			= CASE tl_wo.STATUS
										   WHEN 0 THEN 0	-- TL Open		/ VP Open
										   WHEN 1 THEN 0	-- TL Hold		/ VP Open
										   WHEN 2 THEN 2	-- TL Cancelled / VP Cancelled
										   WHEN 3 THEN 1	-- TL Closed	/ VP Closed
										   WHEN 6 THEN 1	-- TL Completed / VP Closed
										   WHEN 8 THEN 1	-- TL Invoiced	/ VP Closed
										   ELSE 2			-- Catch All	/ VP Cancelled
										   END,
				LeadTechnician		= xt.NewTechnician, /* Change 01 -this as we want the VP Technician number */--tl_wo.TECHNICIAN,
				RequestedByPhone	= NULL,
				JCCo				= NULL,
				Job					= NULL,
				CostingMethod		= NULL
		
		FROM	CV_TL_Source_SM.dbo.WRKORDER AS tl_wo
		LEFT JOIN  budXRefSMTechnician AS xt 
			ON xt.OldSMCo=@FromCo and tl_wo.TECHNICIAN=xt.OldTechnician
		
		JOIN	bHQCO AS vp_co
			ON	vp_co.HQCo = @ToCo
			
		JOIN	vSMServiceSite AS vp_site
			ON	vp_site.SMCo = @ToCo
			AND	tl_wo.SERVSITENBR = vp_site.ServiceSite
			
		
	/******************************************************************
		Reset table attributes
	******************************************************************/	
		SET IDENTITY_INSERT vSMWorkOrder OFF
		ALTER TABLE vSMWorkOrder CHECK CONSTRAINT ALL;
		ALTER TABLE vSMWorkOrder ENABLE TRIGGER ALL;

	/******************************************************************
		Review data
	******************************************************************/	
		SELECT * FROM vSMWorkOrder WHERE SMCo = @ToCo
END TRY

BEGIN CATCH
	/******************************************************************
		Reset table attributes
	******************************************************************/	
		SET IDENTITY_INSERT vSMWorkOrder OFF
		ALTER TABLE vSMWorkOrder CHECK CONSTRAINT ALL;
		ALTER TABLE vSMWorkOrder ENABLE TRIGGER ALL;
		
	/******************************************************************
		Error
	******************************************************************/	
		SELECT ERROR_MESSAGE() 
				+ ' at line number ' 
				+ CAST(ERROR_LINE() AS VARCHAR)
END CATCH 
GO
