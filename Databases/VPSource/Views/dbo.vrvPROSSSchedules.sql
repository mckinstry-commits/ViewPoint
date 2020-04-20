SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:	  Mike Brewer

-- =============================================
CREATE VIEW [dbo].[vrvPROSSSchedules]
--	
as


SELECT 
PROT.PRCo, 
------------------------------------------------------------------------------------------------
case isnull(PROS.Lvl1MonEarnCode,0) when 0 then '' else
cast(PROS.Lvl1MonEarnCode as varchar) + '  ' + SO_L1Mon_PREC.Description end as 'SOL1MonEC',

case isnull(PROS.Lvl1TuesEarnCode,0) when 0 then '' else
cast(PROS.Lvl1TuesEarnCode as varchar) + '  ' + SO_L1Tue_PREC.Description end as 'SOL1TueEC',

case isnull(PROS.Lvl1WedEarnCode,0) when 0 then '' else
cast(PROS.Lvl1WedEarnCode as varchar) + '  ' + SO_L1Wed_PREC.Description end as 'SOL1WedEC',

case isnull(PROS.Lvl1ThursEarnCode,0) when 0 then '' else
cast(PROS.Lvl1ThursEarnCode as varchar) + '  ' + SO_L1Thu_PREC.Description end as 'SOL1ThuEC',

case isnull(PROS.Lvl1FriEarnCode,0) when 0 then '' else
cast(PROS.Lvl1FriEarnCode as varchar) + '  ' + SO_L1Fri_PREC.Description end as 'SOL1FriEC',

case isnull(PROS.Lvl1SatEarnCode,0) when 0 then '' else
cast(PROS.Lvl1SatEarnCode as varchar) + '  ' + SO_L1Sat_PREC.Description end as 'SOL1SatEC',

case isnull(PROS.Lvl1SunEarnCode,0) when 0 then '' else
cast(PROS.Lvl1SunEarnCode as varchar) + '  ' + SO_L1Sun_PREC.Description end as 'SOL1SunEC',

case isnull(PROS.Lvl1HolEarnCode,0) when 0 then '' else
cast(PROS.Lvl1HolEarnCode as varchar) + '  ' + SO_L1Hol_PREC.Description end as 'SOL1HolEC',

--------------------------------------------------------------------------------------------

case isnull(PROS.Lvl2MonEarnCode,0) when 0 then '' else
cast(PROS.Lvl2MonEarnCode as varchar) + '  ' + SO_L2Mon_PREC.Description end as 'SOL2MonEC',

case isnull(PROS.Lvl2TuesEarnCode,0) when 0 then '' else
cast(PROS.Lvl2TuesEarnCode as varchar) + '  ' + SO_L2Tue_PREC.Description end as 'SOL2TueEC',

case isnull(PROS.Lvl2WedEarnCode,0) when 0 then '' else
cast(PROS.Lvl2WedEarnCode as varchar) + '  ' + SO_L2Wed_PREC.Description end as 'SOL2WedEC',

case isnull(PROS.Lvl2ThursEarnCode,0) when 0 then '' else
cast(PROS.Lvl2ThursEarnCode as varchar) + '  ' + SO_L2Thu_PREC.Description end as 'SOL2ThuEC',

case isnull(PROS.Lvl2FriEarnCode,0) when 0 then '' else
cast(PROS.Lvl2FriEarnCode as varchar) + '  ' + SO_L2Fri_PREC.Description end as 'SOL2FriEC',

case isnull(PROS.Lvl2SatEarnCode,0) when 0 then '' else
cast(PROS.Lvl2SatEarnCode as varchar) + '  ' + SO_L2Sat_PREC.Description end as 'SOL2SatEC',

case isnull(PROS.Lvl2SunEarnCode,0) when 0 then '' else
cast(PROS.Lvl2SunEarnCode as varchar) + '  ' + SO_L2Sun_PREC.Description end as 'SOL2SunEC',

case isnull(PROS.Lvl2HolEarnCode,0) when 0 then '' else
cast(PROS.Lvl2HolEarnCode as varchar) + '  ' + SO_L2Hol_PREC.Description end as 'SOL2HolEC',

----------------------------------------------------------------------------------------------

case isnull(PROS.Lvl3MonEarnCode,0) when 0 then '' else
cast(PROS.Lvl3MonEarnCode as varchar) + '  ' + SO_L3Mon_PREC.Description end as 'SOL3MonEC',

case isnull(PROS.Lvl3TuesEarnCode,0) when 0 then '' else
cast(PROS.Lvl3TuesEarnCode as varchar) + '  ' + SO_L3Tue_PREC.Description end as 'SOL3TueEC',

