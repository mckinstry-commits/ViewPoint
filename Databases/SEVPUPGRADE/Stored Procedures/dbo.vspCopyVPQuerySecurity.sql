SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Aaronl - (I adapted this from vspCopyReportSecurity since their 
--						     functionality is near identical)
-- Create date: 12/8/08
-- Modified : 
--			
--            JPD 10/07/2009 - #135189 - changed @ToNameArray to @ToUserOrGroupName to allow commas in names
--                                       (now requires multiple calls for multiple targets)
--
-- Description:	Used in VACopySecuritySettings to copy the VAQuery security 
--				records from one user/group	to multiple users/groups.
-- =============================================
CREATE PROCEDURE [dbo].[vspCopyVPQuerySecurity]
	(@ToUserOrGroupName VARCHAR(40),     -- to/target name (of user or group)
	 @FromUserNameOrGroupId VARCHAR(40), -- name of from/source user OR id number of from/source group
	 @FromType CHAR,                     -- source/from type: 'U' = user, 'G' = group
	 @ToType CHAR,                       -- target/to type: 'U' = user, 'G' = group
	 @Message VARCHAR(60) OUTPUT)
AS
BEGIN

	DECLARE @rcode int;
	SELECT @rcode = 0;

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF @ToType = 'U'  -- Copying TO a USER (from a group or user)
	BEGIN
		--Delete any records that may already exist for the users/groups
		--that are getting new security records
		DELETE [VPQuerySecurity] WHERE [VPUserName] = @ToUserOrGroupName;
			--WHERE [VPUserName] IN (SELECT Names FROM vfTableFromArray(@ToUserOrGroupName));

		IF @FromType = 'U' -- Copying FROM a User TO a User
		BEGIN 
			INSERT INTO [VPQuerySecurity] 
				SELECT Co, QueryName, SecurityGroup, @ToUserOrGroupName, Access 
				FROM VPQuerySecurity f WITH (NOLOCK)
				--CROSS JOIN (SELECT Names FROM vfTableFromArray(@ToUserOrGroupName)) l
				WHERE f.[VPUserName] = @FromUserNameOrGroupId;
		END 
		ELSE  -- Copying FROM a Group TO a User
		BEGIN 
			INSERT INTO [VPQuerySecurity]
				SELECT Co, QueryName, -1 AS SecurityGroup, @ToUserOrGroupName, Access 
				FROM [VPQuerySecurity] f WITH (NOLOCK)
				--CROSS JOIN (SELECT Names FROM vfTableFromArray(@ToUserOrGroupName)) l
				WHERE f.[SecurityGroup] = @FromUserNameOrGroupId;
		END 		
	END 
	ELSE  -- Copying TO a Group
	BEGIN
		--Check for any denied records before attempting to copy
		SELECT Access FROM VPQuerySecurity WHERE [VPUserName] = @FromUserNameOrGroupId AND [Access] = 2
		IF @@rowcount <> 0
  		BEGIN
  			SELECT @Message =  'Note: "Denied" Security records were not copied.', @rcode = 1
			--GOTO bspexit
  		END
		
		--Remove any existing group records for the groups passed in
		DELETE [VPQuerySecurity] WHERE [SecurityGroup] IN 
			(SELECT SecurityGroup FROM DDSG AS g WHERE g.[Name] = @ToUserOrGroupName);
			--(SELECT SecurityGroup FROM vfTableFromArray(@ToUserOrGroupName) a JOIN DDSG g 
			--							ON a.Names = g.[Name]);

		IF @FromType = 'G'  -- Copying FROM a Group TO a Group
		BEGIN 
			INSERT INTO [VPQuerySecurity]
				SELECT Co, QueryName, l.SecurityGroup, '' AS [VPUserName], Access 
				FROM VPQuerySecurity f WITH (NOLOCK)
				CROSS JOIN (SELECT [SecurityGroup] FROM DDSG AS g 
							WHERE g.[Name] = @ToUserOrGroupName AND GroupType = 2) AS l 
				--CROSS JOIN (SELECT [SecurityGroup] 
				--			FROM vfTableFromArray(@ToUserOrGroupName) l JOIN DDSG g 
				--			ON l.Names = g.[Name] and GroupType = 2) l 
				WHERE f.[SecurityGroup] = @FromUserNameOrGroupId AND Access <> 2;
		END  
		ELSE  -- Copying FROM a User TO a Group
		BEGIN 
			INSERT INTO [VPQuerySecurity]
				SELECT Co, QueryName, l.SecurityGroup, '' AS [VPUserName], Access 
				FROM VPQuerySecurity f WITH (NOLOCK)
				CROSS JOIN (SELECT [SecurityGroup] FROM DDSG AS g 
							WHERE g.[Name] = @ToUserOrGroupName AND GroupType = 2) AS l 
				--CROSS JOIN (SELECT [SecurityGroup] 
				--			FROM vfTableFromArray(@ToUserOrGroupName) l JOIN DDSG g 
				--			ON l.Names = g.[Name] and GroupType = 2) l 
				WHERE f.[VPUserName] = @FromUserNameOrGroupId AND Access <> 2;
		END  
	END
	
	IF @@ROWCOUNT = 0
	BEGIN
		SELECT @Message = 'No rows were affected.',  @rcode = 1	
		GOTO bspexit
	END

bspexit:
  	RETURN @rcode
END

GO
GRANT EXECUTE ON  [dbo].[vspCopyVPQuerySecurity] TO [public]
GO
