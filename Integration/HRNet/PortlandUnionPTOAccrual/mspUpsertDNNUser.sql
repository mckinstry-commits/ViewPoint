

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE='PROCEDURE' AND ROUTINE_NAME='mspUpsertDNNUser' AND ROUTINE_SCHEMA='dbo')
BEGIN
PRINT 'DROP PROCEDURE [dbo].[mspUpsertDNNUser]'
DROP PROCEDURE [dbo].[mspUpsertDNNUser]
END
go

PRINT 'CREATE PROCEDURE [dbo].[mspUpsertDNNUser]'
go

create PROCEDURE [dbo].[mspUpsertDNNUser]
(
	@UserToCopy nvarchar(100) = 'mnepto_template'
,	@UserName nvarchar(100)
,	@FirstName nvarchar(100)
,	@LastName nvarchar(100)
,	@Email nvarchar(100)
,	@EmployeeNumber	VARCHAR(20)
,	@RoleName	NVARCHAR(100) = 'Non-Staff PTO Users'
,	@UnionName 	NVARCHAR(100) = null
,	@Status	NVARCHAR(10)
)
AS

SET NOCOUNT ON 

BEGIN

DECLARE @curDBSVR VARCHAR(60)
SELECT @curDBSVR = CAST(SERVERPROPERTY('MachineName') AS VARCHAR(30)) + '\' + COALESCE(CAST(SERVERPROPERTY('InstanceName') AS VARCHAR(30)),'')

DECLARE @CurrentDate AS DATETIME = GETUTCDATE()

DECLARE @ApplicationID UNIQUEIDENTIFIER
DECLARE @UserID INT
DECLARE @AspUserID UNIQUEIDENTIFIER

DECLARE @Password nvarchar(1000)
DECLARE @PasswordSalt nvarchar(1000)
DECLARE @PortalID INT = 0

DECLARE @RegRoleID INT
DECLARE @SubRoleID INT
DECLARE @InputRoleID INT
DECLARE @UnionRoleID INT

DECLARE @DisplayName NVARCHAR(100)

DECLARE  @FirstNamePropertyID INT 
DECLARE  @LastNamePropertyID INT 
DECLARE  @EmployeeIDPropertyID INT 
SELECT @DisplayName = LTRIM(RTRIM(COALESCE(@FirstName,'') + ' ' + COALESCE(@LastName,'')))

SELECT  @Password = [Password], @PasswordSalt = PasswordSalt,  @ApplicationId = dbo.aspnet_Membership.ApplicationId FROM dbo.aspnet_Membership
INNER JOIN dbo.aspnet_Users ON dbo.aspnet_Membership.UserId = dbo.aspnet_Users.UserId
WHERE UserName = @UserToCopy 

IF @ApplicationId is NULL
BEGIN
	RAISERROR ('UserToCopy does not exist', 16, 1);
	return
END

IF NOT EXISTS (SELECT 1 FROM dbo.aspnet_Users WHERE UserName=@UserName)
BEGIN

	--SELECT @ApplicationId = ApplicationId from dbo.aspnet_Applications WHERE ApplicationName='DotNetNuke'
	SELECT @AspUserID = NEWID()
	
	PRINT 'INSERT INTO dbo.aspnet_Users' 
	INSERT INTO dbo.aspnet_Users
	        ( ApplicationId ,
	          UserId ,
	          UserName ,
	          LoweredUserName ,
	          MobileAlias ,
	          IsAnonymous ,
	          LastActivityDate
	        )	
	VALUES  ( @ApplicationId , -- ApplicationId - uniqueidentifier
			  @AspUserID , -- UserId - uniqueidentifier
			  @UserName , -- UserName - nvarchar(256)
			  @UserName , -- LoweredUserName - nvarchar(256)
			  NULL , -- MobileAlias - nvarchar(16)
			  0 , -- IsAnonymous - bit
			  @CurrentDate  -- LastActivityDate - datetime
			)
			
	SELECT @UserID = SCOPE_IDENTITY()
