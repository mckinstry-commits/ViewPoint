SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE procedure [dbo].[vspHRPTORequestUpdate]
CREATE procedure [dbo].[vspHRPTORequestUpdate]

/************************************************************************
* CREATED:	Dan Sochacki 01/10/2008     
* MODIFIED:    
*
* USAGE:
*	Update PTO/Leave Request(s) in the HRES table.
*
******* Due to localization, the word "PTO" has been changed
******* to "Leave" anywhere it would be displayed to the User.
*  
*           
* INPUT PARAMETERS:
*	@HRCo		-- Company
*	@Requests	-- Request information in XML format
*				-- <Requests>
*						<Request HRRef="99699" KeyID="900" Date="2007-09-20" ReqStatus="A" AppComment="Approver Comment" UpdatedByVPName="danso" Source="HRPTOApp"></Request>
*				-- </Requests>
*		@HRRef				-- Resource Number of person requesting PTO/Leave
*		@KeyID				-- Key field of HRES table
*		@Date				-- Date to take PTO/Leave
*		@ReqStatus			-- Request Status - (N)ew, (A)pproved, (D)enied, (C)anceled
*		@AppComment			-- Approver Comment
*		@UpdateByVPName		-- Approver Name who updated request
*		@Source				-- Form Name that updated reqeust
*
* OUTPUT PARAMETERS:
*	@errmsg				-- Error Message
*
* RETURN VALUES:
*   @rcode				-- 0 - Success, 1 - Failure
*************************************************************************/
	(@HRCo bCompany = NULL, @Requests XML = NULL, 
	 @errmsg VARCHAR(255) OUTPUT)

AS
   
