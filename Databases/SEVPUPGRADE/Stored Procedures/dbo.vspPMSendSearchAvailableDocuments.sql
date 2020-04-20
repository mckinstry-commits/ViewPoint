
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/********************************************************/
CREATE procedure [dbo].[vspPMSendSearchAvailableDocuments]
/************************************************************************
* Created By:	TRL 10/19/2012 TK-18468 Added procedure to database
* Modified By:	GP  10/19/2012 Added FormCo and UniqueAttchID, also fixed cast of Rev errors
*				TRL 10/25/2012 TK-18827 Added SourceDocumentKeyID parameter
*				GP	10/12/2012 TK-19144 Removed check against KeyID, created another proc for selected records
*				TRL 11/28/2012 TK-19691  Added section for SUBITEM
*				GP	12/06/2012 TK-19818 Added DocType to select for PMSubmittalPackage
*				AJW 12/13/12 TK-20167 Refactored to include logic from vspPMSendSearchSelectedDocuments 
*						and add DDFH info and contact counts to results
*				AJW 05/09/2013 TFS-49469 Performance change
*
* This stored procedure will search for available document (form records) 
* that can be used to link documents for a message
*
*************************************************************************/
(@PMCo bCompany, @Project bProject, @FormName varchar(30)=NULL, @DocumentType bDocType=NULL,
@Firm bVendor=NULL, @Vendor bVendor=NULL, @SourceDocumentKeyID bigint = null,
@errmsg varchar(256)=NULL)

AS

SET NOCOUNT ON 

DECLARE @rcode tinyint, @templatetype varchar(max), @tmpformname varchar(max), @tablename varchar(max) 

select @rcode = 0

IF @PMCo IS NULL
BEGIN
	select @errmsg = 'Missing PM Company', @rcode=1
	goto vspexit
END

IF @Project IS NULL
BEGIN
	select @errmsg = 'Missing Project', @rcode=1
	goto vspexit
END

CREATE TABLE #DocumentTable(
  [Doc Type] VARCHAR(MAX),
  [Doc ID] VARCHAR(MAX),
  [Revision] VARCHAR(MAX),
  [Date] SMALLDATETIME,
  [Description] VARCHAR(MAX),
  [Firm] VARCHAR(MAX),
  [Firm Name] VARCHAR(MAX),
  [Vendor] VARCHAR(MAX),
  [Vendor Name] VARCHAR(MAX),
  [Doc Cat] VARCHAR(MAX),
  [FormName] VARCHAR(MAX),
  [KeyID] BIGINT,
  [FormCo] BIGINT,
  [UniqueAttchID] uniqueidentifier
)

SET @tmpformname = 'PMChangeOrderRequest'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--COR:  No Doc Type, No Revision, No Responible Firm, No Vendor
	SET @templatetype = 'COR'
	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT null AS [Doc Type], Convert(varchar,a.COR) AS [Doc ID], null AS [Revision], a.Date AS [Date],
		a.Description AS [Description], null AS [Firm], null AS [Firm Name], null AS [Vendor], null AS [Vendor Name],
		@templatetype AS [Doc Cat], @tmpformname AS [FormName], a.KeyID AS [KeyID], a.PMCo as [FormCo], a.UniqueAttchID AS [UniqueAttchID]
	FROM dbo.PMChangeOrderRequest a
		INNER JOIN dbo.JCJM b ON  a.PMCo=b.JCCo and a.Contract=b.Contract
	WHERE a.PMCo=@PMCo AND b.Job = @Project AND @DocumentType IS NULL AND @Firm IS NULL AND @Vendor IS NULL
END

SET @tmpformname = 'PMContractChangeOrder'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
    --CCO:  No Doc Type, No Revision, No Responible Firm, No Vendor
	SET @templatetype = 'CCO'
	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT null AS [Doc Type], Convert(varchar,a.ID) AS [Doc ID], null AS [Revision], a.Date AS [Date], a.Description AS [Description], 
		  null AS [Firm], null AS [Firm Name], null AS [Vendor], null AS [Vendor Name], 
		  @templatetype as [Doc Cat], @tmpformname AS [FormName], a.KeyID AS [KeyID], a.PMCo as [FormCo], a.UniqueAttchID
	FROM dbo.PMContractChangeOrder a
		INNER JOIN dbo.JCJM b ON  a.PMCo=b.JCCo and a.Contract=b.Contract
	WHERE a.PMCo=@PMCo AND b.Job = @Project 
		AND @DocumentType IS NULL  AND @Firm IS NULL AND @Vendor IS NULL
