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
*				TRL  02/05/2012 Task 29751, User Story 13599 Added selection for Meeting Minutes
*				SCOTTP 03/28/2013 TFS-45312 Add support to return document for Request for Quote
*											DocCat = 'REQQUOTE', Form = 'PMRequestForQuote'
*				GP	04/11/2013 TFS 13594 Added select for DAILYLOG
*				GP	04/11/2013 TFS 13585 Added select for ACO
*				SCOTTP 04/12/2013 TFS 42224 Add support for PURCHASE (code was commented out)
*				TRL  04/20/2013 TFS 13609 Add select for PUNCH
*				AJW  04/29/2013 TFS - 47813 Make all Docs support Transmittals
*				SCOTTP 05/06/2013 TFS - 47813 Add support for Transmittal DocType column
*				AJW 05/08/13 TFS - 49469 Change to use temp table for performance
*				SCOTTP 08/20/2013 TFS-58637 When getting Purchase Orders, add union to also get records from POHDPM
*							When getting Subcontacts, add union to also get records from SLHDPM.
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

Create TABLE #DocumentTable(
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
	SELECT a.DocType AS [Doc Type], Convert(varchar,a.COR) AS [Doc ID], null AS [Revision], a.Date AS [Date],
		a.Description AS [Description], null AS [Firm], null AS [Firm Name], null AS [Vendor], null AS [Vendor Name],
		@templatetype AS [Doc Cat], @tmpformname AS [FormName], a.KeyID AS [KeyID], a.PMCo as [FormCo], a.UniqueAttchID AS [UniqueAttchID]
	FROM dbo.PMChangeOrderRequest a
		INNER JOIN dbo.JCJM b ON  a.PMCo=b.JCCo and a.Contract=b.Contract
	WHERE a.PMCo=@PMCo AND b.Job = @Project AND @Firm IS NULL AND @Vendor IS NULL
END

SET @tmpformname = 'PMContractChangeOrder'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
    --CCO:  No Doc Type, No Revision, No Responible Firm, No Vendor
	SET @templatetype = 'CCO'
	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT a.DocType AS [Doc Type], Convert(varchar,a.ID) AS [Doc ID], null AS [Revision], a.Date AS [Date], a.Description AS [Description], 
		  null AS [Firm], null AS [Firm Name], null AS [Vendor], null AS [Vendor Name], 
		  @templatetype as [Doc Cat], @tmpformname AS [FormName], a.KeyID AS [KeyID], a.PMCo as [FormCo], a.UniqueAttchID
	FROM dbo.PMContractChangeOrder a
		INNER JOIN dbo.JCJM b ON  a.PMCo=b.JCCo and a.Contract=b.Contract
	WHERE a.PMCo=@PMCo AND b.Job = @Project 
		AND @Firm IS NULL AND @Vendor IS NULL
END

SET @tmpformname = 'PMDailyLog'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--DAILYLOG:  No Doc Type, No Revision, No Responible Firm, No Vendor
	SET @templatetype = 'DAILYLOG'
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT h.DocType AS [Doc Type], h.DailyLog AS [Doc ID], null AS [Revision], h.LogDate AS [Date], h.Description AS [Description], 
		null AS [Firm], null AS [Firm Name], null AS [Vendor], null AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], h.KeyID AS [KeyID], h.PMCo as [FormCo], h.UniqueAttchID
	FROM dbo.PMDL h 
	WHERE h.PMCo=@PMCo AND h.Project = @Project AND @Firm IS NULL AND @Vendor IS NULL
	GROUP BY h.DocType,h.DailyLog, h.LogDate, h.Description, h.KeyID, h.PMCo, h.UniqueAttchID
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
	SELECT [Type] AS [Doc Type], CONVERT(varchar,Issue) AS [Doc ID], null AS [Revision], DateInitiated AS [Date], Description AS [Description], 
		RelatedFirm AS [Firm], PMFM.FirmName AS [Firm Name], null AS [Vendor], null AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], PMIM.KeyID AS [KeyID], 
		PMIM.PMCo as [FormCo], PMIM.UniqueAttchID
	FROM dbo.PMIM 
		LEFT JOIN dbo.PMFM ON PMIM.VendorGroup=PMFM.VendorGroup AND PMIM.RelatedFirm=PMFM.FirmNumber
	WHERE PMCo=@PMCo AND Project = @Project  AND ISNULL(RelatedFirm,'')=ISNULL(@Firm,ISNULL(RelatedFirm,''))
		AND @Vendor IS NULL
