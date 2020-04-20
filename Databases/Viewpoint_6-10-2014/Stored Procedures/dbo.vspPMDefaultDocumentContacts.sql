SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE   procedure [dbo].[vspPMDefaultDocumentContacts]
/*************************************
* Created By:	AW 2/15/2013
* Modified By:	
*
* Purpose: returns the list of currently configured contacts per document
*
*	
*
* INPUT:
*	PMCo
*	Project
*   DocCategory
*   DocType
* 
*
* OUTPUT
*  List of Contacts
*  PMCo,Project,FirmNumber,FirmName,ContactCode,ContactName
*
* Success returns:
* 0
*
* Error returns:
*
**************************************/
(@PMCo bCompany,
 @Project bProject,
 @DocCat bDocType,
 @DocType varchar(10),
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

IF @DocCat IS NULL
BEGIN
	set @errmsg = 'Document Category can not be null'
	return 1
END

-- allow null doctypes

select distinct PMCo,Project,FirmNumber,ContactCode,a.DocCategory,a.DocType
from vPMProjectDefaultDocumentDistribution a 
join vPMProjectDefaultDistributions d on d.KeyID=a.ContactKeyID
where d.PMCo=@PMCo and d.Project=@Project and a.DocCategory = @DocCat 
	and (@DocType is null or dbo.vfToString(a.DocType) = dbo.vfToString(@DocType))


return 0



GO
GRANT EXECUTE ON  [dbo].[vspPMDefaultDocumentContacts] TO [public]
GO
