SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPMVCInitialize]
/*************************************
 * Created By:	GF 04/01/2004
 * Modified By: GF 12/08/2004 - issue #26340 replaced RFI DateRespReqd with RFI Date Due
 *				GF 01/26/2005 - issue #26892 add material order tab to views
 *				GF 03/20/2007 - issue #28097 6.x changes replace Form with Form
 *				gf 03/22/2007 - issue #122665, #119583, #28847 add totals to SL,PO,MO,PCO,ACO grid forms
 *				GF 03/26/2007 - issue #29238 added PM Project Firms to document tracking
 *				GF 04/02/2007 - issue #120937 added PMRQ.DateDue and PMRQGrid.RespRecd to the PM RFQ grid form.
 *				GF 04/06/2007 - issue #29867 added UniqueAttchID column to all grid forms.
 *				GF 02/16/2008 - issue #126933 changed from JCPM.Description to JCJPDescGet.Description for submittals.
 *				GF 11/14/2008 - issue #131075 added execute as and use tables not views.
 *				CC 04/07/2010 - issue #130945 added email columns
 *				AW 01/11/2013 - issue 147448 / TK-20642 modified to enforce FK_bPMVC_bPMVG
 *
 *
 *
 * called from PMVG insert trigger to load the grid columns
 * the PMVC grid views if missing
 *
 * Pass:
 * PM View Name
 *
 *
 * Success returns:
 *	0 
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@viewname varchar(10) = null,  @form varchar(30) = null, @msg varchar(255) output)

with execute as 'viewpointcs'
as
set nocount on

declare @rcode int

select @rcode = 0

if isnull(@viewname,'') = ''
   	begin
   	select @msg = 'Missing Document Tracking View Name', @rcode = 1
   	goto bspexit
   	end

if isnull(@form,'') = ''
   	begin
   	select @msg = 'Missing Document Tracking Grid Form', @rcode = 1
   	goto bspexit
   	end

---- first check to make sure the Viewpoint Grid defaults exist if not then add these first
---- create each grid view columns in PMVC if missing, these will be loaded from
---- the PMVG insert trigger

---- PMSM
if not exists(select 1 from bPMVC where ViewName='Viewpoint' and Form='PMDocTrackPMSM')
	AND EXISTS(SELECT 1 FROM dbo.bPMVG WHERE ViewName = 'Viewpoint' AND Form = 'PMDocTrackPMSM')
   	begin
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMSM', 'PMSM', 'Description', 'Description', 1, 'Y', 1
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMSM', 'PMSM', 'SubFirm', 'Sub Firm', 2, 'Y', 2
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMSM', 'PMFMSub', 'FirmName', 'Firm Name', 3, 'Y', 3
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMSM', 'PMSM', 'Phase', 'Phase', 4, 'Y', 4
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMSM', 'JCJPDescGet', 'Description', 'Phase Desc', 5, 'Y', 5
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMSM', 'PMSM', 'DateReqd', 'Date Reqd', 6, 'Y', 6
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMSM', 'PMSM', 'DateRecd', 'Date Recd', 7, 'Y', 7
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMSM', 'PMSM', 'ToArchEng', 'To Arch/Eng', 8, 'Y', 8
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMSM', 'PMSM', 'DueBackArch', 'Due Back Arch', 9, 'Y', 9
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMSM', 'PMSM', 'RecdBackArch', 'Recd Back Arch', 10, 'Y', 10
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMSM', 'PMSM', 'DateRetd', 'Date Retd', 11, 'Y', 11
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMSM', 'PMSM', 'ActivityDate', 'Activity Date', 12, 'Y', 12
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMSM', 'PMSM', 'Status', 'Status', 13, 'Y', 13
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMSM', 'PMSC', 'Description', 'Status Desc', 14, 'Y', 14
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMSM', 'PMSC', 'CodeType', 'Code Type', 15, 'N', 15
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMSM', 'PMSM', 'Issue', 'Issue', 16, 'Y', 16
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMSM', 'PMIM', 'Description', 'Issue Desc', 17, 'Y', 17
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMSM', 'PMSM', 'ResponsiblePerson', 'Resp Person', 18, 'Y', 18
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMSM', 'PMPMResp', 'FullContactName', 'Resp Person Name', 19, 'Y', 19
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackPMSM', 'PMSM', 'UniqueAttchID', 'Attachments', 20, 'Y', 20
   	end

---- PMRI
if not exists(select 1 from bPMVC where ViewName='Viewpoint' and Form='PMDocTrackPMRI')
	AND EXISTS(SELECT 1 FROM dbo.bPMVG WHERE ViewName = 'Viewpoint' AND Form = 'PMDocTrackPMRI')
   	begin
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRI', 'PMRI', 'Subject', 'Subject', 1, 'Y', 1
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRI', 'PMRI', 'ReqFirm', 'Req Firm', 2, 'Y', 2
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRI', 'PMFMReq', 'FirmName', 'Firm Name', 3, 'Y', 3
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRI', 'PMRI', 'RFIDate', 'RFI Date', 4, 'Y', 4
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRI', 'PMRI', 'DateDue', 'Date Due', 5, 'Y', 5
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRI', 'PMRIGrid', 'RespReqd', 'Resp Required', 6, 'Y', 6
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRI', 'PMRIGrid', 'RespRecd', 'Resp Received', 7, 'Y', 7
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRI', 'PMRI', 'ResponsiblePerson', 'Resp Person', 8, 'Y', 8
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRI', 'PMPMResp', 'FullContactName', 'Resp Person Name', 9, 'Y', 9
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRI', 'PMRI', 'Status', 'Status', 10, 'Y', 10
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRI', 'PMSC', 'Description', 'Status Desc', 11, 'Y', 11
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRI', 'PMSC', 'CodeType', 'Code Type', 12, 'N', 12
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRI', 'PMRI', 'Issue', 'Issue', 13, 'Y', 13
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRI', 'PMIM', 'Description', 'Issue Desc', 14, 'Y', 14
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackPMRI', 'PMRI', 'UniqueAttchID', 'Attachments', 15, 'Y', 15
   	end

---- PMOP
if not exists(select 1 from bPMVC where ViewName='Viewpoint' and Form='PMDocTrackPMOP')
	AND EXISTS(SELECT 1 FROM dbo.bPMVG WHERE ViewName = 'Viewpoint' AND Form = 'PMDocTrackPMOP')
   	begin
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOP', 'PMOP', 'Description', 'Description', 1, 'Y', 1
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOP', 'PMOP', 'Date1', 'Date1', 2, 'Y', 2
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOP', 'PMOP', 'Date2', 'Date2', 3, 'Y', 3
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOP', 'PMOP', 'Date3', 'Date3', 4, 'Y', 4
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOP', 'PMOP', 'PendingStatus', 'Status', 5, 'Y', 5
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOP', 'PMOP', 'ApprovalDate', 'Approval Date', 6, 'Y', 6
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOP', 'PMOP', 'Issue', 'Issue', 7, 'Y', 7
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOP', 'PMIM', 'Description', 'Issue Desc', 8, 'Y', 8
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOP', 'PMOPTotals', 'PCORevTotal', 'PCO Rev Total', 9, 'Y', 9
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackPMOP', 'PMOP', 'UniqueAttchID', 'Attachments', 10, 'Y', 10
   	end

---- PMRQ
if not exists(select 1 from bPMVC where ViewName='Viewpoint' and Form='PMDocTrackPMRQ')
	AND EXISTS(SELECT 1 FROM dbo.bPMVG WHERE ViewName = 'Viewpoint' AND Form = 'PMDocTrackPMRQ')
   	begin
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRQ', 'PMRQ', 'Description', 'Description', 1, 'Y', 1
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRQ', 'PMRQ', 'RFQDate', 'RFQ Date', 2, 'Y', 2
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRQ', 'PMRQ', 'ResponsiblePerson', 'Resp Person', 3, 'Y', 3
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRQ', 'PMPMResp', 'FullContactName', 'Resp Person Name', 4, 'Y', 4
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRQ', 'PMRQ', 'Status', 'Status', 5, 'Y', 5
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRQ', 'PMSC', 'Description', 'Status Desc', 6, 'Y', 6
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRQ', 'PMSC', 'CodeType', 'Code Type', 7, 'N', 7
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRQ', 'PMRQ', 'DateDue', 'Date Due', 8, 'Y', 8
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRQ', 'PMRQGrid', 'RespReqd', 'Resp Required', 9, 'Y', 9
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMRQ', 'PMRQGrid', 'RespRecd', 'Resp Received', 10, 'Y', 10
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackPMRQ', 'PMRQ', 'UniqueAttchID', 'Attachments', 11, 'Y', 11
   	end

---- PMOH
if not exists(select 1 from bPMVC where ViewName='Viewpoint' and Form='PMDocTrackPMOH')
	AND EXISTS(SELECT 1 FROM dbo.bPMVG WHERE ViewName = 'Viewpoint' AND Form = 'PMDocTrackPMOH')
   	begin
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOH', 'PMOH', 'Description', 'Description', 1, 'Y', 1
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOH', 'PMOH', 'DateSent', 'Date Sent', 2, 'Y', 2
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOH', 'PMOH', 'DateReqd', 'Date Reqd', 3, 'Y', 3
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOH', 'PMOH', 'DateRecd', 'Date Recd', 4, 'Y', 4
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOH', 'PMOH', 'ChangeDays', 'Change Days', 5, 'Y', 5
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOH', 'PMOH', 'NewCmplDate', 'New Cmpl Date', 6, 'Y', 6
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOH', 'PMOH', 'ApprovalDate', 'Approval Date', 7, 'Y', 7
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOH', 'PMOH', 'Issue', 'Issue', 8, 'Y', 8
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOH', 'PMIM', 'Description', 'Issue Desc', 9, 'Y', 9
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOH', 'PMOHTotals', 'ACORevTotal', 'ACO Rev Total', 10, 'Y', 10
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackPMOH', 'PMOH', 'UniqueAttchID', 'Attachments', 11, 'Y', 11
   	end

---- PMOD
if not exists(select 1 from bPMVC where ViewName='Viewpoint' and Form='PMDocTrackPMOD')
	AND EXISTS(SELECT 1 FROM dbo.bPMVG WHERE ViewName = 'Viewpoint' AND Form = 'PMDocTrackPMOD')
   	begin
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOD', 'PMOD', 'Description', 'Description', 1, 'Y', 1
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOD', 'PMOD', 'RelatedFirm', 'Related Firm', 2, 'Y', 2
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOD', 'PMFMRel', 'FirmName', 'Related Firm Name', 3, 'Y', 3
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOD', 'PMOD', 'DateDue', 'Date Due', 4, 'Y', 4
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOD', 'PMOD', 'DateRecd', 'Date Recd', 5, 'Y', 5
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOD', 'PMOD', 'DateSent', 'Date Sent', 6, 'Y', 6
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOD', 'PMOD', 'DateDueBack', 'Date Due Back', 7, 'Y', 7
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOD', 'PMOD', 'DateRecdBack', 'Date Recd Back', 8, 'Y', 8
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOD', 'PMOD', 'DateRetd', 'Date Returned', 9, 'Y', 9
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOD', 'PMOD', 'ResponsiblePerson', 'Resp Person', 10, 'Y', 10
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOD', 'PMPMResp', 'FullContactName', 'Resp Person Name', 11, 'Y', 11
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOD', 'PMOD', 'Status', 'Status', 12, 'Y', 12
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOD', 'PMSC', 'Description', 'Status Desc', 13, 'Y', 13
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOD', 'PMSC', 'CodeType', 'Code Type', 14, 'N', 14
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOD', 'PMOD', 'Issue', 'Issue', 15, 'Y', 15
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMOD', 'PMIM', 'Description', 'Issue Desc', 16, 'Y', 16
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackPMOD', 'PMOD', 'UniqueAttchID', 'Attachments', 17, 'Y', 17
   	end

---- PMIM
if not exists(select 1 from bPMVC where ViewName='Viewpoint' and Form='PMDocTrackPMIM')
	AND EXISTS(SELECT 1 FROM dbo.bPMVG WHERE ViewName = 'Viewpoint' AND Form = 'PMDocTrackPMIM')
   	begin
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMIM', 'PMIM', 'Description', 'Description', 1, 'Y', 1
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMIM', 'PMIM', 'FirmNumber', 'Firm', 2, 'Y', 2
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMIM', 'PMFM', 'FirmName', 'Name', 3, 'Y', 3
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMIM', 'PMIM', 'Initiator', 'Initiator', 4, 'Y', 4
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMIM', 'PMPM2', 'FullContactName', 'Initiator Name', 5, 'Y', 5
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMIM', 'PMIM', 'DateInitiated', 'Date Initiated', 6, 'Y', 6
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMIM', 'PMIM', 'DateResolved', 'Date Resolved', 7, 'Y', 7
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMIM', 'PMIM', 'Status', 'Status', 8, 'Y', 8
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackPMIM', 'PMIM', 'UniqueAttchID', 'Attachments', 9, 'Y', 9
   	end

---- SLHD
if not exists(select 1 from bPMVC where ViewName='Viewpoint' and Form='PMDocTrackSLHD')
	AND EXISTS(SELECT 1 FROM dbo.bPMVG WHERE ViewName = 'Viewpoint' AND Form = 'PMDocTrackSLHD')
   	begin
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackSLHD', 'SLHDPM', 'Description', 'Description', 1, 'Y', 1
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackSLHD', 'SLHDPM', 'Vendor', 'Vendor', 2, 'Y', 2
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackSLHD', 'APVM', 'Name', 'Name', 3, 'Y', 3
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackSLHD', 'SLHDPM', 'Approved', 'Approved', 4, 'Y', 4
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackSLHD', 'SLHDPM', 'ApprovedBy', 'Approved By', 5, 'Y', 5
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackSLHD', 'PMSLTotal', 'TotalOrigSL', 'Total Orig Subct', 6, 'Y', 6
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackSLHD', 'PMSLTotal', 'TotalCurrSL', 'Total Curr Subct', 7, 'Y', 7
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackSLHD', 'SLHDPM', 'UniqueAttchID', 'Attachments', 8, 'Y', 8
   	end

---- POHD
if not exists(select 1 from bPMVC where ViewName='Viewpoint' and Form='PMDocTrackPOHD')
	AND EXISTS(SELECT 1 FROM dbo.bPMVG WHERE ViewName = 'Viewpoint' AND Form = 'PMDocTrackPOHD')
   	begin
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPOHD', 'POHDPM', 'Description', 'Description', 1, 'Y', 1
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPOHD', 'POHDPM', 'Vendor', 'Vendor', 2, 'Y', 2
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPOHD', 'APVM', 'Name', 'Name', 3, 'Y', 3
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPOHD', 'POHDPM', 'OrderDate', 'Date Ordered', 4, 'Y', 4
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPOHD', 'POHDPM', 'OrderedBy', 'Ordered By', 5, 'Y', 5
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPOHD', 'POHDPM', 'Approved', 'Approved', 6, 'Y', 6
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPOHD', 'POHDPM', 'ApprovedBy', 'Approved By', 7, 'Y', 7
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackPOHD', 'PMPOTotal', 'TotalOrigPO', 'Total Orig PO', 8, 'Y', 8
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackPOHD', 'PMPOTotal', 'TotalCurrPO', 'Total Curr PO', 9, 'Y', 9
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackPOHD', 'POHDPM', 'UniqueAttchID', 'Attachments', 10, 'Y', 10
   	end

---- PMPU
if not exists(select 1 from bPMVC where ViewName = 'Viewpoint' and Form='PMDocTrackPMPU')
	AND EXISTS(SELECT 1 FROM dbo.bPMVG WHERE ViewName = 'Viewpoint' AND Form = 'PMDocTrackPMPU')
   	begin
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMPU', 'PMPU', 'Description', 'Description', 1, 'Y', 1
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMPU', 'PMPU', 'PunchListDate', 'Punch List Date', 2, 'Y', 2
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackPMPU', 'PMPU', 'UniqueAttchID', 'Attachments', 3, 'Y', 3
   	end

---- PMMM
if not exists(select 1 from bPMVC where ViewName = 'Viewpoint' and Form='PMDocTrackPMMM')
	AND EXISTS(SELECT 1 FROM dbo.bPMVG WHERE ViewName = 'Viewpoint' AND Form = 'PMDocTrackPMMM')
   	begin
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMMM', 'PMMM', 'MeetingDate', 'Meeting Date', 1, 'Y', 1
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMMM', 'PMMM', 'MeetingTime', 'Time', 2, 'Y', 2
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMMM', 'PMMM', 'Subject', 'Subject', 3, 'Y', 3
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMMM', 'PMMM', 'Preparer', 'Preparer', 4, 'Y', 4
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMMM', 'PMPM2', 'FullContactName', 'Preparer Name', 5, 'Y', 5
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackPMMM', 'PMMM', 'UniqueAttchID', 'Attachments', 6, 'Y', 6
   	end

---- PMDL
if not exists(select 1 from bPMVC where ViewName = 'Viewpoint' and Form='PMDocTrackPMDL')
	AND EXISTS(SELECT 1 FROM dbo.bPMVG WHERE ViewName = 'Viewpoint' AND Form = 'PMDocTrackPMDL')
   	begin
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMDL', 'PMDL', 'Description', 'Description', 1, 'Y', 1
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMDL', 'PMDL', 'Weather', 'Weather', 2, 'Y', 2
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMDL', 'PMDL', 'Wind', 'Wind', 3, 'Y', 3
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMDL', 'PMDL', 'TempHigh', 'High Temp', 4, 'Y', 4
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMDL', 'PMDL', 'TempLow', 'Low Temp', 5, 'Y', 5
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackPMDL', 'PMDL', 'UniqueAttchID', 'Attachments', 6, 'Y', 6
   	end

---- PMDG
if not exists(select 1 from bPMVC where ViewName = 'Viewpoint' and Form='PMDocTrackPMDG')
	AND EXISTS(SELECT 1 FROM dbo.bPMVG WHERE ViewName = 'Viewpoint' AND Form = 'PMDocTrackPMDG')
   	begin
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMDG', 'PMDG', 'Description', 'Description', 1, 'Y', 1
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMDG', 'PMDG', 'DateIssued', 'Date Issued', 2, 'Y', 2
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMDG', 'PMDG', 'Status', 'Status', 3, 'Y', 3
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMDG', 'PMDGGrid', 'Revisions', 'Revisions', 4, 'Y', 4
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackPMDG', 'PMDG', 'UniqueAttchID', 'Attachments', 5, 'Y', 5
   	end

---- PMTL
if not exists(select 1 from bPMVC where ViewName = 'Viewpoint' and Form='PMDocTrackPMTL')
	AND EXISTS(SELECT 1 FROM dbo.bPMVG WHERE ViewName = 'Viewpoint' AND Form = 'PMDocTrackPMTL')
   	begin
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMTL', 'PMTL', 'Description', 'Description', 1, 'Y', 1
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMTL', 'PMTL', 'TestDate', 'Test Date', 2, 'Y', 2
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMTL', 'PMTL', 'Issue', 'Issue', 3, 'Y', 3
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMTL', 'PMTL', 'Status', 'Status', 4, 'Y', 4
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackPMTL', 'PMTL', 'UniqueAttchID', 'Attachments', 5, 'Y', 5
   	end

---- PMIL
if not exists(select 1 from bPMVC where ViewName = 'Viewpoint' and Form='PMDocTrackPMIL')
	AND EXISTS(SELECT 1 FROM dbo.bPMVG WHERE ViewName = 'Viewpoint' AND Form = 'PMDocTrackPMIL')
   	begin
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMIL', 'PMIL', 'Description', 'Description', 1, 'Y', 1
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMIL', 'PMIL', 'InspectionDate', 'Inspection Date', 2, 'Y', 2
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMIL', 'PMIL', 'Issue', 'Issue', 3, 'Y', 3
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMIL', 'PMIL', 'Status', 'Status', 4, 'Y', 4
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackPMIL', 'PMIL', 'UniqueAttchID', 'Attachments', 5, 'Y', 5
   	end

---- PMTM
if not exists(select 1 from bPMVC where ViewName='Viewpoint' and Form='PMDocTrackPMTM')
	AND EXISTS(SELECT 1 FROM dbo.bPMVG WHERE ViewName = 'Viewpoint' AND Form = 'PMDocTrackPMTM')
   	begin
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMTM', 'PMTM', 'TransDate', 'Transmittal Date', 1, 'Y', 1
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMTM', 'PMTM', 'Subject', 'Subject', 2, 'Y', 2
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMTM', 'PMTM', 'DateSent', 'Date Sent', 3, 'Y', 3
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMTM', 'PMTM', 'DateDue', 'Date Due', 4, 'Y', 4
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMTM', 'PMTM', 'DateResponded', 'Responded Date', 5, 'Y', 5
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMTM', 'PMTM', 'Issue', 'Issue', 6, 'Y', 6
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMTM', 'PMTM', 'ResponsiblePerson', 'Resp Person', 7, 'Y', 7
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackPMTM', 'PMTM', 'UniqueAttchID', 'Attachments', 8, 'Y', 8
   	end

---- PMPN
if not exists(select 1 from bPMVC where ViewName = 'Viewpoint' and Form='PMDocTrackPMPN')
	AND EXISTS(SELECT 1 FROM dbo.bPMVG WHERE ViewName = 'Viewpoint' AND Form = 'PMDocTrackPMPN')
   	begin
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMPN', 'PMPN', 'AddedDate', 'Added On Date', 1, 'Y', 1
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMPN', 'PMPN', 'Summary', 'Summary', 2, 'Y', 2
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMPN', 'PMPN', 'PMStatus', 'PM Status', 3, 'Y', 3
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMPN', 'PMFM', 'FirmName', 'Firm Name', 4, 'Y', 4
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMPN', 'PMPM2', 'FullContactName', 'Firm Contact', 5, 'Y', 5
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMPN', 'PMPN', 'Issue', 'Issue', 6, 'Y', 6
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackPMPN', 'PMPN', 'UniqueAttchID', 'Attachments', 7, 'Y', 7
   	end

---- PMPF
if not exists(select 1 from bPMVC where ViewName = 'Viewpoint' and Form='PMDocTrackPMPF')
	AND EXISTS(SELECT 1 FROM dbo.bPMVG WHERE ViewName = 'Viewpoint' AND Form = 'PMDocTrackPMPF')
   	begin
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMPF', 'PMPF', 'Description', 'Description', 1, 'Y', 1
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMPF', 'PMPM2', 'Title', 'Title', 2, 'Y', 2
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMPF', 'PMPM2', 'Phone', 'Phone', 3, 'Y', 3
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMPF', 'PMPM2', 'Fax', 'Fax', 4, 'Y', 4
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMPF', 'PMPM2', 'MobilePhone', 'Mobile Phone', 5, 'Y', 5
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMPF', 'PMPM2', 'EMail', 'EMail', 6, 'Y', 6
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackPMPF', 'PMPM2', 'ExcludeYN', 'Inactive', 7, 'Y', 7
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackPMPF', 'PMPF', 'UniqueAttchID', 'Attachments', 8, 'Y', 8
   	end

---- INMO
if not exists(select 1 from bPMVC where ViewName='Viewpoint' and Form='PMDocTrackINMO')
	AND EXISTS(SELECT 1 FROM dbo.bPMVG WHERE ViewName = 'Viewpoint' AND Form = 'PMDocTrackINMO')
   	begin
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackINMO', 'INMOPM', 'Description', 'Description', 1, 'Y', 1
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackINMO', 'INMOPM', 'OrderDate', 'Order Date', 2, 'Y', 2
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackINMO', 'INMOPM', 'OrderedBy', 'Ordered By', 3, 'Y', 3
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackINMO', 'INMOPM', 'Approved', 'Approved', 4, 'Y', 4
   	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
   	select 'Viewpoint', 'PMDocTrackINMO', 'INMOPM', 'ApprovedBy', 'Approved By', 5, 'Y', 5
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackINMO', 'PMMOTotal', 'TotalMO', 'Total MO', 6, 'Y', 6
	insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
	select 'Viewpoint', 'PMDocTrackINMO', 'INMOPM', 'UniqueAttchID', 'Attachments', 7, 'Y', 7
   	end

IF NOT EXISTS(SELECT 1 FROM dbo.bPMVC WHERE ViewName = 'Viewpoint' AND Form = 'PMDocTrackEmail')
	AND EXISTS(SELECT 1 FROM dbo.bPMVG WHERE ViewName = 'Viewpoint' AND Form = 'PMDocTrackEmail')
	BEGIN
	
		INSERT INTO PMVC (ViewName, TableView, ColumnName, ColTitle, ColSeq, Visible, Form, GridCol)
		VALUES('Viewpoint', 'PMDocEmail', 'From', 'From', 2, 'Y', 'PMDocTrackEmail', 2)

		INSERT INTO PMVC (ViewName, TableView, ColumnName, ColTitle, ColSeq, Visible, Form, GridCol)
		VALUES('Viewpoint', 'PMDocEmail', 'To', 'To', 3, 'Y', 'PMDocTrackEmail', 3)

		INSERT INTO PMVC (ViewName, TableView, ColumnName, ColTitle, ColSeq, Visible, Form, GridCol)
		VALUES('Viewpoint', 'PMDocEmail', 'CC', 'CC', 4, 'Y', 'PMDocTrackEmail', 4)

		INSERT INTO PMVC (ViewName, TableView, ColumnName, ColTitle, ColSeq, Visible, Form, GridCol)
		VALUES('Viewpoint', 'PMDocEmail', 'Subject', 'Subject', 6, 'Y', 'PMDocTrackEmail', 6)

		INSERT INTO PMVC (ViewName, TableView, ColumnName, ColTitle, ColSeq, Visible, Form, GridCol)
		VALUES('Viewpoint', 'PMDocEmail', 'SentDate', 'SentDate', 7, 'Y', 'PMDocTrackEmail', 7)

		INSERT INTO PMVC (ViewName, TableView, ColumnName, ColTitle, ColSeq, Visible, Form, GridCol)
		VALUES('Viewpoint', 'PMDocEmail', 'ReceivedDate', 'ReceivedDate', 8, 'Y', 'PMDocTrackEmail', 8)

	END	

---- insert grids that do not exist in bPMVG
insert bPMVC (ViewName, Form, TableView, ColumnName, ColTitle, ColSeq, Visible, GridCol)
select @viewname, @form, a.TableView, a.ColumnName, a.ColTitle, a.ColSeq, a.Visible, a.GridCol
from PMVC a where a.ViewName = 'Viewpoint' and a.Form = @form
and not exists(select 1 from bPMVC c where c.ViewName=@viewname and c.Form=@form)
and exists(select 1 from bPMVG g where g.ViewName=@viewname and g.Form=@form)



bspexit:
	if @rcode<>0 select @msg = isnull(@msg,'')
	return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspPMVCInitialize] TO [public]
GO