case isnull(PROS.Lvl3WedEarnCode,0) when 0 then '' else
cast(PROS.Lvl3WedEarnCode as varchar) + '  ' + SO_L3Wed_PREC.Description end as 'SOL3WedEC',

case isnull(PROS.Lvl3ThursEarnCode,0) when 0 then '' else
cast(PROS.Lvl3ThursEarnCode as varchar) + '  ' + SO_L3Thu_PREC.Description end as 'SOL3ThuEC',

case isnull(PROS.Lvl3FriEarnCode,0) when 0 then '' else
cast(PROS.Lvl3FriEarnCode as varchar) + '  ' + SO_L3Fri_PREC.Description end as 'SOL3FriEC',

case isnull(PROS.Lvl3SatEarnCode,0) when 0 then '' else
cast(PROS.Lvl3SatEarnCode as varchar) + '  ' + SO_L3Sat_PREC.Description end as 'SOL3SatEC',

case isnull(PROS.Lvl3SunEarnCode,0) when 0 then '' else
cast(PROS.Lvl3SunEarnCode as varchar) + '  ' + SO_L3Sun_PREC.Description end as 'SOL3SunEC',

case isnull(PROS.Lvl3HolEarnCode,0) when 0 then '' else
cast(PROS.Lvl3HolEarnCode as varchar) + '  ' + SO_L3Hol_PREC.Description end as 'SOL3HolEC',

--------------------------------------------------------------------------------------------
PROS.Lvl1MonHrs, 
PROS.Lvl1TuesHrs, 
PROS.Lvl1WedHrs, 
PROS.Lvl1ThursHrs, 
PROS.Lvl1FriHrs, 
PROS.Lvl1SatHrs, 
PROS.Lvl1SunHrs, 
PROS.Lvl1HolHrs, 
---------------------
PROS.Lvl2MonHrs, 
PROS.Lvl2TuesHrs, 
PROS.Lvl2WedHrs, 
PROS.Lvl2ThursHrs, 
PROS.Lvl2FriHrs, 
PROS.Lvl2SatHrs, 
PROS.Lvl2SunHrs, 
PROS.Lvl2HolHrs, 
---------------------
PROS.Lvl3MonHrs, 
PROS.Lvl3TuesHrs, 
PROS.Lvl3WedHrs, 
PROS.Lvl3ThursHrs, 
PROS.Lvl3FriHrs, 
PROS.Lvl3SatHrs, 
PROS.Lvl3SunHrs, 
PROS.Lvl3HolHrs, 
---------------------
PROS.OTSched, 
PROS.Shift
FROM   
PROT PROT 
INNER JOIN PROS PROS 
	ON PROT.PRCo=PROS.PRCo 
	AND PROT.OTSched=PROS.OTSched 
LEFT OUTER JOIN PREC SO_L1Mon_PREC 
	ON PROS.PRCo=SO_L1Mon_PREC.PRCo 
	AND PROS.Lvl1MonEarnCode=SO_L1Mon_PREC.EarnCode 
LEFT OUTER JOIN PREC SO_L1Tue_PREC 
	ON PROS.PRCo=SO_L1Tue_PREC.PRCo 
	AND PROS.Lvl1TuesEarnCode=SO_L1Tue_PREC.EarnCode 
LEFT OUTER JOIN PREC SO_L1Wed_PREC 
	ON PROS.PRCo=SO_L1Wed_PREC.PRCo 
	AND PROS.Lvl1WedEarnCode=SO_L1Wed_PREC.EarnCode 
LEFT OUTER JOIN PREC SO_L1Thu_PREC 
	ON PROS.PRCo=SO_L1Thu_PREC.PRCo 
	AND PROS.Lvl1ThursEarnCode=SO_L1Thu_PREC.EarnCode 
LEFT OUTER JOIN PREC SO_L1Fri_PREC 
	ON PROS.PRCo=SO_L1Fri_PREC.PRCo 
	AND PROS.Lvl1FriEarnCode=SO_L1Fri_PREC.EarnCode 
LEFT OUTER JOIN PREC SO_L1Sat_PREC 
	ON PROS.PRCo=SO_L1Sat_PREC.PRCo 
	AND PROS.Lvl1SatEarnCode=SO_L1Sat_PREC.EarnCode 
LEFT OUTER JOIN PREC SO_L1Sun_PREC 
	ON PROS.PRCo=SO_L1Sun_PREC.PRCo 
	AND PROS.Lvl1SunEarnCode=SO_L1Sun_PREC.EarnCode 
LEFT OUTER JOIN PREC SO_L1Hol_PREC 
	ON PROS.PRCo=SO_L1Hol_PREC.PRCo 
	AND PROS.Lvl1HolEarnCode=SO_L1Hol_PREC.EarnCode 
