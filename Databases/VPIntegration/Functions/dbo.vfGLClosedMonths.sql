SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 6/27/11
-- Description:	Outputs what the last each company's last closed month based on the source.
--				Also outputs the open months for the given source.
--				An optional parameter to pass in the month parameter which will return whether the 
--				given month is an open month and if not then the closest open month will be returned.
-- =============================================
CREATE FUNCTION [dbo].[vfGLClosedMonths]
(	
	@Source bSource, @Month bMonth = NULL
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT GLCo, LastClosedMonth, BeginMonth, EndMonth, IsMonthOpen, ClosestOpenMonth
	FROM (SELECT GLCo,
			CASE
				WHEN @Source LIKE 'GL%' THEN LastMthGLClsd
				WHEN @Source LIKE 'AR%' OR @Source LIKE 'JB%' OR @Source = 'MS Invoice' THEN LastMthARClsd
				WHEN @Source LIKE 'AP%' OR @Source IN ('MS MatlPay', 'MS HaulPay') THEN LastMthAPClsd
				ELSE LastMthSubClsd
			END LastClosedMonth,
			DATEADD(MONTH, MaxOpen, LastMthSubClsd) EndMonth
			FROM dbo.bGLCO) bGLCO
		OUTER APPLY (SELECT DATEADD(MONTH, 1, LastClosedMonth) BeginMonth) BeginMonth
		OUTER APPLY (
			SELECT CAST(CASE WHEN BeginMonth <= @Month AND @Month <= EndMonth THEN 1 ELSE 0 END AS BIT) IsMonthOpen,
				CASE WHEN BeginMonth > @Month THEN BeginMonth WHEN EndMonth < @Month THEN EndMonth ELSE @Month END ClosestOpenMonth
		) IsMonthOpen
)

GO
GRANT SELECT ON  [dbo].[vfGLClosedMonths] TO [public]
GO