SET NOCOUNT ON
	
	DECLARE	@HRRef				bHRRef,
			@KeyID				bigint, 
			@Date				datetime, 
			@ReqStatus			char(1), 
			@ReqStatusDesc		varchar(10),
			@AppComment			varchar(255), 
			@UpdatedByVPName	bVPUserName, 
			@UpdatedByName		varchar(75),
			@Source				char(10),
			@OldHRRef			bHRRef,
			@EmailName			varchar(75),
			@EmailSubject		varchar(500),
			@EmailBody			varchar(MAX),
			@RowCnt				int,
			@MaxRows			int,
			@rcode				int;	


	--------------------------------
	-- CHECK FOR INPUT PARAMETERS --
	--------------------------------
	IF (@HRCo IS NULL) OR
		(@Requests IS NULL)
		BEGIN
			SELECT @rcode = 1, @errmsg = 'Missing Input Parameter(s).'
			GOTO vspExit
		END

	-------------------------------------------------------------
	-- SET UP 'IN MEMORY' TABLE TO HOLD XML PTO/Leave REQUESTS --
	-------------------------------------------------------------
	DECLARE @ReqTable TABLE 
			(RowID				int		IDENTITY,
			 HRRef				bHRRef, 
			 KeyID				bigint, 
			 Date				datetime, 
			 ReqStatus			char(1), 
			 AppComment			varchar(255), 
			 UpdatedByVPName	bVPUserName, 
			 Source				char(10))

	------------------------------
	-- LOAD XML DATA INTO TABLE --
	------------------------------
	INSERT INTO @ReqTable
		 SELECT	HRRef = T.Item.value('@HRRef', 'bHRRef'),
				KeyID = T.Item.value('@KeyID', 'bigint'),
				Date  = T.Item.value('@Date',  'datetime'),
				ReqStatus = T.Item.value('@ReqStatus', 'char(1)'),
				AppComment  = T.Item.value('@AppComment',  'varchar(255)'),
				UpdatedByVPName = T.Item.value('@UpdatedByVPName', 'bVPUserName'),
				Source = T.Item.value('@Source', 'char(10)')
		   FROM @Requests.nodes('Requests/Request') AS T(Item)
	   ORDER BY HRRef, Date


	----------------------------------------------------
	-- GET UPDATE BY NAME "ONCE" - FirstName LastName --
	---------------------------------------------------------------------
	-- All records from the Approval Form will have the same Approver. --
	---------------------------------------------------------------------
	SELECT	@UpdatedByName = h.FirstName + ' ' +  h.LastName
	  FROM	HRRM h
      JOIN	DDUP d on h.HRCo = d.HRCo AND h.HRRef = d.HRRef
	 WHERE	h.HRCo = @HRCo
	   AND	d.VPUserName = (SELECT UpdatedByVPName FROM @ReqTable WHERE RowID = 1)

	------------------
	-- PRIME VALUES --	
	------------------
	SET @OldHRRef = ''
	SET @RowCnt = 1
	SET @rcode = 0
	SET @EmailSubject = ''
	SET @EmailBody = ''
	SELECT @MaxRows = COUNT(*) FROM @ReqTable


	-------------------------------
	-- LOOP THROUGH ALL REQUESTS --
	-------------------------------
	WHILE @RowCnt <= @MaxRows
		BEGIN

			------------------------------
			-- GET REQUESST INFORMATION --
			------------------------------
			SELECT	@HRRef = HRRef, @KeyID = KeyID, @Date = Date, @ReqStatus = ReqStatus, 
					@AppComment = AppComment, @UpdatedByVPName = UpdatedByVPName, @Source = Source
			  FROM  @ReqTable
		     WHERE	RowID = @RowCnt

			-------------------
			-- UPDATE RECORD --
			-------------------
			UPDATE	HRES
			   SET	[Status] = @ReqStatus, 
					ApproverComment = @AppComment,
					Approver = @UpdatedByVPName,
					Source = @Source
			 WHERE	KeyID = @KeyID

			----------------------------
			-- GET STATUS DESCRIPTION --
			---------------------------- 
			SELECT @ReqStatusDesc = 
				CASE @ReqStatus
					WHEN 'N' THEN 'New'
					WHEN 'A' THEN 'Approved'
					WHEN 'D' THEN 'Denied'
					WHEN 'C' THEN 'Canceled'
					ELSE 'Unknown'
				END

			--------------------------------
			-- CHECK FOR APPROVER COMMENT --
			--------------------------------
			IF @AppComment = ''
				BEGIN
					SET @AppComment = 'No Comments Supplied.'
				END

			-----------------------------------------------------------------------
			-- DOES THE SAME PERSON/RESOURCE HAVE ANOTHER UPDATED REQUEST/RECORD --
			-----------------------------------------------------------------------
			IF (@OldHRRef <> @HRRef) 
				BEGIN
					-----------------------------
					-- SEND EMAIL TO OLD HRREF --
					-----------------------------
					EXECUTE @rcode = vspHRPTOEmail @HRCo, @OldHRRef, @UpdatedByVPName, 'R', @EmailSubject, @EmailBody, @errmsg
					
					---------------------
					-- START NEW EMAIL --
					---------------------
					SET @EmailSubject = 'Leave Request(s) *** Updated ***'
					SET @EmailBody = 'Leave request(s) updated by ' + @UpdatedByName + '.' + CHAR(10) + CHAR(10)
					SET @EmailBody = @EmailBody + 'Date: ' + CONVERT(CHAR(10), @Date, 120) + ' ---> ' + @ReqStatusDesc + '  Comments: ' + @AppComment + CHAR(10) 

					--------------------
					-- RESET RESOURCE --
					--------------------
					SET @OldHRRef = @HRRef

				END
			ELSE
				BEGIN
					-------------------------------
					-- ADD DETAILS TO EMAIL BODY --
					-------------------------------
					SET @EmailBody = @EmailBody + 'Date: ' + CONVERT(CHAR(10), @Date, 120) + ' ---> ' + @ReqStatusDesc + '  Comments: ' + @AppComment + CHAR(10) 

				END

			----------------------
			-- UPDATE ROW COUNT --
			----------------------
			SET @RowCnt = @RowCnt + 1

		END -- WHILE @RowCnt <= @MaxRows


	---------------------
	-- SEND LAST EMAIL --
	---------------------
	EXECUTE @rcode = vspHRPTOEmail @HRCo, @OldHRRef, @UpdatedByVPName, 'R', @EmailSubject, @EmailBody, @errmsg 



RETURN @rcode

vspExit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRPTORequestUpdate] TO [public]
GO
