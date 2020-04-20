SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRPurgePayPeriods    Script Date: 8/28/99 9:35:39 AM ******/
CREATE    PROCEDURE [dbo].[bspPRPurgePayPeriods]
	/***********************************************************
	* CREATED BY: EN 5/29/98
	* MODIFIED By : EN 5/29/98
	*               EN 4/28/00 - was checking to see if LeaveProcessed flag was 'Y' before purging pay period; I removed that since not everybody uses the Leave feature
	*               EN 5/8/00 - revise order of deletion to make sure that triggers don't generate errors about reliant details existing
	*				EN 2/25/02 - delete stmts other than for bPRPC referring to wrong variable for PREndDate so not clearing proper info such as bPRAF entries before trying to clear bPRPC
	*				EN 10/9/02 - issue 18877 change double quotes to single
	*				AMR 01/17/11 - #142350, making case insensitive by removing unused vars and renaming same named variables- 
	*				MV 10/15/12 - B-10534/TK-18444 purge Arrears/Payback 
	*
	* USAGE:
	* Purges detail for a payroll group through a specified payroll ending
	* date.  Tables affected are PRPC, PRAF, PRHD, PRPS, PRSQ, PRCA, PRCX,
	* PRIA, PRDT, PRDS, PRVP, PRTH, PRTA, PRTL, PRAP, PRGL, PRJC, PREM,
	* and PRER. Also purges PRArrears/Payback history.
	*
	* INPUT PARAMETERS
	*   @PRCo		PR Company
	*   @PRGroup		Group to purge
	*   @PREndDate		PR ending date to purge through
	*
	* OUTPUT PARAMETERS
	*   @errmsg     if something went wrong
	* RETURN VALUE
	*   0   success
	*   1   fail
	*****************************************************/
(
  @PRCo bCompany,
  @PRGroup bGroup,
  @PREndDate bDate,
  @PRArrearsManualDate bDate = NULL,
  @errmsg varchar(500) OUTPUT
)
AS 
SET NOCOUNT ON
   --#142350 - renaming	@prenddate
	DECLARE @PREndDateLP bDate
    
   /* loop through PRPC and find periods to purge */
   SELECT @PREndDateLP = MIN(PREndDate) 
						FROM dbo.PRPC
   						WHERE PRCo=@PRCo and PRGroup=@PRGroup and PREndDate<=@PREndDate
   						AND Status=1 and JCInterface='Y' and EMInterface='Y' and GLInterface='Y'
   						AND APInterface='Y' 
	IF @PREndDateLP IS NULL
	BEGIN
		SELECT @errmsg = 'No Pay Periods qualified to be purged. Verify PR final updates have been run for: JC, EM, GL and AP.'
		RETURN 1
	END
   WHILE @PREndDateLP is not null
   BEGIN
		BEGIN TRY
		delete from bPRTA
		where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDateLP
		delete from bPRTL
		where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDateLP
		delete from bPRGL
		where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDateLP
		delete from bPRJC
		where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDateLP
		delete from bPREM
		where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDateLP
		delete from bPRER
		where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDateLP
		delete from bPRCX
		where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDateLP
		delete from bPRVP
		where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDateLP
		delete from bPRCA
		where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDateLP
		delete from bPRDS
		where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDateLP
		delete from bPRDT
		where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDateLP
		delete from bPRIA
		where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDateLP
		delete from bPRTH
		where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDateLP
		delete from bPRSQ
		where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDateLP
		delete from bPRPS
		where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDateLP
		delete from bPRAF
		where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDateLP
		delete from bPRHD
		where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDateLP
		delete from bPRAP
		where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDateLP
		delete from bPRPC
		where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDateLP
		-- update purge flag in vPRArrears to disable trigger updates to bPRED Life-to-date amounts - TK-18444
		UPDATE dbo.vPRArrears
		SET PurgeYN = 'Y'
		WHERE PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDateLP
		-- delete vPRArrears history records
		DELETE FROM dbo.vPRArrears
		WHERE PRCo=@PRCo and PRGroup=@PRGroup and PREndDate=@PREndDateLP
		
		END TRY
		BEGIN CATCH
			SET @errmsg = ERROR_MESSAGE()
			ROLLBACK TRAN
			RETURN 1
		END CATCH

		-- get nex pay period
		SELECT @PREndDateLP=min(PREndDate) from PRPC
    		where PRCo=@PRCo and PRGroup=@PRGroup and PREndDate<=@PREndDate and PREndDate>@PREndDateLP
    		and Status=1 and JCInterface='Y' and EMInterface='Y' and GLInterface='Y'
    		and APInterface='Y' 
   END
   
   -- Begin manual vPRArrears purge - TK-18444
	IF ISNULL(@PRArrearsManualDate,'') <> ''
	BEGIN
		-- update purge flag 
		UPDATE dbo.vPRArrears
		SET PurgeYN = 'Y'
		WHERE	PRCo=@PRCo AND
				PRGroup IS NULL AND 
				PREndDate IS NULL AND
				PaySeq IS NULL AND
				Date <= @PRArrearsManualDate
		-- delete manual records
		DELETE FROM dbo.vPRArrears
		WHERE	PRCo=@PRCo AND
				PRGroup IS NULL AND 
				PREndDate IS NULL AND
				PaySeq IS NULL AND
				Date <= @PRArrearsManualDate
		-- manual record delete only happens once so clear the date
		SELECT @PRArrearsManualDate = NULL
	END
   
RETURN
GO
GRANT EXECUTE ON  [dbo].[bspPRPurgePayPeriods] TO [public]
GO
