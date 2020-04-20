/*

1. Update records to mnepto.AccrualSettings for new Viewpoint processing rules (Change 38 & 66 to 503 & 206). [2014.11.07 LWO DONE : 11:24AM]

2. Create and populate Mapping Table for CGC/Viewpoint Translation [2014.11.07 LWO DONE : 11:24AM]
		--CREATE TABLE mnepto.EarnCodeMap(
		--	PRCo		INT			NOT null
		--,	EarnCode	INT			NOT NULL
		--,	DESCRIPTION VARCHAR(30) NOT NULL
		--,	ShortCode	CHAR(2)		NOT null
		--)

		--INSERT mnepto.EarnCodeMap
		--SELECT DISTINCT PRCo, EarnCode,Description, cast('xx' as char(2)) as ShortCode  FROM [MCKTESTSQL04\VIEWPOINT].ViewpointPayroll2.dbo.PREC WHERE EarnType IN (6,7)

3.  Recreate and populate mnepto.AccrualSettings, mnepto.TimeCardHistory & mnepto.TimeCardManualEntries so GroupID is varchar(10) [2014.11.07 LWO DONE : 11:24AM]
4.  Update existing GroupID values in History, Manual Entries and Summary to reflect new codes. [2014.11.07 LWO DONE : 11:24AM]
5.  Recompile two procedures [mnepto].[mspRecalculateAccruals] & [mnepto].[mspSyncPersonnel]
6.  Regrant permissions on all views, functions and procedures. [2014.11.07 LWO DONE : 11:24AM]
7.  Run [mnepto].[mspRecalculateAccruals] for 503 & 206 [2014.11.07 LWO DONE : 11:24AM]

*/


--CREATE TABLE mnepto.EarnCodeMap(
--			PRCo		INT			NOT null
--		,	EarnCode	INT			NOT NULL
--		,	DESCRIPTION VARCHAR(30) NOT NULL
--		,	ShortCode	CHAR(2)		NOT null
--		)

--		INSERT mnepto.EarnCodeMap
--		SELECT *  FROM [DEV-HRISSQL02].HRNET.mnepto.EarnCodeMap
		
