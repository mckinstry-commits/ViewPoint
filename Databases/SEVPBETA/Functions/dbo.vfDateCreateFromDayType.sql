SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 3/16/12
-- Description:	Returns the date built from the month, year, ordinal and day type supplied.
--
-- Ordinal Definition:
--	1 - First
--	2 - Second
--	3 - Third
--	4 - Fourth
--	5 - Last
--
-- DayType Definition:
--	1 - Day
--	2 - Weekday
--	3 - Weekend Day
--	4 - Sunday
--	5 - Monday
--	6 - Tuesday
--	7 - Wednesday
--	8 - Thursday
--	9 - Friday
--	10 - Saturday
-- =============================================
CREATE FUNCTION [dbo].[vfDateCreateFromDayType]
(
	@Month tinyint,
	@Year smallint,
	@Ordinal tinyint,
	@DayType tinyint
)
RETURNS bDate
AS
BEGIN
	DECLARE @Date bDate

	--The last ordinal option takes special handling
	IF @Ordinal = 5
	BEGIN
		--The Day definition is so easy the date is returned right away
		--If a month doesn't have 31 days is it vfDateCreate will find the last day in the month
		IF @DayType = 1 RETURN dbo.vfDateCreate(@Month, 31, @Year)
	
		DECLARE @MonthEnd bDate, @MonthEndWeekDay tinyint
	
		--If a month doesn't have 31 days is it vfDateCreate will find the last day in the month
		SELECT @MonthEnd = dbo.vfDateCreate(@Month, 31, @Year), @MonthEndWeekDay = DATEPART(dw, @MonthEnd)
	
		SET @Date =
			CASE @DayType
				WHEN 2 THEN
					--The last day of the month is returned unless it is Saturday or Sunday in which case
					--the appropriate # of days is taken from the last day of the month
					DATEADD(d, CASE @MonthEndWeekDay WHEN 1 THEN -2 WHEN 7 THEN -1 ELSE 0 END, @MonthEnd)
				WHEN 3 THEN
					--Typically the last weekend of the month will be Sunday
					--For any weekday the number of days needed to find the Sunday before is taken
					--from the last day of the month. With this formula Saturday and Sunday -> 0.
					DATEADD(d, -((@MonthEndWeekDay - 1) % 6), @MonthEnd)
				ELSE
					--The DayType is essentially mapped to a 0 - 6 value which is then
					--taken from the last day of the month to find the correct day of the month.
					DATEADD(d, -((@MonthEndWeekDay + 10 - @DayType) % 7), @MonthEnd)
			END
	END
	ELSE
	BEGIN
		--The Day definition is so easy the date is returned right away
		IF @DayType = 1 RETURN dbo.vfDateCreate(@Month, @Ordinal, @Year)
	
		DECLARE @MonthStart bDate, @MonthStartWeekDay tinyint
	
		SELECT @MonthStart = dbo.vfDateCreate(@Month, 1, @Year), @MonthStartWeekDay = DATEPART(dw, @MonthStart)
	
		SET @Date =
			CASE @DayType
				--Find the weekday
				WHEN 2 THEN
					CASE
						--If the first day of the week is a Sunday or after adding the ordinal the date lands
						--on a Sunday then 1 day needs to be added
						WHEN @MonthStartWeekDay = 1 OR @MonthStartWeekDay + @Ordinal - 1 = 1 THEN
							DATEADD(d, @Ordinal, @MonthStart)
						--If the first day of the week is a Saturday or after adding the ordinal the date overlaps or lands
						--on a weekend then 2 days need to be added.
						WHEN @MonthStartWeekDay + @Ordinal - 1 > 6 THEN
							DATEADD(d, @Ordinal + 1, @MonthStart)
						--The normal scenario is to just add the ordinal value to the first day of the month
						ELSE
							DATEADD(d, @Ordinal - 1, @MonthStart)
					END
				--Find the weekend
				WHEN 3 THEN
					CASE
						--Special handling for when the first day of the month is Sunday
						WHEN @MonthStartWeekDay = 1 THEN
							DATEADD(d, CASE @Ordinal WHEN 2 THEN 6 WHEN 3 THEN 7 WHEN 4 THEN 13 ELSE 0 END, @MonthStart)
						--Normal handling is to find the Saturday for the current week and add the approriate # of days based on the ordinal.
						ELSE
							DATEADD(d, CASE @Ordinal WHEN 2 THEN 1 WHEN 3 THEN 7 WHEN 4 THEN 8 ELSE 0 END, DATEADD(d, 7 - @MonthStartWeekDay, @MonthStart))
					END
				ELSE
					--The DayType is essentially mapped to a 0 - 6 value which is then
					--added to the first day of the month to find the first instance of the week day in the month.
					--The date found then has the approriate # of weeks added to it.
					DATEADD(wk, @Ordinal - 1, DATEADD(d, (@DayType + 4 - @MonthStartWeekDay) % 7, @MonthStart))
			END
	END
		
	RETURN @Date
END
GO
GRANT EXECUTE ON  [dbo].[vfDateCreateFromDayType] TO [public]
GO
