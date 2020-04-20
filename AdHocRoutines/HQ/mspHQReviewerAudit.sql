/*
SELECT
	so.name
,	sc.name
FROM 
	sysobjects so JOIN
	syscolumns sc ON
		so.id=sc.id
	AND so.type='V'
	AND sc.name='Reviewer'
ORDER BY 
	so.name
*/


USE Viewpoint
go

IF EXISTS ( SELECT 1 FROM sysobjects WHERE type='P' AND name='mspHQReviewerAudit')
BEGIN
	PRINT 'DROP PROCEDURE mspHQReviewerAudit'
	DROP PROCEDURE mspHQReviewerAudit
END
go

PRINT 'CREATE PROCEDURE mspHQReviewerAudit'
go

CREATE PROCEDURE mspHQReviewerAudit
(
	@Reviewer	VARCHAR(10)	= NULL
,	@Verbose	INT			= 0
)
AS
/*
2014.12.09 - LWO - mspHQReviewerAudit Created

EXEC mspHQReviewerAudit @Reviewer=NULL, @Verbose=0
EXEC mspHQReviewerAudit @Reviewer=NULL, @Verbose=1
EXEC mspHQReviewerAudit @Reviewer='JA0', @Verbose=1

Routine to evaluate each HQRV record and see if the Reviewer is associated with an Employee (based on email match) and then if the Employee
is not active (as per PR records) determine where the Reviewer is used.

Object is to provide a summary of the places where updates need to be made and/or records reassigned when Employees leave the company.
List of dependencies was based on evaluating syscolumns for any tables/view that have a "Reviewer" field.

Can run for one or all Reviewers ( using @Reviewer parameter ) and can provide full details ( all entries regardless of Employee status ) 
or only entries for Reviewers needing attention (using @Verbose=1 for all or @Verbose=0 for actionable list)
*/

SET NOCOUNT ON

DECLARE revcur CURSOR for
SELECT 
	hqrv.Reviewer
,	hqrv.Name
,	hqrv.RevEmail
FROM 
	HQRV hqrv 
WHERE
	( hqrv.Reviewer=@Reviewer OR @Reviewer IS NULL )
ORDER BY
	hqrv.Reviewer
FOR READ ONLY

DECLARE @reviewer VARCHAR(10)
DECLARE @name VARCHAR(50)
DECLARE @email VARCHAR(50)
DECLARE @employeenumber INT

DECLARE @rcnt INT

DECLARE @inusecount INT
DECLARE @apurcount INT
DECLARE @jcjrcount INT

DECLARE @apvmcount INT
DECLARE @emdmcount INT
DECLARE @hqrdcount INT
DECLARE @hqrpcount INT
DECLARE @hrercount INT
DECLARE @pmnrcount INT
DECLARE @rqqrcount INT
DECLARE @rqrrcount INT

SELECT @rcnt=0

OPEN revcur
FETCH revcur INTO @reviewer,@name,@email

