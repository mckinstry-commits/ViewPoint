IF OBJECT_ID ('dbo.mvwPRInsJob', 'view') IS NOT NULL
DROP VIEW dbo.mvwPRInsJob;
GO

CREATE VIEW dbo.mvwPRInsJob
AS 
--brvPRInsJob
/*Posted Earnings*/ 
SELECT PRTH.PRCo, PRTH.PRGroup, PRTH.PREndDate, PRTH.JCCo, PRTH.Job, PRTH.PhaseGroup, PRTH.Phase, PRTH.Employee, PRTH.PaySeq, PRTH.InsState, PRTH.InsCode, PRTL.LiabCode, 
                         PRTL.Rate, LiabAmt = SUM(PRTL.Amt), TimeCardEarn = SUM(PRTH.Amt), AddonEarn = 0, STE = SUM(CASE WHEN PREC.Factor <> 0 THEN PRTH.Amt / PREC.Factor END), Hours = SUM(PRTH.Hours), 
                         VarSTRate = 0, VarSTE = 0
FROM            bPRTH PRTH JOIN
                         bPRTL PRTL ON PRTH.PRCo = PRTL.PRCo AND PRTH.PRGroup = PRTL.PRGroup AND PRTH.PREndDate = PRTL.PREndDate AND PRTH.Employee = PRTL.Employee AND PRTH.PaySeq = PRTL.PaySeq AND 
                         PRTH.PostSeq = PRTL.PostSeq JOIN
                         bPRIA PRIA ON PRTH.PRCo = PRIA.PRCo AND PRTH.PRGroup = PRIA.PRGroup AND PRTH.PREndDate = PRIA.PREndDate AND PRTH.Employee = PRIA.Employee AND PRTH.PaySeq = PRIA.PaySeq AND 
                         PRTH.InsState = PRIA.State AND PRTH.InsCode = PRIA.InsCode AND PRTL.LiabCode = PRIA.DLCode JOIN
                         PREC ON PRTH.PRCo = PREC.PRCo AND PRTH.EarnCode = PREC.EarnCode
GROUP BY PRTH.PRCo, PRTH.PRGroup, PRTH.PREndDate, PRTH.JCCo, PRTH.Job, PRTH.PhaseGroup, PRTH.Phase, PRTH.Employee, PRTH.PaySeq, PRTH.InsState, PRTH.InsCode, PRTL.LiabCode, PRTL.Rate
UNION ALL
/*Posted Earnings: STE for zero-rate insurance liabilities*/ 
SELECT PRTH.PRCo, PRTH.PRGroup, PRTH.PREndDate, PRTH.JCCo, PRTH.Job, PRTH.PhaseGroup, PRTH.Phase, PRTH.Employee, PRTH.PaySeq, PRTH.InsState, 
                         PRTH.InsCode, PRIA.DLCode, PRIA.Rate, LiabAmt = 0, TimeCardEarn = SUM(PRTH.Amt), AddonEarn = 0, STE = SUM(CASE WHEN PREC.Factor <> 0 THEN PRTH.Amt / PREC.Factor END), 
                         Hours = SUM(PRTH.Hours), VarSTRate = 0, VarSTE = 0
FROM            bPRTH PRTH JOIN
                         bPRIA PRIA ON PRTH.PRCo = PRIA.PRCo AND PRTH.PRGroup = PRIA.PRGroup AND PRTH.PREndDate = PRIA.PREndDate AND PRTH.Employee = PRIA.Employee AND PRTH.PaySeq = PRIA.PaySeq AND 
                         PRTH.InsState = PRIA.State AND PRTH.InsCode = PRIA.InsCode JOIN
                         PRDB ON PRDB.PRCo = PRIA.PRCo AND PRDB.DLCode = PRIA.DLCode AND PRDB.EDLCode = PRTH.EarnCode AND PRDB.EDLType = 'E' JOIN
                         PREC ON PRTH.PRCo = PREC.PRCo AND PRTH.EarnCode = PREC.EarnCode
WHERE        PRIA.Amt = 0
GROUP BY PRTH.PRCo, PRTH.PRGroup, PRTH.PREndDate, PRTH.JCCo, PRTH.Job, PRTH.PhaseGroup, PRTH.Phase, PRTH.Employee, PRTH.EarnCode, PREC.Factor, PRTH.PaySeq, PRTH.InsState, PRTH.InsCode, 
                         PRIA.DLCode, PRIA.Rate
