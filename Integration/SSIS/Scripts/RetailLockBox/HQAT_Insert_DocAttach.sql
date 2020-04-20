ALTER FUNCTION mfnDMAttachmentPath
(
	@Company bCompany
,	@Module VARCHAR(10)
,	@Form   VARCHAR(50)
,	@Month  bDate
)

RETURNS varchar(255)
AS

BEGIN

IF @Month IS NULL
	SELECT @Month=CAST(CAST(MONTH(GETDATE()) AS VARCHAR(2)) + '/1/' + CAST(YEAR(GETDATE()) AS VARCHAR(4)) AS DATETIME)
-- TODO:  Change PATH TO "No Module", "No Form" FOR invalid parameters.

DECLARE @DMAttachmentPath VARCHAR(255)
DECLARE @strCompany VARCHAR(30)
DECLARE @parmsValid bYN
SELECT @DMAttachmentPath='',@parmsValid='Y'

IF	NOT EXISTS (SELECT 1 FROM bHQCO WHERE HQCo=@Company)
BEGIN
	SELECT @strCompany='No Company'
	--SELECT 
	--	@DMAttachmentPath=@DMAttachmentPath+'Invalid Company ''' + CAST(@Company AS VARCHAR(10)) + '''. '
	--,	@parmsValid='N'
END
ELSE
BEGIN
	SELECT @strCompany='Company' + CAST(@Company AS VARCHAR(10))
END

IF NOT EXISTS (SELECT 1 FROM vDDMO WHERE Mod=@Module AND Active='Y')
BEGIN
	SELECT @Module='No Module'
	--SELECT 
	--	@DMAttachmentPath=@DMAttachmentPath+'Invalid Module ''' + @Module + '''. '
	--,	@parmsValid='N'
END

IF	(
	NOT EXISTS (SELECT 1 FROM vDDMF WHERE Form=@Form)
	AND NOT EXISTS (SELECT 1 FROM vDDMFc WHERE Form=@Form)
	)
BEGIN
	SELECT @Form='No Form Name'
	--SELECT	
	--	@DMAttachmentPath=@DMAttachmentPath+'Invalid Form ''' + @Form + '''. '
	--,	@parmsValid='N'
END


IF @parmsValid='N'
BEGIN
	SELECT @DMAttachmentPath = 'ERR - ' + @DMAttachmentPath
END
ELSE
BEGIN
DECLARE @dirMask  VARCHAR(255)
DECLARE @rootPath VARCHAR(255)
SELECT @DMAttachmentPath=''

SELECT
	@rootPath=PermanentDirectory
,	@dirMask=CustomFormat
FROM
	HQAO	

IF RIGHT(@rootPath,1) <> '\'
	SELECT @rootPath=@rootPath + '\'
	
SELECT @dirMask=REPLACE(@dirMask,'%C',CAST(@strCompany AS VARCHAR(30)))
SELECT @dirMask=REPLACE(@dirMask,'%M',@Module)
SELECT @dirMask=REPLACE(@dirMask,'%F',@Form)
SELECT @dirMask=REPLACE(@dirMask,'%D',RIGHT(CONVERT(nvarchar(6), @Month, 112),2) + '-' + LEFT(CONVERT(nvarchar(6), @Month, 112),4))

SELECT @DMAttachmentPath=@rootPath + @dirMask
END

RETURN @DMAttachmentPath
END
go

SELECT dbo.mfnDMAttachmentPath(101,'AP','APUnappInv',GETDATE())

SELECT dbo.mfnDMAttachmentPath(99,'AP','APUnappInv',GETDATE())
SELECT dbo.mfnDMAttachmentPath(101,'AP','NoForm',GETDATE())
SELECT dbo.mfnDMAttachmentPath(99,'XX','APUnappInv',GETDATE())
SELECT dbo.mfnDMAttachmentPath(101,'XX','NoForm',GETDATE())
	
--EXEC dbo.vspHQATInsert @hqco = NULL, -- bCompany
--    @formname = '', -- varchar(30)
--    @keyfield = '', -- varchar(500)
--    @description = '', -- varchar(255)
--    @addedby = '', -- varchar(128)
--    @adddate = NULL, -- bDate
--    @docname = '', -- varchar(512)
--    @tablename = '', -- varchar(128)
--    @origfilename = '', -- varchar(512)
--    @attid = 0, -- int
--    @uniqueattchid = NULL, -- uniqueidentifier
--    @docattchyn = '', -- char(1)
--    @createAsStandAloneAttachment = NULL, -- bYN
--    @attachmentTypeID = 0, -- int
--    @IsEmail = NULL, -- bYN
--    @msg = '' -- varchar(100)