END
ELSE
BEGIN
	PRINT 'dbo.aspnet_Users record exists' 
	SELECT 
		@ApplicationID=ApplicationId
	,	@AspUserID=UserID
	FROM
		dbo.aspnet_Users WHERE UserName=@UserName

END

PRINT 'AppID:' + COALESCE(CAST(@ApplicationId AS VARCHAR(64)),'??')
PRINT 'AspUserID:' + COALESCE(CAST(@AspUserID AS VARCHAR(64)),'??')

IF NOT EXISTS ( SELECT 1 FROM dbo.aspnet_Membership WHERE ApplicationId=@ApplicationId AND UserId=@AspUserID)
BEGIN
	PRINT 'INSERT INTO dbo.aspnet_Membership'
	
	INSERT INTO dbo.aspnet_Membership
			( ApplicationId ,
			  UserId ,
			  Password ,
			  PasswordFormat ,
			  PasswordSalt ,
			  MobilePIN ,
			  Email ,
			  LoweredEmail ,
			  PasswordQuestion ,
			  PasswordAnswer ,
			  IsApproved ,
			  IsLockedOut ,
			  CreateDate ,
			  LastLoginDate ,
			  LastPasswordChangedDate ,
			  LastLockoutDate ,
			  FailedPasswordAttemptCount ,
			  FailedPasswordAttemptWindowStart ,
			  FailedPasswordAnswerAttemptCount ,
			  FailedPasswordAnswerAttemptWindowStart ,
			  Comment
			)
	VALUES  ( @ApplicationId , -- ApplicationId - uniqueidentifier
			  @AspUserID , -- UserId - uniqueidentifier
			  @Password , -- Password - nvarchar(128)
			  2 , -- PasswordFormat - int
			  @PasswordSalt , -- PasswordSalt - nvarchar(128)
			  NULL , -- MobilePIN - nvarchar(16)
			  @Email , -- Email - nvarchar(256)
			  LOWER(@Email) , -- LoweredEmail - nvarchar(256)
			  NULL , -- PasswordQuestion - nvarchar(256)
			  NULL , -- PasswordAnswer - nvarchar(128)
			  1 , -- IsApproved - bit
			  0 , -- IsLockedOut - bit
			  @CurrentDate , -- CreateDate - datetime
			  @CurrentDate , -- LastLoginDate - datetime
			  @CurrentDate , -- LastPasswordChangedDate - datetime
			  '1754-01-01 00:00:00.000' , -- LastLockoutDate - datetime
			  0 , -- FailedPasswordAttemptCount - int
			  '1754-01-01 00:00:00.000' , -- FailedPasswordAttemptWindowStart - datetime
			  0 , -- FailedPasswordAnswerAttemptCount - int
			  '1754-01-01 00:00:00.000' , -- FailedPasswordAnswerAttemptWindowStart - datetime
			  NULL  -- Comment - ntext
			)
END 
ELSE
BEGIN
	PRINT 'aspnet_Membership record exists.'
	
	UPDATE aspnet_Membership SET Email=@Email, LoweredEmail=LOWER(@Email) 
	WHERE ApplicationId=@ApplicationId AND UserId=@AspUserID AND Email <> @Email
	
	IF @Status <> 'A'
	BEGIN
		PRINT 'LOCKING aspnet_Membership record. : ' + @Status
		UPDATE aspnet_Membership SET
			IsApproved=0
		,	IsLockedOut=1
		WHERE ApplicationId=@ApplicationId AND UserId=@AspUserID
		
	END
	ELSE
	BEGIN
		PRINT 'UNLOCKING aspnet_Membership record. : ' + @Status
		UPDATE aspnet_Membership SET
			IsApproved=1
		,	IsLockedOut=0
		WHERE ApplicationId=@ApplicationId AND UserId=@AspUserID AND IsApproved<>1 AND IsLockedOut<>0
		
	END
	
