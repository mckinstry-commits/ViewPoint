SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/14/12
-- Description:	Returns the next generated service date
-- =============================================
CREATE FUNCTION [dbo].[vfSMGenerateWeeklyServiceDates]
(	
	@EffectiveDate bDate,
	@ExpirationDate bDate,
	@WeeklyEveryWeeks int,
	@WeeklyEverySun bYN,
	@WeeklyEveryMon bYN,
	@WeeklyEveryTue bYN,
	@WeeklyEveryWed bYN,
	@WeeklyEveryThu bYN,
	@WeeklyEveryFri bYN,
	@WeeklyEverySat bYN
)
RETURNS TABLE
AS
RETURN
(
	WITH EffectiveDateParts_CTE
	AS
	(
		SELECT DATEPART(dw, @EffectiveDate) EffectiveDateWeekDay
	),
	ServiceDateForEffectiveDateWeek_CTE
	AS
	(
		--Generate the sunday of the effective date week
		SELECT EffectiveDateWeekDay, DATEADD(d, -EffectiveDateWeekDay + 1, @EffectiveDate) ServiceDateForEffectiveDateWeek
		FROM EffectiveDateParts_CTE
	),
	SelectedDays_CTE
	AS
	(
		SELECT [WeekDay]
		FROM
		(
			SELECT @WeeklyEverySun DoWork, 1 [WeekDay]
			UNION ALL
			SELECT @WeeklyEveryMon, 2
			UNION ALL
			SELECT @WeeklyEveryTue, 3
			UNION ALL
			SELECT @WeeklyEveryWed, 4
			UNION ALL
			SELECT @WeeklyEveryThu, 5
			UNION ALL
			SELECT @WeeklyEveryFri, 6
			UNION ALL
			SELECT @WeeklyEverySat, 7
		) SelectedDays
		WHERE DoWork = 'Y'
	),
	FirstServiceDateWeek_CTE
	AS
	(
		--If the effective date week has any work days that wouldn't get done since they are before the effective date then we
		--we use the next week as the start week.
		SELECT CASE 
			WHEN EXISTS(SELECT 1 FROM SelectedDays_CTE WHERE [WeekDay] < EffectiveDateWeekDay) THEN DATEADD(d, 7, ServiceDateForEffectiveDateWeek)
			ELSE ServiceDateForEffectiveDateWeek
		END FirstServiceDateWeek
		FROM ServiceDateForEffectiveDateWeek_CTE
	),
	--Recursive CTE
	GenerateWeekStartDates_CTE
	AS
	(
		--Generate the sunday for each week that will have work done.
		SELECT FirstServiceDateWeek WeekStartDate
		FROM FirstServiceDateWeek_CTE
		UNION ALL
		SELECT DATEADD(wk, @WeeklyEveryWeeks, WeekStartDate)
		FROM GenerateWeekStartDates_CTE
		WHERE WeekStartDate <= @ExpirationDate
	),
	GenerateServiceDates_CTE
	AS
	(
		--For each week that has work to do build out the the specific days work will be done.
		SELECT DATEADD(d, [WeekDay] - 1, WeekStartDate) ServiceDate
		FROM GenerateWeekStartDates_CTE
			CROSS JOIN SelectedDays_CTE
	)
	SELECT ServiceDate
	FROM GenerateServiceDates_CTE
	WHERE ServiceDate <= @ExpirationDate
)
GO
GRANT SELECT ON  [dbo].[vfSMGenerateWeeklyServiceDates] TO [public]
GO