LEFT OUTER JOIN PREC SO_L2Mon_PREC 
	ON PROS.PRCo=SO_L2Mon_PREC.PRCo 
	AND PROS.Lvl2MonEarnCode=SO_L2Mon_PREC.EarnCode 
LEFT OUTER JOIN PREC SO_L3Mon_PREC 
	ON PROS.PRCo=SO_L3Mon_PREC.PRCo 
	AND PROS.Lvl3MonEarnCode=SO_L3Mon_PREC.EarnCode 
LEFT OUTER JOIN PREC SO_L2Tue_PREC 
	ON PROS.PRCo=SO_L2Tue_PREC.PRCo 
	AND PROS.Lvl2TuesEarnCode=SO_L2Tue_PREC.EarnCode 
LEFT OUTER JOIN PREC SO_L3Tue_PREC 
	ON PROS.PRCo=SO_L3Tue_PREC.PRCo 
	AND PROS.Lvl3TuesEarnCode=SO_L3Tue_PREC.EarnCode 
LEFT OUTER JOIN PREC SO_L2Wed_PREC 
	ON PROS.PRCo=SO_L2Wed_PREC.PRCo 
	AND PROS.Lvl2WedEarnCode=SO_L2Wed_PREC.EarnCode 
LEFT OUTER JOIN PREC SO_L3Wed_PREC 
	ON PROS.PRCo=SO_L3Wed_PREC.PRCo 
	AND PROS.Lvl3WedEarnCode=SO_L3Wed_PREC.EarnCode 
LEFT OUTER JOIN PREC SO_L2Thu_PREC 
	ON PROS.PRCo=SO_L2Thu_PREC.PRCo 
	AND PROS.Lvl2ThursEarnCode=SO_L2Thu_PREC.EarnCode 
LEFT OUTER JOIN PREC SO_L3Thu_PREC 
	ON PROS.PRCo=SO_L3Thu_PREC.PRCo 
	AND PROS.Lvl3ThursEarnCode=SO_L3Thu_PREC.EarnCode 
LEFT OUTER JOIN PREC SO_L2Fri_PREC 
	ON PROS.PRCo=SO_L2Fri_PREC.PRCo 
	AND PROS.Lvl2FriEarnCode=SO_L2Fri_PREC.EarnCode 
LEFT OUTER JOIN PREC SO_L3Fri_PREC 
	ON PROS.PRCo=SO_L3Fri_PREC.PRCo 
	AND PROS.Lvl3FriEarnCode=SO_L3Fri_PREC.EarnCode 
LEFT OUTER JOIN PREC SO_L2Sat_PREC 
	ON PROS.PRCo=SO_L2Sat_PREC.PRCo 
	AND PROS.Lvl2SatEarnCode=SO_L2Sat_PREC.EarnCode 
LEFT OUTER JOIN PREC SO_L3Sat_PREC 
	ON PROS.PRCo=SO_L3Sat_PREC.PRCo 
	AND PROS.Lvl3SatEarnCode=SO_L3Sat_PREC.EarnCode 
LEFT OUTER JOIN PREC SO_L2Sun_PREC 
	ON PROS.PRCo=SO_L2Sun_PREC.PRCo 
	AND PROS.Lvl2SunEarnCode=SO_L2Sun_PREC.EarnCode 
LEFT OUTER JOIN PREC SO_L3Sun_PREC 
	ON PROS.PRCo=SO_L3Sun_PREC.PRCo 
	AND PROS.Lvl3SunEarnCode=SO_L3Sun_PREC.EarnCode 
LEFT OUTER JOIN PREC SO_L2Hol_PREC 
	ON PROS.PRCo=SO_L2Hol_PREC.PRCo 
	AND PROS.Lvl2HolEarnCode=SO_L2Hol_PREC.EarnCode 
LEFT OUTER JOIN PREC SO_L3Hol_PREC 
	ON PROS.PRCo=SO_L3Hol_PREC.PRCo 
	AND PROS.Lvl3HolEarnCode=SO_L3Hol_PREC.EarnCode
--WHERE  PROT.PRCo=1 AND PROS.OTSched=1
--ORDER BY PROS.PRCo, PROS.OTSched, PROS.Shift


GO
GRANT SELECT ON  [dbo].[vrvPROSSSchedules] TO [public]
GRANT INSERT ON  [dbo].[vrvPROSSSchedules] TO [public]
GRANT DELETE ON  [dbo].[vrvPROSSSchedules] TO [public]
GRANT UPDATE ON  [dbo].[vrvPROSSSchedules] TO [public]
GO
