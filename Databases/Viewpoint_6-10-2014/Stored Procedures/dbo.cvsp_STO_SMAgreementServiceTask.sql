SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].cvsp_STO_SMAgreementServiceTask (
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
Purpose:	Converts Timberline SM PM Task Items into Viewpoint SM Work Schedule Tasks
			
Change Log:

	20130430	CL	Initial Coding	
**************************************************************************************************/
BEGIN TRY
	/******************************************************************
		Declare variables
	******************************************************************/
		DECLARE @MaxID	INT 

	/******************************************************************
		Backup existing table. Format in: table_YYYY MM DD HH MM SS
	******************************************************************/
		DECLARE @SQL VARCHAR(8000) = 'SELECT * INTO vSMAgreementServiceTask_',
				@TS	 VARCHAR(30)
				
		SELECT	@TS	 = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(30), GETDATE(), 120), '-', ''), ' ', ''), ':', '')
		SELECT	@SQL = @SQL + @TS + ' FROM vSMAgreementServiceTask'
		EXEC	(@SQL)
		
	/******************************************************************
		Modify table attributes
	******************************************************************/	
		ALTER TABLE vSMAgreementServiceTask NOCHECK CONSTRAINT ALL
		ALTER TABLE vSMAgreementServiceTask DISABLE TRIGGER ALL
		SET IDENTITY_INSERT vSMAgreementServiceTask ON
		
	/******************************************************************
		Check Delete flag and remove existing data if required
	******************************************************************/
		IF UPPER(@DeleteDataYN) = 'Y'
		BEGIN
			DELETE vSMAgreementServiceTask WHERE SMCo = @ToCo
		END
		
	/******************************************************************
		Perform the conversion
	******************************************************************/
		-- Get last used Primary Key
		SET @MaxID = (SELECT ISNULL(MAX(SMAgreementServiceTaskID), 0) FROM dbo.vSMAgreementServiceTask)
		
		-- CTE to get most recent Agreement Revision
		;WITH MaxAgrmtSeq (Agreement, Revision, Billing) AS
		(
			SELECT	AGREEMENTNBR,
					MAX(AGREEMENTSEQ),
					BILLINGTYPE
			FROM	CV_TL_Source_SM.dbo.AGRPERIOD
			GROUP BY AGREEMENTNBR, BILLINGTYPE
		),
		-- Get unique list of To Do's for each PM Task. Viewpoint
		-- does not allow duplicates, but Timberline does
		ToDo (EQPPMTASKNBR, DESCRIPTION) AS 
		(
			SELECT	DISTINCT
					EQPPMTASKNBR,
					DESCRIPTION
			FROM	CV_TL_Source_SM.dbo.EQPPMTASKITEM
		)

		INSERT	vSMAgreementServiceTask (
				SMAgreementServiceTaskID,
				SMCo,
				Agreement,
				Revision,
				Service,
				Task,
				SMStandardTask,
				Name,
				Description,
				ServiceItem,
				Notes)

		SELECT DISTINCT 
				SMAgreementServiceTaskID = @MaxID + ROW_NUMBER() OVER (ORDER BY @ToCo),
				SMCo				 = @ToCo,
				Agreement			 = eqp.AGREEMENTNBR,
				Revision			 = rev.Revision,
				Service				 = srv.Service,
				Task				 = ROW_NUMBER() OVER (PARTITION BY srv.Service ORDER BY srv.Service),
				SMStandardTask		 = std_task.SMStandardTask,
				Name				 = LEFT(item.DESCRIPTION, 60),
				Description			 = item.DESCRIPTION,
				ServiceItem			 = site_item.ServiceItem,
				Notes				 = NULL				
		
		FROM	ToDo AS item
		
		JOIN	CV_TL_Source_SM.dbo.EQPPMTASK AS task
			ON	task.EQPPMTASKNBR = item.EQPPMTASKNBR
			
		JOIN	CV_TL_Source_SM.dbo.AGREQUIP AS eqp
			ON	task.SYSEQPNBR = eqp.SYSEQPNBR
			
		JOIN	CV_TL_Source_SM.dbo.SERVSITEEQUIP AS site_eqp
			ON	eqp.SYSEQPNBR = site_eqp.SYSEQPNBR	
		
		JOIN	vSMServiceItems AS site_item
			ON	site_item.SMCo = @ToCo
			AND site_item.ServiceSite = site_eqp.SERVSITENBR
			AND site_item.ServiceItem = site_eqp.SYSEQPNBR

		JOIN	MaxAgrmtSeq AS rev
			ON	eqp.AGREEMENTNBR = rev.Agreement	
			AND eqp.AGREEMENTSEQ = rev.Revision
					
		 JOIN	vSMAgreementService AS srv
			ON	srv.SMCo	  = @ToCo
			AND srv.Agreement = rev.Agreement
			AND srv.Revision  = rev.Revision
			
			-- These join fields effectively roll-up Task Items 
			-- to the unified Work Schedules in Viewpoint
			AND srv.Description   = LEFT(task.DESCRIPTION,60)
			AND srv.PricingMethod = CASE WHEN rev.Billing = 1 THEN 'T'
										 WHEN rev.Billing = 0 THEN 'P'
										 ELSE 'I'
										 END
			AND srv.MonthlySelectOrdinal = CASE WHEN task.WEEKOFMONTH = 1 THEN 1
												WHEN task.WEEKOFMONTH = 2 THEN 2
												WHEN task.WEEKOFMONTH = 3 THEN 3
												WHEN task.WEEKOFMONTH = 4 THEN 4
												WHEN task.WEEKOFMONTH = 5 THEN 5
												END
			AND srv.MonthlySelectDay	 = CASE WHEN task.DAYOFWEEK = 1 THEN 4
												WHEN task.DAYOFWEEK = 2 THEN 5
												WHEN task.DAYOFWEEK = 3 THEN 6
												WHEN task.DAYOFWEEK = 4 THEN 7
												WHEN task.DAYOFWEEK = 5 THEN 8
												WHEN task.DAYOFWEEK = 6 THEN 9
												WHEN task.DAYOFWEEK = 7 THEN 10
												END
			AND srv.MonthlyJan			 = task.QJAN	
			AND srv.MonthlyFeb			 = task.QFEB
			AND srv.MonthlyMar			 = task.QMAR
			AND srv.MonthlyApr			 = task.QAPR
			AND srv.MonthlyMay			 = task.QMAY
			AND srv.MonthlyJun			 = task.QJUN
			AND srv.MonthlyJul			 = task.QJUL
			AND srv.MonthlyAug			 = task.QAUG
			AND srv.MonthlySep			 = task.QSEP
			AND srv.MonthlyOct			 = task.QOCT
			AND srv.MonthlyNov			 = task.QNOV
			AND srv.MonthlyDec			 = task.QDEC
			
		JOIN	vSMStandardTask AS std_task
			ON	std_task.SMCo = @ToCo
			AND std_task.Name = srv.Description

		WHERE	task.QINACTIVE = 'N'
			
		-- Commented out since it's not required to run actual Conversion
		--ORDER BY eqp.AGREEMENTNBR,
		--		 rev.Revision,
		--		 srv.Service,
		--		 site_item.ServiceItem,
		--		 item.EQPPMTASKITEM
		
		
	/******************************************************************
		Reset table attributes
	******************************************************************/	
		SET IDENTITY_INSERT vSMAgreementServiceTask OFF
		ALTER TABLE vSMAgreementServiceTask CHECK CONSTRAINT ALL;
		ALTER TABLE vSMAgreementServiceTask ENABLE TRIGGER ALL;

	/******************************************************************
		Review data
	******************************************************************/	
		SELECT * FROM vSMAgreementServiceTask WHERE SMCo = @ToCo
END TRY

BEGIN CATCH
	/******************************************************************
		Reset table attributes
	******************************************************************/	
		SET IDENTITY_INSERT vSMAgreementServiceTask OFF
		ALTER TABLE vSMAgreementServiceTask CHECK CONSTRAINT ALL;
		ALTER TABLE vSMAgreementServiceTask ENABLE TRIGGER ALL;
		
	/******************************************************************
		Error
	******************************************************************/	
		SELECT ERROR_MESSAGE() 
				+ ' at line number ' 
				+ CAST(ERROR_LINE() AS VARCHAR)
END CATCH 
GO
