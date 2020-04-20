
USE Viewpoint
GO

CREATE USER [MCKINSTRY\Viewpoint PM Training Users] FOR LOGIN [MCKINSTRY\Viewpoint PM Training Users]

/* --ADD USERS FROM DOMAIN GROUP*/
EXEC dbo.mckspAddADUsers @Group = 'Viewpoint PM Training Users', -- varchar(30)
    @DefCompany = 1, -- tinyint
    @ReturnMessage = '' -- varchar(max)
	
	UPDATE u
	SET FullName = REPLACE(u.VPUserName, 'MCKINSTRY\','')
	FROM dbo.DDUP u 
	WHERE VPUserName LIKE '%VPPMTRAIN%'

	--CREATE REVIEWER RECORDS
INSERT INTO dbo.HQRV
        ( Reviewer ,
          Name ,
         -- UniqueAttchID ,
          RevEmail
        )
SELECT RIGHT(VPUserName, 2), FullName, 'erptest@mckinstry.com'
FROM dbo.DDUP
WHERE VPUserName LIKE 'MCKINSTRY\VPPMTRAIN%'




	--WRITE REVIEWER BACK TO DDUP TO PREVENT DUPLICATION
UPDATE dbo.DDUP
SET udReviewer = RIGHT(VPUserName,2)
WHERE VPUserName LIKE 'MCKINSTRY\VPPMTRAIN%'	
/**/

UPDATE r
SET r.RevEmail = u.EMail
FROM HQRV r 
	JOIN DDUP u ON u.udReviewer=r.Reviewer
WHERE u.VPUserName LIKE '%VPPMTRAIN%'

	--ASSIGN REVIEWER ACCOUNTS
INSERT INTO dbo.HQRP
        ( Reviewer ,
          VPUserName 
		  --,          UniqueAttchID
        )
SELECT RIGHT(VPUserName, 2), VPUserName
FROM dbo.DDUP
WHERE VPUserName LIKE 'MCKINSTRY\VPPMTRAIN%'

/*--APPLY SECURITY ACCESS  DISABLE TRIGGERS TO PREVENT UNNECESSARY REVIEWER AND PM RECORDS.*/


--DISABLE TRIGGERS SHOULD NO LONGER BE NEEDED
--DISABLE TRIGGER dbo.mtrUpdateUserRecords2_IU
--ON dbo.vDDSU

DECLARE @Package VARCHAR(2) = 'PM'


			INSERT INTO dbo.DDSU
			    ( SecurityGroup, VPUserName )
			SELECT SecGroup, u.VPUserName
			FROM dbo.udVASecGrpPack p
				JOIN dbo.udVAScGrpPacMember pm ON pm.Package = p.Package
				--LEFT JOIN dbo.DDSU su ON su.VPUserName = u.VPUserName AND su.SecurityGroup=pm.SecGroup 
				CROSS JOIN (
					SELECT VPUserName FROM dbo.DDUP
					WHERE VPUserName LIKE 'MCKINSTRY\VPPMTRAIN%'
				) u
			WHERE pm.Package = @Package;
--DISABLE TRIGGERS SHOULD NO LONGER BE NEEDED
--ENABLE TRIGGER dbo.mtrUpdateUserRecords2_IU
--ON dbo.vDDSU;


/*
SELECT up.VPUserName, su.SecurityGroup
FROM dbo.DDUP up
	JOIN dbo.DDSU su ON su.VPUserName = up.VPUserName
	--RIGHT JOIN dbo.udVAScGrpPacMember pacsg ON pacsg.Package = 'PM' AND pacsg.SecGroup = su.SecurityGroup
WHERE up.VPUserName LIKE 'MCKINSTRY\VPPMTRAIN%'
GROUP BY up.VPUserName
HAVING COUNT(*) <> 3

*/

--ADD DATA SECURITY ACCESS
--NO LONGER NEEDED, DATA ACCESS ADDED TO PACKAGES
/*
INSERT INTO dbo.DDSU (SecurityGroup,VPUserName)
SELECT 10101,VPUserName FROM dbo.DDUP
WHERE VPUserName LIKE 'MCKINSTRY\VPPMTRAIN%'

INSERT INTO dbo.DDSU (SecurityGroup,VPUserName)
SELECT 10000,VPUserName FROM dbo.DDUP
WHERE VPUserName LIKE 'MCKINSTRY\VPPMTRAIN%'
*/

--SELECT SecurityGroup, Description FROM dbo.DDSG
--WHERE SecurityGroup > 10000


--DELETE FROM dbo.DDSU
--WHERE VPUserName LIKE '%\VPPMTRAIN%'
--	AND SecurityGroup IN (10060, 10020, 10001, 200)


--REFORMAT USER COLUMN SETTINGS

--TRAINING SECURITY GROUP 
INSERT DDSU ( SecurityGroup, VPUserName )
SELECT 10101, VPUserName FROM DDUP WHERE (VPUserName LIKE '%VPPM%' 
	--AND VPUserName <> 'MCKINSTRY\VPPMTRAIN01'
	)
AND VPUserName NOT IN (SELECT DISTINCT VPUserName FROM DDSU WHERE SecurityGroup=10101)


USE [Viewpoint]
GO

DECLARE @RC int
DECLARE @username bVPUserName
DECLARE @ReturnValue int
DECLARE @ReturnMessage varchar(255)

-- TODO: Set parameter values here.

DECLARE UserCrsr CURSOR FOR 
SELECT VPUserName FROM dbo.DDUP
WHERE VPUserName LIKE '%VPPM%'

OPEN UserCrsr
FETCH NEXT FROM UserCrsr INTO @username

WHILE @@FETCH_STATUS = 0
BEGIN

	EXECUTE @RC = [dbo].[mckMasterLayoutPerUser] 
	   @username
	  ,@ReturnValue
	  ,@ReturnMessage OUTPUT
	

	FETCH NEXT FROM UserCrsr INTO @username
END
CLOSE UserCrsr	
DEALLOCATE UserCrsr


INSERT INTO dbo.JCJR
        ( JCCo ,
          Job ,
          Seq ,
          Reviewer ,
          ReviewerType
        )
SELECT JCJM.JCCo,JCJM.Job, 1, SUBSTRING(JCJM.Job,5,2),1 
FROM dbo.JCJM
	LEFT JOIN dbo.JCJR ON dbo.JCJR.JCCo = dbo.JCJM.JCCo AND dbo.JCJR.Job = dbo.JCJM.Job 
WHERE JCJM.Job > '100099' AND RIGHT(JCJM.Job,3)='002'
	AND JCJM.Job NOT LIKE '%[A-Za-z]%' AND JCJM.Job < '100171'
	AND JCJM.JCCo = 222 AND (JCJR.Reviewer <> SUBSTRING(JCJM.Job,5,2) OR JCJR.Reviewer IS NULL)
