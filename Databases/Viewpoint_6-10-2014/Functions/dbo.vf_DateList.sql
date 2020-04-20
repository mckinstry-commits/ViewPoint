SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[vf_DateList](@StartDate datetime, @EndDate datetime)

/*****
 Created:  DH 5/21/08
 Modified:
 Usage:  Function that returns a table of dates for use with the time dimension
 in SSAS Cubes
*******/

RETURNS @DateList TABLE ( [TheDate] datetime NOT NULL )
AS
BEGIN
     DECLARE @TheDate DateTime
     SET @TheDate = @StartDate

     WHILE DateDiff(day,@TheDate,@EndDate) >= 0
     BEGIN
           INSERT INTO @DateList ([TheDate]) VALUES (@TheDate)
           SET @TheDate = DATEADD(day, 1, @TheDate)
     END
RETURN
END

GO
GRANT SELECT ON  [dbo].[vf_DateList] TO [public]
GO