END

SET @tmpformname = 'PMDrawingLogs'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--DRAWING:  Has Doc Type, No Revision, No Responible Firm, No Vendor
	SET @templatetype = 'DRAWING'
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT h.DrawingType AS [Doc Type], h.Drawing AS [Doc ID], null AS [Revision], h.DateIssued AS [Date], h.Description AS [Description], 
		null AS [Firm], null AS [Firm Name], null AS [Vendor], null AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], h.KeyID AS [KeyID], h.PMCo as [FormCo], h.UniqueAttchID
	FROM dbo.PMDG h 
		LEFT JOIN PMDR d on h.PMCo=d.PMCo AND h.Project=d.Project AND h.DrawingType=d.DrawingType AND h.Drawing=d.Drawing
	WHERE h.PMCo=@PMCo AND h.Project = @Project AND ISNULL(h.DrawingType,'')=IsNull(@DocumentType,ISNULL(h.DrawingType,''))
		AND @Firm IS NULL AND @Vendor IS NULL
	GROUP BY h.DrawingType,h.Drawing, h.DateIssued, h.Description, h.KeyID, h.PMCo, h.UniqueAttchID
END

SET @tmpformname = 'PMInspectionLogs'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--INSPECT:  Has Doc Type, No Revision, No Responible Firm, No Vendor
	SET @templatetype = 'INSPECT'
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT  InspectionType AS [Doc Type], InspectionCode AS [Doc ID], null AS [Revision], InspectionDate AS [Date], Description AS [Description], 
		null AS [Firm], null AS [Firm Name], null AS [Vendor], null AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], KeyID AS [KeyID], PMCo as [FormCo], UniqueAttchID
	FROM dbo.PMIL 
	WHERE PMCo=@PMCo AND Project = @Project  AND ISNULL(InspectionType,'')=ISNULL(@DocumentType,ISNULL(InspectionType,'')) 
		AND @Firm IS NULL AND @Vendor IS NULL
END

SET @tmpformname = 'PMProjectIssues'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--ISSUE:  No Doc Type, No Revision, No Responible Firm, No Vendor
	SET @templatetype = 'ISSUE'
	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT null AS [Doc Type], CONVERT(varchar,Issue) AS [Doc ID], null AS [Revision], DateInitiated AS [Date], Description AS [Description], 
		RelatedFirm AS [Firm], PMFM.FirmName AS [Firm Name], null AS [Vendor], null AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], PMIM.KeyID AS [KeyID], 
		PMIM.PMCo as [FormCo], PMIM.UniqueAttchID
	FROM dbo.PMIM 
		LEFT JOIN dbo.PMFM ON PMIM.VendorGroup=PMFM.VendorGroup AND PMIM.RelatedFirm=PMFM.FirmNumber
	WHERE PMCo=@PMCo AND Project = @Project  AND ISNULL(RelatedFirm,'')=ISNULL(@Firm,ISNULL(RelatedFirm,''))
		AND @DocumentType IS NULL  AND @Vendor IS NULL
END

SET @tmpformname = 'PMOtherDocs'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--OTHER:  Has Doc Type, No Revision, Has Responible Firm, No Vendor
	SET @templatetype = 'OTHER'
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT DocType AS [Doc Type], Document AS [Doc ID], null AS [Revision], DateDue AS [Date], Description AS [Description], 
		RelatedFirm AS [Firm], PMFM.FirmName AS [Firm Name], null AS [Vendor], null AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], PMOD.KeyID AS [KeyID], PMOD.PMCo as [FormCo], PMOD.UniqueAttchID
	FROM dbo.PMOD 
		LEFT JOIN dbo.PMFM ON PMOD.VendorGroup=PMFM.VendorGroup AND PMOD.RelatedFirm=PMFM.FirmNumber
	WHERE PMCo=@PMCo AND Project = @Project  AND ISNULL(DocType,'')=ISNULL(@DocumentType,ISNULL(DocType,''))  
		AND ISNULL(RelatedFirm,'') = ISNULL(@Firm,ISNULL(RelatedFirm,'')) AND @Vendor IS NULL