END			

	
IF NOT EXISTS ( SELECT 1 FROM Users WHERE Username=@UserName )
BEGIN
	PRINT 'INSERT INTO dbo.Users'

	INSERT INTO dbo.Users
			( Username ,
			  FirstName ,
			  LastName ,
			  IsSuperUser ,
			  AffiliateId ,
			  Email ,
			  DisplayName ,
			  UpdatePassword ,
			  LastIPAddress ,
			  IsDeleted ,
			  CreatedByUserID ,
			  CreatedOnDate ,
			  LastModifiedByUserID ,
			  LastModifiedOnDate
			)
	select  @UserName , -- Username - nvarchar(100)
			@FirstName , -- FirstName - nvarchar(50)
			@LastName , -- LastName - nvarchar(50)
			0 , -- IsSuperUser - bit
			NULL , -- AffiliateId - int
			@Email , -- Email - nvarchar(256)
			@DisplayName , -- DisplayName - nvarchar(128)
			CASE WHEN @UserName LIKE 'MCKINSTRY%' THEN 0 ELSE 1 END , -- UpdatePassword - bit
			N'' , -- LastIPAddress - nvarchar(50)
			0 , -- IsDeleted - bit
			0 , -- CreatedByUserID - int
			@CurrentDate , -- CreatedOnDate - datetime
			0 , -- LastModifiedByUserID - int
			@CurrentDate   -- LastModifiedOnDate - datetime
			
			

	SET @UserID = SCOPE_IDENTITY()
END
ELSE
BEGIN
	UPDATE Users SET Email=@Email  WHERE Username=@UserName AND Email <> @Email
	
	PRINT 'dbo.Users record exists.'
	SELECT @UserId = UserID
	FROM Users WHERE Username=@UserName
	
END	
	
				
PRINT 'UserID:' + COALESCE(CAST(@UserID AS VARCHAR(64)),'??')


SELECT  @RegRoleID = [RoleID] FROM dbo.Roles WHERE RoleName = 'Registered Users' AND PortalID=@PortalID

IF NOT EXISTS ( SELECT 1 FROM dbo.UserRoles WHERE UserID=@UserID AND RoleID=@RegRoleID)
BEGIN
	PRINT 'INSERT INTO dbo.UserRoles : ' + 'Registered Users'+ ' : ' + CAST(@RegRoleID AS CHAR(10))
	INSERT INTO dbo.UserRoles
			( UserID ,
			  RoleID ,
			  ExpiryDate ,
			  IsTrialUsed ,
			  EffectiveDate ,
			  CreatedByUserID ,
			  CreatedOnDate ,
			  LastModifiedByUserID ,
			  LastModifiedOnDate

			)
	SELECT  @UserID , -- UserID - int
			@RegRoleID , -- RoleID - int
			NULL , -- ExpiryDate - datetime
			1 , -- IsTrialUsed - bit
			@CurrentDate , -- EffectiveDate - datetime
			0 , -- CreatedByUserID - int
			@CurrentDate , -- CreatedOnDate - datetime
			0 , -- LastModifiedByUserID - int
			@CurrentDate  -- LastModifiedOnDate - datetime
			
END
ELSE
BEGIN
	PRINT 'dbo.UserRoles record Exists : ' + 'Registered Users'+ ' : ' + CAST(@RegRoleID AS CHAR(10))
END

SELECT  @SubRoleID = [RoleID] FROM dbo.Roles WHERE RoleName = 'Subscribers' AND PortalID=@PortalID

IF NOT EXISTS ( SELECT 1 FROM dbo.UserRoles WHERE UserID=@UserID AND RoleID=@SubRoleID)
BEGIN
	PRINT 'INSERT INTO dbo.UserRoles : ' + 'Subscribers'+ ' : ' + CAST(@SubRoleID AS CHAR(10))
	INSERT INTO dbo.UserRoles
			( UserID ,
			  RoleID ,
			  ExpiryDate ,
			  IsTrialUsed ,
			  EffectiveDate ,
			  CreatedByUserID ,
			  CreatedOnDate ,
			  LastModifiedByUserID ,
			  LastModifiedOnDate 
			)
	SELECT  @UserID , -- UserID - int
			@SubRoleID , -- RoleID - int
			NULL , -- ExpiryDate - datetime
			1 , -- IsTrialUsed - bit
			@CurrentDate , -- EffectiveDate - datetime
			0 , -- CreatedByUserID - int
			@CurrentDate , -- CreatedOnDate - datetime
			0 , -- LastModifiedByUserID - int
			@CurrentDate   -- LastModifiedOnDate - datetime
			
