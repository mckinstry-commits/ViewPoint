SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  PROC [dbo].[vspPMSubmittalRegisterCopyFillGrid]
/***********************************************************
* CREATED BY:		 TRL 10/13/2012 TK-19147 Add Stored Procedure
* MODIFIED BY:	
*						
* USAGE: Used to copy Register Items on PM Submittal Register Copy
*
*****************************************************/ 
(@PMCo bCompany, @SourceProject bProject, @ExcludeRevisions bYN = NULL)

AS

SET NOCOUNT ON

-----------------
--Validate fields
-----------------
IF	@PMCo IS NULL
BEGIN
	RETURN 1
END

IF @SourceProject IS NULL
BEGIN
	RETURN 1
END

--Select Distinct to keep form updating duplicates
IF ISNULL(@ExcludeRevisions,'N') = 'Y'
BEGIN
	SELECT 'true' as [Copy],SubmittalNumber AS [Submittal], SubmittalRev AS [Rev], [Description], SpecSection,
	ApprovingFirm, PMFM.FirmName AS [ApprovingFirmName],PMSubmittal.KeyID, PMSubmittal.UniqueAttchID
	FROM dbo.PMSubmittal
	LEFT JOIN dbo.PMFM ON PMSubmittal.VendorGroup=PMFM.VendorGroup AND PMSubmittal.ApprovingFirm=PMFM.FirmNumber
	WHERE PMCo=@PMCo AND Project=@SourceProject AND ISNULL(PMSubmittal.SubmittalNumber,'') <> '' 
	AND NOT EXISTS (SELECT 1 FROM dbo.PMSubmittal m WHERE PMSubmittal.PMCo=m.PMCo AND PMSubmittal.Project=m.Project AND
		PMSubmittal.SubmittalNumber=m.SubmittalNumber AND ISNULL(m.SubmittalRev,0) < ISNULL(PMSubmittal.SubmittalRev,0) )
	ORDER BY SubmittalNumber		
END
ELSE
BEGIN
	SELECT    'true' as [Copy],SubmittalNumber AS [Submittal], SubmittalRev AS [Rev], [Description], SpecSection,
	 ApprovingFirm, PMFM.FirmName AS [ApprovingFirmName],PMSubmittal.KeyID, PMSubmittal.UniqueAttchID
	FROM dbo.PMSubmittal
	LEFT JOIN dbo.PMFM ON PMSubmittal.VendorGroup=PMFM.VendorGroup AND PMSubmittal.ApprovingFirm=PMFM.FirmNumber
	WHERE PMCo=@PMCo AND Project=@SourceProject AND ISNULL(SubmittalNumber,'') <> ''
	ORDER BY SubmittalNumber
END

---------
--Success
---------
RETURN 0		
GO
GRANT EXECUTE ON  [dbo].[vspPMSubmittalRegisterCopyFillGrid] TO [public]
GO
