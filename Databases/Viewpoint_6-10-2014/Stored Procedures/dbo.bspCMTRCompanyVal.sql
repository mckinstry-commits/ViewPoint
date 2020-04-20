SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspCMTRCompanyVal    Script Date: 8/28/99 9:34:18 AM ******/
CREATE  PROC [dbo].[bspCMTRCompanyVal]
   /***********************************************************
    * CREATED BY: SE   8/20/96
    * MODIFIED By : SE 8/20/96
					AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form
    *
    * USAGE:
    * validates CM Company number for a transfer.
    * it will also make sure that the CMCompany's GLCompany is open
    * for this month.
    * 
    * INPUT PARAMETERS
    *   CMCo   CM Co to Validate
    *   Mth    Batch Month
    
    * OUTPUT PARAMETERS
    *   @msg If Error, error message, otherwise description of Company
    * RETURN VALUE
    *   0   success
    *   1   fail
    *****************************************************/
(
  @cmco bCompany = 0,
  @mth bMonth,
  @msg varchar(60) OUTPUT
)
AS 
SET nocount ON
   
   
DECLARE @rcode int,
    @glco bCompany,
    @glmth bMonth
SELECT  @rcode = 0
   	
IF @cmco = 0 
    BEGIN
        SELECT  @msg = 'Missing CM Company#',
                @rcode = 1
        GOTO bspexit
    END
   
SELECT  @glco = c.GLCo,
        @msg = h.Name
FROM    dbo.CMCO c
        JOIN dbo.bHQCO h ON  h.HQCo = c.CMCo
WHERE  @cmco = c.CMCo
   
IF @@rowcount = 0 
    BEGIN
        SELECT  @msg = 'Not a valid CM Company',
                @rcode = 1
        GOTO bspexit
    END
   
SELECT  @glmth = LastMthSubClsd
FROM    bGLCO
WHERE   GLCo = @glco
IF @@rowcount = 0 
    BEGIN
        SELECT  @msg = 'GL Company ' + CONVERT(varchar(3), @glco)
                + ' not setup for CM Company',
                @rcode = 1
        GOTO bspexit
   
    END
   
   
IF @glmth >= @mth 
    BEGIN
        SELECT  @msg = 'GL Company ' + CONVERT(varchar(3), @glco)
                + ' subledgers are closed for this batch month.',
                @rcode = 1
        GOTO bspexit
    END
   
bspexit:
RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspCMTRCompanyVal] TO [public]
GO