END
ELSE
BEGIN
	PRINT 'dbo.UserRoles record Exists : ' + 'Subscribers'+ ' : ' + CAST(@SubRoleID AS CHAR(10))
END

SELECT  @InputRoleID = [RoleID] FROM dbo.Roles WHERE RoleName = @RoleName AND PortalID=@PortalID

IF NOT EXISTS ( SELECT * FROM dbo.UserRoles WHERE UserID=@UserID AND RoleID=@InputRoleID)
BEGIN
	PRINT 'INSERT INTO dbo.UserRoles : ' + @RoleName + ' : ' + CAST(@InputRoleID AS CHAR(10))
	INSERT INTO dbo.UserRoles
			( UserID ,
			  RoleID ,
			  ExpiryDate ,
			  IsTrialUsed ,
			  EffectiveDate ,
			  CreatedByUserID ,
			  CreatedOnDate ,
			  LastModifiedByUserID ,
			  LastModifiedOnDate 
			)
	SELECT  @UserID , -- UserID - int
			@InputRoleID , -- RoleID - int
			NULL , -- ExpiryDate - datetime
			1 , -- IsTrialUsed - bit
			@CurrentDate , -- EffectiveDate - datetime
			0 , -- CreatedByUserID - int
			@CurrentDate , -- CreatedOnDate - datetime
			0 , -- LastModifiedByUserID - int
			@CurrentDate  -- LastModifiedOnDate - datetime
			
END
ELSE
BEGIN
	PRINT 'dbo.UserRoles record Exists : ' + @RoleName+ ' : ' + CAST(@InputRoleID AS CHAR(10))
END

IF @UnionName IS NOT NULL
BEGIN

	IF NOT EXISTS ( SELECT 1 FROM Roles WHERE RoleName = 'Union ' + @UnionName AND PortalID=@PortalID )
	BEGIN
		--SELECT * FROM Roles WHERE RoleName LIKE '%PTO%'
		INSERT dbo.Roles
		        ( PortalID ,
		          RoleName ,
		          Description ,
		          ServiceFee ,
		          BillingFrequency ,
		          TrialPeriod ,
		          TrialFrequency ,
		          BillingPeriod ,
		          TrialFee ,
		          IsPublic ,
		          AutoAssignment ,
		          RoleGroupID ,
		          RSVPCode ,
		          IconFile ,
		          CreatedByUserID ,
		          CreatedOnDate ,
		          LastModifiedByUserID ,
		          LastModifiedOnDate ,
		          Status ,
		          SecurityMode
		        )
		SELECT	@PortalID , -- PortalID - int
		        'Union ' + @UnionName , -- RoleName - nvarchar(50)
		        'Union ' + @UnionName , -- Description - nvarchar(1000)
		          0.00 , -- ServiceFee - money
		          'N' , -- BillingFrequency - char(1)
		          1 , -- TrialPeriod - int
		          'N' , -- TrialFrequency - char(1)
		          1 , -- BillingPeriod - int
		          0.00 , -- TrialFee - money
		          0 , -- IsPublic - bit
		          0 , -- AutoAssignment - bit
		          3 , -- RoleGroupID - int
		          CAST(NEWID() AS VARCHAR(50)) , -- RSVPCode - nvarchar(50)
		          N'' , -- IconFile - nvarchar(100)
		          0 , -- CreatedByUserID - int
		          GETDATE() , -- CreatedOnDate - datetime
		          0 , -- LastModifiedByUserID - int
		          GETDATE() , -- LastModifiedOnDate - datetime
		          1 , -- Status - int
		          0  -- SecurityMode - int        
	END
	
	SELECT  @UnionRoleID = [RoleID] FROM dbo.Roles WHERE RoleName = 'Union ' + @UnionName AND PortalID=@PortalID
	
	IF NOT EXISTS ( SELECT * FROM dbo.UserRoles WHERE UserID=@UserID AND RoleID=@UnionRoleID)
	BEGIN
		PRINT 'INSERT INTO dbo.UserRoles : Union ' + @UnionName + ' : ' + CAST(@UnionRoleID AS CHAR(10))
		INSERT INTO dbo.UserRoles
				( UserID ,
				  RoleID ,
				  ExpiryDate ,
				  IsTrialUsed ,
				  EffectiveDate ,
				  CreatedByUserID ,
				  CreatedOnDate ,
				  LastModifiedByUserID ,
				  LastModifiedOnDate 
				)
		SELECT  @UserID , -- UserID - int
				@UnionRoleID , -- RoleID - int
				NULL , -- ExpiryDate - datetime
				1 , -- IsTrialUsed - bit
				@CurrentDate , -- EffectiveDate - datetime
				0 , -- CreatedByUserID - int
				@CurrentDate , -- CreatedOnDate - datetime
				0 , -- LastModifiedByUserID - int
				@CurrentDate  -- LastModifiedOnDate - datetime
				
	END
	ELSE
	BEGIN
		PRINT 'dbo.UserRoles record Exists Union : ' + @UnionName+ ' : ' + CAST(@InputRoleID AS CHAR(10))
	END

	--Delete from other Union Roles
	PRINT 'Revoking other Union Role Memberships'
	DELETE dbo.UserRoles WHERE UserID=@UserID AND 
	RoleID IN ( SELECT DISTINCT RoleID FROM dbo.Roles WHERE RoleID<>@UnionRoleID AND RoleGroupID =3 AND RoleName LIKE 'Union%')

