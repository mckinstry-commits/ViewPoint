SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[brvPRInsJob]
      
/*******************************************************************

View used by the PR Insurance by Job Report.  
Created 2/14/2002 DH

View selects each liability amount, as well as timecard posted earnings and addon earnings 
used as the basis for the liability amount calculation

Revision history
10/23/2003 - DH - Added select statements to return earnings for zero liability amts
04/02/2004 - DH - Added Hours to View (Issue 21741)
10/31/2010 - CW - Changed linkage of view PRDB from to support new columns EDLCode and EDLType (Issue 140541)
05/18/2012 - CC - In Select statement for addon earnings, in Case statement for selected column VarSTE, added
case for addon earncodes that use calculation method Factored Rate per Hour to return correct STE dollar amount

*******************************************************************/

AS

--Posted Earnings
SELECT	PRTH.PRCo, PRTH.PRGroup, PRTH.PREndDate, PRTH.JCCo, PRTH.Job, PRTH.PhaseGroup, PRTH.Phase,
		PRTH.Employee, PRTH.PaySeq, PRTH.InsState, PRTH.InsCode, PRTL.LiabCode, PRTL.Rate, LiabAmt=SUM(PRTL.Amt), TimeCardEarn=SUM(PRTH.Amt), 
		AddonEarn=0, STE=SUM(CASE WHEN PREC.Factor<>0 THEN PRTH.Amt/PREC.Factor END), Hours=SUM(PRTH.Hours), VarSTRate=0, VarSTE=0
FROM PRTH
JOIN PRTL ON PRTH.PRCo=PRTL.PRCo AND PRTH.PRGroup=PRTL.PRGroup AND PRTH.PREndDate=PRTL.PREndDate AND PRTH.Employee=PRTL.Employee AND PRTH.PaySeq=PRTL.PaySeq AND PRTH.PostSeq=PRTL.PostSeq
JOIN PRIA ON PRTH.PRCo=PRIA.PRCo AND PRTH.PRGroup=PRIA.PRGroup AND PRTH.PREndDate=PRIA.PREndDate AND PRTH.Employee=PRIA.Employee AND PRTH.PaySeq=PRIA.PaySeq AND PRTH.InsState=PRIA.State AND PRTH.InsCode=PRIA.InsCode AND PRTL.LiabCode=PRIA.DLCode
JOIN PREC ON PRTH.PRCo=PREC.PRCo AND PRTH.EarnCode=PREC.EarnCode
GROUP BY PRTH.PRCo, PRTH.PRGroup, PRTH.PREndDate, PRTH.JCCo, PRTH.Job, PRTH.PhaseGroup, PRTH.Phase, PRTH.Employee, PRTH.PaySeq, PRTH.InsState, PRTH.InsCode, PRTL.LiabCode, PRTL.Rate

UNION ALL

--Posted Earnings: STE for zero-rate insurance liabilities
SELECT	PRTH.PRCo, PRTH.PRGroup, PRTH.PREndDate, PRTH.JCCo, PRTH.Job, PRTH.PhaseGroup, PRTH.Phase, 
		PRTH.Employee, PRTH.PaySeq, PRTH.InsState, PRTH.InsCode, PRIA.DLCode, PRIA.Rate, LiabAmt=0, TimeCardEarn=SUM(PRTH.Amt),
		AddonEarn=0, STE=SUM(CASE WHEN PREC.Factor<>0 THEN PRTH.Amt/PREC.Factor END), Hours=SUM(PRTH.Hours), VarSTRate=0, VarSTE=0
FROM PRTH
JOIN PRIA ON PRTH.PRCo=PRIA.PRCo AND PRTH.PRGroup=PRIA.PRGroup AND PRTH.PREndDate=PRIA.PREndDate AND PRTH.Employee=PRIA.Employee AND PRTH.PaySeq=PRIA.PaySeq AND PRTH.InsState=PRIA.State AND PRTH.InsCode=PRIA.InsCode
JOIN PRDB ON PRDB.PRCo=PRIA.PRCo AND PRDB.DLCode=PRIA.DLCode AND PRDB.EDLCode=PRTH.EarnCode and PRDB.EDLType = 'E' 
JOIN PREC ON PRTH.PRCo=PREC.PRCo AND PRTH.EarnCode=PREC.EarnCode
WHERE PRIA.Amt=0
GROUP BY PRTH.PRCo, PRTH.PRGroup, PRTH.PREndDate, PRTH.JCCo, PRTH.Job, PRTH.PhaseGroup, PRTH.Phase, PRTH.Employee, PRTH.EarnCode, PREC.Factor, PRTH.PaySeq, PRTH.InsState, PRTH.InsCode, PRIA.DLCode, PRIA.Rate

