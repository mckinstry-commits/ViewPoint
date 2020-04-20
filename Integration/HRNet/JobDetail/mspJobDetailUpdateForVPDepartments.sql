USE HRNET
go

alter PROCEDURE mspJobDetailUpdateForVPDepartments
(
	@DoUpdate INT = 0
,	@EffectiveDate DATETIME
,	@ReasonForChange	VARCHAR(50)
,	@Note	VARCHAR(255)	
,	@EmpNumber NVARCHAR(10) = null
)
AS
DECLARE empcur CURSOR for
SELECT
	company.COMPANYREFNO
--,	company.COMPANY
,	people.REFERENCENUMBER
,	people.FULLNAME
--,	people.STATUS
,	org2.CODE
,	REPLACE(LEFT(org2.CODE,CHARINDEX('.',org2.CODE)),'.','') AS DepartmentNumber
--,	org2.NAME
--,	jobdetail.CURRENTRECORD
,	jobdetail.JOBDETAIL_ID
,	jobdetail.JOBTITLE
FROM 
	dbo.PEOPLE people LEFT OUTER JOIN
	dbo.JOBDETAIL jobdetail ON
		jobdetail.PEOPLE_ID = people.PEOPLE_ID LEFT OUTER JOIN
	dbo.ORGLEVEL2 org2 ON
		jobdetail.ORGLEVEL2=org2.ORGLEVEL2_ID LEFT OUTER JOIN
	dbo.COMPANY company ON
		jobdetail.COMPANY=company.COMPANY_ID
WHERE 
	people.STATUS='A'
AND jobdetail.TOPJOB='T'
AND jobdetail.CURRENTRECORD='YES'
AND 
	(
		CAST(people.REFERENCENUMBER AS INT) <= 999999
	AND ( people.REFERENCENUMBER=@EmpNumber OR @EmpNumber IS NULL )
	)
ORDER BY 
	org2.CODE
,	company.COMPANYREFNO
,	people.REFERENCENUMBER
FOR READ ONLY

DECLARE @rcnt INT

DECLARE @COMPANYREFNO VARCHAR(20)
DECLARE @REFERENCENUMBER  VARCHAR(10)
DECLARE @FULLNAME VARCHAR(61)
DECLARE @CODE VARCHAR(20)
DECLARE @DepartmentNumber VARCHAR(10)
DECLARE @JOBDETAIL_ID UNIQUEIDENTIFIER

DECLARE @NewDepartmentNumber VARCHAR(10)
DECLARE @NewCODE VARCHAR(20)
DECLARE @NewOrg2Id UNIQUEIDENTIFIER

DECLARE @PositionId UNIQUEIDENTIFIER
DECLARE @NewPositionId UNIQUEIDENTIFIER

DECLARE @PositionName NVARCHAR(60)
DECLARE @NewPositionName NVARCHAR(60)

SELECT @rcnt=0

PRINT
		CAST('Count' AS CHAR(10))
	+	CAST('Company'  AS CHAR(10))
	+	CAST('EmpId'  AS CHAR(10))  
	+	CAST('Name' AS CHAR(65))
	+	CAST('Org2Code' AS CHAR(10)) 
	+	CAST('Old->New Dept'	AS CHAR(20))
	+	CAST('NOrg2Code' AS CHAR(10)) 
	--+	CAST(COALESCE(@NewOrg2Id,'<null>') AS CHAR(64)) 
	--+	CAST('OldPosition' AS CHAR(60)) 
	--+	CAST('NewPosition' AS CHAR(60)) 
	
OPEN empcur
FETCH empcur INTO
	@COMPANYREFNO 
,	@REFERENCENUMBER  
,	@FULLNAME 
,	@CODE 
,	@DepartmentNumber 
,	@JOBDETAIL_ID
,	@PositionId

