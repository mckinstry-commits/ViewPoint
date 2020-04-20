SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Created: Dan So 11/26/2008 - Issue: #129484 - Notify Reviewer
-- Modified: Dan So 03/02/2009 - Issue: #132507 - Log error instead of raising error
--
-- Description:	Send Project Notification
-- =============================================

CREATE PROCEDURE [dbo].[vspPMProjectEmail] 
	(@ToUser bVPUserName = NULL, @FromUser bVPUserName = NULL,
	 @CoNum varchar(10), 
	 @ProjNum varchar(20),  
	 @AddedBy bVPUserName, @AddedDate bDate, 
	 @ChangedBy bVPUserName, @ChangedDate bDate, 
	 @msg varchar(255)output)
	
AS

BEGIN TRY

	DECLARE	@CoName varchar(30),
			@ProjName varchar(30),
			@ToEmailAddr varchar(255),
			@FromEmailAddr varchar(255),
			@EmailSubject varchar(255), 
			@EmailBody varchar(max),
			@NotifySource varchar(30),
			@rcode int


		SET NOCOUNT ON

		-- ***************** --
		-- PRIME VARIABLE(S) --
		-- ***************** --
		SET @rcode = 0


		-- **************************** --
		-- GET NOTIFICATION INFORMATION --
		-- **************************** --
		SELECT @ToEmailAddr = EMail
		  FROM vDDUP 
		 WHERE VPUserName = @ToUser

		-- NOTIFY PREFERENCE --
		SELECT @NotifySource = Source 
		  FROM DDNotificationPrefs 
		 WHERE VPUserName = @ToUser 
		   AND Source = 'Project Notes'

		SELECT @FromEmailAddr = EMail 
		  FROM vDDUP 
		 WHERE VPUserName = @FromUser

		-- GET COMPANY NAME --
		SELECT	@CoName = HQCO.Name
		  FROM	HQCO WITH (NOLOCK)
		 WHERE	HQCO.HQCo = @CoNum

		-- GET PROJECT NAME --
		SELECT	TOP 1 
				@ProjName = Description
		  FROM	JCJMPM j WITH (NOLOCK)
		 WHERE  j.JCCo = @CoNum
		   AND  j.Job = @ProjNum

		-- ***************************** --
		-- CHECK FOR VALID EMAIL ADDRESS -- 
		-- ***************************** --
		IF @ToEmailAddr IS NULL 
			BEGIN
				-- ISSUE: #132507 --
				-- LOG MESSAGE/ERROR --
				SET @msg = 'Could not find valid TO Email address for: ' + ISNULL(@ToUser, 'N/A') + '  ' +
						   'Notification Email could not be sent.'

				INSERT vDDAL(DateTime, HostName, UserName, ErrorNumber, Description, SQLRetCode, UnhandledError, Informational,
							 Assembly, Class, [Procedure], AssemblyVersion, StackTrace, FriendlyMessage, LineNumber, Event, Company,
							 Object, CrystalErrorID, ErrorProcedure)
					  VALUES(current_timestamp, host_name(), suser_name(), error_number(), error_message(), null, 0, 1, 
							'PM', null, 'vspPMProjectEmail', null, null, @msg, error_line(), null, null, 
							null, null, null)

			END
		ELSE
			BEGIN
				-- ******************** --
				-- SET UP EMAIL MESSAGE --
				-- ******************** -- 
				SET @EmailSubject = 'New Note Added for Project #' + ISNULL(@ProjNum, 'N/A')
				SET @EmailBody = 'Company #' + ISNULL(@CoNum, 'N/A') + char(10) +
								 'Company Name: ' + ISNULL(@CoName, 'N/A') + char(10) +
								 'Project #' + ISNULL(@ProjNum, 'N/A') + char(10) +
								 'Project Name: ' + ISNULL(@ProjName, 'N/A') + char(10) +
								 'Added By: ' + ISNULL(@AddedBy, 'N/A') + char(10) +
								 'Added Date: ' + ISNULL(CONVERT(CHAR(10),@AddedDate, 110), 'N/A') + char(10) + --(110 -> mm-dd-yyy)
								 'Changed By: ' + ISNULL(@ChangedBy, 'N/A') + char(10) +
								 'Changed Date: ' + ISNULL(CONVERT(CHAR(10), @ChangedDate, 110), 'N/A') + char(10) + char(10) + char(10) + --(110 -> mm-dd-yyy)
								 'You have project notes to review.  Please run the PM Notes Review form.'


				-- ****************************** --
				-- INSERT NOTIFICATION TO BE SENT --
				-- ************************************************************************* --
				-- IF Source IS NULL -> vMailQueue will route to default preference          --
				-- IF @FromEmailAddr -> vMailQueue will use the system default email address --
				-- ************************************************************************* --
				INSERT INTO vMailQueue([To], [From], [Subject], Body, Source) 
					 VALUES (@ToEmailAddr, @FromEmailAddr, @EmailSubject, @EmailBody, @NotifySource)


				-- RETURN SUCCESS --
				RETURN @rcode
			END

END TRY

BEGIN CATCH
	-- RETURN FAILURE --
	SET @rcode = 1
	SET @msg = ERROR_MESSAGE()

END CATCH

GO
GRANT EXECUTE ON  [dbo].[vspPMProjectEmail] TO [public]
GO
