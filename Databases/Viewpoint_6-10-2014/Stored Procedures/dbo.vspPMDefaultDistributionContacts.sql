SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   procedure [dbo].[vspPMDefaultDistributionContacts]
/*************************************
* Created By:	GBJ 6/10/2013
* Modified By:	
*
* Purpose: returns the list of currently configured contacts unrelated to documents.
*
*	
*
* INPUT:
*	PMCo
*	Project
* 
*
* OUTPUT
*  List of Contacts
*  PMCo,Project,FirmNumber,FirmName,ContactCode
*
* Success returns:
* 0
*
* Error returns:
*
**************************************/
(@PMCo bCompany,
 @Project bProject,
 @errmsg varchar(255) output
)
AS
SET NOCOUNT ON

declare @rcode INT

SET @rcode = 0

IF @PMCo IS NULL
BEGIN
	set @errmsg = 'PMCo can not be null'
	return 1
END

IF @Project IS NULL
BEGIN
	set @errmsg = 'Project can not be null'
	return 1
END

SELECT DISTINCT 
	PMCo,
	Project,
	FirmNumber,
	ContactCode,
	'X' as 'DocType'
FROM PMProjectDefaultDistributions d
WHERE d.PMCo=@PMCo AND d.Project=@Project


return 0


GO
GRANT EXECUTE ON  [dbo].[vspPMDefaultDistributionContacts] TO [public]
GO
