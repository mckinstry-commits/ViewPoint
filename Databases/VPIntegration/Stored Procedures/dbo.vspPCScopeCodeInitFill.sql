SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   CREATE proc [dbo].[vspPCScopeCodeInitFill]
   
   /***********************************************************
    * CREATED BY:	GP	03/22/2010 - Issue #129020
    * MODIFIED BY:	JVH 5/4/10 - Phases can now be allowed on multiple vendor group's scope codes
    *
    * USAGE:
    * Return dataset to fill list view in PCScopeCodesInitialize
    *
    *
    * INPUT PARAMETERS
    *	@PCCo
    *	@VendorGroup
    *   @Scope
    *
    * OUTPUT PARAMETERS
    *	Dataset containing Phases and Descriptions.
    *
    * RETURN VALUE
    *   0         Success
    *   1         Failure or nothing to format
    *****************************************************/
   (@PhaseGroup tinyint, @VendorGroup bGroup, @msg varchar(255) output)
	AS
	BEGIN
	
		SET NOCOUNT ON

		IF @PhaseGroup IS NULL OR @VendorGroup IS NULL
		BEGIN
			SET @msg = 'The phase group and vendor group must be supplied'
			RETURN 1
		END

		--get phase and description
		SELECT JCPM.Phase, JCPM.[Description]
		FROM dbo.JCPM
			LEFT JOIN
				(SELECT PhaseGroup, Phase
					FROM dbo.PCScopePhases
					WHERE VendorGroup = @VendorGroup -- Scopes can be assigned multiple times to different vendor groups
				) ScopePhases
				ON JCPM.PhaseGroup = ScopePhases.PhaseGroup AND JCPM.Phase = ScopePhases.Phase
		WHERE JCPM.PhaseGroup = @PhaseGroup AND ScopePhases.Phase IS NULL -- Only show the phases that haven't been assigned to a vendor group's scope code
	END
GO
GRANT EXECUTE ON  [dbo].[vspPCScopeCodeInitFill] TO [public]
GO