END

SET @tmpformname = 'PMMeetingMinutes'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--MTG:  Has Doc Type, Has Revision, Has Responible Firm, No Vendor
	SET @templatetype = 'MTG'
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT MeetingType AS [Doc Type], Meeting AS [Doc ID], MinutesType AS [Revision], MeetingDate AS [Date], Subject AS [Description], 
		PMMM.FirmNumber  AS [Firm], PMFM.FirmName AS [Firm Name], null AS [Vendor], null AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], PMMM.KeyID AS [KeyID], PMMM.PMCo as [FormCo], PMMM.UniqueAttchID
	FROM dbo.PMMM
		LEFT JOIN dbo.PMFM ON PMMM.VendorGroup=PMFM.VendorGroup AND PMMM.FirmNumber=PMFM.FirmNumber
	WHERE PMCo=@PMCo AND Project = @Project  AND ISNULL(MeetingType,'')=ISNULL(@DocumentType,ISNULL(MeetingType,''))  
		AND ISNULL(PMMM.FirmNumber,'') = ISNULL(@Firm,ISNULL(PMMM.FirmNumber,'')) AND @Vendor IS NULL
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

SET @tmpformname = 'PMACOS'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--PCO:  No Doc Type, No Revision, Has Responible Firm, No Vendor
	SET @templatetype = 'ACO'
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT DocType AS [Doc Type], ACO AS [Doc ID], NULL AS [Revision], ApprovalDate AS [Date], [Description] AS [Description], 
		NULL AS [Firm], NULL AS [Firm Name], NULL AS [Vendor], NULL AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], PMOH.KeyID AS [KeyID], PMOH.PMCo as [FormCo], PMOH.UniqueAttchID
	FROM dbo.PMOH 
	WHERE PMCo=@PMCo AND Project = @Project AND @Firm IS NULL
END

SET @tmpformname = 'PMPunchList'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--PCO:  No Doc Type, No Revision, No Responible Firm, No Vendor
	SET @templatetype = 'PUNCH'
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT DocType AS [Doc Type], PunchList  AS [Doc ID], NULL AS [Revision], PunchListDate  AS [Date], [Description] AS [Description], 
		NULL AS [Firm], NULL AS [Firm Name], NULL AS [Vendor], NULL AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], PMPU.KeyID AS [KeyID], PMPU.PMCo as [FormCo], PMPU.UniqueAttchID
	FROM dbo.PMPU
	WHERE PMCo=@PMCo AND Project = @Project AND @Firm IS NULL
END

SET @tmpformname = 'PMPOHeader'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--PURHASE/PO:  No Doc Type, No Revision, No Responible Firm, Has Vendor
	SET @templatetype = 'PURCHASE'
	;with PMPOHD as
		(
		select POCo,PO,JCCo as PMCo,Job as Project from POIT where JCCo=@PMCo and Job=@Project
		union
		select POCo,PO,PMCo,Project from PMMF where PMCo=@PMCo and Project=@Project and PO is not null
		union
		select POCo,PO,PMCo,Project from POHDPM where PMCo=@PMCo and Project=@Project and PO is not null
		)
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT POHDPM.DocType AS [Doc Type], POHDPM.PO AS [Doc ID], null AS [Revision], OrderDate AS [Date], Description AS [Description], 
		NULL AS [Firm], null AS [Firm Name], POHDPM.Vendor AS [Vendor], APVM.Name AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], POHDPM.KeyID AS [KeyID], POHDPM.PMCo as [FormCo], POHDPM.UniqueAttchID
	FROM dbo.POHDPM
		JOIN PMPOHD on POHDPM.POCo = PMPOHD.POCo AND POHDPM.PO = PMPOHD.PO
		LEFT JOIN dbo.APVM ON APVM.VendorGroup=POHDPM.VendorGroup AND APVM.Vendor=POHDPM.Vendor
	WHERE ISNULL(POHDPM.Vendor,'') = ISNULL(@Vendor,ISNULL(POHDPM.Vendor,''))
		AND @Firm IS NULL 
