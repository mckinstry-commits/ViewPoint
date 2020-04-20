SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		AJW 05/10/13 TFS-13608 Function used for table constraint
-- Mod:
-- =============================================
CREATE FUNCTION dbo.vfPMProjectMasterTemplatesDefault(
	@PMCo bCompany,
	@Project bProject,
	@DocCategory varchar(10),
	@DocType varchar(10)
) RETURNS INT AS BEGIN

  DECLARE @ret INT;
  SELECT @ret = COUNT(1) 
  FROM PMProjectMasterTemplates 
  WHERE PMCo = @PMCo AND Project = @Project AND DocCategory = @DocCategory AND dbo.vfToString(DocType) = dbo.vfToString(@DocType) AND DefaultYN = 'Y'
  ;
  RETURN @ret;

END;
GO
GRANT EXECUTE ON  [dbo].[vfPMProjectMasterTemplatesDefault] TO [public]
GO
