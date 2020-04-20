SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.BITargetBudget
AS
SELECT * FROM dbo.vBITargetBudget
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* Created: HH 12/21/2012 TK-20369
* Modified: 
*
*	This trigger sends formatted date data to BITargetBudget columns
*
************************************************************************/
CREATE TRIGGER [dbo].[vtBITargetBudgeti] 
   ON  [dbo].[BITargetBudget] 
   INSTEAD OF INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	INSERT INTO vBITargetBudget (BICo
						,TargetName
						,Revision						
						,TargetDate
						,[DayOfWeek]
						,DayNameOfWeek
						,[DayOfMonth]
						,[DayOfYear]
						,WeekdayWeekend
						,WeekOfYear
						,[MonthName]
						,MonthOfYear
						,IsLastDayOfMonth
						,CalendarQuarter
						,CalendarYear
						,Goal)
	SELECT BICo
			,TargetName
			,Revision
			,TargetDate
			,DATEPART(dw, TargetDate)			--DayOfWeek
			,DATENAME(dw, TargetDate)			--DayNameOfWeek
			,DATENAME(dd, TargetDate)			--DayOfMonth
			,DATENAME(dy, TargetDate)			--DayOfYear
			,CASE DATENAME(dw, TargetDate)
				WHEN 'Saturday' THEN 'Weekend'
				WHEN 'Sunday' THEN 'Weekend'
				ELSE 'Weekday'
			END									--WeekdayWeekend
			,DATENAME(ww, TargetDate)			--WeekOfYear
			,DATENAME(mm, TargetDate)			--MonthName
			,MONTH(TargetDate)					--MonthOfYear
			,CASE MONTH(TargetDate)
				WHEN MONTH(DATEADD(d, 1, TargetDate)) THEN 'N'
				ELSE 'Y'
			END									--IsLastDayOfMonth
			,DATENAME(qq, TargetDate)			--CalendarQuarter
			,YEAR(TargetDate)					--CalendarYear
			,Goal
	FROM inserted
		
		
END

GO
GRANT SELECT ON  [dbo].[BITargetBudget] TO [public]
GRANT INSERT ON  [dbo].[BITargetBudget] TO [public]
GRANT DELETE ON  [dbo].[BITargetBudget] TO [public]
GRANT UPDATE ON  [dbo].[BITargetBudget] TO [public]
GRANT SELECT ON  [dbo].[BITargetBudget] TO [Viewpoint]
GRANT INSERT ON  [dbo].[BITargetBudget] TO [Viewpoint]
GRANT DELETE ON  [dbo].[BITargetBudget] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[BITargetBudget] TO [Viewpoint]
GO