END

IF NOT EXISTS ( SELECT 1 FROM dbo.UserPortals WHERE PortalId=@PortalId AND UserId=@UserID )
BEGIN
	PRINT 'INSERT INTO dbo.UserPortals'
	INSERT INTO dbo.UserPortals
			( UserId ,
			  PortalId ,
			  CreatedDate ,
			  Authorised ,
			  IsDeleted ,
			  RefreshRoles
			)
	VALUES  ( @UserID , -- UserId - int
			  @PortalID , -- PortalId - int
			  @CurrentDate , -- CreatedDate - datetime
			  1 , -- Authorised - bit
			  0 , -- IsDeleted - bit
			  0  -- RefreshRoles - bit
			)
END
ELSE
BEGIN
	PRINT 'dbo.UserPortals record exists'
	IF @Status <> 'A'
	BEGIN
		PRINT 'Unauthosing aspnet_Membership record. : ' + @Status
		UPDATE UserPortals SET
			Authorised=0
		WHERE PortalId=@PortalId AND UserId=@UserID
	END
	ELSE
	BEGIN
		PRINT 'Authosing aspnet_Membership record. : ' + @Status
		UPDATE UserPortals SET
			Authorised=1
		WHERE PortalId=@PortalId AND UserId=@UserID AND Authorised<>1
	END
END

SELECT @FirstNamePropertyID=PropertyDefinitionID FROM dbo.ProfilePropertyDefinition WHERE PortalID=0 AND PropertyName='FirstName'

IF NOT EXISTS ( SELECT 1 FROM dbo.UserProfile WHERE UserID=@UserID AND PropertyDefinitionID=@FirstNamePropertyID )
BEGIN
		--Create FirstName UserProfile Property
		PRINT 'Adding Property [FirstName] :' + @FirstName
		INSERT INTO dbo.UserProfile
				( UserID ,
				  PropertyDefinitionID ,
				  PropertyValue ,
				  PropertyText ,
				  Visibility ,
				  LastUpdatedDate ,
				  ExtendedVisibility
				)
		VALUES  ( @UserID , -- UserID - int
				  @FirstNamePropertyID , -- PropertyDefinitionID - int
				  @FirstName , -- PropertyValue - nvarchar(3750)
				  NULL , -- PropertyText - nvarchar(max)
				  1 , -- Visibility - int
				  @CurrentDate , -- LastUpdatedDate - datetime
				  ''  -- ExtendedVisibility - varchar(400)
				)					
