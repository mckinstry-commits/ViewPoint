SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[SMAgreementServiceDatesGenerated]
AS
SELECT SMAgreementService.SMCo, SMAgreementService.Agreement, SMAgreementService.Revision, SMAgreementService.[Service], ServiceDates.ServiceDate
FROM dbo.SMAgreementService
	INNER JOIN dbo.SMAgreementExtended ON SMAgreementService.SMCo = SMAgreementExtended.SMCo AND SMAgreementService.Agreement = SMAgreementExtended.Agreement AND SMAgreementService.Revision = SMAgreementExtended.Revision
	CROSS APPLY (SELECT ISNULL(SMAgreementExtended.EffectiveDate, dbo.vfDateOnly()) EffectiveDate, ISNULL(SMAgreementExtended.EndDate, DATEADD(year, 1, ISNULL(SMAgreementExtended.EffectiveDate, dbo.vfDateOnly()))) EndDate) DeriveDates
	CROSS APPLY (
		SELECT ServiceDate
		FROM dbo.vfSMGenerateDailyServiceDates(DeriveDates.EffectiveDate, DeriveDates.EndDate, SMAgreementService.DailyType, SMAgreementService.DailyEveryDays)
		WHERE SMAgreementService.RecurringPatternType = 'D'
		UNION ALL
		SELECT ServiceDate
		FROM dbo.vfSMGenerateWeeklyServiceDates(DeriveDates.EffectiveDate, DeriveDates.EndDate, WeeklyEveryWeeks, WeeklyEverySun, WeeklyEveryMon, WeeklyEveryTue, WeeklyEveryWed, WeeklyEveryThu, WeeklyEveryFri, WeeklyEverySat)
		WHERE SMAgreementService.RecurringPatternType = 'W'
		UNION ALL
		SELECT ServiceDate
		FROM dbo.vfSMGenerateMonthlyServiceDates(DeriveDates.EffectiveDate, DeriveDates.EndDate, MonthlyType, MonthlyDay, MonthlyDayEveryMonths, MonthlyEveryOrdinal, MonthlyEveryDay, MonthlyEveryMonths, MonthlySelectOrdinal, MonthlySelectDay, MonthlyJan, MonthlyFeb, MonthlyMar, MonthlyApr, MonthlyMay, MonthlyJun, MonthlyJul, MonthlyAug, MonthlySep, MonthlyOct, MonthlyNov, MonthlyDec)
		WHERE SMAgreementService.RecurringPatternType = 'M'
		UNION ALL
		SELECT ServiceDate
		FROM dbo.vfSMGenerateYearlyServiceDates(DeriveDates.EffectiveDate, DeriveDates.EndDate, YearlyType, YearlyEveryYear, YearlyEveryDateMonth, YearlyEveryDateMonthDay, YearlyEveryDayOrdinal, YearlyEveryDayDay, YearlyEveryDayMonth)
		WHERE SMAgreementService.RecurringPatternType = 'Y'
	) ServiceDates
GO
GRANT SELECT ON  [dbo].[SMAgreementServiceDatesGenerated] TO [public]
GRANT INSERT ON  [dbo].[SMAgreementServiceDatesGenerated] TO [public]
GRANT DELETE ON  [dbo].[SMAgreementServiceDatesGenerated] TO [public]
GRANT UPDATE ON  [dbo].[SMAgreementServiceDatesGenerated] TO [public]
GRANT SELECT ON  [dbo].[SMAgreementServiceDatesGenerated] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMAgreementServiceDatesGenerated] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMAgreementServiceDatesGenerated] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMAgreementServiceDatesGenerated] TO [Viewpoint]
GO
