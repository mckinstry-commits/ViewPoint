CREATE TABLE [dbo].[bHRES]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NOT NULL,
[Date] [dbo].[bDate] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[ScheduleCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Seq] [tinyint] NOT NULL CONSTRAINT [DF_bHRES_Seq] DEFAULT ((1)),
[Hours] [dbo].[bHrs] NOT NULL CONSTRAINT [DF_bHRES_Hours] DEFAULT ((0)),
[Status] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bHRES_Status] DEFAULT ('A'),
[Source] [char] (10) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bHRES_Source] DEFAULT ('HRSched'),
[RequesterComment] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[ApproverComment] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[Approver] [dbo].[bVPUserName] NULL,
[UpdatedBy] [dbo].[bVPUserName] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*-----------------------------------------------------------------
* Created: Dan So 01/03/2008
* Modified: 
*
*	Delete trigger on HR Resource table.
*
*/----------------------------------------------------------------
--CREATE TRIGGER [dbo].[btHRESd] ON  [dbo].[bHRES] FOR DELETE 
CREATE  TRIGGER [dbo].[btHRESd] ON [dbo].[bHRES] FOR DELETE 
AS

	DECLARE	@lChgSrc		varchar(10),
			@numrows		int,
			@errmsg			varchar(255), 
			@rcode			int;
			

	SELECT @numrows = @@rowcount
	IF @numrows = 0 RETURN

	SET NOCOUNT ON


	------------------
	-- INSERT AUDIT --
	------------------
	INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		 SELECT 'bHRES', 
				'HRCo: ' + ISNULL(CONVERT(CHAR(3), d.HRCo),0) + 
				'  HRRef: ' + ISNULL(CONVERT(VARCHAR, d.HRRef),0) + 
				'  Date: ' + ISNULL(CONVERT(CHAR(10), d.Date, 110), '??') + 
				'  Seq: ' + ISNULL(CONVERT(CHAR(3), d.Seq),0),
				d.HRCo, 'D', '', NULL, NULL, getdate(), SUSER_SNAME() 
		   FROM Deleted d JOIN bHRCO h ON d.HRCo = h.HRCo
		  WHERE h.AuditPTOYN = 'Y'


 RETURN
     
 Error:
 	SELECT @errmsg = @errmsg + ' - cannot delete HR Resource Schedule!'
    RAISERROR(@errmsg, 11, -1);
    ROLLBACK TRANSACTION






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*-----------------------------------------------------------------
* Created: Dan So 02/25/2008
* Modified: Dan So 07/18/2012 - TK-16449 - Enabled Leave requested from Connects to send email
*
*	Insert trigger on HR Resource table.
*
*
******* Due to localization, the word "PTO" has been changed
******* to "Leave" anywhere it would be displayed to the User.
*
*/----------------------------------------------------------------
--CREATE TRIGGER [dbo].[btHRESi] ON  [dbo].[bHRES] FOR INSERT 
CREATE  TRIGGER [dbo].[btHRESi] ON [dbo].[bHRES] FOR INSERT 
AS

	DECLARE		@lHRCo			bCompany,
				@lHRRef			bHRRef,
				@lSrc			varchar(10),
				@lDate			datetime,
				@lCode			varchar(10),
				@lHours			bHrs,
				@EmailSubject	varchar(500),
				@EmailBody		varchar(3000),
				@EmailBodyA		varchar(3000),
				@EmailName		varchar(75),
				@lPTODay		varchar(50),
				@lReqComm		varchar(255),
				@lAppComm		varchar(255),
				@lStatus		char(1),
				@lStatusDesc	varchar(10),
				@lBHRRef		bHRRef,
				@lBEmailName	varchar(75),
				@lReqVPName		bVPUserName,
				@openHREScursor int,
				@numrows		int,
				@ValCnt			int,
				@lErcode		int,
				@lEerrmsg		varchar(255),
				@errmsg			varchar(255), 
				@rcode			int;
			

	SELECT @numrows = @@rowcount
	IF @numrows = 0 RETURN

	SET NOCOUNT ON

	SET @rcode = 0

	---------------------
	-- VALIDATE STATUS --
	---------------------
	SELECT @ValCnt = COUNT(*) 
      FROM Inserted i
     WHERE i.Status in ('N', 'A', 'D', 'C')

	IF @ValCnt <> @numrows 
		BEGIN
  			SELECT @errmsg = 'Invalid Status - Status must be N, A, D, or C)'
  			GOTO Error
		END

	----------------------------
	-- VALIDATE SCHEDULE CODE --
	----------------------------
	SELECT @ValCnt = COUNT(*) 
      FROM bHRCM m WITH (NOLOCK)
      JOIN Inserted i 
        ON m.HRCo = i.HRCo AND m.Code = i.ScheduleCode and m.Type = 'C'

	IF @ValCnt  <> @numrows 
		BEGIN
  			SELECT @errmsg = 'Invalid Schedule Code HRES: ' + cast(@ValCnt as varchar(10))
  			GOTO Error
		END


	--Set the UpdatedBy value
	update bHRES set UpdatedBy = SUSER_SNAME()
	from inserted i join bHRES s on i.HRCo = s.HRCo and i.HRRef = s.HRRef and i.Date = s.Date

	-------------------
	-- SET UP CURSOR --
	-------------------
	DECLARE cur_HRES CURSOR LOCAL FAST_FORWARD FOR
		SELECT HRCo, HRRef, Date, ScheduleCode, Hours, Status, RequesterComment, ApproverComment, Source
		  FROM Inserted

	------------------
	-- PRIME VALUES --
	------------------
	OPEN cur_HRES
	SELECT @openHREScursor = 1

	FETCH NEXT FROM cur_HRES
		INTO @lHRCo, @lHRRef, @lDate, @lCode, @lHours, @lStatus, @lReqComm, @lAppComm, @lSrc

	-------------------------
	-- LOOP THROUGH CURSOR --
	-------------------------
	WHILE @@FETCH_STATUS = 0
		BEGIN

			-- *********************** --
			-- CREATE EMAIL TO BE SENT --
			-- *********************** --

			------------------------------
			-- REQUESTED PTO/LEAVE DATE --
			------------------------------
			SET @lPTODay = CONVERT(CHAR(10), @lDate, 110)

			-----------------------------------------------------
			-- NAME OF PERSON THAT IS TAKING THE PTO/LEAVE DAY --
			-----------------------------------------------------
			SELECT @EmailName = ISNULL(FirstName, '') + ' ' + ISNULL(LastName, '')
			  FROM HRRM 
			 WHERE HRCo = @lHRCo AND HRRef = @lHRRef


			---------------------------------------------------------------------------------
			-- IS THE REQUEST COMING FROM THE ACTUAL REQUESTER - HR PTO/LEAVE REQUEST FORM --
			---------------------------------------------------------------------------------
			--IF UPPER(@lSrc) = 'HRPTOREQ' 
				-- **************************************************
				-- INSERT EMAILS HANDLED IN vspHRPTORequestInsert.sql
				-- **************************************************

			------------------------------------------------------------------------------------------
			-- IS THE REQUEST COMING FROM THE ACTUAL REQUESTER - HR PTO/LEAVE (M)ASTER REQUEST FORM --
			------------------------------------------------------------------------------------------
			IF (UPPER(@lSrc) = 'HRPTOMREQ')  OR (UPPER(@lSrc) = 'HRPTOREQVC')  -- TK-16449 -- 
				BEGIN
					-----------------------
					-- CREATE EMAIL BODY --
					-----------------------
					SELECT @EmailSubject = 'Leave Request from ' + @EmailName
					SELECT @EmailBody = @EmailName + ' (HR Resource #' + CAST(@lHRRef AS VARCHAR(10)) + ') has submitted a Leave request via Viewpoint.'
					SELECT @EmailBody = @EmailBody + CHAR(10) + CHAR (10) + 'Date: ' + @lPTODay
					SELECT @EmailBody = @EmailBody + CHAR(10) + 'Code: ' + @lCode
					SELECT @EmailBody = @EmailBody + CHAR(10) + 'Hours: ' + CAST(@lHours AS VARCHAR(10))

					IF (@lReqComm IS NULL) OR
						@lReqComm = ''
						BEGIN
							SET @lReqComm = 'No Comments Supplied.'
						END

					SELECT @EmailBody = @EmailBody + CHAR(10) + 'Requester Comment: ' + @lReqComm
					SELECT @EmailBody = @EmailBody + CHAR(10) + CHAR(10) + CHAR (10) + 'To Approve or Decline this request, please run the Leave Approvals form.'

					------------------------------
					-- SEND EMAIL TO (A)PPROVER --
					------------------------------
					EXECUTE @rcode = vspHRPTOEmail @lHRCo, @lHRRef, '', 'A', @EmailSubject, @EmailBody, @errmsg 

				END

			------------------------------------------------------------------------------------------------------
			-- IS THE REQUEST BEING MADE BY SOMEONE OTHER THAN THE ACUTAL REQUESTER - HR RESOURCE SCHEDULE FORM --
			------------------------------------------------------------------------------------------------------
			IF UPPER(@lSrc) = 'HRSCHED'
				BEGIN
					----------------------------------------
					-- MAKE SURE CODE IS A PTO/LEAVE CODE --
					----------------------------------------
					EXECUTE @lErcode = vspHRPTOCodeVal @lHRCo, @lCode, @lEerrmsg OUTPUT

					IF @lErcode = 0
						BEGIN
							---------------------------------------------------
							-- GET HRREF OF PERSON SUBMITTING THE REQUESTING --
							---------------------------------------------------
							EXECUTE @lErcode = vspHRGetResFromVPUser @lHRCo, @lBHRRef OUTPUT, @lEerrmsg OUTPUT

							IF @lErcode = 0
								BEGIN

									SELECT @EmailSubject = 'Leave has been entered for ' + @EmailName 

									-----------------------------------------------
									-- GET NAME OF PERSON SUBMITTING THE REQUEST --
									-----------------------------------------------
									SELECT @lBEmailName = ISNULL(FirstName, '') + ' ' + ISNULL(LastName, '')
									  FROM HRRM 
									 WHERE HRCo = @lHRCo AND HRRef = @lBHRRef

									----------------------------
									-- SET STATUS DESCRIPTION --
									----------------------------
									SELECT @lStatusDesc = 
										CASE @lStatus
											WHEN 'N' THEN 'New'
											WHEN 'A' THEN 'Approved'
											WHEN 'D' THEN 'Denied'
											WHEN 'C' THEN 'Canceled'
											ELSE 'Unknown'
										END

									-----------------------
									-- CREATE EMAIL BODY --
									-----------------------
									SELECT @EmailBody = ISNULL(@lBEmailName, 'N/A') + ' has entered Leave for '
									SELECT @EmailBody = @EmailBody + @EmailName + ' (HR Resource #' + CAST(@lHRRef AS VARCHAR(10)) + ') via Viewpoint.'
									SELECT @EmailBody = @EmailBody + CHAR(10) + CHAR (10) + 'Date: ' + @lPTODay
									SELECT @EmailBody = @EmailBody + CHAR(10) + 'Code: ' + @lCode
									SELECT @EmailBody = @EmailBody + CHAR(10) + 'Hours: ' + CAST(@lHours AS VARCHAR(10))

									IF (@lAppComm IS NULL) OR
										@lAppComm = ''
										BEGIN
											SET @lAppComm = 'No Comments Supplied.'
										END

									SELECT @EmailBody = @EmailBody + CHAR(10) + 'Approver Comment: ' + @lAppComm
									SELECT @EmailBody = @EmailBody + CHAR(10) + 'Status: ' + @lStatusDesc
									
									SELECT @EmailBodyA = @EmailBody
									-------------------------------------------------------
									-- ONLY FOR NEW REQUESTS SENT TO THE GROUP APPROVERS --
									-------------------------------------------------------
									IF @lStatus = 'N' 
										BEGIN
											SELECT @EmailBodyA = @EmailBody + CHAR(10) + CHAR(10) + CHAR (10) + 'To Approve or Decline this request, please run the Leave Approvals form.'
										END
									
									------------------------------------------
									-- GET VPUserName OF WOULD BE REQUESTER --
									------------------------------------------
									SELECT @lReqVPName = VPUserName 
									  FROM DDUP 
									 WHERE HRCo = @lHRCo AND HRRef = @lHRRef

									-------------------------------------------------------
									-- SEND EMAIL TO (A)PPROVER AND WOULD BE (R)EQUESTER --
									-------------------------------------------------------
									EXECUTE @rcode = vspHRPTOEmail @lHRCo, @lHRRef, '', 'A', @EmailSubject, @EmailBodyA, @errmsg 
									EXECUTE @rcode = vspHRPTOEmail @lHRCo, @lHRRef, @lReqVPName, 'R', @EmailSubject, @EmailBody, @errmsg
								
								END -- IF @lErcode = 0
						END -- IF @lErcode = 0
				END -- IF UPPER(@lSrc) = 'HRRESSCHED'

			---------------------
			-- GET NEXT RECORD --
			---------------------
			FETCH NEXT FROM cur_HRES
				INTO @lHRCo, @lHRRef, @lDate, @lCode, @lHours, @lStatus, @lReqComm, @lAppComm, @lSrc

		END -- WHILE @@FETCH_STATUS = 0

	-----------------------------
	-- CLOSE AND REMOVE CURSOR --
	-----------------------------
	IF @openHREScursor = 1
		BEGIN	
			CLOSE cur_HRES
			DEALLOCATE cur_HRES
			SELECT @openHREScursor = 0
		END


	-------------------
	-- INSERT AUDITS --
	-------------------
	INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		 SELECT 'bHRES', 
			    'HRCo: ' + CONVERT(CHAR(3), i.HRCo) + 
			    '  HRRef: ' + CONVERT(VARCHAR, i.HRRef) + 
			    '  Date: ' + CONVERT(CHAR(10), i.Date, 110) + 
			    '  Seq: ' + CONVERT(CHAR(3), i.Seq),
				i.HRCo, 'A', '', NULL, NULL, getdate(), SUSER_SNAME() 
		   FROM Inserted i JOIN bHRCO h ON i.HRCo = h.HRCo
		  WHERE h.AuditPTOYN = 'Y'


 RETURN      

 Error:

	-----------------------------
	-- CLOSE AND REMOVE CURSOR --
	-----------------------------
	IF @openHREScursor = 1
		BEGIN	
			CLOSE cur_HRES
			DEALLOCATE cur_HRES
			SELECT @openHREScursor = 0
		END

	------------------------------
	-- RETURN ERROR INFORMATION --
	------------------------------
 	SELECT @errmsg = @errmsg + ' - cannot update HR Resource Schedule!'
    RAISERROR(@errmsg, 11, -1);
    ROLLBACK TRANSACTION






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*-----------------------------------------------------------------
* Created: Dan So 01/03/2008
* Modified: Dan So 07/18/2012 - TK-16449 - Enabled Leave requested from Connects to send email
*
*	Update trigger on HR Resource table.
*
******* Due to localization, the word "PTO" has been changed
******* to "Leave" anywhere it would be displayed to the User.
*
*/----------------------------------------------------------------
--CREATE TRIGGER [dbo].[btHRESu] ON  [dbo].[bHRES] FOR UPDATE 
CREATE  TRIGGER [dbo].[btHRESu] ON [dbo].[bHRES] FOR UPDATE 
AS

	DECLARE		@lHRCo			bCompany,
				@lHRRef			bHRRef,
				@lSrc			varchar(10),
				@lDate			datetime,
				@lCode			varchar(10),
				@EmailSubject	varchar(500),
				@EmailBody		varchar(3000),
				@EmailBodyA		varchar(3000),
				@EmailName		varchar(75),
				@lPTODay		varchar(50),
				@lReqComm		varchar(255),
				@lAppComm		varchar(255),
				@lStatus		char(1),
				@lStatusDesc	varchar(10),
				@lDescription	bDesc,
				@lHours			bHrs,
				@lBHRRef		bHRRef,
				@lBEmailName	varchar(75),
				@lReqVPName		bVPUserName,
				@lUpdates		varchar(1000),
				@openHREScursor int,
				@numrows		int,
				@ValCnt			int,
				@lErcode		int,
				@lEerrmsg		varchar(255),
				@errmsg			varchar(255), 
				@rcode			int;


	SELECT @numrows = @@rowcount
	IF @numrows = 0 RETURN

	SET NOCOUNT ON

	SET @rcode = 0

	if update(UpdatedBy)
	begin
		return
	end

	---------------------
	-- VALIDATE STATUS --
	---------------------
	SELECT @ValCnt = COUNT(*) 
      FROM Inserted i
     WHERE i.Status in ('N', 'A', 'D', 'C')

	IF @ValCnt <> @numrows 
		BEGIN
  			SELECT @errmsg = 'Invalid Status - Status must be N, A, D, or C)'
  			GOTO Error
		END

	----------------------------
	-- VALIDATE SCHEDULE CODE --
	----------------------------
	SELECT @ValCnt = COUNT(*) 
      FROM bHRCM m WITH (NOLOCK)
      JOIN Inserted i 
        ON m.HRCo = i.HRCo AND m.Code = i.ScheduleCode and m.Type = 'C'

	IF @ValCnt <> @numrows 
		BEGIN
  			SELECT @errmsg = 'Invalid Schedule Code HRES: ' + cast(@ValCnt as varchar(10))
  			GOTO Error
		END


	--Set the UpdatedBy value
	update bHRES set UpdatedBy = SUSER_SNAME()
	from inserted i join bHRES s on i.HRCo = s.HRCo and i.HRRef = s.HRRef and i.Date = s.Date

	-------------------
	-- SET UP CURSOR --
	-------------------
	DECLARE cur_HRES CURSOR LOCAL FAST_FORWARD FOR
	SELECT  i.HRCo, i.HRRef, i.Date, i.ScheduleCode, i.Description, i.Hours, i.Status, 
			i.RequesterComment, i.ApproverComment, i.Source
	  FROM  Inserted i
	  JOIN  Deleted d on d.HRCo = i.HRCo and d.HRRef = i.HRRef and d.Date = i.Date and d.Seq = i.Seq

	------------------
	-- PRIME VALUES --
	------------------
	OPEN cur_HRES
   	SELECT @openHREScursor = 1

	FETCH NEXT FROM cur_HRES
		INTO @lHRCo, @lHRRef, @lDate, @lCode, @lDescription, @lHours, @lStatus, 
             @lReqComm, @lAppComm, @lSrc

	-------------------------
	-- LOOP THROUGH CURSOR --
	-------------------------
	WHILE @@FETCH_STATUS = 0
		BEGIN

			-- *********************** --
			-- CREATE EMAIL TO BE SENT --
			-- *********************** --

			------------------------------
			-- REQUESTED PTO/LEAVE DATE --
			------------------------------
			SET @lPTODay = CONVERT(CHAR(10), @lDate, 110)

			-----------------------------
			-- CREATE EMAIL TO BE SENT --
			-----------------------------
			SET @lUpdates = 'Date: ' + @lPTODay + CHAR(10)

			-----------------------
			-- CHECK FOR UPDATES --
			-----------------------
			IF UPDATE(ScheduleCode)
				BEGIN
					SET @lUpdates =  'Leave Type: ' + ISNULL(@lCode, 'N/A') + CHAR(10)
				END

			IF UPDATE(Hours)
				BEGIN
					SET @lUpdates = @lUpdates + 'Hours Per Day: ' + ISNULL(CAST(@lHours AS VARCHAR(5)), 'N/A') + CHAR(10)
				END

			IF UPDATE(Description)
				BEGIN
					SET @lUpdates =  @lUpdates + 'Description: ' + ISNULL(@lDescription, 'N/A') + CHAR(10)
				END

			IF UPDATE(RequesterComment) 
				BEGIN
					SET @lUpdates = @lUpdates + 'Requester Comment: ' + ISNULL(@lReqComm, 'No Comments Supplied.') + CHAR(10) 
				END

			IF UPDATE(ApproverComment)
				BEGIN
					SET @lUpdates = @lUpdates + 'Approver Comment: ' + ISNULL(@lAppComm, 'No Comments Supplied.') + CHAR(10)
				END

			IF UPDATE([Status]) 
				BEGIN
					SELECT @lStatusDesc = 
						CASE @lStatus
							WHEN 'N' THEN 'New'
							WHEN 'A' THEN 'Approved'
							WHEN 'D' THEN 'Denied'
							WHEN 'C' THEN 'Canceled'
							ELSE 'Unknown'
						END

					SET @lUpdates = @lUpdates + 'Status: ' + ISNULL(@lStatusDesc, 'N/A') + CHAR(10) 
				END

			------------------------
			-- GET REQUESTER NAME --
			------------------------
			SELECT @EmailName = ISNULL(FirstName, '') + ' ' + ISNULL(LastName, '')
			  FROM HRRM 
			 WHERE HRCo = @lHRCo AND HRRef = @lHRRef


			-------------------------------------------------------------------------------------
			-- IS THE REQUEST BEING APPROVED FROM APPROVAL SCREEN - HR PTO/LEAVE APPROVAL FORM --
			-------------------------------------------------------------------------------------
			--IF UPPER(@lSrc) = 'HRPTOAPP' 
				-- **************************************************
				-- UPDATE EMAILS HANDLED IN vspHRPTORequestUpdate.sql
				-- **************************************************


			-----------------------------------------------------------------------------------------
			-- IS THE UPDATE COMING FROM THE ACTUAL REQUESTER - HR PTO/LEAVE (M)ASTER REQUEST FORM --
			-----------------------------------------------------------------------------------------
			IF (UPPER(@lSrc) = 'HRPTOMREQ') OR (UPPER(@lSrc) = 'HRPTOREQVC')  -- TK-16449 --
				BEGIN
					-----------------------
					-- CREATE EMAIL BODY --
					-----------------------
						BEGIN

							-------------------
							-- EMAIL SUBJECT --
							-------------------
							SELECT @EmailSubject = 'Leave Request *** Updated ***'

							----------------
							-- EMAIL BODY --
							----------------
							SELECT @EmailBody = 'Leave request updated by ' + @EmailName + '.' 
							SELECT @EmailBody = @EmailBody + CHAR(10) + CHAR (10) + @lUpdates

							IF @lStatus = 'N'
								BEGIN
									SELECT @EmailBody = @EmailBody + CHAR(10) + CHAR(10) + CHAR (10) + 'To Approve or Decline this request, please run the Leave Approvals form.'
								END
						END

					------------------------------
					-- SEND EMAIL TO (A)PPROVER --
					------------------------------
					EXECUTE @rcode = vspHRPTOEmail @lHRCo, @lHRRef, '', 'A', @EmailSubject, @EmailBody, @errmsg 

				END

			-----------------------------------------------------------------------------------------------------
			-- IS THE UPDATE BEING MADE BY SOMEONE OTHER THAN THE ACUTAL REQUESTER - HR RESOURCE SCHEDULE FORM --
			-----------------------------------------------------------------------------------------------------
			IF UPPER(@lSrc) = 'HRSCHED'
				BEGIN
					----------------------------------------
					-- MAKE SURE CODE IS A PTO/LEAVE CODE --
					----------------------------------------
					EXECUTE @lErcode = vspHRPTOCodeVal @lHRCo, @lCode, @lEerrmsg OUTPUT

					IF @lErcode = 0
						BEGIN
							-------------------------------------------------
							-- GET HRREF OF PERSON UPDATING THE REQUESTING --
							-------------------------------------------------
							EXECUTE @lErcode = vspHRGetResFromVPUser @lHRCo, @lBHRRef OUTPUT, @lEerrmsg OUTPUT

							IF @lErcode = 0
								BEGIN

									---------------------------------------------
									-- GET NAME OF PERSON UPDATING THE REQUEST --
									---------------------------------------------
									SELECT @lBEmailName = ISNULL(FirstName, '') + ' ' + ISNULL(LastName, '')
									  FROM bHRRM 
									 WHERE HRCo = @lHRCo AND HRRef = @lBHRRef

									-------------------
									-- EMAIL SUBJECT --
									-------------------
									SELECT @EmailSubject = 'Leave Request *** Updated ***'

									----------------
									-- EMAIL BODY --
									---------------- 
									SELECT @EmailBody = 'Leave request updated by ' + @lBEmailName + '.' 
									SELECT @EmailBody = @EmailBody + CHAR(10) + CHAR (10) + @lUpdates

									SELECT @EmailBodyA = @EmailBody
									-------------------------------------------------------
									-- ONLY FOR NEW REQUESTS SENT TO THE GROUP APPROVERS --
									-------------------------------------------------------
									IF @lStatus = 'N' 
										BEGIN
											SELECT @EmailBodyA = @EmailBody + CHAR(10) + CHAR(10) + CHAR (10) + 'To Approve or Decline this request, please run the Leave Approvals form.'
										END

									------------------------------------------
									-- GET VPUserName OF WOULD BE REQUESTER --
									------------------------------------------
									SELECT @lReqVPName = VPUserName 
									  FROM vDDUP 
									 WHERE HRCo = @lHRCo AND HRRef = @lHRRef

									-------------------------------------------------------
									-- SEND EMAIL TO (A)PPROVER AND WOULD BE (R)EQUESTER --
									-------------------------------------------------------
									EXECUTE @rcode = vspHRPTOEmail @lHRCo, @lHRRef, '', 'A', @EmailSubject, @EmailBodyA, @errmsg 
									EXECUTE @rcode = vspHRPTOEmail @lHRCo, @lHRRef, @lReqVPName, 'R', @EmailSubject, @EmailBody, @errmsg
								
								END -- @lErcode = 0
						END -- @lErcode = 0
				END -- IF UPPER(@lSrc) = 'HRRESSCHED'

			---------------------
			-- GET NEXT RECORD --
			---------------------
			FETCH NEXT FROM cur_HRES
				INTO @lHRCo, @lHRRef, @lDate, @lCode, @lDescription, @lHours, @lStatus, 
					 @lReqComm, @lAppComm, @lSrc

		END -- WHILE @@FETCH_STATUS = 0

	-----------------------------
	-- CLOSE AND REMOVE CURSOR --
	-----------------------------
	IF @openHREScursor = 1
		BEGIN	
			CLOSE cur_HRES
			DEALLOCATE cur_HRES
			SELECT @openHREScursor = 0
		END


	-------------------
	-- INSERT AUDITS --
	-------------------
	IF UPDATE([Status])
		BEGIN
			INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
				SELECT 'bHRES', 
					   'HRCo: ' + CONVERT(CHAR(3), i.HRCo) + 
					   '  HRRef: ' + CONVERT(VARCHAR, i.HRRef) + 
					   '  Date: ' + CONVERT(CHAR(10), i.Date, 110) + 
					   '  Seq: ' + CONVERT(CHAR(3), i.Seq),
						i.HRCo, 'C', 'Status', d.Status, i.Status, getdate(), SUSER_SNAME() 
				  FROM inserted i
				  JOIN deleted d ON i.HRCo = d.HRCo
				   AND i.HRRef = d.HRRef
				   AND i.Date = d.Date
				   AND i.Seq = d.Seq 
		           JOIN bHRCO h ON i.HRCo = h.HRCo
                    AND h.AuditPTOYN = 'Y'
                  WHERE i.Status <> d.Status
		END

	IF UPDATE(ScheduleCode)
		BEGIN
			INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
				SELECT 'bHRES', 
					   'HRCo: ' + CONVERT(CHAR(3), i.HRCo) + 
					   '  HRRef: ' + CONVERT(VARCHAR, i.HRRef) + 
					   '  RequestDate: ' + CONVERT(CHAR(10), i.Date, 110) + 
					   '  Seq: ' + CONVERT(CHAR(3), i.Seq),
						i.HRCo, 'C', 'ScheduleCode', d.ScheduleCode, i.ScheduleCode, getdate(), SUSER_SNAME() 
				  FROM inserted i
				  JOIN deleted d ON i.HRCo = d.HRCo
				   AND i.HRRef = d.HRRef
				   AND i.Date = d.Date
				   AND i.Seq = d.Seq 
		           JOIN bHRCO h ON i.HRCo = h.HRCo
                    AND h.AuditPTOYN = 'Y'
                  WHERE i.ScheduleCode <> d.ScheduleCode
		END

	IF UPDATE(Hours)
		BEGIN
   			INSERT INTO dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   				 SELECT 'bHRES', 
				   	    'HRCo: ' + ISNULL(CONVERT(CHAR(3), i.HRCo),0) + 
				 	    '  HRRef: ' + ISNULL(CONVERT(VARCHAR, i.HRRef),0) + 
				 	    '  RequestDate: ' + ISNULL(CONVERT(CHAR(10), i.Date, 110), '??') + 
				 	    '  Seq: ' + ISNULL(CONVERT(CHAR(3), i.Seq),0),
						i.HRCo, 'C', 'Hours', d.Hours, i.Hours, getdate(), SUSER_SNAME() 
   				   FROM inserted i
   				   JOIN deleted d ON i.HRCo = d.HRCo
                    AND i.HRRef = d.HRRef
                    AND i.Date = d.Date
				    AND i.Seq = d.Seq 
		           JOIN bHRCO h ON i.HRCo = h.HRCo
                    AND h.AuditPTOYN = 'Y'
                  WHERE i.Hours <> d.Hours
		END

	
 RETURN  
    
 Error:

	------------------------------
	-- CLOSE AND REMOVE CURSORS --
	------------------------------
	IF @openHREScursor = 1
		BEGIN	
			CLOSE cur_HRES
			DEALLOCATE cur_HRES
			SELECT @openHREScursor = 0
		END

	------------------------------
	-- RETURN ERROR INFORMATION --
	------------------------------
 	SELECT @errmsg = @errmsg + ' - cannot update HR Resource Schedule!'
    RAISERROR(@errmsg, 11, -1);
    ROLLBACK TRANSACTION






GO
CREATE UNIQUE CLUSTERED INDEX [biHRES] ON [dbo].[bHRES] ([HRCo], [HRRef], [Date], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRES] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