END
ELSE
BEGIN
	PRINT 'Updating Property [FirstName] :' + @FirstName
	UPDATE dbo.UserProfile SET
	PropertyValue=@FirstName
	WHERE UserID=@UserID AND PropertyDefinitionID=@FirstNamePropertyID
END

SELECT @LastNamePropertyID=PropertyDefinitionID FROM dbo.ProfilePropertyDefinition WHERE PortalID=0 AND PropertyName='LastName'

IF NOT EXISTS ( SELECT 1 FROM dbo.UserProfile WHERE UserID=@UserID AND PropertyDefinitionID=@LastNamePropertyID )
BEGIN
		--Create FirstName UserProfile Property
		PRINT 'Inserting Property [LastName] :' + @LastName
		INSERT INTO dbo.UserProfile
				( UserID ,
				  PropertyDefinitionID ,
				  PropertyValue ,
				  PropertyText ,
				  Visibility ,
				  LastUpdatedDate ,
				  ExtendedVisibility
				)
		VALUES  ( @UserID , -- UserID - int
				  @LastNamePropertyID , -- PropertyDefinitionID - int
				  @LastName , -- PropertyValue - nvarchar(3750)
				  NULL , -- PropertyText - nvarchar(max)
				  1 , -- Visibility - int
				  @CurrentDate , -- LastUpdatedDate - datetime
				  ''  -- ExtendedVisibility - varchar(400)
				)					
END
ELSE
BEGIN
	PRINT 'Updating Property [LastName] :' + @LastName
	UPDATE dbo.UserProfile SET
	PropertyValue=@LastName
	WHERE UserID=@UserID AND PropertyDefinitionID=@LastNamePropertyID
END

SELECT @EmployeeIDPropertyID=PropertyDefinitionID FROM dbo.ProfilePropertyDefinition WHERE PortalID=0 AND PropertyName='EmployeeID'

IF NOT EXISTS ( SELECT 1 FROM dbo.UserProfile WHERE UserID=@UserID AND PropertyDefinitionID=@EmployeeIDPropertyID )
BEGIN
		--Create FirstName UserProfile Property
		PRINT 'Inserting Property [EmployeeNumber] :' + @EmployeeNumber
		INSERT INTO dbo.UserProfile
				( UserID ,
				  PropertyDefinitionID ,				 
				  PropertyValue ,
				  PropertyText ,
				  Visibility ,
				  LastUpdatedDate ,
				  ExtendedVisibility
				)
		VALUES  ( @UserID , -- UserID - int
				  @EmployeeIDPropertyID , -- PropertyDefinitionID - int
				  CAST(@EmployeeNumber AS VARCHAR(30)) , -- PropertyValue - nvarchar(3750)
				  NULL , -- PropertyText - nvarchar(max)
				  1 , -- Visibility - int
				  @CurrentDate , -- LastUpdatedDate - datetime
				  ''  -- ExtendedVisibility - varchar(400)
				)					
END
ELSE
BEGIN
	PRINT 'Updating Property [EmployeeNumber] :' + @EmployeeNumber
	UPDATE dbo.UserProfile SET
	PropertyValue=CAST(@EmployeeNumber AS VARCHAR(30))
	WHERE UserID=@UserID AND PropertyDefinitionID=@EmployeeIDPropertyID
END

