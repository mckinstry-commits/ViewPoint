--SELECT apui.VendorGroup, apui.Vendor, apvm.Name AS VendorName, apui.UIMth, apui.APRef, apui.InvTotal, apui.UniqueAttchID,COUNT(apui.KeyID) 
--FROM APUI apui JOIN APVM apvm ON apui.VendorGroup=apvm.VendorGroup AND apui.Vendor=apvm.Vendor
--WHERE APCo<100 GROUP BY apui.VendorGroup, apui.Vendor, apvm.Name , apui.UIMth, apui.APRef, apui.InvTotal,apui.UniqueAttchID
--HAVING COUNT(*) <> 1

--/*
--SELECT 
--	apui.APCo
--,	apui.UIMth
--,	apui.UISeq
--,	hqai.APCo
--,	hqai.APReference
--,	hqat.DocName
--,	hqat.DocAttchYN 
--FROM 
--	HQAI hqai JOIN
--	HQAT hqat ON
--		hqai.AttachmentID=hqat.AttachmentID LEFT OUTER JOIN
--	APUI apui ON
--		hqai.APCo=apui.APCo
--	AND hqai.APReference=apui.APRef
--	AND hqai.UniqueAttchID=apui.UniqueAttchID
--*/	

--SELECT * FROM HQAI
--SELECT * FROM HQAT

--SELECT
--	apui.UniqueAttchID
--,	apui.APCo
--,	apui.UIMth
--,	apui.UISeq
--,	apui.VendorGroup
--,	apui.Vendor
--,	apui.APRef
--,	hqai.IndexSeq
--,	hqai.IndexName
--,	hqai.UniqueAttchID
--,	hqat.OrigFileName
--,	hqat.DocAttchYN
--,	hqat.DocName
--,	hqat.AttachmentID
--,	hqat.UniqueAttchID
--,	apui.InvTotal
--FROM	
--	HQAI hqai LEFT OUTER JOIN
--	APUI apui ON 
--		hqai.APCo=apui.APCo
--	AND hqai.APReference=apui.APRef
--	AND hqai.APVendorGroup=apui.VendorGroup
--	AND hqai.APVendor=apui.Vendor LEFT OUTER JOIN
--	HQAT hqat ON
--		--hqai.UniqueAttchID=hqat.UniqueAttchID
--		hqai.AttachmentID=hqat.AttachmentID
--	AND hqat.AttachmentTypeID IN (50064,50063,50061,50056,4)
--WHERE
--	apui.APRef='59903'

--SELECT * FROM HQAI


--SELECT
--	t1.DocName
--,	MAX(IX_IndexSeq)
--,	COUNT(*)
--from 
--(
--SELECT 
--	--CAST(SUBSTRING(hqat.KeyField, CHARINDEX('KeyID=',hqat.KeyField) + 6, LEN(hqat.KeyField) - (CHARINDEX('KeyID=',hqat.KeyField) + 6) ) AS INT)
--	hqat.HQCo
--,	hqat.FormName
--,	hqat.TableName
--,	hqat.Description
--,	hqat.AddedBy
--,	hqat.AddDate
--,	hqat.DocName
--,	dmat.Name AS AttachmentType
--,	hqat.DocAttchYN
--,	hqat.CurrentState
--,	hqat.AttachmentID
--,	hqat.UniqueAttchID
--,	hqat.KeyField
--,	hqai.IndexSeq AS IX_IndexSeq
--,	hqai.APCo AS IX_APCo
--,	hqai.APVendorGroup AS IX_APVendorGroup
--,	hqai.APVendor AS IX_APVendor
--,	hqai.APReference AS IX_APReference
--,	apui.APCo AS APUI_APCo
--,	apui.VendorGroup AS APUI_VendorGroup
--,	apui.Vendor AS APUI_Vendor
--,	apui.APRef AS APUI_APRef
--,	apui.KeyID AS APUI_KeyID
--,	apui.UniqueAttchID AS APUI_UniqueAttchID
--,	hqai.*
--from 
--	HQAT hqat LEFT OUTER JOIN
--	HQAI hqai ON
--		hqat.AttachmentID=hqai.AttachmentID LEFT OUTER JOIN
--	APUI apui ON 
--		CAST(SUBSTRING(hqat.KeyField, CHARINDEX('KeyID=',hqat.KeyField) + 6, LEN(hqat.KeyField) - (CHARINDEX('KeyID=',hqat.KeyField) + 6) ) AS INT)=apui.KeyID	LEFT OUTER JOIN
--	APVM apvm ON
--		apui.VendorGroup=apvm.VendorGroup	
--	AND apui.Vendor=apvm.Vendor LEFT OUTER JOIN 
--	DMAttachmentTypesShared dmat ON
--		hqat.AttachmentTypeID=dmat.AttachmentTypeID
	
--WHERE 
--	hqat.AttachmentTypeID IN (50064,50063,50061,50056,4)
--AND hqat.TableName IN ('APUI')
--AND hqat.DocName='\\mckconimg\ViewpointAttachments\No Company\AP\APUnappInv\10-2014\AP_201411060000063.pdf'
--) t1
--GROUP BY
--	t1.DocName
--HAVING 
--	COUNT(*) > 1
--ORDER BY 2



