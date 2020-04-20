
USE Viewpoint
go

IF EXISTS (SELECT 1 FROM sysobjects WHERE name='mspProcessAPUIStandaloneAttachments' AND type='P')
BEGIN
	PRINT 'DROP PROCEDURE mspProcessAPUIStandaloneAttachments'
	DROP PROCEDURE mspProcessAPUIStandaloneAttachments
END
go

PRINT 'CREATE PROCEDURE mspProcessAPUIStandaloneAttachments'
go

create PROCEDURE mspProcessAPUIStandaloneAttachments
AS
/*
2014.10.07 - LWO - Created
	Utility procedure to process any "Standalone" DM records that have been indexed to APUI (Unapproved Invoices)  and update the records
	so they are treated as "Attached" documents and removed from the "Standalone" list.  Without this, the DM Standalone list
	will continually grow and users will have no way of determining what has been attended to and what is outstanding (e.g. in queue).

2014.11.18 - Modfied to accomodate new customer Document Types (50061, 50063, 50056)  Had to switch to DMAttachmentTypesShared view so both
    Viewpoint default and McKinstry custom document types were available in the query.
*/

DECLARE apuicur CURSOR for
SELECT 
	hqat.HQCo
,	hqat.AttachmentID
,	hqai.APCo
,	hqai.APReference
,	hqai.APVendorGroup
,	hqai.APVendor
,	'APUnappInv' AS FormName
,	'KeyField=''KeyID=' + CAST(apui.KeyID AS VARCHAR(20)) + '''' as KeyField
,	'A' AS CurrentState
,	apui.UniqueAttchID AS UniqueAttchID
,	'APUI' AS TableName
,	apui.KeyID
FROM 
	HQAT hqat JOIN
	dbo.DMAttachmentTypesShared dmat ON
		hqat.AttachmentTypeID=dmat.AttachmentTypeID 
	AND dmat.AttachmentTypeID in (50061, 50063, 50056) JOIN
	HQAI hqai on
		hqat.AttachmentID=hqai.AttachmentID JOIN
	APUI apui ON
		hqai.APCo=apui.APCo
	AND hqai.APVendorGroup=apui.VendorGroup
	AND hqai.APVendor=apui.Vendor
	AND hqai.APReference=apui.APRef
WHERE hqat.CurrentState='S'
ORDER BY 1

DECLARE @HQCo bCompany
DECLARE @AttachmentID int
DECLARE @APCo bCompany
DECLARE @APReference bAPReference
DECLARE @APVendorGroup bGroup
DECLARE @APVendor bVendor
DECLARE @FormName VARCHAR(30)
DECLARE @KeyField VARCHAR(500)
DECLARE @CurrentState CHAR(1)
DECLARE @UniqueAttchID UNIQUEIDENTIFIER
DECLARE @TableName VARCHAR(128)
DECLARE @KeyID int


OPEN apuicur
FETCH apuicur INTO
	@HQCo
,	@AttachmentID --int
,	@APCo --bCompany
,	@APReference --bAPReference
,	@APVendorGroup --bGroup
,	@APVendor --bVendor
,	@FormName --VARCHAR(30)
,	@KeyField --VARCHAR(500)
,	@CurrentState --CHAR(1)
,	@UniqueAttchID --UNIQUEIDENTIFIER
,	@TableName --VARCHAR(128)
,	@KeyID --int

WHILE @@fetch_status=0
BEGIN
	IF @UniqueAttchID IS NULL
		SELECT @UniqueAttchID = NEWID()

	IF @HQCo IS NULL
		SELECT @HQCo=@APCo

	--PRINT 'UPDATE APUI SET UniqueAttchID=''' + CAST(@UniqueAttchID AS VARCHAR(64)) + ''' WHERE KeyID=' + CAST(@KeyID AS VARCHAR(20))
	UPDATE APUI SET UniqueAttchID=@UniqueAttchID WHERE KeyID=@KeyID
	
	--PRINT 'UPDATE HQAT SET'
	--PRINT '	FormName=''' + @FormName + ''''
	--PRINT ',	KeyField=''' + @KeyField + ''''
	--PRINT ',	CurrentState=''' + @CurrentState + ''''
	--PRINT ',	UniqueAttchID=''' + CAST(@UniqueAttchID AS VARCHAR(64)) + ''''
	--PRINT ',	TableName=''' + @TableName + ''''
	--PRINT 'WHERE '
	--PRINT '		AttachmentID=' + CAST(@AttachmentID AS VARCHAR(20))
	
	UPDATE HQAT SET
		HQCo=@HQCo
	,	FormName=@FormName
	,	KeyField=@KeyField
	,	CurrentState=@CurrentState
	,	UniqueAttchID=@UniqueAttchID
	,	TableName=@TableName
	WHERE
		AttachmentID=@AttachmentID		

	FETCH apuicur INTO
		@HQCo
	,	@AttachmentID --int
	,	@APCo --bCompany
	,	@APReference --bAPReference
	,	@APVendorGroup --bGroup
	,	@APVendor --bVendor
	,	@FormName --VARCHAR(30)
	,	@KeyField --VARCHAR(500)
	,	@CurrentState --CHAR(1)
	,	@UniqueAttchID --UNIQUEIDENTIFIER
	,	@TableName --VARCHAR(128)
	,	@KeyID --int
END

CLOSE apuicur
DEALLOCATE apuicur
go