UNION ALL
/*Addon Earnings */ 
SELECT PRTH.PRCo, PRTH.PRGroup, PRTH.PREndDate, PRTH.JCCo, PRTH.Job, PRTH.PhaseGroup, PRTH.Phase, PRTH.Employee, PRTH.PaySeq, PRTH.InsState, PRTH.InsCode, PRIA.DLCode, 
                         PRIA.Rate, LiabAmt = 0, TimeCardEarn = 0, AddonEarn = SUM(PRTA.Amt), STE = 0, Hours = 0, VarSTRate = MAX(b.VarSTRate), VarSTE = SUM(CASE WHEN PREC_TA.Method = 'V' AND ISNULL(b.VarSTRate, 0) 
                         <> 0 AND ISNULL(PRTA.Rate, 0) <> 0 THEN PRTA.Amt / (PRTA.Rate / b.VarSTRate) WHEN PREC_TA.Method = 'F' AND ISNULL(PREC_TH.Factor, 0) <> 0 THEN PRTA.Amt / PREC_TH.Factor ELSE PRTA.Amt END)
FROM            bPRTH PRTH JOIN
                         PRTA ON PRTH.PRCo = PRTA.PRCo AND PRTH.PRGroup = PRTA.PRGroup AND PRTH.PREndDate = PRTA.PREndDate AND PRTH.Employee = PRTA.Employee AND PRTH.PaySeq = PRTA.PaySeq AND 
                         PRTH.PostSeq = PRTA.PostSeq JOIN
                         bPRIA PRIA ON PRTH.PRCo = PRIA.PRCo AND PRTH.PRGroup = PRIA.PRGroup AND PRTH.PREndDate = PRIA.PREndDate AND PRTH.Employee = PRIA.Employee AND PRTH.PaySeq = PRIA.PaySeq AND 
                         PRTH.InsState = PRIA.State AND PRTH.InsCode = PRIA.InsCode JOIN
                         PRDB ON PRDB.PRCo = PRIA.PRCo AND PRDB.DLCode = PRIA.DLCode AND PRDB.EDLCode = PRTA.EarnCode AND PRDB.EDLType = 'E' JOIN
                         PREC PREC_TH ON PRTH.PRCo = PREC_TH.PRCo AND PRTH.EarnCode = PREC_TH.EarnCode JOIN
                         PREC PREC_TA ON PRTA.PRCo = PREC_TA.PRCo AND PRTA.EarnCode = PREC_TA.EarnCode LEFT JOIN
                         --brvPRInsVarRate b 
						 (SELECT        dbo.PRTA.PRCo, dbo.PRTA.PRGroup, dbo.PRTA.PREndDate, dbo.PRTA.Employee, dbo.PRTA.PaySeq, dbo.bPRTH.PostDate, dbo.PRTA.EarnCode AS AddonEC, MIN(dbo.PRTA.Rate) AS VarSTRate
							FROM        dbo.PRTA INNER JOIN
										dbo.bPRTH ON dbo.bPRTH.PRCo = dbo.PRTA.PRCo AND dbo.bPRTH.PRGroup = dbo.PRTA.PRGroup AND dbo.bPRTH.PREndDate = dbo.PRTA.PREndDate AND dbo.bPRTH.Employee = dbo.PRTA.Employee AND 
										dbo.bPRTH.PaySeq = dbo.PRTA.PaySeq AND dbo.bPRTH.PostSeq = dbo.PRTA.PostSeq INNER JOIN
										dbo.PREC AS PREC_TH ON PREC_TH.PRCo = dbo.bPRTH.PRCo AND PREC_TH.EarnCode = dbo.bPRTH.EarnCode INNER JOIN
										dbo.PREC AS PREC_TA ON PREC_TA.PRCo = dbo.PRTA.PRCo AND PREC_TA.EarnCode = dbo.PRTA.EarnCode
							WHERE       (PREC_TA.Method = 'V') AND (PREC_TH.Factor = 1.0)
							GROUP BY dbo.PRTA.PRCo, dbo.PRTA.PRGroup, dbo.PRTA.PREndDate, dbo.PRTA.Employee, dbo.PRTA.PaySeq, dbo.bPRTH.PostDate, dbo.PRTA.EarnCode
						 ) b
						 ON b.PRCo = PRTH.PRCo AND b.PRGroup = PRTH.PRGroup AND b.PREndDate = PRTH.PREndDate AND b.Employee = PRTH.Employee AND b.PaySeq = PRTH.PaySeq AND 
                         b.PostDate = PRTH.PostDate AND b.AddonEC = PRTA.EarnCode
GROUP BY PRTH.PRCo, PRTH.PRGroup, PRTH.PREndDate, PRTH.JCCo, PRTH.Job, PRTH.PhaseGroup, PRTH.Phase, PRTH.Employee, PRTH.PaySeq, PRTH.InsState, PRTH.InsCode, PRIA.DLCode, PRIA.Rate
GO

GRANT SELECT ON dbo.mvwPRInsJob TO [public]
GO