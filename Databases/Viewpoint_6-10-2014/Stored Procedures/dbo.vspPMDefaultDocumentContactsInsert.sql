SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   procedure [dbo].[vspPMDefaultDocumentContactsInsert]
/*************************************
* Created By:	AW 2/15/2013
* Modified By:	
*
* Purpose: inserts/delete default contact list for doc category
*
*	
*
* INPUT:
*	PMCo
*	Project
*   DocCategory
*   DocType
*   FirmVendor
*   ContactList - csv list of contacts to default
*
* Success returns:
* 0
*
* Error returns:
* 1
*
**************************************/
(@PMCo bCompany,
 @Project bProject,
 @DocCat bDocType,
 @DocType varchar(10),
 @FirmVendor bFirm,
 @ContactList varchar(max),
 @msg varchar(255) output
)
AS
SET NOCOUNT ON
DECLARE @rcode INT
SET @rcode = 0

-- First verify parameters are valid
IF (@PMCo is null)
BEGIN
  SET @msg = 'PMCo can not be null'
  RETURN 1
END

IF (@Project is null)
BEGIN
  SET @msg = 'Project can not be null'
  RETURN 1
END

IF (@DocCat is null)
BEGIN
  SET @msg = 'Document Category can not be null'
  RETURN 1
END

IF (@FirmVendor is null)
BEGIN
  SET @msg = 'FirmVendor can not be null'
  RETURN 1
END

-- Allow Firm/Contact params to be null

-- First delete any default contacts for this project/doccat/doctype
DELETE vPMProjectDefaultDocumentDistribution
	FROM vPMProjectDefaultDocumentDistribution d
	JOIN vPMProjectDefaultDistributions p ON d.ContactKeyID=p.KeyID
	WHERE d.DocCategory=@DocCat AND isnull(d.DocType,'')=isnull(@DocType,'') 
	AND p.PMCo=@PMCo AND p.Project=@Project and dbo.vfToString(p.FirmNumber) = dbo.vfToString(@FirmVendor)



-- delete any orphan records in vPMProjectDefaultDistributions no longer referencing valid contacts/documents
DELETE vPMProjectDefaultDistributions 
	FROM vPMProjectDefaultDistributions p
	JOIN bHQCO h on p.PMCo = h.HQCo
	LEFT JOIN vPMProjectDefaultDocumentDistribution d ON d.ContactKeyID=p.KeyID
	LEFT JOIN bPMPM c on c.VendorGroup=h.VendorGroup and p.ContactCode=c.ContactCode and p.FirmNumber=c.FirmNumber
	WHERE (d.ContactKeyID IS NULL OR c.KeyID IS NULL) AND p.KeyID IS NOT NULL

-- If contact list is null just return
IF (dbo.vfToString(@ContactList) = '')
	RETURN 0

-- insert contacts for this project/doccat/doctype
INSERT vPMProjectDefaultDistributions(PMCo,Project,FirmNumber,ContactCode)
SELECT @PMCo,@Project,@FirmVendor,f.Names
	FROM vfTableFromArray(@ContactList) f
	WHERE NOT EXISTS (SELECT 1 FROM vPMProjectDefaultDistributions d 
		WHERE d.PMCo=@PMCo AND d.Project=@Project AND 
		d.FirmNumber=@FirmVendor AND d.ContactCode=f.Names)

INSERT vPMProjectDefaultDocumentDistribution(DocCategory,DocType,ContactKeyID)
	SELECT @DocCat,@DocType,KeyID
	FROM vPMProjectDefaultDistributions d
	JOIN vfTableFromArray(@ContactList) f ON f.Names=d.ContactCode
	WHERE PMCo=@PMCo and Project=@Project AND FirmNumber=@FirmVendor 



GO
GRANT EXECUTE ON  [dbo].[vspPMDefaultDocumentContactsInsert] TO [public]
GO
