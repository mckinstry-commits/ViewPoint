SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].cvsp_STO_SMAgreementService (
		@ToCo			bCompany,
		@FromCo			bCompany,
		@DeleteDataYN	CHAR(1))
AS
/**************************************************************************************************
Copyright:	2013 Coaxis/Viewpoint Construction Software (VCS) 
			The TSQL code in this procedure may not be reproduced, copied, modified,
			or executed without the expressed written consent from VCS.

Project:	Timberline to Viewpoint V6 SM Conversion - SM Agreement, Work Schedule tab (Services)
Author:		Chris Lounsbury
Purpose:	Convert Timberline Freqency schedule into Viewpoint SM Work Schedules.  This form defines
			what services will be performed at a given site, on a given schedule
			
Change Log:

	20130428	CL	Initial Coding	
	20130502	CL	Added UNION to pull PM tasks by Equipment reference as well as Agreement reference
					Timberline allows both methods of linking PM Tasks to Agreements.
					Final INSERT has groupings to group PM Tasks from Timberline for all PM Tasks
					with like attributes.
**************************************************************************************************/
BEGIN TRY
	/******************************************************************
		Declare variables
	******************************************************************/
		DECLARE @MaxID	INT 

	/******************************************************************
		Backup existing table. Format in: table_YYYY MM DD HH MM SS
	******************************************************************/
		DECLARE @SQL VARCHAR(8000) = 'SELECT * INTO vSMAgreementService_',
				@TS	 VARCHAR(30)
				
		SELECT	@TS	 = REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(30), GETDATE(), 120), '-', ''), ' ', ''), ':', '')
		SELECT	@SQL = @SQL + @TS + ' FROM vSMAgreementService'
		EXEC	(@SQL)
		
	/******************************************************************
		Modify table attributes
	******************************************************************/	
		ALTER TABLE vSMAgreementService NOCHECK CONSTRAINT ALL
		ALTER TABLE vSMAgreementService DISABLE TRIGGER ALL
		SET IDENTITY_INSERT vSMAgreementService ON
		
	/******************************************************************
		Check Delete flag and remove existing data if required
	******************************************************************/
		IF UPPER(@DeleteDataYN) = 'Y'
		BEGIN
			DELETE vSMAgreementService WHERE SMCo = @ToCo
		END
		
	/******************************************************************
		Perform the conversion
	******************************************************************/
		-- Reset intermediate results table
		IF OBJECT_ID('tempdb..#PMTasks') IS NOT NULL
		BEGIN
			DROP TABLE #PMTasks
		END
	
		-- Get last used Primary Key
		SET @MaxID = (SELECT ISNULL(MAX(SMAgreementServiceID), 0) FROM dbo.vSMAgreementService)
		
		-- CTE to get most recent Agreement Revision
		;WITH Revisions (id, Agreement, Revision, Billing)
		AS
		(
			SELECT	ROW_NUMBER() OVER (PARTITION BY AGREEMENTNBR ORDER BY AGREEMENTNBR) AS id,
					AGREEMENTNBR,
					MAX(AGREEMENTSEQ),
					BILLINGTYPE
			FROM	CV_TL_Source_SM.dbo.AGRPERIOD
			GROUP BY AGREEMENTNBR, BILLINGTYPE
		)

		-- Union both scenarios together:
		-- 1. Tasks linked directly to an agreement
		-- 2. Tasks linked through Equipment to an agreeement
		SELECT	*
		INTO	#PMTasks
		FROM	(
					-- 1. Tasks linked directly to an agreement
					SELECT	SMCo				 = @ToCo,
							Agreement			 = task.AGREEMENTNBR,
							Revision			 = rev.Revision,
							Service				 = task.EQPPMTASKNBR,
							Description			 = LEFT(task.DESCRIPTION,60), --60 char limit
							ServiceSite			 = CAST(agr.SERVSITENBR AS VARCHAR(20)),
							CallType			 = xct.NewCallType,
							ServiceCenter		 = ctr.ABBREVIATION, --Both are varchar(10)
							TaxSource			 = 'S',
							PricingMethod		 = CASE WHEN rev.Billing = 1 THEN 'T'
														WHEN rev.Billing = 0 THEN 'P'
														ELSE 'I'
														END,
							PricingFrequency	 = NULL,
							PricingPrice		 = NULL,
							BilledSeparately	 = NULL,
							PricingRateTemplate	 = NULL,
							ScheOptContactBeforeScheduling = 'Y',
							ScheOptDueType		 = NULL,
							ScheOptDays			 = NULL,
							RecurringPatternType = 'M', -- Default to Monthly due to how Timberline schedules
							DailyType			 = NULL,
							DailyEveryDays		 = NULL,
							WeeklyEveryWeeks	 = NULL,
							WeeklyEverySun		 = NULL,
							WeeklyEveryMon		 = NULL,
							WeeklyEveryTue		 = NULL,
							WeeklyEveryWed		 = NULL,
							WeeklyEveryThu		 = NULL,
							WeeklyEveryFri		 = NULL,
							WeeklyEverySat		 = NULL,
							MonthlyType			 = 3, -- Default to X day of X month(s) from Timberline
							MonthlyDay			 = NULL,
							MonthlyDayEveryMonths= NULL,
							MonthlyEveryOrdinal	 = NULL,
							MonthlyEveryDay		 = NULL,
							MonthlyEveryMonths	 = NULL,
							MonthlySelectOrdinal = CASE WHEN task.WEEKOFMONTH = 1 THEN 1
														WHEN task.WEEKOFMONTH = 2 THEN 2
														WHEN task.WEEKOFMONTH = 3 THEN 3
														WHEN task.WEEKOFMONTH = 4 THEN 4
														WHEN task.WEEKOFMONTH = 5 THEN 5
														END,
							MonthlySelectDay	 = CASE WHEN task.DAYOFWEEK = 1 THEN 4
														WHEN task.DAYOFWEEK = 2 THEN 5
														WHEN task.DAYOFWEEK = 3 THEN 6
														WHEN task.DAYOFWEEK = 4 THEN 7
														WHEN task.DAYOFWEEK = 5 THEN 8
														WHEN task.DAYOFWEEK = 6 THEN 9
														WHEN task.DAYOFWEEK = 7 THEN 10
														END,
							MonthlyJan			 = QJAN,	
							MonthlyFeb			 = QFEB,
							MonthlyMar			 = QMAR,
							MonthlyApr			 = QAPR,
							MonthlyMay			 = QMAY,
							MonthlyJun			 = QJUN,
							MonthlyJul			 = QJUL,
							MonthlyAug			 = QAUG,
							MonthlySep			 = QSEP,
							MonthlyOct			 = QOCT,
							MonthlyNov			 = QNOV,
							MonthlyDec			 = QDEC,
							YearlyType			 = NULL,
							YearlyEveryYear		 = NULL,
							YearlyEveryDateMonth = NULL,
							YearlyEveryDateMonthDay = NULL,
							YearlyEveryDayOrdinal= NULL,
							YearlyEveryDayDay	 = NULL,
							YearlyEveryDayMonth	 = NULL,
							WasCopied			 = 0,
							Notes				 = NULL
				
					FROM	CV_TL_Source_SM.dbo.EQPPMTASK AS task
						
					JOIN	Revisions AS rev
						ON	task.AGREEMENTNBR = rev.Agreement
						
					JOIN	CV_TL_Source_SM.dbo.AGREEMENT AS agr
						ON	task.AGREEMENTNBR = agr.AGREEMENTNBR
						
					JOIN	CV_TL_Source_SM.dbo.CENTER AS ctr
						ON	ctr.CENTERNBR = task.CENTERNBR
						
					LEFT JOIN budXRefSMCallTypes AS xct
						ON	xct.SMCo = @FromCo 
						and xct.OldCallType = task.CALLTYPECODE 
					
					WHERE	task.QINACTIVE = 'N'			
						AND	task.AGREEMENTNBR <> 0 
									
					UNION ALL		
					
					-- 2. Tasks linked through Equipment to an agreeement		
					SELECT DISTINCT
							SMCo				 = @ToCo,
							Agreement			 = eqp.AGREEMENTNBR,
							Revision			 = rev.Revision,
							Service				 = task.EQPPMTASKNBR,
							Description			 = LEFT(task.DESCRIPTION,60), --60 char limit
							ServiceSite			 = CAST(agr.SERVSITENBR AS VARCHAR(20)),
							CallType			 = xct.NewCallType,
							ServiceCenter		 = ctr.ABBREVIATION, --Both are varchar(10)
							TaxSource			 = 'S',
							PricingMethod		 = CASE WHEN rev.Billing = 1 THEN 'T'
														WHEN rev.Billing = 0 THEN 'P'
														ELSE 'I'
														END,
							PricingFrequency	 = NULL,
							PricingPrice		 = NULL,
							BilledSeparately	 = NULL,
							PricingRateTemplate	 = NULL,
							ScheOptContactBeforeScheduling = 'Y',
							ScheOptDueType		 = NULL,
							ScheOptDays			 = NULL,
							RecurringPatternType = 'M', -- Default to Monthly due to how Timberline schedules
							DailyType			 = NULL,
							DailyEveryDays		 = NULL,
							WeeklyEveryWeeks	 = NULL,
							WeeklyEverySun		 = NULL,
							WeeklyEveryMon		 = NULL,
							WeeklyEveryTue		 = NULL,
							WeeklyEveryWed		 = NULL,
							WeeklyEveryThu		 = NULL,
							WeeklyEveryFri		 = NULL,
							WeeklyEverySat		 = NULL,
							MonthlyType			 = 3, -- Default to X day of X month(s) from Timberline
							MonthlyDay			 = NULL,
							MonthlyDayEveryMonths= NULL,
							MonthlyEveryOrdinal	 = NULL,
							MonthlyEveryDay		 = NULL,
							MonthlyEveryMonths	 = NULL,
							MonthlySelectOrdinal = CASE WHEN task.WEEKOFMONTH = 1 THEN 1
														WHEN task.WEEKOFMONTH = 2 THEN 2
														WHEN task.WEEKOFMONTH = 3 THEN 3
														WHEN task.WEEKOFMONTH = 4 THEN 4
														WHEN task.WEEKOFMONTH = 5 THEN 5
														END,
							MonthlySelectDay	 = CASE WHEN task.DAYOFWEEK = 1 THEN 4
														WHEN task.DAYOFWEEK = 2 THEN 5
														WHEN task.DAYOFWEEK = 3 THEN 6
														WHEN task.DAYOFWEEK = 4 THEN 7
														WHEN task.DAYOFWEEK = 5 THEN 8
														WHEN task.DAYOFWEEK = 6 THEN 9
														WHEN task.DAYOFWEEK = 7 THEN 10
														END,
							MonthlyJan			 = QJAN,	
							MonthlyFeb			 = QFEB,
							MonthlyMar			 = QMAR,
							MonthlyApr			 = QAPR,
							MonthlyMay			 = QMAY,
							MonthlyJun			 = QJUN,
							MonthlyJul			 = QJUL,
							MonthlyAug			 = QAUG,
							MonthlySep			 = QSEP,
							MonthlyOct			 = QOCT,
							MonthlyNov			 = QNOV,
							MonthlyDec			 = QDEC,
							YearlyType			 = NULL,
							YearlyEveryYear		 = NULL,
							YearlyEveryDateMonth = NULL,
							YearlyEveryDateMonthDay = NULL,
							YearlyEveryDayOrdinal= NULL,
							YearlyEveryDayDay	 = NULL,
							YearlyEveryDayMonth	 = NULL,
							WasCopied			 = 0,
							Notes				 = NULL
				
					FROM	CV_TL_Source_SM.dbo.EQPPMTASK AS task
						
					JOIN CV_TL_Source_SM.dbo.AGREQUIP AS eqp
						ON	task.SYSEQPNBR = eqp.SYSEQPNBR
						
					JOIN	Revisions AS rev
						ON	eqp.AGREEMENTNBR = rev.Agreement
						
					JOIN CV_TL_Source_SM.dbo.AGREEMENT AS agr
						ON	eqp.AGREEMENTNBR = agr.AGREEMENTNBR
									
					JOIN	CV_TL_Source_SM.dbo.CENTER AS ctr
						ON	ctr.CENTERNBR = task.CENTERNBR
						
					LEFT JOIN budXRefSMCallTypes AS xct
						ON	xct.SMCo = @FromCo 
						and xct.OldCallType = task.CALLTYPECODE 
					
					WHERE	task.QINACTIVE = 'N'			
						AND	task.AGREEMENTNBR = 0
						AND eqp.AGREEMENTNBR <> 0
				) AS tasks
				
		-- Populate SM table and generate ID's here	
		-- Insert unique values only, TL stores Tasks as separate records
		-- but this would lead to a single Work Order for a single peice of Equipment
		-- in Viewpoint.  This effectively rolls up PM Tasks for the same Description/Schedule
		INSERT	vSMAgreementService (
				SMAgreementServiceID,
				SMCo,
				Agreement,
				Revision,
				Service,
				Description,
				ServiceSite,
				CallType,
				ServiceCenter,
				TaxSource,
				PricingMethod,
				PricingFrequency,
				PricingPrice,
				BilledSeparately,
				PricingRateTemplate,
				ScheOptContactBeforeScheduling,
				ScheOptDueType,
				ScheOptDays,
				RecurringPatternType,
				DailyType,
				DailyEveryDays,
				WeeklyEveryWeeks,
				WeeklyEverySun,
				WeeklyEveryMon,
				WeeklyEveryTue,
				WeeklyEveryWed,
				WeeklyEveryThu,
				WeeklyEveryFri,
				WeeklyEverySat,
				MonthlyType,
				MonthlyDay,
				MonthlyDayEveryMonths,
				MonthlyEveryOrdinal,
				MonthlyEveryDay,
				MonthlyEveryMonths,
				MonthlySelectOrdinal,
				MonthlySelectDay,
				MonthlyJan,
				MonthlyFeb,
				MonthlyMar,
				MonthlyApr,
				MonthlyMay,
				MonthlyJun,
				MonthlyJul,
				MonthlyAug,
				MonthlySep,
				MonthlyOct,
				MonthlyNov,
				MonthlyDec,
				YearlyType,
				YearlyEveryYear,
				YearlyEveryDateMonth,
				YearlyEveryDateMonthDay,
				YearlyEveryDayOrdinal,
				YearlyEveryDayDay,
				YearlyEveryDayMonth,
				WasCopied,
				Notes)
				
		SELECT	SMAgreementServiceID = @MaxID + ROW_NUMBER() OVER (ORDER BY @ToCo),
				SMCo,
				Agreement,
				Revision,
				MAX(Service) AS Service,
				Description,
				ServiceSite,
				CallType,
				ServiceCenter,
				TaxSource,
				PricingMethod,
				PricingFrequency,
				PricingPrice,
				BilledSeparately,
				PricingRateTemplate,
				ScheOptContactBeforeScheduling,
				ScheOptDueType,
				ScheOptDays,
				RecurringPatternType,
				DailyType,
				DailyEveryDays,
				WeeklyEveryWeeks,
				WeeklyEverySun,
				WeeklyEveryMon,
				WeeklyEveryTue,
				WeeklyEveryWed,
				WeeklyEveryThu,
				WeeklyEveryFri,
				WeeklyEverySat,
				MonthlyType,
				MonthlyDay,
				MonthlyDayEveryMonths,
				MonthlyEveryOrdinal,
				MonthlyEveryDay,
				MonthlyEveryMonths,
				MonthlySelectOrdinal,
				MonthlySelectDay,
				MonthlyJan,
				MonthlyFeb,
				MonthlyMar,
				MonthlyApr,
				MonthlyMay,
				MonthlyJun,
				MonthlyJul,
				MonthlyAug,
				MonthlySep,
				MonthlyOct,
				MonthlyNov,
				MonthlyDec,
				YearlyType,
				YearlyEveryYear,
				YearlyEveryDateMonth,
				YearlyEveryDateMonthDay,
				YearlyEveryDayOrdinal,
				YearlyEveryDayDay,
				YearlyEveryDayMonth,
				WasCopied,
				Notes
		FROM	#PMTasks AS task
		GROUP BY SMCo,
				 Agreement,
				 Revision,
				 Description,
				 ServiceSite,
				 CallType,
				 ServiceCenter,
				 TaxSource,
				 PricingMethod,
				 PricingFrequency,
				 PricingPrice,
				 BilledSeparately,
				 PricingRateTemplate,
				 ScheOptContactBeforeScheduling,
				 ScheOptDueType,
				 ScheOptDays,
				 RecurringPatternType,
				 DailyType,
				 DailyEveryDays,
				 WeeklyEveryWeeks,
				 WeeklyEverySun,
				 WeeklyEveryMon,
				 WeeklyEveryTue,
				 WeeklyEveryWed,
				 WeeklyEveryThu,
				 WeeklyEveryFri,
				 WeeklyEverySat,
				 MonthlyType,
				 MonthlyDay,
				 MonthlyDayEveryMonths,
				 MonthlyEveryOrdinal,
				 MonthlyEveryDay,
				 MonthlyEveryMonths,
				 MonthlySelectOrdinal,
				 MonthlySelectDay,
				 MonthlyJan,
				 MonthlyFeb,
				 MonthlyMar,
				 MonthlyApr,
				 MonthlyMay,
				 MonthlyJun,
				 MonthlyJul,
				 MonthlyAug,
				 MonthlySep,
				 MonthlyOct,
				 MonthlyNov,
				 MonthlyDec,
				 YearlyType,
				 YearlyEveryYear,
				 YearlyEveryDateMonth,
				 YearlyEveryDateMonthDay,
				 YearlyEveryDayOrdinal,
				 YearlyEveryDayDay,
				 YearlyEveryDayMonth,
				 WasCopied,
				 Notes
		
	/******************************************************************
		Reset table attributes
	******************************************************************/	
		SET IDENTITY_INSERT vSMAgreementService OFF
		ALTER TABLE vSMAgreementService CHECK CONSTRAINT ALL;
		ALTER TABLE vSMAgreementService ENABLE TRIGGER ALL;

	/******************************************************************
		Review data
	******************************************************************/	
		SELECT * FROM vSMAgreementService WHERE SMCo = @ToCo
END TRY

BEGIN CATCH
	/******************************************************************
		Reset table attributes
	******************************************************************/	
		SET IDENTITY_INSERT vSMAgreementService OFF
		ALTER TABLE vSMAgreementService CHECK CONSTRAINT ALL;
		ALTER TABLE vSMAgreementService ENABLE TRIGGER ALL;
		
	/******************************************************************
		Error
	******************************************************************/	
		SELECT ERROR_MESSAGE() 
				+ ' at line number ' 
				+ CAST(ERROR_LINE() AS VARCHAR)
END CATCH 
GO
