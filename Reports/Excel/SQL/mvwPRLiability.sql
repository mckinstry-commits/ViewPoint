IF OBJECT_ID ('dbo.mvwPRLiability', 'view') IS NOT NULL
DROP VIEW dbo.mvwPRLiability;
GO

CREATE VIEW dbo.mvwPRLiability
AS 
	SELECT "HQCO"."Name" AS [CompanyName], "brvPRInsJob"."PRCo", "PRDL"."DLType", "PRDL"."Description" AS [DLDescription], "PREH"."FirstName", "PREH"."LastName", "HQIC"."Description" AS [InsDescription], "JCJM"."Description" AS [JobDescription], "brvPRInsJob"."InsState", "brvPRInsJob"."InsCode", "brvPRInsJob"."LiabCode", "brvPRInsJob"."Employee", "brvPRInsJob"."LiabAmt", "brvPRInsJob"."PREndDate", "brvPRInsJob"."Job", "brvPRInsJob"."Phase", "brvPRInsJob"."Rate", "brvPRInsJob"."TimeCardEarn", "brvPRInsJob"."AddonEarn", "brvPRInsJob"."STE", "brvPRInsJob"."JCCo", "HQCO_Job"."Name" AS [JCCo Name], "JCJP"."Description", "PRDL"."Method", "brvPRInsJob"."Hours", "brvPRInsJob"."VarSTE"
	FROM   {oj ((((((("Viewpoint"."dbo"."mvwPRInsJob" "brvPRInsJob"
		INNER JOIN "Viewpoint"."dbo"."PRGR" "PRGR" ON "brvPRInsJob"."PRCo" = "PRGR"."PRCo" AND "brvPRInsJob"."PRGroup" = "PRGR"."PRGroup" AND "PRGR"."Description" = 'Union')
		INNER JOIN "Viewpoint"."dbo"."HQCO" "HQCO" ON "brvPRInsJob"."PRCo"="HQCO"."HQCo") 
		LEFT OUTER JOIN "Viewpoint"."dbo"."bPREH" "PREH" ON ("brvPRInsJob"."PRCo"="PREH"."PRCo") AND ("brvPRInsJob"."Employee"="PREH"."Employee")) 
		LEFT OUTER JOIN "Viewpoint"."dbo"."PRDL" "PRDL" ON ("brvPRInsJob"."PRCo"="PRDL"."PRCo") AND ("brvPRInsJob"."LiabCode"="PRDL"."DLCode")) 
		LEFT OUTER JOIN "Viewpoint"."dbo"."HQIC" "HQIC" ON "brvPRInsJob"."InsCode"="HQIC"."InsCode") 
		INNER JOIN "Viewpoint"."dbo"."JCJM" "JCJM" ON ("brvPRInsJob"."JCCo"="JCJM"."JCCo") AND ("brvPRInsJob"."Job"="JCJM"."Job")) 
		INNER JOIN "Viewpoint"."dbo"."HQCO" "HQCO_Job" ON "brvPRInsJob"."JCCo"="HQCO_Job"."HQCo") 
		LEFT OUTER JOIN "Viewpoint"."dbo"."JCJP" "JCJP" ON ((("brvPRInsJob"."JCCo"="JCJP"."JCCo") AND ("brvPRInsJob"."Job"="JCJP"."Job")) AND ("brvPRInsJob"."PhaseGroup"="JCJP"."PhaseGroup")) AND ("brvPRInsJob"."Phase"="JCJP"."Phase")}
	--ORDER BY "brvPRInsJob"."PRCo", "brvPRInsJob"."JCCo", "brvPRInsJob"."Job", "brvPRInsJob"."InsState", "brvPRInsJob"."InsCode", "brvPRInsJob"."LiabCode", "brvPRInsJob"."Employee", "brvPRInsJob"."Phase"
GO

GRANT SELECT ON dbo.mvwPRLiability TO [public]
GO