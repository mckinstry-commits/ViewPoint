USE [Viewpoint]
GO
/****** Object:  StoredProcedure [dbo].[mckPRTimecardExceptions]    Script Date: 11/7/2014 11:21:41 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[mckPRTimecardExceptions]
(
    @Company bCompany = 101
   ,@PRGroup varchar(3) = null
   ,@PREndDate date = null
   ,@PaySeq tinyint = null
)
AS
/********************************************************************************************************************
* mckPRTimecardExceptions																							*
*																													*
* Purpose: Extract data for the SSRS PRTimecardExceptions report													*
*																													*
*																													*
* Date			By			Comment																					*
* ==========	========	========================================================================================*
* 04/29/2014 	ZachFu		Created																					*
* 05/16/2014    ZachFu   	Modified																				* 
* 05/29/2014    ZachFu   	Modified																				* 
* 11/07/2014	Amit Mody   Bug fix - Print error 'Rate is less than $15 or over $150' for rate with non-zero hours * 
* 11/17/2014	Amit Mody	Change request - Print error 'Exempt staff, total Hours not equal to 40' for PRGroup=1	*                                                                           * 
********************************************************************************************************************/
BEGIN



DECLARE
   @PaySeqDesc varchar(30)

-- Push date to last valid PREndDate (Sunday); If not invoked from VP launcher
IF @PREndDate IS NULL OR @PREndDate = ''
   -- SELECT @PREndDate = DATEADD(DAY,1-DATEPART(WEEKDAY,GETDATE()),GETDATE()); 
   SELECT @PREndDate = MAX(PREndDate) FROM PRPC WHERE PREndDate <= GETDATE();

IF @PRGroup = ''
   SET @PRGroup = null
ELSE
   SET @PRGroup = CAST(@PRGroup AS tinyint);

IF @PaySeq = ''
   SET @PaySeq = null
ELSE
   SET  @PaySeq = CAST(@PaySeq AS tinyint);

-- Set up the PaySeq Description
SELECT @PaySeqDesc =
   CASE
      WHEN @PaySeq IS NULL THEN 'All'
      WHEN @PRGroup IS NULL THEN CAST(@PaySeq AS varchar(10))
      ELSE CAST(PaySeq AS varchar(10)) + ' - ' + Description
   END
FROM
   dbo.bPRPS WITH (READUNCOMMITTED)
WHERE
    PRCo = @Company
   AND PRGroup = @PRGroup
   AND PaySeq = @PaySeq
   AND PREndDate = @PREndDate

SELECT @PaySeqDesc = ISNULL(@PaySeqDesc,@PaySeq);