END

SET @tmpformname = 'PMPCOS'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--PCO:  No Doc Type, No Revision, Has Responible Firm, No Vendor
	SET @templatetype = 'PCO'
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT PCOType AS [Doc Type], PCO AS [Doc ID], null AS [Revision], ApprovalDate AS [Date], Description AS [Description], 
		NULL AS [Firm], NULL AS [Firm Name], null AS [Vendor], null AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], PMOP.KeyID AS [KeyID], PMOP.PMCo as [FormCo], PMOP.UniqueAttchID
	FROM dbo.PMOP 
		LEFT JOIN dbo.PMFM ON PMOP.VendorGroup=PMFM.VendorGroup AND PMOP.ResponsibleFirm=PMFM.FirmNumber
	WHERE PMCo=@PMCo AND Project = @Project  AND ISNULL(PCOType,'')=ISNULL(@DocumentType,ISNULL(PCOType,'')) 
		AND @Firm IS NULL
END

/* PURCHASE is not currently a supported doctype Place holder in case we implement it someday */
--SET @tmpformname = 'PMPOHeader'
--IF dbo.vfToString(@FormName) in (@tmpformname,'')
--BEGIN
--	--PURHASE/PO:  No Doc Type, No Revision, No Responible Firm, Has Vendor
--	SET @templatetype = 'PURCHASE'
--  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
--		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
--	SELECT NULL AS [Doc Type], PO AS [Doc ID], null AS [Revision], OrderDate AS [Date], Description AS [Description], 
--		NULL AS [Firm], null AS [Firm Name], POHDPM.Vendor AS [Vendor], APVM.Name AS [Vendor Name],
--		@templatetype as [Doc Cat], @tmpformname AS [FormName], POHDPM.KeyID AS [KeyID], POHDPM.PMCo as [FormCo], POHDPM.UniqueAttchID
--	FROM dbo.POHDPM
--		LEFT JOIN dbo.APVM ON APVM.VendorGroup=POHDPM.VendorGroup AND APVM.Vendor=POHDPM.Vendor
--	WHERE PMCo=@PMCo AND Project = @Project  AND ISNULL(POHDPM.Vendor,'') = ISNULL(@Vendor,ISNULL(POHDPM.Vendor,''))
--		AND @DocumentType IS NULL AND @Firm IS NULL 
--END

SET @tmpformname = 'PMPOCO'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--PURHASECO/POCO:  No Doc Type, Has Revision, No Responible Firm, Has Vendor
	SET @templatetype = 'PURCHASECO'
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT NULL AS [Doc Type], a.PO AS [Doc ID], CAST(a.POCONum AS VARCHAR(10)) AS [Revision], a.Date AS [Date], a.Description AS [Description], 
		NULL AS [Firm], null AS [Firm Name], b.Vendor AS [Vendor], c.Name AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], a.KeyID AS [KeyID], a.PMCo as [FormCo], a.UniqueAttchID
	FROM dbo.PMPOCO a
		LEFT JOIN dbo.POHDPM b ON a.PMCo=b.PMCo AND a.Project =b.Project AND a.PO=b.PO AND a.POCo=b.POCo 
		LEFT JOIN dbo.APVM c ON b.VendorGroup=c.VendorGroup AND b.Vendor=c.Vendor
	WHERE a.PMCo=@PMCo AND a.Project = @Project  AND ISNULL(b.Vendor,'') = ISNULL(@Vendor,ISNULL(b.Vendor,''))
		AND @DocumentType IS NULL AND @Firm IS NULL 
END