WHILE @@FETCH_STATUS=0
BEGIN

	IF @employeenumber IS NULL
		SELECT @employeenumber=u.Employee FROM DDUP u JOIN dbo.PREHFullName p ON u.PRCo=p.PRCo AND u.Employee=p.Employee and ( u.EMail=@email OR p.Email=@email )

	IF @employeenumber IS NULL
		SELECT @employeenumber=CAST(p.REFERENCENUMBER AS int) FROM SESQL08.HRNET.dbo.PEOPLE p WHERE p.EMAILPRIMARY=@email 
	
	SELECT @inusecount=0

	IF ( @employeenumber IS NULL )
	BEGIN
		
		SELECT @rcnt=@rcnt+1

		PRINT REPLICATE('-',150)
		PRINT 
			CAST(@rcnt AS CHAR(10))
		+	'Reviewer : ' 
		+	CAST(COALESCE(@reviewer,'Unknown') AS CHAR(10))
		+	CAST(COALESCE(@name,'Unknown') AS CHAR(50))
		+	COALESCE(CAST(@employeenumber AS CHAR(20)),CAST('Unknown' AS CHAR(20)))
		+	CAST(COALESCE(@email,'Unknown') AS CHAR(50))
		PRINT REPLICATE('-',150)

		PRINT 
				CAST('' AS CHAR(12))
			+	'- Reivewer can not be identified as an employee record based on email match : ' + COALESCE(CAST(@email AS VARCHAR(50)),'')
	END
	ELSE
	BEGIN 	

		IF EXISTS ( SELECT 1 from PREHFullName WHERE ActiveYN='Y' AND Employee=@employeenumber)
		BEGIN
			IF @Verbose <> 0
			BEGIN
            	SELECT @rcnt=@rcnt+1

				PRINT REPLICATE('-',150)
				PRINT 
					CAST(@rcnt AS CHAR(10))
				+	'Reviewer : ' 
				+	CAST(COALESCE(@reviewer,'Unknown') AS CHAR(10))
				+	CAST(COALESCE(@name,'Unknown') AS CHAR(50))
				+	COALESCE(CAST(@employeenumber AS CHAR(20)),CAST('Unknown' AS CHAR(20)))
				+	CAST(COALESCE(@email,'Unknown') AS CHAR(50))
				PRINT REPLICATE('-',150)

				PRINT 
					CAST('' AS CHAR(12))
				+	'+ Reivewer has active employee record based on email match : ' + COALESCE(CAST(@email AS VARCHAR(50)),'')
			end
		END
		ELSE
		BEGIN
			SELECT @rcnt=@rcnt+1

			PRINT REPLICATE('-',150)
			PRINT 
				CAST(@rcnt AS CHAR(10))
			+	'Reviewer : ' 
			+	CAST(COALESCE(@reviewer,'Unknown') AS CHAR(10))
			+	CAST(COALESCE(@name,'Unknown') AS CHAR(50))
			+	COALESCE(CAST(@employeenumber AS CHAR(20)),CAST('Unknown' AS CHAR(20)))
			+	CAST(COALESCE(@email,'Unknown') AS CHAR(50))
			PRINT REPLICATE('-',150)
		
			PRINT 
				CAST('' AS CHAR(12))
			+	'-*- Reivewer does not have an active employee record based on email match : ' + COALESCE(CAST(@email AS VARCHAR(50)),'')

			SELECT @apurcount=COUNT(*) FROM APUR WHERE Reviewer=@reviewer
			SELECT @jcjrcount=COUNT(*) FROM JCJR WHERE Reviewer=@reviewer

			SELECT @apvmcount=COUNT(*) FROM APVM WHERE Reviewer=@reviewer
			SELECT @emdmcount=COUNT(*) FROM EMDM WHERE Reviewer=@reviewer
			SELECT @hqrdcount=COUNT(*) FROM HQRD WHERE Reviewer=@reviewer
			SELECT @hqrpcount=COUNT(*) FROM HQRP WHERE Reviewer=@reviewer
			SELECT @hrercount=COUNT(*) FROM HRER WHERE Reviewer=@reviewer
			SELECT @pmnrcount=COUNT(*) FROM PMNR WHERE Reviewer=@reviewer
			SELECT @rqqrcount=COUNT(*) FROM RQQR WHERE Reviewer=@reviewer
			SELECT @rqrrcount=COUNT(*) FROM RQRR WHERE Reviewer=@reviewer
			
			IF @apurcount > 0
			BEGIN	
				SELECT @inusecount=@inusecount+@apurcount	
				PRINT 
					CAST('' AS CHAR(12))
				+	'-*- Reivewer used in APUR ' + COALESCE(CAST(@apurcount AS VARCHAR(50)),'') + ' times.'
			END 
			--ELSE
			--BEGIN
			--	PRINT 
			--		CAST('' AS CHAR(12))
			--	+	'-*- Reivewer not used in APUR' 
			--END 

			IF @jcjrcount > 0
			BEGIN	
				SELECT @inusecount=@inusecount+@jcjrcount				
				PRINT 
					CAST('' AS CHAR(12))
				+	'-*- Reivewer used in JCJR ' + COALESCE(CAST(@jcjrcount AS VARCHAR(50)),'') + ' times.'
			END 
			--ELSE
			--BEGIN
			--	PRINT 
			--		CAST('' AS CHAR(12))
			--	+	'-*- Reivewer not used in JCJR' 
			--END 

			IF @apvmcount > 0
			BEGIN	
				SELECT @inusecount=@inusecount+@apvmcount				
				PRINT 
					CAST('' AS CHAR(12))
				+	'-*- Reivewer used in APVM ' + COALESCE(CAST(@apvmcount AS VARCHAR(50)),'') + ' times.'
			END 
			--ELSE
			--BEGIN
			--	PRINT 
			--		CAST('' AS CHAR(12))
			--	+	'-*- Reivewer not used in APVM' 
			--END 

			IF @emdmcount > 0
			BEGIN	
				SELECT @inusecount=@inusecount+@emdmcount				
				PRINT 
					CAST('' AS CHAR(12))
				+	'-*- Reivewer used in EMDM ' + COALESCE(CAST(@emdmcount AS VARCHAR(50)),'') + ' times.'
			END 
			--ELSE
			--BEGIN
			--	PRINT 
			--		CAST('' AS CHAR(12))
			--	+	'-*- Reivewer not used in EMDM' 
			--END 

			IF @hqrdcount > 0
			BEGIN	
				SELECT @inusecount=@inusecount+@hqrdcount				
				PRINT 
					CAST('' AS CHAR(12))
				+	'-*- Reivewer used in HQRD ' + COALESCE(CAST(@hqrdcount AS VARCHAR(50)),'') + ' times.'
			END 
			--ELSE
			--BEGIN
			--	PRINT 
			--		CAST('' AS CHAR(12))
			--	+	'-*- Reivewer not used in HQRD' 
			--END 

			
			IF @hqrpcount > 0
			BEGIN	
				SELECT @inusecount=@inusecount+@hqrpcount				
				PRINT 
					CAST('' AS CHAR(12))
				+	'-*- Reivewer used in HQRP ' + COALESCE(CAST(@hqrpcount AS VARCHAR(50)),'') + ' times. (Remove Reviewer Members)'
			END 
			--ELSE
			--BEGIN
			--	PRINT 
			--		CAST('' AS CHAR(12))
			--	+	'-*- Reivewer not used in HQRP' 
			--END 

			IF @hrercount > 0
			BEGIN	
				SELECT @inusecount=@inusecount+@hrercount				
				PRINT 
					CAST('' AS CHAR(12))
				+	'-*- Reivewer used in HRER ' + COALESCE(CAST(@hrercount AS VARCHAR(50)),'') + ' times.'
			END 
			--ELSE
			--BEGIN
			--	PRINT 
			--		CAST('' AS CHAR(12))
			--	+	'-*- Reivewer not used in HRER' 
			--END 

			IF @pmnrcount > 0
			BEGIN	
				SELECT @inusecount=@inusecount+@pmnrcount				
				PRINT 
					CAST('' AS CHAR(12))
				+	'-*- Reivewer used in PMNR ' + COALESCE(CAST(@pmnrcount AS VARCHAR(50)),'') + ' times.'
			END 
			--ELSE
			--BEGIN
			--	PRINT 
			--		CAST('' AS CHAR(12))
			--	+	'-*- Reivewer not used in PMNR' 
			--END 

			IF @rqqrcount > 0
			BEGIN	
				SELECT @inusecount=@inusecount+@rqqrcount				
				PRINT 
					CAST('' AS CHAR(12))
				+	'-*- Reivewer used in RQQR ' + COALESCE(CAST(@rqqrcount AS VARCHAR(50)),'') + ' times.'
			END 
			--ELSE
			--BEGIN
			--	PRINT 
			--		CAST('' AS CHAR(12))
			--	+	'-*- Reivewer not used in RQQR' 
			--END 

			IF @rqrrcount > 0
			BEGIN	
				SELECT @inusecount=@inusecount+@rqrrcount				
				PRINT 
					CAST('' AS CHAR(12))
				+	'-*- Reivewer used in RQRR ' + COALESCE(CAST(@rqrrcount AS VARCHAR(50)),'') + ' times.'
			END 
			--ELSE
			--BEGIN
			--	PRINT 
			--		CAST('' AS CHAR(12))
			--	+	'-*- Reivewer not used in RQRR' 
			--END 

			PRINT
				CAST('' AS CHAR(12))
			+	'-*- Reivewer used a total of ' + COALESCE(CAST(@inusecount AS VARCHAR(50)),'') + ' times.'

			IF @inusecount=0
			BEGIN
				PRINT
					CAST('' AS CHAR(12))
				+	'**[ Reivewer NOT USED : Safe To Delete "' + CAST(@reviewer AS VARCHAR(50)) + '" ]**'
			END
		END
	END 	
	
	select @reviewer=NULL,@name=NULL,@email=NULL,@employeenumber=NULL,@inusecount=0
    
	--PRINT ''

	FETCH revcur INTO @reviewer,@name,@email
END

CLOSE revcur
DEALLOCATE revcur
go

/*
EXEC mspHQReviewerAudit @Reviewer=NULL, @Verbose=0
EXEC mspHQReviewerAudit @Reviewer=NULL, @Verbose=1
EXEC mspHQReviewerAudit @Reviewer='JA0', @Verbose=1
*/