;WITH EmpLastPayPeriod
AS
(
SELECT
    preh.PRCo
   ,preh.Employee
   ,preh.LastName + ', ' + preh.FirstName + CASE WHEN preh.MidName IS NULL THEN '' ELSE ' ' + preh.MidName END AS EmployeeName
   ,prth.LastPaidDate
   ,ISNULL(prth.LastPaidHrs,0) AS LastPaidHrs
   ,preh.udExempt 
   ,preh.PRGroup
   ,ISNULL(preh.HrlyRate,0) AS BaseRate
   ,preh.ActiveYN
FROM
   bPREH preh
   LEFT JOIN 
      (
        SELECT
            PRCo 
           ,Employee
           ,PREndDate AS LastPaidDate
           ,SUM(Hours) AS LastPaidHrs
        FROM
           PRTH prth
        WHERE
           PREndDate = (SELECT
                           MAX(PREndDate)
                        FROM
                           PRTH prth2
                        WHERE
                           prth2.PREndDate < @PREndDate  -- prior to the PREnddate filter (current)
                           AND prth2.PREndDate IS NOT NULL
                           AND prth2.PRCo = prth.PRCo
                           AND prth2.Employee = prth.Employee)
        GROUP BY
             PRCo 
            ,Employee
            ,PREndDate
        ) prth
             ON prth.PRCo = preh.PRCo
                AND prth.Employee = preh.Employee
WHERE
   (preh.PRCo = @Company AND @Company IS NOT NULL)
   AND preh.ActiveYN = 'Y'
   AND (@PRGroup IS NULL OR preh.PRGroup = @PRGroup)
)
,AggReportHrs
AS
(
SELECT
    elpp.PRCo
   ,elpp.EmployeeName
   ,elpp.Employee
   ,elpp.udExempt 
   ,elpp.PRGroup
   ,elpp.LastPaidDate
   ,elpp.LastPaidHrs
   --,elpp.ActiveYN
   -- if pay rate > 0, return highest pay rate, otherwise return base rate
   ,CASE WHEN MAX(ISNULL(prth.Rate,0)) > 0 THEN MAX(prth.Rate) ELSE elpp.BaseRate END AS Rate
   ,prth.Memo
   ,MAX(ISNULL(prth.Rate,0)) AS MaxRate  -- for error checking
   ,MIN(ISNULL(prth.Rate,0)) AS MinRate  -- for error checking
   ,SUM(CASE WHEN prth.EarnCode = 1 THEN ISNULL(prth.Hours,0) ELSE 0 END) AS RegHrs      
   ,SUM(CASE WHEN prth.EarnCode = 2 THEN ISNULL(prth.Hours,0) ELSE 0 END) AS OTHrs           
   ,SUM(CASE WHEN prth.EarnCode = 3 THEN ISNULL(prth.Hours,0) ELSE 0 END) AS DblHrs              
   ,SUM(CASE WHEN prth.EarnCode NOT IN (1,2,3) THEN ISNULL(prth.Hours,0) ELSE 0 END) AS OtherHrs

   -- For shopcategory and shopjob, udShopYN will be 'Y' and udpc.KeyID will not be null, Sum will be zero
   ,SUM(CASE WHEN prcc.udShopYN = 'Y' AND udpc.KeyID IS null THEN 1 ELSE 0 END) AS ShopJobErr  -- Shop job category but not a shop job       
FROM
   EmpLastPayPeriod elpp -- for last Paid date and Hrs paid prior to PREndDate filter
   LEFT JOIN      
      dbo.bPRTH prth WITH (READUNCOMMITTED)
         ON prth.PRCo = elpp.PRCo
            AND prth.Employee = elpp.Employee
            AND prth.PRGroup = elpp.PRGroup
            AND prth.PREndDate = @PREndDate
			AND prth.Hours <> 0
   LEFT JOIN
      bPRCC prcc WITH (READUNCOMMITTED)
         ON prcc.PRCo = prth.PRCo
            AND prcc.Craft = prth.Craft
            AND prcc.Class = prth.Class
   LEFT JOIN
      udPhaseCategories udpc WITH (READUNCOMMITTED)
         ON udpc.Phase = prth.Phase
            AND udpc.PhaseGroup = prth.PhaseGroup
WHERE
   (@PaySeq IS NULL OR prth.PaySeq = @PaySeq)
   AND elpp.ActiveYN = 'Y'
GROUP BY
    elpp.PRCo
   ,elpp.EmployeeName
   ,elpp.Employee
   ,elpp.udExempt
   ,elpp.PRGroup 
   ,elpp.LastPaidDate
   ,elpp.LastPaidHrs
   ,elpp.BaseRate
   ,prth.Memo
   --,elpp.ActiveYN
)
SELECT
    arh.PRCo AS Company
   ,arh.PRGroup
   ,arh.EmployeeName
   ,arh.Employee AS EmployeeNum
   ,arh.udExempt AS Status
   ,@PaySeqDesc AS PaySeqDesc
   ,CAST(arh.LastPaidDate AS date) AS LastPaidDate
   ,LastPaidHrs AS LastPaidHrs
   ,CAST(ROUND(arh.Rate,2) AS decimal(6,2)) AS Rate
   --,CAST(ROUND(arh.MinRate,2) AS decimal(6,2)) AS MinRate
   --,CAST(ROUND(arh.MaxRate,2) AS decimal(6,2)) AS MaxRate
   ,arh.RegHrs AS RegHrs
   ,arh.OTHrs AS OTHrs
   ,arh.DblHrs AS DblHrs
   ,arh.OtherHrs AS OtherHrs
   ,CAST(ROUND((arh.RegHrs + arh.OTHrs + arh.DblHrs + arh.OtherHrs),2) AS decimal(6,2)) AS TotalHours
   ,arh.Memo
  -- All employees, no hours
   ,CASE WHEN arh.RegHrs + arh.OTHrs + arh.OtherHrs = 0 THEN 'No hours(Missing timecard) ' ELSE '' END AS Err1
   -- All employees hours but rate < $15 or > $150
   ,CASE WHEN ((arh.RegHrs + arh.OTHrs + arh.OtherHrs) <> 0) AND (arh.MaxRate > 150 OR arh.MinRate < 15) THEN 'Rate is less than $15 or over $150 ' ELSE '' END AS Err2
   -- Union (PRGroup = 2 and reg hours > 40
   ,CASE WHEN arh.PRGroup = 2 AND arh.RegHrs > 40 THEN 'Union, over 40 regular Hours ' ELSE '' END AS Err3
    -- Non-Exempt staff, regular hours > 40
    ,CASE WHEN arh.PRGroup = 1 AND arh.udExempt = 'N' AND arh.RegHrs > 40 THEN 'Non-exempt, over 40 regular Hours ' ELSE '' END AS Err4
    -- Exempt staff,  total hours <> 40
    ,CASE WHEN arh.PRGroup = 1 AND arh.udExempt = 'E' AND (arh.RegHrs + arh.OTHrs + arh.OtherHrs)  <> 40 THEN 'Exempt staff, total Hours not equal to 40 ' ELSE '' END AS Err5
    -- Shop class but non-shop jobs
    ,CASE WHEN arh.ShopJobErr > 0 THEN 'Shop class but non-shop job' ELSE '' END AS Err6
FROM
   AggReportHrs arh WITH (READUNCOMMITTED)
ORDER BY
    arh.PRCo
   ,arh.PRGroup
   ,arh.EmployeeName
      
END
GO

-- Test Script
EXEC [dbo].[mckPRTimecardExceptions] 1, null, '10/12/2014'