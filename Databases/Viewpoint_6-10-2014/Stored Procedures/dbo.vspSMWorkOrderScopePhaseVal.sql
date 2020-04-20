SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/* =============================================
-- Author:		TRL  TK-13380
-- Create date: 03/15/2012
-- Modifyed by:  TL 05/01/2012 - TK-14606 changed code for Job/Phase Validation
-- Description:	Work Order Scope Phase Validation
=============================================*/
CREATE PROCEDURE [dbo].[vspSMWorkOrderScopePhaseVal]
	@JCCo bCompany = NULL, @Job bJob = NULL, @Phase bPhase = NULL, @phasegroup tinyint,	@msg AS varchar(255) OUTPUT
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @rcode int, @errortext varchar(255), @JCJPexists varchar(1)
	
	If (@Phase IS NOT NULL)
	BEGIN

		IF (@JCCo IS NULL)
		BEGIN
			SET @msg = 'Missing JC Company!'
			RETURN 1
		END

		IF (@Job IS NULL)
		BEGIN
			SET @msg = 'Missing Job!'
			RETURN 1
		END
		
		--check Job Phases - exact match
		EXEC @rcode = dbo.bspJCVPHASE  @jcco=@JCCo,@job=@Job,@phase=@Phase,@phasegroup=@phasegroup,@override= 'N', @JCJPexists=@JCJPexists OUTPUT,@msg=@msg OUTPUT
		IF @rcode <> 0
		BEGIN
			SELECT @errortext = dbo.vfToString(@msg)
			SELECT @msg =  @errortext
			RETURN 1	
		END
			END

	RETURN 0
END







GO
GRANT EXECUTE ON  [dbo].[vspSMWorkOrderScopePhaseVal] TO [public]
GO
