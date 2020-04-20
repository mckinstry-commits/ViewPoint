SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		AL vspCopySecuritySettings
-- Create date: 9/5/07
-- Modified : 11/6/07 Added fix that caused 'Group access cannot be set to 2-denied' to
--			  to be returned when copying from user to user	
--			
--			  11/16/07 Procedure now copies all records to groups where Access is not set to Denied
--		
--			  AL 5/22/08 Only form security groups will have records copied
--			  AL 7/22/07 - Issue #128987 Added joins to shared views. 
--		      JonathanP 02/25/09 - #132390 - updated to handle attachment security level column in DDFS
--
--            JPD 10/07/2009 - #135189 - changed @ToNameArray to @ToUserOrGroupName to allow commas in names
--                                       (now requires multiple calls for multiple targets)
--
-- Description:	Used in VACopySecuritySettings to copy 
--				the security records from one user/group
--				to multiple users/groups.
-- =============================================
CREATE PROCEDURE [dbo].[vspCopySecuritySettings]
	(@ToUserOrGroupName VARCHAR(40),     -- to/target name (of user or group)
	 @FromUserNameOrGroupId VARCHAR(40), -- name of from/source user OR id number of from/source group
	 @FromType CHAR,                     -- source/from type: 'U' = user, 'G' = group
	 @ToType CHAR,                       -- target/to type: 'U' = user, 'G' = group
	 @Message VARCHAR(60) OUTPUT)
AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @ReturnCode INT;
	SELECT @ReturnCode = 0;

	IF @ToType = 'U'  -- Copying TO a USER (from a group or user)
	BEGIN
		--Delete any records that may already exist for the users/groups
		--that are getting new security records
		DELETE DDTS WHERE [VPUserName] = @ToUserOrGroupName;
		--	DELETE DDTS 
		--		WHERE [VPUserName] 
		--		IN (SELECT Names FROM vfTableFromArray(@ToUserOrGroupName))		

		DELETE [DDFS] WHERE [VPUserName] = @ToUserOrGroupName;
		--	DELETE [DDFS]
		--	WHERE [VPUserName] IN (SELECT Names FROM vfTableFromArray(@ToUserOrGroupName))
		
		IF @FromType = 'U' -- Copying FROM a User TO a User
		BEGIN 
			INSERT INTO [DDFS]
				SELECT Co, f.Form, -1 
					AS SecurityGroup, @ToUserOrGroupName, Access, RecAdd, RecUpdate, RecDelete, AttachmentSecurityLevel 
					FROM DDFS f 
					WITH (NOLOCK)
				Join DDFHShared s (NOLOCK) ON s.Form = f.Form
				-- CROSS JOIN (SELECT Names FROM vfTableFromArray(@ToUserOrGroupName)) l
				WHERE  f.[VPUserName] = @FromUserNameOrGroupId;
			
			INSERT INTO [DDTS] 
				SELECT Co, t.Form, t.Tab,-1 as  SecurityGroup, @ToUserOrGroupName, Access FROM DDTS t WITH (NOLOCK)
				Join dbo.DDFTShared s (nolock)
				on s.Form = t.Form and s.Tab = t.Tab
				-- CROSS JOIN (SELECT Names FROM vfTableFromArray(@ToUserOrGroupName)) l
				WHERE t.[VPUserName] = @FromUserNameOrGroupId;
		END 
		ELSE  -- Copying FROM a Group TO a User
		BEGIN 
			INSERT INTO [DDFS]
				SELECT Co, f.Form, -1 AS SecurityGroup, @ToUserOrGroupName, Access, RecAdd, RecUpdate, RecDelete, AttachmentSecurityLevel 
					FROM DDFS f WITH (NOLOCK)
				Join DDFHShared s (nolock) on s.Form = f.Form
				-- CROSS JOIN (SELECT Names FROM vfTableFromArray(@ToUserOrGroupName)) l
				WHERE f.[SecurityGroup] = @FromUserNameOrGroupId;

			INSERT INTO [DDTS] 
				SELECT Co, t.Form, t.Tab, -1 as SecurityGroup, @ToUserOrGroupName, Access 
					FROM DDTS t WITH (NOLOCK)
				Join dbo.DDFTShared s (nolock)
				on s.Form = t.Form and s.Tab = t.Tab
				-- CROSS JOIN (SELECT Names FROM vfTableFromArray(@ToUserOrGroupName)) l
				WHERE t.[SecurityGroup] = @FromUserNameOrGroupId;
		END 
	END
	ELSE  -- Copying TO a Group
	BEGIN

		--Check for any denied records before attempting to copy
		SELECT Access FROM DDTS WHERE [VPUserName] = @FromUserNameOrGroupId AND [Access] = 2;
		IF @@rowcount <> 0
  		BEGIN
  			select @Message = 'Tab records with "Denied" Access level were not copied.', @ReturnCode = 1;
			--GOTO bspexit;
		END

		SELECT Access FROM DDFS WHERE [VPUserName] = @FromUserNameOrGroupId AND [Access] = 2;
		IF @@rowcount <> 0
  		BEGIN
  			select @Message = 'Form records with "Denied" Access level were not copied.', @ReturnCode = 1;
			--GOTO bspexit
		END
		

		--Remove any existing group records for the groups passed in
		DELETE DDTS 
		WHERE [SecurityGroup] 
			IN (SELECT SecurityGroup FROM DDSG g WHERE g.[Name] = @ToUserOrGroupName AND GroupType = 1);
			--IN (SELECT SecurityGroup FROM vfTableFromArray(@ToUserOrGroupName) a 
			--	JOIN DDSG g ON a.Names = g.[Name] where GroupType = 1)
		
		DELETE [DDFS]
		WHERE [SecurityGroup] 
			IN (SELECT SecurityGroup FROM DDSG g WHERE g.[Name] = @ToUserOrGroupName AND GroupType = 1);
			--IN (SELECT SecurityGroup FROM vfTableFromArray(@ToUserOrGroupName) a 
			--	JOIN DDSG g ON a.Names = g.[Name] where GroupType = 1)

		IF @FromType = 'G'  -- Copying FROM a Group TO a Group
		BEGIN 
			INSERT INTO [DDFS]
				SELECT Co, f.Form, l.SecurityGroup, '' 
					AS [VPUserName], Access, RecAdd, RecUpdate, RecDelete, AttachmentSecurityLevel 
					FROM DDFS f WITH (NOLOCK)
				Join DDFHShared s (NOLOCK) ON s.Form = f.Form
				CROSS JOIN (SELECT [SecurityGroup] FROM DDSG AS g 
								WHERE g.[Name] = @ToUserOrGroupName AND GroupType = 1) AS l
				--CROSS JOIN (SELECT [SecurityGroup] 
				--			FROM vfTableFromArray(@ToUserOrGroupName) l JOIN DDSG g 
				--			ON l.Names = g.[Name] Where GroupType = 1) l 
				WHERE f.[SecurityGroup] = @FromUserNameOrGroupId AND Access <> 2;
			
			INSERT INTO DDTS 
				SELECT Co, t.Form, t.Tab, l.SecurityGroup, '' 
					AS VPUserName, Access 
					FROM DDTS t WITH (NOLOCK)
				Join dbo.DDFTShared s (NOLOCK) ON s.Form = t.Form and s.Tab = t.Tab
				CROSS JOIN (SELECT [SecurityGroup] FROM DDSG AS g 
								WHERE g.[Name] = @ToUserOrGroupName AND GroupType = 1) AS l
				--CROSS JOIN (SELECT [SecurityGroup] 
				--			FROM vfTableFromArray(@ToUserOrGroupName) l JOIN DDSG g 
				--			ON l.Names = g.[Name] Where GroupType = 1) l 
				WHERE t.SecurityGroup = @FromUserNameOrGroupId AND Access <> 2;
		END  
		ELSE  -- Copying FROM a User TO a Group
		BEGIN 
			
			INSERT INTO [DDFS]
				SELECT Co, f.Form, l.SecurityGroup, '' AS [VPUserName], Access, RecAdd, RecUpdate, RecDelete, AttachmentSecurityLevel FROM DDFS f WITH (NOLOCK)
				Join DDFHShared s (nolock) ON s.Form = f.Form
				CROSS JOIN (SELECT [SecurityGroup] FROM DDSG AS g 
							WHERE g.[Name] = @ToUserOrGroupName AND GroupType = 1) AS l
				--CROSS JOIN (SELECT [SecurityGroup] 
				--			FROM vfTableFromArray(@ToUserOrGroupName) l JOIN DDSG g 
				--			ON l.Names = g.[Name] Where g.GroupType = 1 ) l 
				WHERE f.[VPUserName] = @FromUserNameOrGroupId and Access <> 2;
			
			INSERT INTO DDTS 
				SELECT Co, t.Form, t.Tab, l.SecurityGroup, '' AS VPUserName, Access FROM DDTS t WITH (NOLOCK)
				Join dbo.DDFTShared s (nolock) ON s.Form = t.Form AND s.Tab = t.Tab
				CROSS JOIN (SELECT [SecurityGroup] FROM DDSG AS g 
							WHERE g.[Name] = @ToUserOrGroupName AND GroupType = 1) AS l
				--CROSS JOIN (SELECT [SecurityGroup] 
				--			FROM vfTableFromArray(@ToUserOrGroupName) l JOIN DDSG g 
				--			ON l.Names = g.[Name] Where g.GroupType = 1 ) l 
				WHERE t.[VPUserName] = @FromUserNameOrGroupId and Access <> 2;
		END  
	END

--
--		IF @@ROWCOUNT = 0
--		begin
--  		select @Message = 'No rows were affected.',  @ReturnCode = 1	
--  		GOTO bspexit
--  		END
--		

bspexit:
	RETURN @ReturnCode
END 

GO
GRANT EXECUTE ON  [dbo].[vspCopySecuritySettings] TO [public]
GO
