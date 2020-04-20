SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--CREATE procedure [dbo].[vspHRGetPTORequests]
CREATE procedure [dbo].[vspHRGetPTORequests]
/************************************************************************
* CREATED:	Dan Sochacki 01/23/2008     
* MODIFIED: MarkH 08/26/2008 Issue 129554 - Dup records being returned.  HRCo not included in query
*											where clause.   
*			DAN SO 07/20/2009 - ISSUE: #133174 - reordered s.HRRef
*
* Purpose of Stored Procedure
*
*	Get all PTO/Leave Requests based on incoming criteria.
*    
*           
* Notes about Stored Procedure
*
******* Due to localization, the word "PTO" has been changed
******* to "Leave" anywhere it would be displayed to the User.
* 
* Inputs
*	@HRCo		- Company
*	@AppRes		- Approver Resource Number
*	@AppGroup	- Approval Group Number
*	@ReqStatus	- Request Status
*	@FromDate	- Earliest Date to Retrieve PTO/Leave Request From
*	@ReqRes		- Requester Resource Number
*
* Outputs
*	@rcode		- 0 = successfull - 1 = error
*	@errmsg		- Error Message
*
*************************************************************************/

    (@HRCo bCompany = NULL, @AppRes bHRRef = NULL, @AppGroup bGroup = NULL,
     @ReqStatus CHAR(1) = NULL, @FromDate bDate = NULL, @ReqRes bHRRef = NULL,
	 @errmsg varchar(80) = '' output)

AS
SET NOCOUNT ON

    DECLARE 	@lCnt			int,
				@lDaysDiff		int,
				@rcode			int

	----------------
	-- SET VALUES --
	----------------
	SET @rcode = 0	

	---------------------------------------------------
	-- CHECK FOR MINIMUM VALUES TO PERFORM SELECTION --	
	---------------------------------------------------
	IF ((@HRCo IS NULL) OR (@AppRes IS NULL))
		BEGIN
			SELECT @errmsg = 'Missing Company and/or Approver Resource value!', @rcode = 1
  			GOTO vspExit
		END

	----------------------------
	-- GET PTO/LEAVE REQUESTS --
	--------------------------------------------------------
	-- 'Selected' & 'Action' COLUMN NECESSARY TO MAKE THE --
	-- NON-STANDARD GRID COLUMN TO FUNCTION PROPERLY	  --
	--------------------------------------------------------
	SELECT  Selected = 'N',
			(dbo.vfHRGetFullName(@HRCo, s.HRRef)) HRRefFullName, s.HRRef,
			ScheduleCode, Date, Hours, RequesterComment, s.Status, 
			[Action] = '',
			ApproverComment,
			s.KeyID
	  FROM	HRES s WITH (NOLOCK)
	  JOIN  HRRM m WITH (NOLOCK)
        ON  s.HRCo = m.HRCo AND s.HRRef = m.HRRef
	  JOIN  HRCM c WITH (NOLOCK)
	    ON	s.HRCo = c.HRCo AND s.ScheduleCode = c.Code
	 WHERE  (m.PTOAppvrGrp = @AppGroup OR @AppGroup IS NULL) 
	   AND  (s.Status = @ReqStatus OR @ReqStatus IS NULL) 
       AND  (s.Date >= @FromDate OR @FromDate IS NULL)
       AND  (s.HRRef = @ReqRes OR @ReqRes IS NULL) 
       AND  m.PTOAppvrGrp in (SELECT PTOAppvrGrp 
								FROM HRAG WITH (NOLOCK)
							   WHERE HRCo = @HRCo 
								 AND (PriAppvr = @AppRes OR SecAppvr = @AppRes))
	   AND	c.Type = 'C'
       AND	c.PTOTypeYN = 'Y'
	   AND  s.HRCo = @HRCo	--Issue 129554.  Include @HRCo in query.

vspExit:
     RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHRGetPTORequests] TO [public]
GO
