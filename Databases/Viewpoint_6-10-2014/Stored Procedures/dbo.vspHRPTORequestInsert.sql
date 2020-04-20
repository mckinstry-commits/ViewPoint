SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* CREATED:	Dan Sochacki 02/21/2008     
* MODIFIED:    
*
* USAGE:
* This script will insert 1 record for each PTO/Leave day 
*	requested into the bHRES table.  Upon successful
*	insertion - an email will be created and sent to
*	vspHRPTOEmail routine to acutally send the email
*	to the corresponding Approval Group.
*
******* Due to localization, the word "PTO" has been changed
******* to "Leave" anywhere it would be displayed to the User.
*  
* INPUT PARAMETERS:
*	@HRCo		- Company
*	@HRRes		- HR Resource
*	@Desc		- Description of record
*	@PTOCode	- PTO/Leave Code
*	@StartDate	- First Day Requested
*	@EndDate	- Last Day Requested
*	@Hrs		- Hours Per Day
*	@Comments	- Requester Comments
*
* OUTPUT PARAMETERS:
*	@errmsg				-- Error Message
*
* RETURN VALUES:
*   @rcode				-- 0 - Success, 1 - Failure
*************************************************************************/

--CREATE procedure [dbo].[vspHRPTORequestInsert]
CREATE procedure [dbo].[vspHRPTORequestInsert]
	(@HRCo bCompany = NULL, @HRRef bHRRef = NULL, @Desc bDesc, @PTOCode VARCHAR(10) = NULL,
     @StartDate bDate = NULL, @EndDate bDate = NULL, @Hrs bHrs = NULL, @Source VARCHAR(10) = NULL,
	 @Comments VARCHAR(255),
	 @errmsg VARCHAR(255) OUTPUT)
AS 

	DECLARE		@lTempDate		datetime,
				@lCnt			int,
				@lDaysDiff		int,
				@EmailSubject	varchar(500),
				@EmailBody		varchar(3000),
				@EmailName		varchar(75),
				@PTODays		varchar(50),
				@lNewSeq		int,
				@rcode			int;


	--------------------------------
	-- CHECK FOR INPUT PARAMETERS --
	--------------------------------
	IF (@HRCo IS NULL) OR
		(@HRRef IS NULL) OR
		(@PTOCode IS NULL) OR
		(@StartDate IS NULL) OR
		(@EndDate IS NULL) OR
		(@Hrs IS NULL) OR
		(@Source IS NULL)
		BEGIN
			SELECT @rcode = 1, @errmsg = 'Missing input parameter(s).'
			GOTO vspExit
		END

	----------------
	-- SET VALUES --
	----------------
	SET @rcode = 0
	SET @lDaysDiff = 0
	SET @lCnt = 0
	SET @EmailBody = ' (HR Resource #' + CAST(@HRRef AS VARCHAR(10)) + ') has submitted Leave request(s) via Viewpoint.' + CHAR(10) 
	
	------------------------
	-- GET NUMBER OF DAYS --
	------------------------
	SELECT @lDaysDiff = DATEDIFF(DAY, @StartDate, @EndDate) 

	-------------------------------
	-- CYCLE THROUGH ALL RECORDS --
	-------------------------------
	WHILE (@lCnt <= @lDaysDiff)
		BEGIN

			------------------------------------------------
			-- CREATE 1 RECORD FOR EACH DAY IN DATE RANGE --
			------------------------------------------------
			SET @lTempDate = DATEADD(DAY, @lCnt, @StartDate)

			---------------------------------
			-- GET NEW Seq FOR NEW RECORDS --
			---------------------------------
			SELECT @lNewSeq = ISNULL(MAX(Seq), 0) + 1
			  FROM bHRES
			 WHERE HRCo = @HRCo
			   AND HRRef = @HRRef
			   AND Date = @lTempDate

			----------------------------------
			-- INSERT NEW RECORD INTO bHRES --
			----------------------------------
			INSERT INTO bHRES
				(HRCo, HRRef, [Date], [Description], ScheduleCode, Seq, Hours, [Status], 
				 Source, RequesterComment)
			VALUES
				(@HRCo, @HRRef, @lTempDate, @Desc, @PTOCode, @lNewSeq, @Hrs, 'N',
				 @Source, @Comments)
 
			---------------------
			-- UPDATE COUNTERS --
			---------------------
			SET @lCnt = @lCnt + 1

			------------------------
			-- EMAIL BODY - DATES --
			------------------------
			SELECT @EmailBody = @EmailBody + CHAR (10) + 'Date: ' + CONVERT(CHAR(10), @lTempDate, 120)

		END --WHILE (@lCnt <= @lDaysDiff)

	-------------------
	-- EMAIL SUBJECT --
	-------------------
	SELECT @EmailName = ISNULL(FirstName, '') + ' ' + ISNULL(LastName, '')
	  FROM HRRM 
	 WHERE HRCo = @HRCo AND HRRef = @HRRef

	SELECT @EmailSubject = 'Leave Request from ' + @EmailName 

	----------------
	-- EMAIL BODY --
	----------------
	SELECT @EmailBody = @EmailName + @EmailBody
	SELECT @EmailBody = @EmailBody + CHAR(10) + CHAR(10) + 'Code: ' + @PTOCode
	SELECT @EmailBody = @EmailBody + CHAR(10) + 'Hours Per Day: ' + CAST(@Hrs AS VARCHAR(10))

	IF (@Comments IS NULL) OR
		@Comments = ''
		BEGIN
			SET @Comments = 'No Comments Supplied.'
		END

	SELECT @EmailBody = @EmailBody + CHAR(10) + 'Requester Comment: ' + @Comments
	SELECT @EmailBody = @EmailBody + CHAR(10) + CHAR(10) + CHAR (10) + 'To Approve or Decline request(s), please run the Leave Approvals form.'

	----------------
	-- SEND EMAIL --
	----------------
	EXECUTE @rcode = vspHRPTOEmail @HRCo, @HRRef, '', 'A', @EmailSubject, @EmailBody, @errmsg 



RETURN @rcode

vspExit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRPTORequestInsert] TO [public]
GO