SET @tmpformname = 'PMRFI'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--RFI:  Has Doc Type, No Revision, Has Responible Firm, No Vendor
	SET @templatetype = 'RFI'
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT  RFIType AS [Doc Type], RFI AS [Doc ID], null AS [Revision], RFIDate AS [Date], Subject AS [Description], 
		ReqFirm AS [Firm], PMFM.FirmName AS [Firm Name], null AS [Vendor], null AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], PMRI.KeyID AS [KeyID], PMRI.PMCo as [FormCo], PMRI.UniqueAttchID
	FROM dbo.PMRI 
		LEFT JOIN dbo.PMFM ON PMRI.VendorGroup=PMFM.VendorGroup AND PMRI.ReqFirm=PMFM.FirmNumber
	WHERE PMCo=@PMCo AND Project = @Project  AND ISNULL(RFIType,'')=ISNULL(@DocumentType,ISNULL(RFIType,'')) AND ISNULL(ReqFirm,'')=ISNULL(@Firm,ISNULL(ReqFirm,'')) 
		AND @Vendor IS NULL
END

SET @tmpformname = 'PMRFQ'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--RFQ:  Has Doc Type, Has Revision, No Responible Firm, No Vendor
	SET @templatetype = 'RFQ'
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT PCOType AS [Doc Type], PCO AS [Doc ID], CAST(RFQ AS VARCHAR(10)) AS [Revision], RFQDate AS [Date], Description AS [Description], 
		NULL AS [Firm], NULL AS [Firm Name], null AS [Vendor], null AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], KeyID AS [KeyID], PMCo as [FormCo], UniqueAttchID
	FROM dbo.PMRQ 
	WHERE PMCo=@PMCo AND Project = @Project  AND ISNULL(PCOType,'')=ISNULL(@DocumentType,ISNULL(PCOType,'')) 
		AND @Firm IS NULL AND @Vendor IS NULL
END

SET @tmpformname = 'PMSLHeader'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--SUBCONTRACT/SL:  No Doc Type, No Revision, No Responible Firm, Has Vendor
	SET @templatetype = 'SUB'
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT NULL AS [Doc Type], SL AS [Doc ID], null AS [Revision], OrigDate AS [Date], Description AS [Description], 
		NULL AS [Firm], null AS [Firm Name], SLHDPM.Vendor AS [Vendor], APVM.Name AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], SLHDPM.KeyID AS [KeyID], SLHDPM.PMCo as [FormCo], SLHDPM.UniqueAttchID
	FROM dbo.SLHDPM
		LEFT JOIN dbo.APVM ON APVM.VendorGroup=SLHDPM.VendorGroup AND APVM.Vendor=SLHDPM.Vendor
	WHERE PMCo=@PMCo AND Project = @Project  AND ISNULL(SLHDPM.Vendor,'') =ISNULL(@Vendor, ISNULL(SLHDPM.Vendor,''))
		AND @DocumentType IS NULL AND @Firm IS NULL 
END

SET @tmpformname = 'PMSLHeader' -- Sub with items is an exception to the rule where @FormName = DDFH.Form 
IF dbo.vfToString(@FormName) in ('PMSLHeaderItem','')
BEGIN
	--SUBITEM:  No Doc Type, No Revision, No Responible Firm, Has Vendor
	SET @templatetype = 'SUBITEM'
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT NULL AS [Doc Type], SL AS [Doc ID], null AS [Revision], OrigDate AS [Date], Description AS [Description], 
		NULL AS [Firm], null AS [Firm Name], SLHDPM.Vendor AS [Vendor], APVM.Name AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], SLHDPM.KeyID AS [KeyID], SLHDPM.PMCo as [FormCo], SLHDPM.UniqueAttchID
	FROM dbo.SLHDPM
		LEFT JOIN dbo.APVM ON APVM.VendorGroup=SLHDPM.VendorGroup AND APVM.Vendor=SLHDPM.Vendor
	WHERE PMCo=@PMCo AND Project = @Project  AND ISNULL(SLHDPM.Vendor,'') = ISNULL(@Vendor,ISNULL(SLHDPM.Vendor,''))
		AND @DocumentType IS NULL AND @Firm IS NULL
END

