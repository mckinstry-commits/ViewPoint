SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:	  Mike Brewer

-- =============================================
CREATE VIEW [dbo].[vrvPROTSchedules]
--	
as

SELECT 
HQCO.HQCo, 
HQCO.Name, 
PROT.PRCo, 
PROT.OTSched, 
PROT.Description,
-------------------------------------------------------
PROT.MonHrs, 
PROT.TuesHrs, 
PROT.WedHrs, 
PROT.ThursHrs, 
PROT.FriHrs, 
PROT.SatHrs, 
PROT.SunHrs, 
PROT.HolHrs, 
-------------------------------------------------------
PROT.Lvl2MonHrs, 
PROT.Lvl2TuesHrs, 
PROT.Lvl2WedHrs, 
PROT.Lvl2ThursHrs, 
PROT.Lvl2FriHrs, 
PROT.Lvl2SatHrs, 
PROT.Lvl2SunHrs, 
PROT.Lvl2HolHrs, 
--------------------------------------------------------
PROT.Lvl3MonHrs, 
PROT.Lvl3TuesHrs, 
PROT.Lvl3WedHrs, 
PROT.Lvl3ThursHrs, 
PROT.Lvl3FriHrs, 
PROT.Lvl3SatHrs, 
PROT.Lvl3SunHrs, 
PROT.Lvl3HolHrs, 
-------------------------------------------------------------

case isnull(PROT.MonEarnCode,0) when 0 then '' else
cast(PROT.MonEarnCode as varchar) + '  ' +  L1Mon_PREC.Description end as 'L1MonEC',

case isnull(PROT.TuesEarnCode,0) when 0 then '' else
cast(PROT.TuesEarnCode as varchar) + '  ' +  L1Tue_PREC.Description end as 'L1TueEC',

case isnull(PROT.WedEarnCode,0) when 0 then '' else
cast(PROT.WedEarnCode as varchar) + '  ' +  L1Wed_PREC.Description end as 'L1WedEC',

case isnull(PROT.ThursEarnCode,0) when 0 then '' else
cast(PROT.ThursEarnCode as varchar) + '  ' +  L1Thu_PREC.Description end as 'L1ThuEC', 

case isnull(PROT.FriEarnCode,0) when 0 then '' else
cast(PROT.FriEarnCode as varchar) + '  ' +  L1Fri_PREC.Description end as 'L1FriEC', 

case isnull(PROT.SatEarnCode,0) when 0 then '' else
cast(PROT.SatEarnCode as varchar) + '  ' +  L1Sat_PREC.Description end as 'L1SatEC', 

case isnull(PROT.SunEarnCode,0) when 0 then '' else
cast(PROT.SunEarnCode as varchar) + '  ' +  L1Sun_PREC.Description end as 'L1SunEC', 

case isnull(PROT.HolEarnCode,0) when 0 then '' else
cast(PROT.HolEarnCode as varchar) + '  ' +  L1Hol_PREC.Description end as 'L1HolEC', 

-----------------------------------------------------------------------------------------

case isnull(PROT.Lvl2MonEarnCode,0) when 0 then '' else
cast(PROT.Lvl2MonEarnCode as varchar) + '  ' +  L2Mon_PREC.Description end as 'L2MonEC',  

case isnull(PROT.Lvl2TuesEarnCode,0) when 0 then '' else
cast(PROT.Lvl2TuesEarnCode as varchar) + '  ' +  L2Tue_PREC.Description end as 'L2TueEC',  

case isnull(PROT.Lvl2WedEarnCode,0) when 0 then '' else
cast(PROT.Lvl2WedEarnCode as varchar) + '  ' +  L2Wed_PREC.Description end as 'L2WedEC',

case isnull(PROT.Lvl2ThursEarnCode,0) when 0 then '' else
cast(PROT.Lvl2ThursEarnCode as varchar) + '  ' +  L2Thu_PREC.Description end as 'L2ThuEC',

case isnull(PROT.Lvl2FriEarnCode,0) when 0 then '' else
cast(PROT.Lvl2FriEarnCode as varchar) + '  ' +  L2Fri_PREC.Description end as 'L2FriEC',

case isnull(PROT.Lvl2SatEarnCode,0) when 0 then '' else
cast(PROT.Lvl2SatEarnCode as varchar) + '  ' +  L2Sat_PREC.Description end as 'L2SatEC',