--SELECT * FROM HQAT WHERE DocName='\\mckconimg\ViewpointAttachments\No Company\AP\APUnappInv\10-2014\AP_201411060000063.pdf'


--SELECT * FROM APUI WHERE KeyID=15333
--SELECT * FROM APUI WHERE APCo=1 AND VendorGroup=1 AND Vendor=50127 AND APRef='B73011014'


alter PROCEDURE spAttachmentAudit
(
	@TableName		sysname			='APUI'
,	@AttachmentID	INT				=NULL
,	@Document		VARCHAR(255)	= null
)
AS

SET NOCOUNT ON

DECLARE hqat_cur CURSOR FOR
SELECT
	hqat.HQCo
,	hqat.FormName
,	hqat.TableName
,	hqat.Description
,	hqat.AddedBy
,	hqat.AddDate
,	hqat.DocName
,	dmat.Name AS AttachmentType
,	hqat.DocAttchYN
,	hqat.CurrentState
,	hqat.AttachmentID
,	hqat.UniqueAttchID
,	hqat.KeyField
,	CAST(SUBSTRING(hqat.KeyField, CHARINDEX('KeyID=',hqat.KeyField) + 6, LEN(hqat.KeyField) - (CHARINDEX('KeyID=',hqat.KeyField) + 6) ) AS INT)
FROM
	HQAT hqat LEFT OUTER JOIN 
	DMAttachmentTypesShared dmat ON
		hqat.AttachmentTypeID=dmat.AttachmentTypeID
WHERE 
	hqat.TableName = @TableName
AND ( hqat.AttachmentID=@AttachmentID OR @AttachmentID IS NULL)
AND ( hqat.DocName LIKE '%' + @Document + '%' OR @Document IS NULL)
ORDER BY
	hqat.HQCo
,	hqat.AddDate
,	hqat.AddedBy
,	hqat.DocName
FOR READ ONLY

DECLARE @rcnt INT

DECLARE @hqat_HQCo bCompany
DECLARE @hqat_Form VARCHAR(30)
DECLARE @hqat_TableName sysname
DECLARE @hqat_Description bDesc
DECLARE @hqat_AddedBy VARCHAR(30)
DECLARE @hqat_AddDate	DATETIME
DECLARE @hqat_DocName	VARCHAR(255)
DECLARE @hqat_AttType VARCHAR(30)
DECLARE @hqat_DocAttchYN bYN
DECLARE @hqat_CurrentState CHAR(1)
DECLARE @hqat_AttachmentID int
DECLARE @hqat_UniqueAttchID UNIQUEIDENTIFIER
DECLARE @hqat_KeyField VARCHAR(100)
DECLARE @hqat_APUIKey VARCHAR(100)

DECLARE @hqai_IX_IndexSeq INT 
DECLARE @hqai_IX_APCo bCompany 
DECLARE @hqai_IX_APVendorGroup bGroup
DECLARE @hqai_IX_APVendor bVendor
DECLARE @hqai_IX_APReference VARCHAR(50)

DECLARE @hqai_apui_APCo bCompany
DECLARE @hqai_apui_UIMth bMonth
DECLARE @hqai_apui_UISeq  int
DECLARE @hqai_apui_VendorGroup  int
DECLARE @hqai_apui_Vendor INT
DECLARE @hqai_hqai_APRef VARCHAR(50)

DECLARE @apui_APCo bCompany
DECLARE @apui_UIMth bMonth
DECLARE @apui_UISeq  int
DECLARE @apui_VendorGroup  int
DECLARE @apui_Vendor INT
DECLARE @hqai_APRef VARCHAR(50)