SET @tmpformname = 'PMSubcontractCO'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--SUBCO:  No Doc Type, Has Revision, No Responible Firm, Has Vendor
	SET @templatetype = 'SUBCO'
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT NULL AS [Doc Type], a.SL AS [Doc ID], CAST(a.SubCO AS VARCHAR(10)) AS [Revision], a.Date AS [Date], a.Description AS [Description], 
		NULL AS [Firm], null AS [Firm Name], b.Vendor AS [Vendor], c.Name AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], a.KeyID AS [KeyID], a.PMCo as [FormCo], a.UniqueAttchID
	FROM dbo.PMSubcontractCO a
		INNER JOIN dbo.SLHDPM b ON a.PMCo=b.PMCo AND a.Project =b.Project  AND a.SLCo=b.SLCo AND a.SL=b.SL
		LEFT JOIN dbo.APVM c ON b.VendorGroup=c.VendorGroup AND b.Vendor=c.Vendor
	WHERE a.PMCo=@PMCo AND a.Project = @Project  AND ISNULL(b.Vendor,'') = ISNULL(@Vendor,ISNULL(b.Vendor,''))
		AND @DocumentType IS NULL AND @Firm IS NULL
END

SET @tmpformname = 'PMSubmittalRegisterGrid'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--SBMTL:  Has Doc Type, Has Revision, Has Responible Firm, No Vendor
	SET @templatetype = 'SBMTL'
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT  DocumentType AS [Doc Type], SubmittalNumber AS [Doc ID], CAST(SubmittalRev AS VARCHAR(10)) AS [Revision], ActivityDate AS [Date], Description AS [Description], 
		ResponsibleFirm AS [Firm], PMFM.FirmName AS [Firm Name], null AS [Vendor], null AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], PMSubmittal.KeyID AS [KeyID], PMSubmittal.PMCo as [FormCo], 
		PMSubmittal.UniqueAttchID
	FROM dbo.PMSubmittal 
		LEFT JOIN dbo.PMFM ON PMSubmittal.VendorGroup=PMFM.VendorGroup AND PMSubmittal.ResponsibleFirm=PMFM.FirmNumber
	WHERE PMCo=@PMCo AND Project = @Project  AND ISNULL(ResponsibleFirm,'')=ISNULL(@Firm,IsNULL(ResponsibleFirm,'')) 
		AND IsNULL(DocumentType,'')=ISNULL(@DocumentType,IsNULL(DocumentType,'')) 
		AND @Vendor IS NULL
END

SET @tmpformname = 'PMSubmittalPackage'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--SBMTLPCKG:  No Doc Type, Has Revision, No Responible Firm, No Vendor
	SET @templatetype = 'SBMTLPCKG'
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT DocType AS [Doc Type], Package AS [Doc ID], CAST(PackageRev AS VARCHAR(10)) AS [Revision], ActivityDate AS [Date], Description AS [Description], 
		ApprovingFirm AS [Firm], null AS [Firm Name], null AS [Vendor], null AS [Vendor Name],
		@templatetype as [Doc Cat],@tmpformname AS [FormName], PMSubmittalPackage.KeyID AS [KeyID], 
		PMSubmittalPackage.PMCo as [FormCo], PMSubmittalPackage.UniqueAttchID
	FROM dbo.PMSubmittalPackage 
		LEFT JOIN dbo.PMFM ON PMSubmittalPackage.VendorGroup=PMFM.VendorGroup AND PMSubmittalPackage.ApprovingFirm=PMFM.FirmNumber
	WHERE PMCo=@PMCo AND Project = @Project  AND ISNULL(ApprovingFirm,'')=ISNULL(@Firm,ISNULL(ApprovingFirm,''))
		AND ISNULL(DocType,'')=ISNULL(@DocumentType,ISNULL(DocType,'')) AND @Vendor IS NULL
END

SET @tmpformname = 'PMSubmittal'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--SUBMIT: Has Doc Type, Has Revision, Has Responible Firm, No Vendor
	SET @templatetype = 'SUBMIT'
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT SubmittalType AS [Doc Type], Submittal AS [Doc ID], CAST(Rev AS VARCHAR(10)) AS [Revision], DateReqd AS [Date], Description AS [Description], 
		ResponsibleFirm AS [Firm], PMFM.FirmName AS [Firm Name], null AS [Vendor], null AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], PMSM.KeyID AS [KeyID], PMSM.PMCo as [FormCo], PMSM.UniqueAttchID
	FROM dbo.PMSM 
		LEFT JOIN dbo.PMFM ON PMSM.VendorGroup=PMFM.VendorGroup AND PMSM.ResponsibleFirm=PMFM.FirmNumber
	WHERE PMCo=@PMCo AND Project = @Project  AND ISNULL(ResponsibleFirm,'')=ISNULL(@Firm,isnull(ResponsibleFirm,''))
		AND ISNULL(SubmittalType,'')=ISNULL(@DocumentType,ISNULL(SubmittalType,'')) AND @Vendor IS NULL
