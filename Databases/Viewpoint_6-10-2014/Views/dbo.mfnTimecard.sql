SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[mfnTimecard]
AS
/***********************************************************************************************************
* mfnTimecard                                                                                              *
*                                                                                                          *
* Purpose: Extract Timecard data for Payroll                                                               *
*                                                                                                          *
*                                                                                                          *
* Date			By			Comment                                                                            *
* ==========	========	=============================================================================      *
* 04/29/2014 	ZachFu	Created                                                                            *
*                                                                                                          * 
*                                                                                                          * 
************************************************************************************************************/
WITH PRLast
AS
(
SELECT
    prth.PRCo
   ,prth.Employee
   ,prth.PREndDate AS PREndDate
   ,prth.PRGroup
   ,prth.PaySeq
   ,prth.Memo
   ,MAX(prth.Rate) AS MaxRate
   ,MIN(prth.Rate) AS MinRate
   ,SUM(CASE WHEN EarnCode = 1 THEN prth.Hours ELSE 0 END) AS RegHrs           
   ,SUM(CASE WHEN EarnCode = 2 THEN prth.Hours ELSE 0 END) AS OTHrs           
   ,SUM(CASE WHEN EarnCode NOT IN (1,2) THEN prth.Hours ELSE 0 END) AS OtherHrs           
   ,SUM(prth.Amt) AS TotAmt
FROM
   dbo.bPRTH prth WITH (READUNCOMMITTED)
   JOIN
      (
       SELECT
          prth2.PRCo
         ,prth2.Employee
         ,MAX(prth2.PREndDate) AS PREndDate
       FROM
         dbo.bPRTH prth2 WITH (READUNCOMMITTED)
       GROUP BY
          prth2.PRCo
         ,prth2.Employee
       ) prth2 
		      ON prth.PRCo = prth2.PRCo
               AND prth.Employee = prth2.Employee
               AND prth.PREndDate = prth2.PREndDate 
WHERE
   prth.Hours <> 0
GROUP BY
    prth.PRCo
   ,prth.Employee
   ,prth.PREndDate
   ,prth.PRGroup
   ,prth.PaySeq
   ,prth.Memo
)
SELECT
    prl.PRCo
   ,prl.Employee
   ,preh.LastName
   ,preh.FirstName
   ,preh.MidName
   ,preh.udExempt
   ,prl.PRGroup
   ,prl.PaySeq
   ,prps.Description
   ,prl.PREndDate
   ,CAST(ROUND(prl.MaxRate,2) AS decimal(6,2)) AS MaxRate
   ,CAST(ROUND(prl.MinRate,2) AS decimal(6,2)) AS MinRate
   ,CAST(ROUND(preh.HrlyRate,2) AS decimal(6,2)) AS BaseRate
   ,prl.RegHrs AS RegHrs
   ,prl.OTHrs AS OTHrs
   ,prl.OtherHrs AS OtherHrs
   ,prl.TotAmt 
   ,prl.Memo
FROM
   PRLast prl WITH (READUNCOMMITTED)
	RIGHT OUTER JOIN
      dbo.bPREH preh WITH (READUNCOMMITTED)
         ON preh.PRCo = prl.PRCo
            AND preh.Employee = prl.Employee
            AND preh.PRGroup = prl.PRGroup 
	JOIN
      dbo.bPRPS prps WITH (READUNCOMMITTED)
         ON prps.PRCo = prl.PRCo
            AND prps.PRGroup = preh.PRGroup
            AND prps.PaySeq = prl.PaySeq
            AND prps.PREndDate = prl.PREndDate 
WHERE
   preh.ActiveYN = 'Y'
GO
