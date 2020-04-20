SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************/
CREATE  proc [dbo].[vspPMSubcontractCODesc]
/*************************************
 * Created By:	DAN SO 01/31/2010
 * Modified by:	GF 11/02/2011 TK-09613 allow SCO for project to SL setup under another.
 *
 *
 * called from PM Subcontract Change Order to return key description.
 *
 * Pass:
 * PMCo			PM Company
 * Project		PM Project
 * SL			PM Subcontract
 * SubCO		PM Subcontract Change Order
 *
 * Returns:
 *
 * Success returns:
 *	0 and Description from PMSubcontractCO
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@PMCo bCompany = NULL, @Project bJob = NULL, @SLCo bCompany = NULL,
 @SL VARCHAR(30) = NULL, @SubCO SMALLINT = NULL,
 @msg varchar(255) output)
AS
SET NOCOUNT ON


DECLARE @rcode INT, @SCOProject bJob, @SCOPMCo bCompany

SET @rcode = 0
SET @msg = ''

---------------------
-- GET DESCRIPTION --
---------------------
IF ISNULL(@SubCO,0) <> 0
	BEGIN
		---- TK-09613
		SELECT @msg = Description, @SCOProject = Project, @SCOPMCo = PMCo
		FROM PMSubcontractCO WITH (NOLOCK) 
		--WHERE PMCo = @PMCo 
		--  --AND Project = @Project
		WHERE SLCo = @SLCo
		   AND SL = @SL
		   AND SubCO = @SubCO
		IF @@ROWCOUNT <> 0
			BEGIN
			IF ISNULL(@SCOPMCo,0) <> ISNULL(@PMCo,0)
				BEGIN
				SELECT @msg = 'Subcontract CO already exists for JCCo: ' + isnull(convert(varchar(3),@SCOPMCo),'') + ' .', @rcode = 1
				GOTO vspExit
				END
				
			IF ISNULL(@SCOProject,'') <> ISNULL(@Project,'')
				BEGIN
				SELECT @msg = 'Subcontract CO already exists for Job: ' + isnull(convert(varchar(10),@SCOProject),'') + ' .', @rcode = 1
				GOTO vspExit
				END
				
			END
	END




vspExit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMSubcontractCODesc] TO [public]
GO