WHILE @@fetch_status=0
BEGIN
	SELECT @rcnt=@rcnt+1
	
	SELECT 
		@NewDepartmentNumber=COALESCE(VPGLDeptNumber,'<null>')
	FROM 
		[MCKTESTSQL04\VIEWPOINT].Viewpoint.dbo.budxrefGLDept
	WHERE 
		CAST(CGCCompany AS TINYINT)=CAST(@COMPANYREFNO AS TINYINT)
	AND CAST(CGCGLDeptNumber AS INT)=CAST(@DepartmentNumber AS INT)

	SELECT 
		@NewCODE=COALESCE(CODE,'<null>')
	,	@NewOrg2Id=ORGLEVEL2_ID
	FROM 
		dbo.ORGLEVEL2
	WHERE
		CODE=REPLACE(@CODE,@DepartmentNumber + '.',@NewDepartmentNumber+'.')
	
		
	PRINT
		CAST(@rcnt AS CHAR(10))
	+	CAST(COALESCE(@COMPANYREFNO,'<null>')  AS CHAR(10))
	+	CAST(COALESCE(@REFERENCENUMBER,'<null>')  AS CHAR(10))  
	+	CAST(COALESCE(@FULLNAME,'<null>') AS CHAR(65))
	+	CAST(COALESCE(@CODE,'<null>') AS CHAR(10)) 
	+	CAST(CAST(COALESCE(@DepartmentNumber,'<null>') AS VARCHAR(10)) 
	+	' ---> ' + COALESCE(@NewDepartmentNumber,'<null>')	AS CHAR(20))
	+	CAST(COALESCE(@NewCODE,'<null>') AS CHAR(10)) 
	--+	CAST(COALESCE(@NewOrg2Id,'<null>') AS CHAR(64) 

	IF @DoUpdate=1
	BEGIN
	
	BEGIN TRAN 
	-- Deactivate Old Job Detail Record
	UPDATE dbo.JOBDETAIL SET  TOPJOB='F', DATELASTMODIFIED=GETDATE(), LASTMODIFIEDBY='VPCONV', ENDDATE=DATEADD(second,-1,@EffectiveDate)
	WHERE JOBDETAIL_ID=@JOBDETAIL_ID
	
	-- Add new Job Detail Record
	INSERT dbo.JOBDETAIL
	        ( JOBDETAIL_ID ,
	          DATECREATED ,
	          DATELASTMODIFIED ,
	          CREATEDBY ,
	          LASTMODIFIEDBY ,
	          EFFECTIVEDATE ,
	          PERSONALJOBTITLE ,
	          PERCENTALLOCATION ,
	          ENDDATE ,
	          JOBTITLE ,
	          PEOPLE_ID ,
	          NOTES ,
	          COVERINGPOSITION ,
	          WORKINGHOURS ,
	          LOCATION ,
	          REASONFORCHANGE ,
	          LASTSALARYINJOB ,
	          ORGLEVEL1 ,
	          ORGLEVEL2 ,
	          ORGLEVEL3 ,
	          ORGLEVEL4 ,
	          DATEOFNEWORGLEVEL ,
	          DATEOFNEWORGLEVEL3 ,
	          CLOSEPREVIOUSJOB ,
	          DATEOFNEWORGLEVEL4 ,
	          POSTHOURS ,
	          CURRENTSALARY ,
	          APPOINTEETYPE ,
	          CONTRACTTYPE ,
	          FULLPARTTIME ,
	          TOPJOB ,
	          COMPANY ,
	          ACTUALSALARY ,
	          LASTJOB ,
	          EXEMPTSTATUS ,
	          COSTCODE ,
	          REGION ,
	          COPYTONEWRECORD ,
	          TOTALHOURS ,
	          FMSPROJECTHIRE ,
	          INCENTIVEPLANPOTENTIAL ,
	          GRADE
	        )
	select  NEWID() , -- JOBDETAIL_ID - uniqueidentifier
	        GETDATE() , -- DATECREATED - datetime
	        GETDATE() , -- DATELASTMODIFIED - datetime
	          N'VPCONV' , -- CREATEDBY - nvarchar(20)
	          N'VPCONV' , -- LASTMODIFIEDBY - nvarchar(20)
	          @EffectiveDate , -- EFFECTIVEDATE - datetime
	          PERSONALJOBTITLE , -- PERSONALJOBTITLE - nvarchar(250)
	          PERCENTALLOCATION , -- PERCENTALLOCATION - decimal
	          null , -- ENDDATE - datetime
	          JOBTITLE , -- JOBTITLE - uniqueidentifier ( Position reference to POST table)
	          PEOPLE_ID , -- PEOPLE_ID - uniqueidentifier
	          @Note , -- NOTES - nvarchar(1000)
	          COVERINGPOSITION , -- COVERINGPOSITION - nchar(1)
	          WORKINGHOURS , -- WORKINGHOURS - decimal
	          LOCATION , -- LOCATION - uniqueidentifier
	          @ReasonForChange , -- REASONFORCHANGE - nvarchar(50)
	          LASTSALARYINJOB , -- LASTSALARYINJOB - decimal
	          ORGLEVEL1 , -- ORGLEVEL1 - uniqueidentifier
	          @NewOrg2Id , -- ORGLEVEL2 - uniqueidentifier
	          ORGLEVEL3 , -- ORGLEVEL3 - uniqueidentifier
	          ORGLEVEL4 , -- ORGLEVEL4 - uniqueidentifier
	          @EffectiveDate , -- DATEOFNEWORGLEVEL - datetime
	          @EffectiveDate , -- DATEOFNEWORGLEVEL3 - datetime
	          CLOSEPREVIOUSJOB , -- CLOSEPREVIOUSJOB - nchar(1)
	          @EffectiveDate , -- DATEOFNEWORGLEVEL4 - datetime
	          POSTHOURS , -- POSTHOURS - decimal
	          CURRENTSALARY , -- CURRENTSALARY - decimal
	          APPOINTEETYPE , -- APPOINTEETYPE - nvarchar(50)
	          CONTRACTTYPE , -- CONTRACTTYPE - nvarchar(50)
	          FULLPARTTIME , -- FULLPARTTIME - nvarchar(50)
	          'T' , -- TOPJOB - nchar(1)
	          COMPANY , -- COMPANY - uniqueidentifier
	          ACTUALSALARY , -- ACTUALSALARY - decimal
	          LASTJOB , -- LASTJOB - nvarchar(20)
	          EXEMPTSTATUS , -- EXEMPTSTATUS - nvarchar(50)
	          COSTCODE , -- COSTCODE - nvarchar(50)
	          REGION , -- REGION - nvarchar(50)
	          COPYTONEWRECORD , -- COPYTONEWRECORD - nchar(1)
	          TOTALHOURS, -- TOTALHOURS - nvarchar(20)
	          FMSPROJECTHIRE , -- FMSPROJECTHIRE - nvarchar(50)
	          INCENTIVEPLANPOTENTIAL , -- INCENTIVEPLANPOTENTIAL - decimal
	          GRADE  -- GRADE - nvarchar(5)
	    FROM dbo.JOBDETAIL
	    WHERE JOBDETAIL_ID=@JOBDETAIL_ID	
	
		COMMIT TRAN
	END

SELECT
	@COMPANYREFNO = null
,	@REFERENCENUMBER = null
,	@FULLNAME = null
,	@CODE = null
,	@DepartmentNumber = null
,	@NewDepartmentNumber = null
,	@NewCODE = null
,	@NewOrg2Id = null

	FETCH empcur INTO
		@COMPANYREFNO 
	,	@REFERENCENUMBER  
	,	@FULLNAME 
	,	@CODE 
	,	@DepartmentNumber 
	,	@JOBDETAIL_ID
	,	@PositionId

END

CLOSE empcur
DEALLOCATE empcur

go

--EXEC mspJobDetailUpdateForVPDepartments @DoUpdate=1, @EmpNumber=null, @EffectiveDate='10/27/2014',@ReasonForChange='Org Structure Change', @Note='Dept Change for VP Conversion'
--EXEC mspJobDetailUpdateForVPDepartments @DoUpdate=1, @EmpNumber=39835, @EffectiveDate='10/27/2014',@ReasonForChange='Org Structure Change', @Note='Dept Change for VP Conversion'


--SELECT PEOPLE_ID FROM dbo.PEOPLE WHERE REFERENCENUMBER='68221'

--SELECT
--	McKCurrent = (case when getdate()>=[EFFECTIVEDATE] AND getdate()<=isnull([ENDDATE],getdate()) then 'YES' else 'NO' END)
--,	[Current] = (case when [TOPJOB]='T' then 'YES' else case when getdate()>=[EFFECTIVEDATE] AND getdate()<=isnull([ENDDATE],getdate()) then 'YES' else 'NO' end end)
--,	TOPJOB
--,	CURRENTRECORD
--,	EFFECTIVEDATE
--,	[ENDDATE]
--,	*
--FROM dbo.JOBDETAIL WHERE PEOPLE_ID='290973FA-8801-4BCD-8A44-7849A8A4A0C8'


BEGIN tran
DELETE FROM dbo.JOBDETAIL WHERE CREATEDBY='VPCONV' AND DATECREATED >= '9/22/2014'
UPDATE dbo.JOBDETAIL SET TOPJOB='T' WHERE LASTMODIFIEDBY='VPCONV' AND DATELASTMODIFIED >='9/22/2014' AND TOPJOB<>'T'
COMMIT TRAN


SELECT * FROM dbo.JOBDETAIL WHERE LASTMODIFIEDBY='VPCONV'