--Fix Missing Employee Number
BEGIN

	if @curDBSVR = 'SESQL08\'
	BEGIN 
		PRINT 'Sync Accounts on ' + @curDBSVR  + ' http://dnn.mckinstry.com'
		UPDATE 
			UserProfile 
		SET 
			PropertyValue=p.REFERENCENUMBER
		FROM 
			dbo.UserProfile up INNER JOIN
			dbo.ProfilePropertyDefinition ppd ON
				up.PropertyDefinitionID=ppd.PropertyDefinitionID
			AND ppd.PropertyName='EmployeeID' INNER JOIN
			Users u ON
				u.UserID=up.UserID INNER JOIN	 
			HRNET.[mnepto].[mvwActiveEmployees] p ON
				p.STATUS <> 'T'
			AND	u.Email = COALESCE(p.EMAILPRIMARY, p.EMAILSECONDARY) COLLATE SQL_Latin1_General_CP1_CI_AS 	
			AND p.REFERENCENUMBER <> up.PropertyValue COLLATE SQL_Latin1_General_CP1_CI_AS 
	END
	if @curDBSVR = 'SEDEVSQL01\'
	BEGIN 
		PRINT 'Sync Accounts on ' + @curDBSVR  + ' http://dnndev.mckinstry.com'
		UPDATE 
			UserProfile 
		SET 
			PropertyValue=p.REFERENCENUMBER
		FROM 
			dbo.UserProfile up INNER JOIN
			dbo.ProfilePropertyDefinition ppd ON
				up.PropertyDefinitionID=ppd.PropertyDefinitionID
			AND ppd.PropertyName='EmployeeID' INNER JOIN
			Users u ON
				u.UserID=up.UserID INNER JOIN	 
			[DEV-HRISSQL02].HRNET.[mnepto].[mvwActiveEmployees] p ON
				p.STATUS <> 'T'
			AND	u.Email = COALESCE(p.EMAILPRIMARY, p.EMAILSECONDARY) COLLATE SQL_Latin1_General_CP1_CI_AS 	
			AND p.REFERENCENUMBER <> up.PropertyValue COLLATE SQL_Latin1_General_CP1_CI_AS 
	END	
	
END
	
END

go

	--EXEC [sesql08]/[sedevsql01].McK_DNN_DB.dbo.mspUpsertDNNUser 
	--		@UserToCopy = 'mnepto_template' --nvarchar(100)
	--	,	@UserName = 'MCKINSTRY\TerryA' --nvarchar(100)
	--	,	@FirstName = 'Terry' --nvarchar(100)
	--	,	@LastName = 'Ashley' --nvarchar(100)
	--	,	@Email = 'terrya@mckinstry.com' --nvarchar(100)
	--	,	@EmployeeNumber	= null --VARCHAR(20)
	--	,	@RoleName = 'Non-Staff PTO Users' --	NVARCHAR(100) = 'Non-Staff PTO Users'
	--	,	@UnionName = null
	--	,	@Status	= 'A' --NVARCHAR(10)

--DECLARE @UserId INT 
--SELECT @UserId= 34

--select * from Users WHERE UserID=@UserId
--SELECT * FROM dbo.Roles WHERE RoleGroupId=3
--SELECT * FROM dbo.UserPortals WHERE UserId=@UserId
--SELECT * FROM dbo.UserProfile WHERE UserId=@UserId
--SELECT * FROM dbo.UserRoles WHERE UserID=@UserId

--go

IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME='mvwPTOUsers' AND TABLE_SCHEMA='dbo')
BEGIN
PRINT 'DROP VIEW [dbo].[mvwPTOUsers]'
DROP VIEW [dbo].[mvwPTOUsers]
END
go

PRINT 'CREATE VIEW [dbo].[mvwPTOUsers]'
go

CREATE VIEW [dbo].[mvwPTOUsers]
as
SELECT
	up.PropertyValue AS EmployeeNumber
,	up.PropertyValue+ ' : ' + u.DisplayName  AS EmployeeSelectName
from 
	dbo.Users u JOIN
	dbo.UserRoles ur ON
		u.UserID=ur.UserID JOIN
	dbo.Roles r ON
		ur.RoleID=r.RoleID JOIN
	dbo.UserProfile up ON
		u.UserID=up.UserID JOIN
	dbo.ProfilePropertyDefinition ppd ON
		up.PropertyDefinitionID=ppd.PropertyDefinitionID
WHERE
	r.RoleName='Non-Staff PTO Users'
AND ppd.PropertyName='EmployeeID'
go