SELECT @rcnt=0

OPEN hqat_cur
FETCH hqat_cur INTO
	@hqat_HQCo --bCompany
,	@hqat_Form --VARCHAR(30)
,	@hqat_TableName --sysname
,	@hqat_Description --bDesc
,	@hqat_AddedBy --VARCHAR(30)
,	@hqat_AddDate	--DATETIME
,	@hqat_DocName	--VARCHAR(255)
,	@hqat_AttType --VARCHAR(30)
,	@hqat_DocAttchYN --bYN
,	@hqat_CurrentState --int
,	@hqat_AttachmentID --int
,	@hqat_UniqueAttchID --UNIQUEIDENTIFIER
,	@hqat_KeyField --VARCHAR(100)
,	@hqat_APUIKey

WHILE @@FETCH_STATUS = 0
BEGIN

	SELECT @rcnt=@rcnt+1
	PRINT REPLICATE('-',300)
	PRINT 
		CAST(@rcnt AS CHAR(12))--bCompany
	+	CAST(@hqat_HQCo AS CHAR(5))--bCompany
	+	CAST(@hqat_Form AS CHAR(20)) --VARCHAR(30)
	+	CAST(@hqat_TableName AS CHAR(20)) --sysname
	+	CAST(@hqat_Description AS CHAR(30)) --bDesc
	+	CAST(@hqat_AddedBy AS CHAR(30)) --VARCHAR(30)
	+	CONVERT(CHAR(20),@hqat_AddDate,120)	--DATETIME
	+	CAST(@hqat_DocAttchYN AS CHAR(5)) --bYN
	+	CAST(@hqat_CurrentState AS CHAR(5)) --int
	+	CAST(@hqat_AttachmentID AS CHAR(15)) --int
	+	CAST(@hqat_UniqueAttchID AS CHAR(64)) --UNIQUEIDENTIFIER
	+	CAST(@hqat_KeyField AS CHAR(30)) --VARCHAR(100)
	+	CAST(@hqat_APUIKey AS CHAR(30)) --VARCHAR(100)
	PRINT REPLICATE('-',300)
	print
		CAST('' AS CHAR(12))
	+	'[' + CAST(@hqat_AttType AS CHAR(30)) + '] ' --VARCHAR(30)
	+	CAST(@hqat_DocName AS CHAR(2555))	--VARCHAR(255)

	PRINT CAST('' AS CHAR(12)) + REPLICATE('-',288)

	IF EXISTS ( SELECT 1 FROM HQAI WHERE AttachmentID=@hqat_AttachmentID )
	begin
		DECLARE hqai_cur CURSOR FOR
		SELECT
			hqai.IndexSeq AS IX_IndexSeq
		,	hqai.APCo AS IX_APCo
		,	hqai.APVendorGroup AS IX_APVendorGroup
		,	hqai.APVendor AS IX_APVendor
		,	hqai.APReference AS IX_APReference
		from 
			HQAI hqai
		WHERE
			hqai.AttachmentID=@hqat_AttachmentID
		ORDER BY 
			hqai.IndexSeq
		FOR READ ONLY

		OPEN hqai_cur
		FETCH hqai_cur INTO
			@hqai_IX_IndexSeq --INT 
		,	@hqai_IX_APCo --bCompany 
		,	@hqai_IX_APVendorGroup --bGroup
		,	@hqai_IX_APVendor --bVendor
		,	@hqai_IX_APReference --VARCHAR(30)

		WHILE @@FETCH_STATUS=0
		BEGIN

			print
				CAST('HQAI' AS CHAR(20))
			+	CAST(@hqai_IX_IndexSeq AS CHAR(10))--INT 
			+	CAST(@hqai_IX_APCo AS CHAR(10)) --bCompany 
			+	CAST(@hqai_IX_APVendorGroup AS CHAR(10)) --bGroup
			+	CAST(@hqai_IX_APVendor AS CHAR(10)) --bVendor
			+	CAST(@hqai_IX_APReference AS CHAR(50)) --VARCHAR(30)

			IF EXISTS ( SELECT 1 FROM APUI WHERE APCo=@hqai_IX_APCo AND VendorGroup=@hqai_IX_APVendorGroup AND Vendor=@hqai_IX_APVendor AND APRef=@hqai_IX_APReference)
			BEGIN
				--print
				--	CAST('' AS CHAR(20))
				--+	'APUI Records found using APCo, VendorGroup, Vendor and APRef'

				PRINT CAST('' AS CHAR(20)) + REPLICATE('-',288)

				DECLARE hqai_apui_cur CURSOR FOR
				SELECT
					apui.APCo
				,	apui.UIMth
				,	apui.UISeq
				,	apui.VendorGroup
				,	apui.Vendor
				,	apui.APRef
				from 
					APUI apui
				WHERE
					APCo=@hqai_IX_APCo 
				AND VendorGroup=@hqai_IX_APVendorGroup 
				AND Vendor=@hqai_IX_APVendor 
				AND APRef=@hqai_IX_APReference
				ORDER BY 
					apui.APCo
				,	apui.UIMth
				,	apui.UISeq
				FOR READ ONLY

				OPEN hqai_apui_cur
				FETCH hqai_apui_cur INTO
					@hqai_apui_APCo
				,	@hqai_apui_UIMth
				,	@hqai_apui_UISeq
				,	@hqai_apui_VendorGroup
				,	@hqai_apui_Vendor
				,	@hqai_hqai_APRef


				WHILE @@FETCH_STATUS=0
				BEGIN

					print
						CAST('HQAI_APUI' AS CHAR(30))
					+	CAST(@hqai_apui_APCo AS CHAR(10))--INT 
					+	CAST(CONVERT(VARCHAR(10),@hqai_apui_UIMth,102) AS CHAR(12)) --bCompany 
					+	CAST(@hqai_apui_UISeq AS CHAR(10)) --bGroup
					+	CAST(@hqai_apui_VendorGroup AS CHAR(10)) --bVendor
					+	CAST(@hqai_apui_Vendor AS CHAR(20)) --VARCHAR(30)
					+	CAST(@hqai_hqai_APRef AS CHAR(50)) --VARCHAR(30)


					FETCH hqai_apui_cur INTO
						@hqai_apui_APCo
					,	@hqai_apui_UIMth
					,	@hqai_apui_UISeq
					,	@hqai_apui_VendorGroup
					,	@hqai_apui_Vendor
					,	@hqai_hqai_APRef

				END
	
				CLOSE hqai_apui_cur
				DEALLOCATE hqai_apui_cur
				
			END
			ELSE
            begin
				print
					CAST('HQAI_APUI' AS CHAR(30))
				+	' ** APUI Records NOT found using APCo, VendorGroup, Vendor and APRef : '
				+	CAST(@hqai_IX_APCo AS VARCHAR(10)) + ', ' 
				+	CAST(@hqai_IX_APVendorGroup AS VARCHAR(10)) + ', ' 
				+	CAST(@hqai_IX_APVendor AS VARCHAR(20)) + ', ' 
				+	CAST(@hqai_IX_APReference AS VARCHAR(50))


			END

			FETCH hqai_cur INTO
				@hqai_IX_IndexSeq --INT 
			,	@hqai_IX_APCo --bCompany 
			,	@hqai_IX_APVendorGroup --bGroup
			,	@hqai_IX_APVendor --bVendor
			,	@hqai_IX_APReference --VARCHAR(30)

		END
	
		CLOSE hqai_cur
		DEALLOCATE hqai_cur
	END
	ELSE
	BEGIN
		print
				CAST('' AS CHAR(20))
			+	' ** HQAI Index Records NOT found using AttachmentID=' + CAST(@hqat_AttachmentID AS VARCHAR(30))
	END

	--PRINT CAST('' AS CHAR(30)) + REPLICATE('-',288)

	IF EXISTS ( SELECT 1 FROM APUI WHERE KeyID=@hqat_APUIKey)
	begin
		DECLARE apui_cur CURSOR FOR
		SELECT
			apui.APCo
		,	apui.UIMth
		,	apui.UISeq
		,	apui.VendorGroup
		,	apui.Vendor
		,	apui.APRef
		from 
			APUI apui
		WHERE
			apui.KeyID=@hqat_APUIKey
		ORDER BY 
		apui.APCo
		,	apui.UIMth
		,	apui.UISeq
		FOR READ ONLY

		OPEN apui_cur
		FETCH apui_cur INTO
			@apui_APCo
		,	@apui_UIMth
		,	@apui_UISeq
		,	@apui_VendorGroup
		,	@apui_Vendor
		,	@hqai_APRef


		WHILE @@FETCH_STATUS=0
		BEGIN

			print
				CAST('APUI (Key)' AS CHAR(30))
			+	CAST(@apui_APCo AS CHAR(10))--INT 
			+	CAST(CONVERT(VARCHAR(10),@apui_UIMth,102) AS CHAR(12)) --bCompany 
			+	CAST(@apui_UISeq AS CHAR(10)) --bGroup
			+	CAST(@apui_VendorGroup AS CHAR(10)) --bVendor
			+	CAST(@apui_Vendor AS CHAR(20)) --VARCHAR(30)
			+	CAST(@hqai_APRef AS CHAR(50)) --VARCHAR(30)


			FETCH apui_cur INTO
				@apui_APCo
			,	@apui_UIMth
			,	@apui_UISeq
			,	@apui_VendorGroup
			,	@apui_Vendor
			,	@hqai_APRef

		END
	
		CLOSE apui_cur
		DEALLOCATE apui_cur
	END
	ELSE
	BEGIN
		print
				CAST('APUI (Key)' AS CHAR(20))
			+	'** APUI Records NOT found using KeyID=' + CAST(@hqat_APUIKey AS VARCHAR(30))
	END

	IF EXISTS ( SELECT 1 FROM APUI WHERE UniqueAttchID=@hqat_UniqueAttchID)
	begin
		DECLARE apui_cur CURSOR FOR
		SELECT
			apui.APCo
		,	apui.UIMth
		,	apui.UISeq
		,	apui.VendorGroup
		,	apui.Vendor
		,	apui.APRef
		from 
			APUI apui
		WHERE
			apui.UniqueAttchID=@hqat_UniqueAttchID
		ORDER BY 
		apui.APCo
		,	apui.UIMth
		,	apui.UISeq
		FOR READ ONLY

		OPEN apui_cur
		FETCH apui_cur INTO
			@apui_APCo
		,	@apui_UIMth
		,	@apui_UISeq
		,	@apui_VendorGroup
		,	@apui_Vendor
		,	@hqai_APRef


		WHILE @@FETCH_STATUS=0
		BEGIN

			print
				CAST('APUI (UID)' AS CHAR(30))
			+	CAST(@apui_APCo AS CHAR(10))--INT 
			+	CAST(CONVERT(VARCHAR(10),@apui_UIMth,102) AS CHAR(12)) --bCompany 
			+	CAST(@apui_UISeq AS CHAR(10)) --bGroup
			+	CAST(@apui_VendorGroup AS CHAR(10)) --bVendor
			+	CAST(@apui_Vendor AS CHAR(20)) --VARCHAR(30)
			+	CAST(@hqai_APRef AS CHAR(50)) --VARCHAR(30)


			FETCH apui_cur INTO
				@apui_APCo
			,	@apui_UIMth
			,	@apui_UISeq
			,	@apui_VendorGroup
			,	@apui_Vendor
			,	@hqai_APRef

		END
	
		CLOSE apui_cur
		DEALLOCATE apui_cur
	END
	ELSE
	BEGIN
		print
				CAST('APUI (UID)' AS CHAR(20))
			+	'** APUI Records NOT found using UniqueAttchID=' + CAST(@hqat_UniqueAttchID AS VARCHAR(64))
	END
	PRINT ''

	FETCH hqat_cur INTO
		@hqat_HQCo --bCompany
	,	@hqat_Form --VARCHAR(30)
	,	@hqat_TableName --sysname
	,	@hqat_Description --bDesc
	,	@hqat_AddedBy --VARCHAR(30)
	,	@hqat_AddDate	--DATETIME
	,	@hqat_DocName	--VARCHAR(255)
	,	@hqat_AttType --VARCHAR(30)
	,	@hqat_DocAttchYN --bYN
	,	@hqat_CurrentState --int
	,	@hqat_AttachmentID --int
	,	@hqat_UniqueAttchID --UNIQUEIDENTIFIER
	,	@hqat_KeyField --VARCHAR(100)
	,	@hqat_APUIKey

END

CLOSE hqat_cur
DEALLOCATE hqat_cur
GO


EXEC spAttachmentAudit 
	@TableName		=	'APUI'
,	@AttachmentID	=	NULL
,	@Document		=	NULL --'AP_2014112'


--SELECT * FROM DMAttachmentAuditLog WHERE DateTime BETWEEN '12/6/2014' AND '12/8/2014' ORDER BY DateTime desc