END

SET @tmpformname = 'PMPOCO'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--PURHASECO/POCO:  No Doc Type, Has Revision, No Responible Firm, Has Vendor
	SET @templatetype = 'PURCHASECO'
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT a.DocType AS [Doc Type], a.PO AS [Doc ID], CAST(a.POCONum AS VARCHAR(10)) AS [Revision], a.Date AS [Date], a.Description AS [Description], 
		NULL AS [Firm], null AS [Firm Name], b.Vendor AS [Vendor], c.Name AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], a.KeyID AS [KeyID], a.PMCo as [FormCo], a.UniqueAttchID
	FROM dbo.PMPOCO a
		LEFT JOIN dbo.POHDPM b ON a.PMCo=b.PMCo AND a.Project =b.Project AND a.PO=b.PO AND a.POCo=b.POCo 
		LEFT JOIN dbo.APVM c ON b.VendorGroup=c.VendorGroup AND b.Vendor=c.Vendor
	WHERE a.PMCo=@PMCo AND a.Project = @Project  AND ISNULL(b.Vendor,'') = ISNULL(@Vendor,ISNULL(b.Vendor,''))
		AND @Firm IS NULL 
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

SET @tmpformname = 'PMRequestForQuote'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--RFQ:  Has Doc Type, Has Revision, No Responible Firm, No Vendor
	SET @templatetype = 'REQQUOTE'
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT  DocType AS [Doc Type], RFQ AS [Doc ID], null AS [Revision], CreateDate AS [Date], Description AS [Description], 
		null AS [Firm], null AS [Firm Name], null AS [Vendor], null AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], PMRequestForQuote.KeyID AS [KeyID], PMRequestForQuote.PMCo as [FormCo], PMRequestForQuote.UniqueAttchID
	FROM dbo.PMRequestForQuote 
	WHERE PMCo=@PMCo AND Project = @Project
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
	SET @templatetype = 'SUB'
	--SUBCONTRACT/SL:  No Doc Type, No Revision, No Responible Firm, Has Vendor
	;with PMSLIT as
		(
		select SLCo,SL,JCCo as PMCo,Job as Project from SLIT where JCCo=@PMCo and Job=@Project
		union
		select SLCo,SL,PMCo,Project from PMSL where PMCo=@PMCo and Project=@Project
		union
		select SLCo,SL,PMCo,Project from SLHDPM where PMCo=@PMCo and Project=@Project
		)
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT DocType AS [Doc Type], SLHDPM.SL AS [Doc ID], null AS [Revision], OrigDate AS [Date], Description AS [Description], 
		NULL AS [Firm], null AS [Firm Name], SLHDPM.Vendor AS [Vendor], APVM.Name AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], SLHDPM.KeyID AS [KeyID], SLHDPM.PMCo as [FormCo], SLHDPM.UniqueAttchID
	FROM dbo.SLHDPM
		JOIN PMSLIT ON SLHDPM.SLCo = PMSLIT.SLCo AND SLHDPM.SL = PMSLIT.SL
		LEFT JOIN dbo.APVM ON APVM.VendorGroup=SLHDPM.VendorGroup AND APVM.Vendor=SLHDPM.Vendor
	WHERE ISNULL(SLHDPM.Vendor,'') =ISNULL(@Vendor, ISNULL(SLHDPM.Vendor,''))
		AND @Firm IS NULL 
END

