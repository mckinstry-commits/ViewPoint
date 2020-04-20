SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJCPCVal    Script Date: 8/28/99 9:33:00 AM ******/
   /****** Object:  Stored Procedure dbo.bspJCPCVal    Script Date: 2/12/97 3:25:06 PM ******/
CREATE   PROC [dbo].[bspJCPCVal]
(
  @phasegroup tinyint = NULL,
  @phase bPhase = NULL,
  @costtype bJCCType = NULL,
  @msg varchar(60) OUTPUT
)
AS 
SET nocount ON
   /***********************************************************
    * CREATED BY: SE  11/15/96
    * MODIFIED By : SE 11/15/96
    *				TV - 23061 added isnulls
					AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form
    * USAGE:
    * validates Cost types in JCPC
    * an error is returned if any of the following occurs
    * cost type not valid for phase passed.     
    *
    * INPUT PARAMETERS
    *   PhaseGroup
    *   Phase
    *   CostType
    *
   
    * OUTPUT PARAMETERS
   
    *   @msg      error message if error occurs otherwise Description from JCCT
    * RETURN VALUE
    *   0         success
    *   1         Failure
    *****************************************************/ 
   
DECLARE @rcode int
SELECT  @rcode = 0
   
   
IF @phasegroup IS NULL 
    BEGIN
        SELECT  @msg = 'Missing Phase Group!',
                @rcode = 1
        GOTO bspexit
    END
   
IF @phase IS NULL 
    BEGIN
        SELECT  @msg = 'Missing Phase code!',
                @rcode = 1
        GOTO bspexit
    END
   
IF @costtype IS NULL 
    BEGIN
        SELECT  @msg = 'Missing Cost Type!',
                @rcode = 1
        GOTO bspexit
    END
--#142278   
SELECT  @msg = [Description]
FROM    dbo.JCPC p
        JOIN dbo.JCCT c ON p.PhaseGroup = c.PhaseGroup
							AND p.CostType = c.CostType
WHERE   p.PhaseGroup = @phasegroup
        AND p.Phase = @phase
        AND p.CostType = @costtype
           
IF @@rowcount = 0 
    BEGIN
        SELECT  @msg = 'Phase Cost Type not setup!',
                @rcode = 1
        GOTO bspexit
    END
   
bspexit:
RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJCPCVal] TO [public]
GO
