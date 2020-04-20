SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

   CREATE proc [dbo].[vspPMProjectDefaultDistributionsInsert]
   
   /***********************************************************
    * CREATED BY:	JG	07/29/2010 - Issue #140529
    * MODIFIED BY:	
    *
    * USAGE:
    * Return dataset to fill list view in PMProjectDefaultDistributions
    *
    *
    * INPUT PARAMETERS
    *	@PCCo
    *	@Project
    *   @FirmNumber
    *	@ContactCode
    *	@DocCats
    *
    * OUTPUT PARAMETERS
    *	None.
    *
    * RETURN VALUE
    *   0         Success
    *   1         Failure or nothing to format
    *****************************************************/
   (@PMCo bCompany, @Project bJob, @FirmNumber bFirm, @ContactCode bEmployee, @DocTypes varchar(MAX), @msg varchar(255) output)
	AS
	BEGIN
	
		SET NOCOUNT ON

		IF @PMCo IS NULL OR @Project IS NULL OR @FirmNumber IS NULL OR @ContactCode IS NULL OR @DocTypes IS NULL
		BEGIN
			SET @msg = 'The Company, Project, Firm, Contact, and DocTypes must be supplied. Please contact Viewpoint Customer Support.'
			RETURN 1
		END

		DECLARE @KeyID bigint
		SELECT @KeyID = KeyID FROM PMProjectDefaultDistributions
		WHERE PMCo = @PMCo
		AND Project = @Project
		AND FirmNumber = @FirmNumber
		AND ContactCode = @ContactCode

		IF @KeyID IS NULL
		BEGIN
			INSERT INTO PMProjectDefaultDistributions
			(PMCo, Project, FirmNumber, ContactCode)
			VALUES
			(@PMCo, @Project, @FirmNumber, @ContactCode)
			SELECT @KeyID = SCOPE_IDENTITY()
		END
		ELSE
			--delete previous records
			DELETE FROM PMProjDefDistDocType
			WHERE DefaultKeyID = @KeyID

		INSERT INTO PMProjDefDistDocType
		SELECT  @KeyID, [Names]
		FROM    dbo.vfTableFromArray(@DocTypes)
	END
GO
GRANT EXECUTE ON  [dbo].[vspPMProjectDefaultDistributionsInsert] TO [public]
GO
