SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[vrvPRPayStubByEmployee] 
/************** 
 Created:  03/07/11 HH initial version 
 Modified: 03/13/12 HH TK-13162 added function vf_rptPRGetYTDAmount that calculates the YTD amounts
								and wrapped records in a cte that fills up the 0 amounts for earning codes 
								in order to get the YTD amounts on report
		   JayR 2013-03-13  Re-adding this to db.
  
 Usage: 
 View Returning earnings, deductions, and liabilities for the PR Paystub report in Connects. 
   
*************/ 
AS 
  WITH cte 
       AS (SELECT dt.PRCo, 
                  hq.Name, 
                  dt.PRGroup, 
                  eh.Employee, 
                  dt.PREndDate, 
                  sq.PaidDate, 
                  dt.PaySeq, 
                  dt.EDLType, 
                  dt.EDLCode, 
                  dt.Amount, 
                  dbo.vf_rptPRGetYTDAmount(	dt.PRCo
											, eh.Employee
											, dt.EDLType
											, dt.EDLCode 
											, dt.PREndDate
											, dt.PaySeq
											, sq.PaidMth) AS YTDByEDLCode, 
                  dt.[Hours], 
                  dt.SubjectAmt, 
                  dt.EligibleAmt, 
                  sq.PaidMth, 
                  eh.LastName, 
                  eh.FirstName, 
                  dl.[Description]                     AS DLCodeDescription, 
                  ec.[Description]                     AS EarnCodeDescription, 
                  dt.UseOver, 
                  dt.OverAmt, 
                  gr.[Description]                     AS PRGroupDescription, 
                  dl.LimitPeriod, 
                  pc.LimitMth, 
                  eh.SortName, 
                  ec.TrueEarns 
           FROM   HQCO hq 
                  INNER JOIN PRDT dt 
                    ON hq.HQCo = dt.PRCo 
                  INNER JOIN PRSQ sq 
                    ON dt.PRCo = sq.PRCo 
                       AND dt.PRGroup = sq.PRGroup 
                       AND dt.PREndDate = sq.PREndDate 
                       AND dt.Employee = sq.Employee 
                       AND dt.PaySeq = sq.PaySeq 
                  INNER JOIN PREH eh 
                    ON dt.PRCo = eh.PRCo 
                       AND dt.Employee = eh.Employee 
                  INNER JOIN PRPC pc 
                    ON dt.PRCo = pc.PRCo 
                       AND dt.PRGroup = pc.PRGroup 
                       AND dt.PREndDate = pc.PREndDate 
                  INNER JOIN PRGR gr 
                    ON dt.PRCo = gr.PRCo 
                       AND dt.PRGroup = gr.PRGroup 
                  LEFT OUTER JOIN PRDL dl 
                    ON dt.PRCo = dl.PRCo 
                       AND dt.EDLCode = dl.DLCode 
                  LEFT OUTER JOIN PREC ec 
                    ON dt.PRCo = ec.PRCo 
                       AND dt.EDLCode = ec.EarnCode 
           WHERE  sq.PaidDate IS NOT NULL), 
       
       -- need to capture amounts that are 0 in order to cover cases
       -- where amount = 0 and YTD <> 0 for earning codes
       cteDistinct1 
       AS (SELECT DISTINCT PRCo, 
                           PRGroup, 
                           Employee, 
                           EDLType, 
                           EDLCode 
           FROM   cte 
          ), 
       cteDistinct2 
       AS (SELECT DISTINCT PRCo, 
                           PRGroup, 
                           Employee, 
                           PREndDate, 
                           PaidDate, 
                           PaidMth, 
                           PaySeq 
           FROM   cte 
          ), 
       cteRoot 
       AS (SELECT c1.*, 
                  c2.PREndDate, 
                  c2.PaidDate, 
                  c2.PaidMth, 
                  c2.PaySeq 
           FROM   cteDistinct1 c1 
                  LEFT OUTER JOIN cteDistinct2 c2 
                    ON c1.PRCo = c2.PRCo 
                       AND c1.PRGroup = c2.PRGroup 
                       AND c1.Employee = c2.Employee), 
       cteFinal 
       AS (SELECT r.*, 
                  --records that does not exist in cte because of combining 
                  --cteDistinct1 and cteDistinct2 are null, so turn to 0
                  Isnull(c.Amount, 0)  AS Amount, 
                  
                  --records that does not exist in cte because of combining 
                  --cteDistinct1 and cteDistinct2 are null, so call 
                  --the vf_rptPRGetYTDAmount function in order to get YTD amount
                  Isnull(c.YTDByEDLCode, dbo.vf_rptPRGetYTDAmount(	r.PRCo
																	, r.Employee
																	, r.EDLType
																	, r.EDLCode
																	, r.PREndDate
																	, r.PaySeq
																	, r.PaidMth)
						) AS YTDByEDLCode, 
                  c.DLCodeDescription, 
                  c.EarnCodeDescription 
           FROM   cteRoot r 
                  LEFT OUTER JOIN cte c 
                    ON r.PRCo = c.PRCo 
                       AND r.PRGroup = c.PRGroup 
                       AND r.Employee = c.Employee 
                       AND r.PREndDate = c.PREndDate 
                       AND r.PaidDate = c.PaidDate 
                       AND r.EDLType = c.EDLType 
                       AND r.EDLCode = c.EDLCode) 
  SELECT * 
  FROM   cteFinal 


GO
GRANT SELECT ON  [dbo].[vrvPRPayStubByEmployee] TO [public]
GRANT INSERT ON  [dbo].[vrvPRPayStubByEmployee] TO [public]
GRANT DELETE ON  [dbo].[vrvPRPayStubByEmployee] TO [public]
GRANT UPDATE ON  [dbo].[vrvPRPayStubByEmployee] TO [public]
GO
