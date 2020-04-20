SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].cvsp_STO_SMWorkOrderScope (
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
Usage:		EXEC cvsp_STO_SMWorkOrderScope 1, 1, 'Y'
			
Change Log:

	20130510	CL	Initial Coding	
**************************************************************************************************/
BEGIN TRY
	/******************************************************************
		Declare variables
	******************************************************************/
		DECLARE @MaxID	INT 
		DECLARE @Scopes TABLE (
				id			 INT IDENTITY(1, 1),
				WorkOrder	 INT,
				StandardTask INT,
				PMTask		 INT)

	/******************************************************************
		Backup existing table. Format in: table_YYYY MM DD HH MM SS
	******************************************************************/
		DECLARE @SQL VARCHAR(8000) = 'SELECT * INTO vSMWorkOrder_',
				@TS	 VARCHAR(30)
				
		SELECT	@TS	 = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(30), GETDATE(), 120), '-', ''), ' ', ''), ':', '')
		SELECT	@SQL = @SQL + @TS + ' FROM vSMWorkOrderScope'
		EXEC	(@SQL)
		
	/******************************************************************
		Modify table attributes
	******************************************************************/	
		ALTER TABLE vSMWorkOrderScope NOCHECK CONSTRAINT ALL
		ALTER TABLE vSMWorkOrderScope DISABLE TRIGGER ALL
		SET IDENTITY_INSERT vSMWorkOrderScope ON
		
	/******************************************************************
		Check Delete flag and remove existing data if required
	******************************************************************/
		IF UPPER(@DeleteDataYN) = 'Y'
		BEGIN
			DELETE vSMWorkOrderScope WHERE SMCo = @ToCo
		END
		
	/******************************************************************
		Perform the conversion
	******************************************************************/
		-- Get last used Primary Key
		SET @MaxID = (SELECT ISNULL(MAX(SMWorkOrderScopeID), 0) FROM vSMWorkOrderScope)
		
		-- Get list of all Unique Work Order Scopes from Timberline
		-- This will be either WO To Do's assigned via Standard Tasks
		-- or by Misc. PM Task entries
		INSERT	@Scopes 
		SELECT	DISTINCT
				WRKORDNBR,
				STANDARDTASK,
				EQPPMTASKNBR
		FROM	CV_TL_Source_SM.dbo.WOTODO
		ORDER BY WRKORDNBR ASC

		-- Convert final data set
		INSERT	vSMWorkOrderScope (
				SMWorkOrderScopeID,
				SMCo,
				WorkOrder,
				Scope,
				CallType,
				WorkScope,
				Description,
				DueStartDate,
				DueEndDate,
				ServiceCenter,
				Division,
				Notes,
				CustGroup,
				BillToARCustomer,
				RateTemplate,
				ServiceItem,
				SaleLocation,
				IsComplete,
				PriorityName,
				IsTrackingWIP,
				CustomerPO,
				NotToExceed,
				Phase,
				PhaseGroup,
				JCCo,
				Job,
				Agreement,
				Revision,
				PriceMethod,
				Price,
				Service,
				UseAgreementRates,
				TaxType,
				TaxGroup,
				TaxCode,
				TaxBasis,
				TaxAmount)