SET @tmpformname = 'PMSLHeader' -- Sub with items is an exception to the rule where @FormName = DDFH.Form 
IF dbo.vfToString(@FormName) in ('PMSLHeaderItem','')
BEGIN
	--SUBITEM:  No Doc Type, No Revision, No Responible Firm, Has Vendor
	SET @templatetype = 'SUBITEM'
	;with PMSLIT as
		(
		select SLCo,SL,JCCo as PMCo,Job as Project from SLIT where JCCo=@PMCo and Job=@Project
		union
		select SLCo,SL,PMCo,Project from PMSL where PMCo=@PMCo and Project=@Project
		union
		select SLCo,SL,PMCo,Project from SLHDPM where PMCo=@PMCo and Project=@Project
		)
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT DocType AS [Doc Type], SLHDPM.SL AS [Doc ID], null AS [Revision], OrigDate AS [Date], Description AS [Description], 
		NULL AS [Firm], null AS [Firm Name], SLHDPM.Vendor AS [Vendor], APVM.Name AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], SLHDPM.KeyID AS [KeyID], SLHDPM.PMCo as [FormCo], SLHDPM.UniqueAttchID
	FROM dbo.SLHDPM
		JOIN PMSLIT ON SLHDPM.SLCo = PMSLIT.SLCo AND SLHDPM.SL = PMSLIT.SL
		LEFT JOIN dbo.APVM ON APVM.VendorGroup=SLHDPM.VendorGroup AND APVM.Vendor=SLHDPM.Vendor
	WHERE ISNULL(SLHDPM.Vendor,'') = ISNULL(@Vendor,ISNULL(SLHDPM.Vendor,''))
		AND @Firm IS NULL
END

SET @tmpformname = 'PMSubcontractCO'
IF dbo.vfToString(@FormName) in (@tmpformname,'')
BEGIN
	--SUBCO:  No Doc Type, Has Revision, No Responible Firm, Has Vendor
	SET @templatetype = 'SUBCO'
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT a.DocType AS [Doc Type], a.SL AS [Doc ID], CAST(a.SubCO AS VARCHAR(10)) AS [Revision], a.Date AS [Date], a.Description AS [Description], 
		NULL AS [Firm], null AS [Firm Name], b.Vendor AS [Vendor], c.Name AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], a.KeyID AS [KeyID], a.PMCo as [FormCo], a.UniqueAttchID
	FROM dbo.PMSubcontractCO a
		INNER JOIN dbo.SLHDPM b ON a.PMCo=b.PMCo AND a.Project =b.Project  AND a.SLCo=b.SLCo AND a.SL=b.SL
		LEFT JOIN dbo.APVM c ON b.VendorGroup=c.VendorGroup AND b.Vendor=c.Vendor
	WHERE a.PMCo=@PMCo AND a.Project = @Project  AND ISNULL(b.Vendor,'') = ISNULL(@Vendor,ISNULL(b.Vendor,''))
		AND @Firm IS NULL
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
	--TRANSMIT:  No Revision, Has Responible Firm, No Vendor
	SET @templatetype = 'TRANSMIT'
  	INSERT #DocumentTable([Doc Type],[Doc ID],[Revision],[Date],[Description],[Firm],[Firm Name],[Vendor],
		[Vendor Name],[Doc Cat],[FormName], [KeyID],[FormCo],[UniqueAttchID])
	SELECT DocType AS [Doc Type], Transmittal AS [Doc ID], NULL AS [Revision], TransDate AS [Date], Subject AS [Description], 
		ResponsibleFirm AS [Firm], PMFM.FirmName AS [Firm Name], null AS [Vendor], null AS [Vendor Name],
		@templatetype as [Doc Cat], @tmpformname AS [FormName], PMTM.KeyID AS [KeyID], PMTM.PMCo as [FormCo], PMTM.UniqueAttchID
	FROM dbo.PMTM 
		LEFT JOIN dbo.PMFM ON PMTM.VendorGroup=PMFM.VendorGroup AND PMTM.ResponsibleFirm=PMFM.FirmNumber
	WHERE PMCo=@PMCo AND Project = @Project AND @Vendor IS NULL
END

-- return results from TableVariable Joining to PMCT and DDFH
SELECT t.Description as [Category], d.[Doc Type], d.[Doc ID], d.Revision, d.Date, d.Description, d.Firm, d.[Firm Name],
	d.Vendor, d.[Vendor Name], d.[Doc Cat], d.[FormName],
	f.ViewName AS [TableName], d.KeyID, d.FormCo, d.UniqueAttchID
	,f.AssemblyName AS [AssemblyName], f.FormClassName AS [FormClassName]
FROM #DocumentTable d
	JOIN DDFH f on f.Form=d.FormName
	JOIN PMCT t on d.[Doc Cat]=t.DocCat
WHERE d.KeyID = isnull(@SourceDocumentKeyID,d.KeyID)
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
