SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRPurgePayHistory    Script Date: 8/28/99 9:35:38 AM ******/
CREATE  PROCEDURE [dbo].[bspPRPurgePayHistory]
    /***********************************************************
     * CREATED BY: EN 5/29/98
     * MODIFIED By : GG 07/19/98
     *				EN 8/10/05 - issue 28686  use LOCAL FAST_FORWARD to speed up bcPRPH cursor
					AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form
     *
     * USAGE:
     * Purges payment history (PRPH) and deposit history (PRDH)
     * for a payroll group through a specified payroll ending
     * date.  Affects only periods which have either been closed
     * and fully interfaced, or deleted from pay period control.
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
  @errmsg varchar(60) OUTPUT
)
AS 
SET nocount ON
    
DECLARE @rcode int,
    @PRPHopened tinyint,
    @cmco bCompany,
    @cmacct bCMAcct,
    @paymethod varchar(1),
    @cmref bCMRef,
    @cmrefseq tinyint,
    @eftseq smallint
    
SELECT  @rcode = 0
SELECT  @PRPHopened = 0
    
    /* initialize cursor for Payment History */
DECLARE bcPRPH CURSOR LOCAL FAST_FORWARD FOR
	SELECT  CMCo,
			CMAcct,
			PayMethod,
			CMRef,
			CMRefSeq,
			EFTSeq
	FROM    dbo.bPRPH
	WHERE   PRCo = @PRCo
			AND PRGroup = @PRGroup
			AND PREndDate <= @PREndDate
			--#142278
			AND ( PREndDate IN ( SELECT h.PREndDate
								 FROM   dbo.PRPH h
											JOIN dbo.PRPC c ON h.PRCo = c.PRCo
																AND h.PRGroup = c.PRGroup
																AND h.PREndDate = c.PREndDate
								 WHERE  h.PRCo = @PRCo
										AND h.PRGroup = @PRGroup
										AND h.PREndDate <= @PREndDate
										AND c.[Status] = 1
										AND c.JCInterface = 'Y'
										AND c.EMInterface = 'Y'
										AND c.GLInterface = 'Y'
										AND c.APInterface = 'Y' )
				  OR PREndDate NOT IN ( SELECT  h.PREndDate
										FROM    dbo.PRPH h
												JOIN dbo.PRPC c ON h.PRCo = c.PRCo
																AND h.PRGroup = c.PRGroup
																AND h.PREndDate = c.PREndDate 
										WHERE   h.PRCo = @PRCo
												AND h.PRGroup = @PRGroup
												AND h.PREndDate <= @PREndDate
										)
				)
    
    /* open cursor */
OPEN bcPRPH
    
    /* set open cursor flag to true */
SELECT  @PRPHopened = 1
    
    /* loop through all rows in this batch */
PRPH_loop:
FETCH NEXT FROM bcPRPH INTO @cmco, @cmacct, @paymethod, @cmref, @cmrefseq, @eftseq
    
IF @@fetch_status <> 0 
    GOTO bspexit
    
DELETE  FROM bPRDH
WHERE   PRCo = @PRCo
        AND CMCo = @cmco
        AND CMAcct = @cmacct
        AND PayMethod = @paymethod
        AND CMRef = @cmref
        AND CMRefSeq = @cmrefseq
        AND EFTSeq = @eftseq
    
DELETE  FROM bPRPH
WHERE   PRCo = @PRCo
        AND CMCo = @cmco
        AND CMAcct = @cmacct
        AND PayMethod = @paymethod
        AND CMRef = @cmref
        AND CMRefSeq = @cmrefseq
        AND EFTSeq = @eftseq
    
GOTO PRPH_loop
    
    
bspexit:
IF @PRPHopened = 1 
    BEGIN
        CLOSE bcPRPH
        DEALLOCATE bcPRPH
    END
    
RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPurgePayHistory] TO [public]
GO
