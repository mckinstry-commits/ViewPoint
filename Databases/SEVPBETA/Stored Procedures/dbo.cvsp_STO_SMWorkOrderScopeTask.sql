SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].cvsp_STO_SMWorkOrderScopeTask (
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
Purpose:	Converts Timberline SM Work Orders Scope Tasks into Viewpoint SM Work Order Scope Tasks
Usage:		EXEC cvsp_STO_SMWorkOrderScopeTask 1, 1, 'Y'

Change Log:

	20130514	CL	Initial Coding	
**************************************************************************************************/
BEGIN TRY
	/******************************************************************
		Declare variables
	******************************************************************/
		DECLARE @MaxID	INT 

	/******************************************************************
		Backup existing table. Format in: table_YYYY MM DD HH MM SS
	******************************************************************/
		--DECLARE @SQL VARCHAR(8000) = 'SELECT * INTO vSMWorkOrderScopeTask_',
		--		@TS	 VARCHAR(30)
				
		--SELECT	@TS	 = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(30), GETDATE(), 120), '-', ''), ' ', ''), ':', '')
		--SELECT	@SQL = @SQL + @TS + ' FROM vSMWorkOrderScopeTask'
		--EXEC	(@SQL)
		
	/******************************************************************
		Modify table attributes
	******************************************************************/	
		ALTER TABLE vSMWorkOrderScopeTask NOCHECK CONSTRAINT ALL
		ALTER TABLE vSMWorkOrderScopeTask DISABLE TRIGGER ALL
		SET IDENTITY_INSERT vSMWorkOrderScopeTask ON
		
	/******************************************************************
		Check Delete flag and remove existing data if required
	******************************************************************/
		IF UPPER(@DeleteDataYN) = 'Y'
		BEGIN
			DELETE vSMWorkOrderScopeTask WHERE SMCo = @ToCo
		END
		
	/******************************************************************
		Perform the conversion
	******************************************************************/
		-- Get last used Primary Key
		SET @MaxID = (SELECT ISNULL(MAX(SMWorkOrderScopeTaskID), 0) FROM vSMWorkOrderScopeTask)

		INSERT	vSMWorkOrderScopeTask (
				SMWorkOrderScopeTaskID,
				SMCo,
				WorkOrder,
				Scope,
				Task,
				SMStandardTask,
				Name,
				Description,
				ServiceItem,
				Notes)
--DECLARE @MaxID INT = 1,
--		@ToCo INT = 1
		SELECT	SMWorkOrderScopeTaskID = @MaxID + ROW_NUMBER() OVER (ORDER BY @ToCo),
				SMCo				= @ToCo,
				WorkOrder			= tl_wo.WRKORDNBR,
				Scope				= vp_ws.Scope,
				Task				= tl_todo.WOTODONBR,
				SMStandardTask		= tl_todo.STANDARDTASK,
				Name				= LEFT(tl_todo.DESCRIPTION, 60),
				Description			= tl_todo.DESCRIPTION,
				ServiceItem			= vp_ws.ServiceItem,
				Notes				= NULL
		
		FROM	CV_TL_Source_SM.dbo.WOTODO AS tl_todo
		
		LEFT JOIN CV_TL_Source_SM.dbo.WOSTDTASK AS tl_wotsk
			ON	tl_todo.WRKORDNBR	 = tl_wotsk.WRKORDNBR
			AND tl_todo.STANDARDTASK = tl_wotsk.STANDARDTASK
		
		LEFT JOIN CV_TL_Source_SM.dbo.WRKORDER AS tl_wo
			ON	tl_todo.WRKORDNBR = tl_wo.WRKORDNBR
			
		LEFT JOIN CV_TL_Source_SM.dbo.EQPPMTASK AS tl_tsk
			ON	tl_tsk.EQPPMTASKNBR = tl_todo.EQPPMTASKNBR
			
		--LEFT JOIN CV_TL_Source_SM.dbo.SYSEQ
		
		LEFT JOIN vSMStandardTask AS vp_st
			ON	vp_st.SMCo = @ToCo
			AND vp_st.SMStandardTask = tl_todo.STANDARDTASK
			
		LEFT JOIN vSMWorkOrderScope AS vp_ws
			ON	vp_ws.SMCo = @ToCo
			AND vp_ws.WorkOrder = tl_todo.WRKORDNBR
			AND vp_ws.Description = CASE WHEN tl_tsk.DESCRIPTION IS NOT NULL
										 THEN tl_tsk.DESCRIPTION
										 ELSE vp_st.Description
										 END			
					--AND vp_ws.ServiceItem = tl_tsk.SYSEQPNBR)
		WHERE	vp_ws.Scope IS NOT NULL
			AND vp_ws.ServiceItem IS NOT NULL

/*			
select  * from CV_TL_Source_SM.dbo.WOTODO 
select top 1 * from vSMWorkOrder WHERE SMCo = 1
select top 1 * from vSMWorkOrderScope where SMCo = 1
select top 1 * from vSMWorkOrderScopeTask
*/

					
	/******************************************************************
		Reset table attributes
	******************************************************************/	
		SET IDENTITY_INSERT vSMWorkOrderScopeTask OFF
		ALTER TABLE vSMWorkOrderScopeTask CHECK CONSTRAINT ALL;
		ALTER TABLE vSMWorkOrderScopeTask ENABLE TRIGGER ALL;

	/******************************************************************
		Review data
	******************************************************************/	
		SELECT * FROM vSMWorkOrderScopeTask WHERE SMCo = @ToCo
END TRY

BEGIN CATCH
	/******************************************************************
		Reset table attributes
	******************************************************************/	
		SET IDENTITY_INSERT vSMWorkOrderScopeTask OFF
		ALTER TABLE vSMWorkOrderScopeTask CHECK CONSTRAINT ALL;
		ALTER TABLE vSMWorkOrderScopeTask ENABLE TRIGGER ALL;
		
	/******************************************************************
		Error
	******************************************************************/	
		SELECT ERROR_MESSAGE() 
				+ ' at line number ' 
				+ CAST(ERROR_LINE() AS VARCHAR)
END CATCH 
GO