case isnull(PROT.Lvl2SunEarnCode,0) when 0 then '' else
cast(PROT.Lvl2SunEarnCode as varchar) + '  ' +  L2Sun_PREC.Description end as 'L2SunEC',

case isnull(PROT.Lvl2HolEarnCode,0) when 0 then '' else
cast(PROT.Lvl2HolEarnCode as varchar) + '  ' +  L2Hol_PREC.Description end as 'L2HolEC',

----------------------------------------------------------------------------------------

case isnull(PROT.Lvl3MonEarnCode,0) when 0 then '' else
cast(PROT.Lvl3MonEarnCode as varchar) + '  ' +  L3Mon_PREC.Description end as 'L3MonEC',

case isnull(PROT.Lvl3TuesEarnCode,0) when 0 then '' else
cast(PROT.Lvl3TuesEarnCode as varchar) + '  ' +  L3Tue_PREC.Description end as 'L3TueEC',

case isnull(PROT.Lvl3WedEarnCode,0) when 0 then '' else
cast(PROT.Lvl3WedEarnCode as varchar) + '  ' +  L3Wed_PREC.Description end as 'L3WedEC',

case isnull(PROT.Lvl3ThursEarnCode,0) when 0 then '' else
cast(PROT.Lvl3ThursEarnCode as varchar) + '  ' +  L3Thu_PREC.Description end as 'L3ThuEC',

case isnull(PROT.Lvl3FriEarnCode,0) when 0 then '' else
cast(PROT.Lvl3FriEarnCode as varchar) + '  ' +  L3Fri_PREC.Description end as 'L3FriEC',

case isnull(PROT.Lvl3SatEarnCode,0) when 0 then '' else
cast(PROT.Lvl3SatEarnCode as varchar) + '  ' +  L3Sat_PREC.Description end as 'L3SatEC',

case isnull(PROT.Lvl3SunEarnCode,0) when 0 then '' else
cast(PROT.Lvl3SunEarnCode as varchar) + '  ' +  L3Sun_PREC.Description end as 'L3SunEC',

case isnull(PROT.Lvl3HolEarnCode,0) when 0 then '' else
cast(PROT.Lvl3HolEarnCode as varchar) + '  ' +  L3Hol_PREC.Description end as 'L3HolEC',

-------------------------------------------------------------------------

PROT.Notes
FROM   PROT PROT 
LEFT OUTER JOIN PROS PROS 
	ON PROT.PRCo=PROS.PRCo 
	AND PROT.OTSched=PROS.OTSched 
LEFT OUTER JOIN HQCO HQCO 
	ON PROT.PRCo=HQCO.HQCo 
LEFT OUTER JOIN PREC L1Mon_PREC 
	ON PROT.MonEarnCode=L1Mon_PREC.EarnCode 
	AND PROT.PRCo=L1Mon_PREC.PRCo 
LEFT OUTER JOIN PREC L1Tue_PREC 
	ON PROT.PRCo=L1Tue_PREC.PRCo 
	AND PROT.TuesEarnCode=L1Tue_PREC.EarnCode 
LEFT OUTER JOIN PREC L1Wed_PREC 
	ON PROT.PRCo=L1Wed_PREC.PRCo 
	AND PROT.WedEarnCode=L1Wed_PREC.EarnCode 
LEFT OUTER JOIN PREC L1Thu_PREC 
	ON PROT.PRCo=L1Thu_PREC.PRCo 
	AND PROT.ThursEarnCode=L1Thu_PREC.EarnCode 
LEFT OUTER JOIN PREC L1Fri_PREC 
	ON PROT.PRCo=L1Fri_PREC.PRCo 
	AND PROT.FriEarnCode=L1Fri_PREC.EarnCode 
LEFT OUTER JOIN PREC L1Sat_PREC 
	ON PROT.PRCo=L1Sat_PREC.PRCo 
	AND PROT.SatEarnCode=L1Sat_PREC.EarnCode 
LEFT OUTER JOIN PREC L1Sun_PREC 
	ON PROT.PRCo=L1Sun_PREC.PRCo 
	AND PROT.SunEarnCode=L1Sun_PREC.EarnCode 
LEFT OUTER JOIN PREC L1Hol_PREC 
	ON PROT.PRCo=L1Hol_PREC.PRCo 
	AND PROT.HolEarnCode=L1Hol_PREC.EarnCode 