UNION ALL

--Addon Earnings 
SELECT	PRTH.PRCo, PRTH.PRGroup, PRTH.PREndDate, PRTH.JCCo, PRTH.Job, PRTH.PhaseGroup, PRTH.Phase, 
		PRTH.Employee, PRTH.PaySeq, PRTH.InsState, PRTH.InsCode, PRIA.DLCode, PRIA.Rate, LiabAmt=0, TimeCardEarn=0, 
		AddonEarn=SUM(PRTA.Amt), STE=0, Hours=0, VarSTRate=MAX(b.VarSTRate), 
		VarSTE=SUM(CASE 
					WHEN PREC_TA.Method = 'V' AND ISNULL(b.VarSTRate,0)<>0 AND ISNULL(PRTA.Rate,0)<>0 THEN PRTA.Amt/(PRTA.Rate/b.VarSTRate) 
					WHEN PREC_TA.Method = 'F' AND ISNULL(PREC_TH.Factor,0)<>0 THEN PRTA.Amt/PREC_TH.Factor
					ELSE PRTA.Amt END)
FROM PRTH
JOIN PRTA ON PRTH.PRCo=PRTA.PRCo AND PRTH.PRGroup=PRTA.PRGroup AND PRTH.PREndDate=PRTA.PREndDate AND PRTH.Employee=PRTA.Employee AND PRTH.PaySeq=PRTA.PaySeq AND PRTH.PostSeq=PRTA.PostSeq
JOIN PRIA ON PRTH.PRCo=PRIA.PRCo AND PRTH.PRGroup=PRIA.PRGroup AND PRTH.PREndDate=PRIA.PREndDate AND PRTH.Employee=PRIA.Employee AND PRTH.PaySeq=PRIA.PaySeq AND PRTH.InsState=PRIA.State AND PRTH.InsCode=PRIA.InsCode
JOIN PRDB ON PRDB.PRCo=PRIA.PRCo AND PRDB.DLCode=PRIA.DLCode AND PRDB.EDLCode=PRTA.EarnCode and PRDB.EDLType = 'E'
JOIN PREC PREC_TH ON PRTH.PRCo=PREC_TH.PRCo AND PRTH.EarnCode=PREC_TH.EarnCode
JOIN PREC PREC_TA ON PRTA.PRCo=PREC_TA.PRCo AND PRTA.EarnCode=PREC_TA.EarnCode
LEFT JOIN brvPRInsVarRate b ON b.PRCo=PRTH.PRCo AND b.PRGroup=PRTH.PRGroup AND b.PREndDate=PRTH.PREndDate AND b.Employee=PRTH.Employee AND b.PaySeq=PRTH.PaySeq AND b.PostDate=PRTH.PostDate AND b.AddonEC=PRTA.EarnCode
GROUP BY PRTH.PRCo, PRTH.PRGroup, PRTH.PREndDate, PRTH.JCCo, PRTH.Job, PRTH.PhaseGroup, PRTH.Phase, PRTH.Employee, PRTH.PaySeq, PRTH.InsState, PRTH.InsCode, PRIA.DLCode, PRIA.Rate
GO
GRANT SELECT ON  [dbo].[brvPRInsJob] TO [public]
GRANT INSERT ON  [dbo].[brvPRInsJob] TO [public]
GRANT DELETE ON  [dbo].[brvPRInsJob] TO [public]
GRANT UPDATE ON  [dbo].[brvPRInsJob] TO [public]
GRANT SELECT ON  [dbo].[brvPRInsJob] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvPRInsJob] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvPRInsJob] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvPRInsJob] TO [Viewpoint]
GO
