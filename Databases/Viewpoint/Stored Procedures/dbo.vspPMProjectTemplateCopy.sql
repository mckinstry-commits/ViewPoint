SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*************************************
* Created By:	Dan So 07/26/2010 - Issue: #140529
* Modified by:
*
* Called from PM Project Master
* Copies information from PMCompanyTemplates and inserts into PMProjectMasterTemplates
*
* INPUT:
*	@pmco			MS Company
*	@Project		MS Haul Code
*
* OUTPUT:
*	@msg		Description or Error message
*	@rcode		0 - Success
*				1 - Error
*
**************************************/
 CREATE PROC [dbo].[vspPMProjectTemplateCopy]
 --ALTER PROC [dbo].[vspPMProjectTemplateCopy]
 
(@pmco bCompany, @Project bJob, 
 @msg varchar(255) output)
	
AS
SET NOCOUNT ON

	DECLARE	@rcode int
	
	
	-- PRIME VARIABLES --
	SET @rcode = 0


	-------------------------------
	-- VALIDATE INPUT PARAMETERS --
	-------------------------------
	IF @pmco IS NULL
		BEGIN
			SET @msg = 'Missing PM Company'
			SET @rcode = 1
			GOTO vspexit
		END
		
	IF @Project IS NULL
		BEGIN
			SET @msg = 'Missing Project'
			SET @rcode = 1
			GOTO vspexit
		END
		

	---------------------------------------------------------
	-- COPY/INSERT INFORMATION THAT DOES NOT ALREADY EXIST --
	---------------------------------------------------------
	INSERT INTO vPMProjectMasterTemplates (PMCo, Project, DocType, DefaultTemplate)
		 SELECT @pmco, @Project, CT.DocType, CT.DefaultTemplate 
		   FROM vPMCompanyTemplates CT WITH (NOLOCK)
	      WHERE NOT EXISTS (SELECT TOP 1 1 FROM vPMProjectMasterTemplates PMT2 
						     WHERE PMT2.PMCo = @pmco 
						       AND PMT2.Project = @Project 
						       AND PMT2.DocType = CT.DocType)
			AND CT.PMCo = @pmco

	   
	   
	-----------------
	-- END ROUTINE --
	-----------------
	vspexit:
		IF @rcode <> 0 
			SET @msg = isnull(@msg,'')
			
		RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMProjectTemplateCopy] TO [public]
GO