--DECLARE @Scopes TABLE (
--id			 INT IDENTITY(1, 1),
--WorkOrder	 INT,
--StandardTask INT,
--PMTask		 INT)
--INSERT	@Scopes 
--		SELECT	DISTINCT
--				WRKORDNBR,
--				STANDARDTASK,
--				EQPPMTASKNBR
--		FROM	CV_TL_Source_SM.dbo.WOTODO
--		ORDER BY WRKORDNBR ASC
--DECLARE @MaxID INT = 1,
--		@ToCo INT = 1
		SELECT 	SMWorkOrderID		= @MaxID + ROW_NUMBER() OVER (ORDER BY @ToCo),
				SMCo				= @ToCo,
				WorkOrder			= tl_wo.WRKORDNBR,
				Scope				= ROW_NUMBER() OVER (PARTITION BY @ToCo, tl_wo.WRKORDNBR ORDER BY @ToCo, tl_wo.WRKORDNBR),
				CallType			= vp_cll.NewCallType,
				WorkScope			= vp_scp.WorkScope,
				Description			= vp_stdtsk.Description,
				DueStartDate		= NULL, 
				DueEndDate			= NULL, 
				ServiceCenter		= vp_wo.ServiceCenter,
				Division			= NULL, 
				Notes				= NULL,
				CustGroup			= vp_wo.CustGroup,
				BillToARCustomer	= tl_wo.ARCUST,
				RateTemplate		= tl_wo.RATESHEETNBR,
				ServiceItem			= CASE WHEN tl_wo.SYSEQPNBR <> 0
										   THEN tl_wo.SYSEQPNBR
										   ELSE NULL
										   END,
				SaleLocation		= 0,
				IsComplete			= 'N', -- ? how to determine in TL
				PriorityName		= vp_scp.PriorityName,
				IsTrackingWIP		= 'N', -- ? how to determine in TL
				CustomerPO			= tl_wo.CUSTOMERPO,
				NotToExceed			= NULL,
				Phase				= NULL, -- ?
				PhaseGroup			= NULL, -- ?
				JCCo				= NULL, -- ?
				Job					= NULL, -- ?
				Agreement			= CASE WHEN tl_wo.AGREEMENTNBR <> 0
										   THEN tl_wo.AGREEMENTNBR
										   ELSE NULL
										   END,
				Revision			= CASE WHEN tl_wo.AGREEMENTSEQ <> 0
										   THEN tl_wo.AGREEMENTSEQ
										   ELSE NULL
										   END,
				PriceMethod			= NULL, -- not sure about this: vp_agr.PricingMethod,
				Price				= NULL,
				Service				= NULL,
				UseAgreementRates	= 'N',
				TaxType				= NULL,
				TaxGroup			= NULL,
				TaxCode				= NULL,
				TaxBasis			= NULL,
				TaxAmount			= NULL
		
		FROM	@Scopes AS scope
		
		LEFT JOIN CV_TL_Source_SM.dbo.WOSTDTASK AS tl_tsk
			ON	scope.WorkOrder = tl_tsk.WRKORDNBR
			AND scope.StandardTask = tl_tsk.STANDARDTASK
		
		JOIN	CV_TL_Source_SM.dbo.WRKORDER AS tl_wo
			ON	scope.WorkOrder = tl_wo.WRKORDNBR
			
		JOIN	vSMWorkOrder AS vp_wo
			ON	vp_wo.SMCo = @ToCo
			AND scope.WorkOrder = vp_wo.WorkOrder
		
		JOIN	bHQCO AS vp_co
			ON	vp_co.HQCo = @ToCo
			
		JOIN	budXRefSMCallTypes AS vp_cll
			ON	vp_cll.SMCo = @ToCo
			AND vp_cll.OldCallType = tl_wo.CALLTYPECODE
		
		JOIN	budXRefSMWorkScopes AS xr_scp
			ON	xr_scp.SMCo = @ToCo
			AND xr_scp.OldProblemCode = tl_wo.PROBLEMCODE
			
		JOIN	vSMWorkScope AS vp_scp
			ON	vp_scp.SMCo = @ToCo
			AND vp_scp.WorkScope = xr_scp.NewWorkScope
			
		LEFT JOIN vSMStandardTask AS vp_stdtsk
			ON	vp_stdtsk.SMCo = @ToCo
			AND vp_stdtsk.SMStandardTask = scope.StandardTask
					
	/******************************************************************
		Reset table attributes
	******************************************************************/	
		SET IDENTITY_INSERT vSMWorkOrderScope OFF
		ALTER TABLE vSMWorkOrderScope CHECK CONSTRAINT ALL;
		ALTER TABLE vSMWorkOrderScope ENABLE TRIGGER ALL;

	/******************************************************************
		Review data
	******************************************************************/	
		SELECT * FROM vSMWorkOrderScope WHERE SMCo = @ToCo
END TRY

BEGIN CATCH
	/******************************************************************
		Reset table attributes
	******************************************************************/	
		SET IDENTITY_INSERT vSMWorkOrderScope OFF
		ALTER TABLE vSMWorkOrderScope CHECK CONSTRAINT ALL;
		ALTER TABLE vSMWorkOrderScope ENABLE TRIGGER ALL;
		
	/******************************************************************
		Error
	******************************************************************/	
		SELECT ERROR_MESSAGE() 
				+ ' at line number ' 
				+ CAST(ERROR_LINE() AS VARCHAR)
END CATCH 
GO