LEFT OUTER JOIN PREC L2Mon_PREC 
	ON PROT.PRCo=L2Mon_PREC.PRCo 
	AND PROT.Lvl2MonEarnCode=L2Mon_PREC.EarnCode 
LEFT OUTER JOIN PREC L2Tue_PREC 
	ON PROT.PRCo=L2Tue_PREC.PRCo 
	AND PROT.Lvl2TuesEarnCode=L2Tue_PREC.EarnCode 
LEFT OUTER JOIN PREC L2Wed_PREC 
	ON PROT.PRCo=L2Wed_PREC.PRCo 
	AND PROT.Lvl2WedEarnCode=L2Wed_PREC.EarnCode 
LEFT OUTER JOIN PREC L2Thu_PREC 
	ON PROT.PRCo=L2Thu_PREC.PRCo 
	AND PROT.Lvl2ThursEarnCode=L2Thu_PREC.EarnCode 
LEFT OUTER JOIN PREC L2Fri_PREC 
	ON PROT.PRCo=L2Fri_PREC.PRCo 
	AND PROT.Lvl2FriEarnCode=L2Fri_PREC.EarnCode 
LEFT OUTER JOIN PREC L2Sat_PREC 
	ON PROT.PRCo=L2Sat_PREC.PRCo 
	AND PROT.Lvl2SatEarnCode=L2Sat_PREC.EarnCode 
LEFT OUTER JOIN PREC L2Sun_PREC 
	ON PROT.PRCo=L2Sun_PREC.PRCo 
	AND PROT.Lvl2SunEarnCode=L2Sun_PREC.EarnCode 
LEFT OUTER JOIN PREC L2Hol_PREC 
	ON PROT.PRCo=L2Hol_PREC.PRCo 
	AND PROT.Lvl2HolEarnCode=L2Hol_PREC.EarnCode 
LEFT OUTER JOIN PREC L3Mon_PREC 
	ON PROT.PRCo=L3Mon_PREC.PRCo 
	AND PROT.Lvl3MonEarnCode=L3Mon_PREC.EarnCode 
LEFT OUTER JOIN PREC L3Tue_PREC 
	ON PROT.PRCo=L3Tue_PREC.PRCo 
	AND PROT.Lvl3TuesEarnCode=L3Tue_PREC.EarnCode 
LEFT OUTER JOIN PREC L3Wed_PREC 
	ON PROT.PRCo=L3Wed_PREC.PRCo 
	AND PROT.Lvl3WedEarnCode=L3Wed_PREC.EarnCode 
LEFT OUTER JOIN PREC L3Thu_PREC 
	ON PROT.PRCo=L3Thu_PREC.PRCo 
	AND PROT.Lvl3ThursEarnCode=L3Thu_PREC.EarnCode 
LEFT OUTER JOIN PREC L3Fri_PREC 
	ON PROT.PRCo=L3Fri_PREC.PRCo 
	AND PROT.Lvl3FriEarnCode=L3Fri_PREC.EarnCode 
LEFT OUTER JOIN PREC L3Sat_PREC 
	ON PROT.PRCo=L3Sat_PREC.PRCo 
	AND PROT.Lvl3SatEarnCode=L3Sat_PREC.EarnCode 
LEFT OUTER JOIN PREC L3Sun_PREC 
	ON PROT.PRCo=L3Sun_PREC.PRCo 
	AND PROT.Lvl3SunEarnCode=L3Sun_PREC.EarnCode 
LEFT OUTER JOIN PREC L3Hol_PREC 
	ON PROT.PRCo=L3Hol_PREC.PRCo 
	AND PROT.Lvl3HolEarnCode=L3Hol_PREC.EarnCode
--WHERE PROT.OTSched>=@BegOTSched 
--AND PROT.OTSched<=@EndOTSched 
--AND PROT.PRCo=@JCCo
--ORDER BY PROT.PRCo, PROT.OTSched

GO
GRANT SELECT ON  [dbo].[vrvPROTSchedules] TO [public]
GRANT INSERT ON  [dbo].[vrvPROTSchedules] TO [public]
GRANT DELETE ON  [dbo].[vrvPROTSchedules] TO [public]
GRANT UPDATE ON  [dbo].[vrvPROTSchedules] TO [public]
GRANT SELECT ON  [dbo].[vrvPROTSchedules] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPROTSchedules] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPROTSchedules] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPROTSchedules] TO [Viewpoint]
GO
