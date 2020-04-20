SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE dbo.mckGenMonthYears
AS
/***************************************************************************************
* mckGenMonthYears                                                                     *
*                                                                                      *
* Purpose: Generate month and year value from first day of current month               *
*                                                                                      *
*                                                                                      *
* Date			By			Comment                                                        *
* ==========	========	===================================================            *
* 2014/2/09 	ZachFu	Created                                                        *
*                                                                                      *
*                                                                                      *
****************************************************************************************/
BEGIN

;WITH GenerateMonth(GenDate,Level)
AS
(
-- Push to first day of month
SELECT 
    DATEADD(dd,-(DAY(GETDATE())-1),GETDATE()) AS Gendate
   ,0 AS Level
UNION ALL
SELECT
   DATEADD(month,-1, GenDate), Level + 1
FROM
   GenerateMonth
WHERE
   Level < 24
)
SELECT
    CAST(GenDate AS date) AS DateValue
   ,CAST(MONTH(GenDate) AS varchar(2)) + '/' + RIGHT(CAST(DATENAME(year,GenDate) AS char(4)),2) AS DateLabel
FROM
   GenerateMonth;

END
GO
GRANT EXECUTE ON  [dbo].[mckGenMonthYears] TO [public]
GO
