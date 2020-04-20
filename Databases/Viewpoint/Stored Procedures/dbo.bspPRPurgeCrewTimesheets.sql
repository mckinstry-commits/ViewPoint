SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRPurgeCrewTimesheets    Script Date: 8/28/99 9:35:38 AM ******/
CREATE  PROCEDURE [dbo].[bspPRPurgeCrewTimesheets]
   /***********************************************************
    * CREATED BY: EN 3/14/03
    * MODIFIED By :  mh 04/03/09 - Issue 132862 - Delete PRRQ prior to PRRE
    *				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables-  
    *
    * USAGE:
    * Purges status 4 (Send Complete) timesheets from
    * bPRRH/bPRRE/bPRRO/bPRRN/bPRRQ tables for the specified
    * (and optional) JCCo, Job, Crew, and Posting Date.
    * 
    * INPUT PARAMETERS
    *   @prco		PR Company
    *   @jcco		Job Company to purge (optional)
    *   @job		Job to purge (optional)
    *	 @crew		Crew to purge (optional)
    *	 @postdate	Posting Date to purge (optional)
    *
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/
(
  @prco bCompany,
  @jcco bCompany = NULL,
  @job bJob = NULL,
  @crew varchar(10) = NULL,
  @postdate bDate = NULL,
  @errmsg varchar(60) OUTPUT
)
AS 
SET NOCOUNT ON
   -- #142350 renaming @CREW and @POSTDATE
DECLARE @rcode int,
		@opencursor tinyint,
		@CrewCur varchar(10),
		@PostDateCur bDate,
		@SHEETNUM smallint
   
SELECT  @rcode = 0
   
   -- Purge timesheet details from  bPRRE, bPRRO, bPRRN, and bPRRQ first, then delete from bPRRH
   
   --use cursor to find timesheets for purge
DECLARE bcPRRH CURSOR
FOR
SELECT  Crew,
        PostDate,
        SheetNum
FROM    PRRH
WHERE   PRCo = @prco
        AND JCCo = ISNULL(@jcco, JCCo)
        AND Job = ISNULL(@job, Job)
        AND Crew = ISNULL(@crew, Crew)
        AND PostDate <= ISNULL(@postdate, PostDate)
        AND Status = 4
   
   --open cursor
OPEN bcPRRH
   
   --set open cursor flag to true
SELECT  @opencursor = 1
   
   --loop through all rows in PRRH which fit the criteria and purge first the details (bPRRE/bPRRO/bPRRN/bPRRQ) then the header (bPRRH)
purge_loop:
FETCH NEXT FROM bcPRRH INTO @CrewCur, @PostDateCur, @SHEETNUM
IF @@fetch_status <> 0 
    GOTO bspexit
      
DELETE  FROM bPRRQ
WHERE   PRCo = @prco
        AND Crew = @CrewCur
        AND PostDate = @PostDateCur
        AND SheetNum = @SHEETNUM
   
DELETE  FROM bPRRE
WHERE   PRCo = @prco
        AND Crew = @CrewCur
        AND PostDate = @PostDateCur
        AND SheetNum = @SHEETNUM
   
DELETE  FROM bPRRO
WHERE   PRCo = @prco
        AND Crew = @CrewCur
        AND PostDate = @PostDateCur
        AND SheetNum = @SHEETNUM
   
DELETE  FROM bPRRN
WHERE   PRCo = @prco
        AND Crew = @CrewCur
        AND PostDate = @PostDateCur
        AND SheetNum = @SHEETNUM

DELETE  FROM bPRRH
WHERE   PRCo = @prco
        AND Crew = @CrewCur
        AND PostDate = @PostDateCur
        AND SheetNum = @SHEETNUM
   
GOTO purge_loop
   
   		
bspexit:
IF @opencursor = 1 
    BEGIN
        CLOSE bcPRRH
        DEALLOCATE bcPRRH
        SELECT  @opencursor = 0
    END
   
RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPurgeCrewTimesheets] TO [public]
GO
