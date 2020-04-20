SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[vf_ARAgeEndMonthDates](@StartDate datetime, @EndDate datetime)



RETURNS @DateList TABLE ( [TheDate] datetime NOT NULL )
AS
BEGIN
     DECLARE @TheDate DateTime
     SET @TheDate = dateadd(day,-1,dateadd(m,1,cast(cast(DATEPART(yy,@StartDate) as varchar) + '-'+ DATENAME(m, @StartDate) +'-01' as datetime)))
	 SET @EndDate = dateadd(day,-1,dateadd(m,1,cast(cast(DATEPART(yy,@EndDate) as varchar) + '-'+ DATENAME(m, @EndDate) +'-01' as datetime)))
     WHILE DateDiff(day,@TheDate,@EndDate) >= 0
     BEGIN
           INSERT INTO @DateList ([TheDate]) VALUES (@TheDate)
           SET @TheDate = dateadd(day,-1,dateadd(m,2,cast(cast(DATEPART(yy,@TheDate) as varchar) + '-'+ DATENAME(m, @TheDate) +'-01' as datetime)))
     END
RETURN
END


GO
GRANT SELECT ON  [dbo].[vf_ARAgeEndMonthDates] TO [public]
GO