END

SET @tmpformname = 'PMTestLogs'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--TEST:  Has Doc Type, No Revision, No Responible Firm, No Vendor
	SET @templatetype = 'TEST'
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT TestType AS [Doc Type], TestCode AS [Doc ID], NULL AS [Revision], TestDate AS [Date], Description AS [Description], 
		TestFirm AS [Firm], PMFM.FirmName AS [Firm Name], null AS [Vendor], null AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], PMTL.KeyID AS [KeyID], PMTL.PMCo as [FormCo], PMTL.UniqueAttchID
	FROM dbo.PMTL 
		LEFT JOIN dbo.PMFM ON PMTL.VendorGroup=PMFM.VendorGroup AND PMTL.TestFirm=PMFM.FirmNumber
	WHERE PMCo=@PMCo AND Project = @Project  AND ISNULL(TestType,'')=ISNULL(@DocumentType,ISNULL(TestType,'')) AND ISNULL(TestFirm,'')=ISNULL(@Firm,ISNULL(TestFirm,''))
		AND @Vendor IS NULL
END

SET @tmpformname = 'PMTransmittal'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--TRANSMIT:  No Doc Type, No Revision, Has Responible Firm, No Vendor
	SET @templatetype = 'TRANSMIT'
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT NULL AS [Doc Type], Transmittal AS [Doc ID], NULL AS [Revision], TransDate AS [Date], Subject AS [Description], 
		ResponsibleFirm AS [Firm], PMFM.FirmName AS [Firm Name], null AS [Vendor], null AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], PMTM.KeyID AS [KeyID], PMTM.PMCo as [FormCo], PMTM.UniqueAttchID
	FROM dbo.PMTM 
		LEFT JOIN dbo.PMFM ON PMTM.VendorGroup=PMFM.VendorGroup AND PMTM.ResponsibleFirm=PMFM.FirmNumber
	WHERE PMCo=@PMCo AND Project = @Project  
		AND @DocumentType IS NULL AND @Vendor IS NULL
END

-- return results from TableVariable Joining to PMCT and DDFH
SELECT t.Description as [Category], d.[Doc Type], d.[Doc ID], d.Revision, d.Date, d.Description, d.Firm, d.[Firm Name],
	d.Vendor, d.[Vendor Name], d.[Doc Cat], d.[FormName],
	f.ViewName AS [TableName], d.KeyID, d.FormCo, d.UniqueAttchID
	,f.AssemblyName AS [AssemblyName], f.FormClassName AS [FormClassName],
	 --SBMTL & SBMTLPKCG currently don't require any distribution to be set up for doc creation so ret 1 from them
	CASE WHEN d.[Doc Cat] in ('SBMTL','SBMTLPCKG') THEN 1 ELSE COUNT(v.DocKeyID) END as ContactCount
FROM #DocumentTable d
	JOIN DDFH f on f.Form=d.FormName
	JOIN PMCT t on d.[Doc Cat]=t.DocCat
	LEFT JOIN PMDocDistribution v on v.DocCat=d.[Doc Cat] and v.DocKeyID=d.KeyID
WHERE d.KeyID = isnull(@SourceDocumentKeyID,d.KeyID)
	AND isnull(v.CC,'N') = 'N' and isnull(v.Send,'Y') = 'Y' -- only Active To contacts should be counted
GROUP BY t.Description, d.[Doc Type], d.[Doc ID], d.Revision, d.Date, d.Description, d.Firm, d.[Firm Name],
	d.Vendor, d.[Vendor Name], d.[Doc Cat], d.[FormName],
	f.ViewName, d.KeyID, d.FormCo, d.UniqueAttchID
	,f.AssemblyName, f.FormClassName
ORDER BY [Category],[Doc Type],[Doc ID] desc,Revision,Date
vspexit:
	return @rcode



GO

GRANT EXECUTE ON  [dbo].[vspPMSendSearchAvailableDocuments] TO [public]
GO
