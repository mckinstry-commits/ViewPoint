SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspHRPTOEmail]
/**************************************************
* Created:  Dan So 01/02/08
* Modified: markh 07/28/08 - 129146 - Retrieving Approvers from HRAG/HRRM needs to 
*					include HRCo.
*			CC 02/03/2009 - 131588 - Allow resource # to be assigned to multiple records, select first email address.
*			CC 02/26/2009 - 128583 - Set message source
*
* Used by HRES triggers to send email to PTO/Leave Approvers and Requesters.
*
******* Due to localization, the word "PTO" has been changed
******* to "Leave" anywhere it would be displayed to the User.
* 
* Inputs
*	@HRCo				-- Company
*	@HRRes				-- Resource Number
*   @EmailApprOrReq		-- Email (A)pprover or (R)equester
*	@EmailSubject		-- Email Subject
*	@EmailBody			-- EMail Body
*
* Output
*   @rcode
*	@errmsg
*
****************************************************/
	(@HRCo bCompany = NULL, @HRRes bHRRef = NULL, @UpdateByName bVPUserName = NULL,
	 @EmailApprOrReq char(1) = NULL, @EmailSubject varchar(500) = NULL, @EmailBody varchar(MAX) = NULL, 
	 @errmsg varchar(255) output)
AS

SET NOCOUNT ON
 
DECLARE @PriAppvr	bHRRef,
		@PriNotify	bYN,
		@PriEmail	varchar(100),
		@SecAppvr	bHRRef,
		@SecNotify	bYN,
		@SecEmail	varchar(100),
		@ReqEmail	varchar(100),
		@FromEmail	varchar(100),
		@rcode		int;


	SELECT @rcode = 0

	-------------------------------
	-- CHECK FOR INCOMING VALUES --
	-------------------------------
	IF @HRCo IS NULL OR
		@HRRes IS NULL OR
		@EmailApprOrReq IS NULL
		BEGIN
			SELECT @rcode = 1, @errmsg = 'Missing an input parameter.'
			GOTO vspexit
		END

	-- ********** --
	-- SEND EMAIL --
	-- ********** --

	------------------
	-- TO APPROVERS --
	------------------
	IF UPPER(@EmailApprOrReq) = 'A'
		BEGIN

			-- GET APPROVER INFORMATION --
			SELECT @PriAppvr = PriAppvr, @PriNotify = PriNotifyYN, @SecAppvr = SecAppvr, @SecNotify = SecNotifyYN 
			  FROM HRAG 
			 WHERE HRCo = @HRCo and PTOAppvrGrp = (SELECT PTOAppvrGrp 
								    FROM HRRM 
								   WHERE HRCo = @HRCo AND HRRef = @HRRes and HRCo = @HRCo)

			----------
			-- FROM --
			----------
			SELECT @FromEmail = (SELECT TOP 1 EMail 
								   FROM DDUP 
								  WHERE HRCo = @HRCo AND HRRef = @HRRes)

			-- CHECK FOR VALID EMAIL ADDRESS --
			IF @FromEmail IS NULL
				BEGIN
					-- INSERT A BOGUS EMAIL ADDRESS --
					SELECT @FromEmail = 'LeaveSystem@DoNotReply.com'
					SELECT @EmailBody = @EmailBody + CHAR(10) + CHAR(10) + '*** This Employee does NOT HAVE a valid email address - DO NOT REPLY! ***'
				END

			-------------------------
			-- TO PRIMARY APPROVER --
			-------------------------
			IF UPPER(@PriNotify) = 'Y' 
				BEGIN
					SELECT @PriEmail = (SELECT TOP 1 EMail 
										  FROM DDUP 
										 WHERE HRCo = @HRCo AND HRRef = @PriAppvr)

					-- CHECK FOR VALID EMAIL ADDRESS --
					IF @PriEmail IS NOT NULL
						BEGIN
							INSERT INTO vMailQueue([To], [From], [Subject], Body, [Source]) 
							VALUES (@PriEmail, @FromEmail, @EmailSubject, @EmailBody, 'Leave Request');
						END
					ELSE
						BEGIN
							SELECT @rcode = 1, @errmsg = 'Message CAN NOT be sent to Primary Approver - email address is NOT valid!'
						END
				END

			---------------------------
			-- TO SECONDARY APPROVER --
			---------------------------
			IF UPPER(@SecNotify) = 'Y' 
				BEGIN
					SELECT @SecEmail = (SELECT TOP 1 EMail 
										  FROM DDUP 
										 WHERE HRCo = @HRCo AND HRRef = @SecAppvr)

					-- CHECK FOR VALID EMAIL ADDRESS --
					IF @SecEmail IS NOT NULL
						BEGIN
							INSERT INTO vMailQueue([To], [From], Subject, Body, [Source]) 
							VALUES (@SecEmail, @FromEmail, @EmailSubject, @EmailBody,'Leave Request');
						END
					ELSE
						BEGIN
							SELECT @rcode = 1, @errmsg = @errmsg + CHAR(10) + 'Message CAN NOT be sent to Secondary Approver - email address is NOT valid!'
						END
				END

			----------------------
			-- CHECK FOR ERRORS --
			----------------------
			IF @rcode = 1
				BEGIN
					GOTO vspexit
				END
		END

	------------------
	-- TO REQUESTER --
	------------------
	ELSE IF UPPER(@EmailApprOrReq) = 'R'
			BEGIN

				----------
				-- FROM --
				----------
				SELECT @FromEmail = (SELECT TOP 1 EMail 
									   FROM DDUP 
									  WHERE VPUserName = @UpdateByName)

				-- CHECK FOR VALID EMAIL ADDRESS --
				IF @FromEmail IS NULL
					BEGIN
						-- INSERT A BOGUS EMAIL ADDRESS --
						SELECT @FromEmail = 'LeaveSystem@DoNotReply.com'
						SELECT @EmailBody = @EmailBody + CHAR(10) + CHAR(10) + '*** This Employee does NOT HAVE a valid email address - DO NOT REPLY! ***'
					END

				--------
				-- TO --
				--------
				SELECT @ReqEmail = (SELECT TOP 1 EMail 
								      FROM DDUP 
									 WHERE HRCo = @HRCo AND HRRef = @HRRes)

				-- CHECK FOR VALID EMAIL ADDRESS --
				IF @ReqEmail IS NOT NULL
					BEGIN
						INSERT INTO vMailQueue([To], [From], Subject, Body, [Source]) 
						VALUES (@ReqEmail, @FromEmail, @EmailSubject, @EmailBody, 'Leave Request');
					END
				ELSE
					BEGIN
						SELECT @rcode = 1, @errmsg = 'Message CAN NOT be sent to Leave Requester - email address is NOT valid!'
						GOTO vspexit
					END
			END

vspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspHRPTOEmail] TO [public]
GO
