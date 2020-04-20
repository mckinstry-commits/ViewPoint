CREATE TABLE [dbo].[bJCJM]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[Job] [dbo].[bJob] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[Contract] [dbo].[bContract] NULL,
[JobStatus] [tinyint] NOT NULL CONSTRAINT [DF_bJCJM_JobStatus] DEFAULT ((0)),
[BidNumber] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[LockPhases] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCJM_LockPhases] DEFAULT ('N'),
[ProjectMgr] [int] NULL,
[JobPhone] [dbo].[bPhone] NULL,
[JobFax] [dbo].[bPhone] NULL,
[MailAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[MailCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[MailState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[MailZip] [dbo].[bZip] NULL,
[MailAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ShipAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ShipCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ShipState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[ShipZip] [dbo].[bZip] NULL,
[ShipAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[LiabTemplate] [smallint] NULL,
[TaxGroup] [dbo].[bGroup] NOT NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[InsTemplate] [smallint] NULL,
[MarkUpDiscRate] [dbo].[bRate] NOT NULL,
[PRLocalCode] [dbo].[bLocalCode] NULL,
[PRStateCode] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Certified] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCJM_Certified] DEFAULT ('N'),
[EEORegion] [char] (8) COLLATE Latin1_General_BIN NULL,
[SMSACode] [char] (10) COLLATE Latin1_General_BIN NULL,
[CraftTemplate] [smallint] NULL,
[ProjMinPct] [dbo].[bPct] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[SLCompGroup] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[POCompGroup] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[ArchEngFirm] [dbo].[bFirm] NULL,
[OTSched] [tinyint] NULL,
[PriceTemplate] [smallint] NULL,
[HaulTaxOpt] [tinyint] NOT NULL CONSTRAINT [DF_bJCJM_HaulTaxOpt] DEFAULT ((0)),
[GeoCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[BaseTaxOn] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJCJM_BaseTaxOn] DEFAULT ('J'),
[UpdatePlugs] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCJM_UpdatePlugs] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[ContactCode] [dbo].[bEmployee] NULL,
[ClosePurgeFlag] [dbo].[bYN] NULL CONSTRAINT [DF_bJCJM_ClosePurgeFlag] DEFAULT ('N'),
[OurFirm] [dbo].[bFirm] NULL,
[AutoAddItemYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCJM_AutoAddItemYN] DEFAULT ('N'),
[OverProjNotes] [varchar] (8000) COLLATE Latin1_General_BIN NULL CONSTRAINT [DF_bJCJM_OverProjNotes] DEFAULT (NULL),
[WghtAvgOT] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCJM_WghtAvgOT] DEFAULT ('N'),
[HrsPerManDay] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJCJM_HrsPerManDay] DEFAULT ((8)),
[AutoGenSubNo] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJCJM_AutoGenSubNo] DEFAULT ('T'),
[SecurityGroup] [int] NULL,
[DefaultStdDaysDue] [smallint] NULL,
[DefaultRFIDaysDue] [smallint] NULL,
[UpdateAPActualsYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCJM_UpdateAPActualsYN] DEFAULT ('Y'),
[UpdateMSActualsYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCJM_UpdateMSActualsYN] DEFAULT ('Y'),
[AutoGenPCONo] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJCJM_AutoGenPCONo] DEFAULT ('P'),
[AutoGenMTGNo] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJCJM_AutoGenMTGNo] DEFAULT ('P'),
[AutoGenRFINo] [varchar] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJCJM_AutoGenRFINo] DEFAULT ('P'),
[RateTemplate] [smallint] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[RevGrpInv] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[MailCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[ShipCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[CertDate] [dbo].[bDate] NULL,
[AutoGenRFQNo] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJCJM_AutoGenRFQNo] DEFAULT ('T'),
[ApplyEscalators] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCJM_ApplyEscalators] DEFAULT ('N'),
[UseTaxYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCJM_UseTaxYN] DEFAULT ('N'),
[TimesheetRevGroup] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[PotentialProjectID] [bigint] NULL,
[PCVisibleInJC] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJCJM_PCVisibleInJC] DEFAULT ('Y'),
[SubmittalReviewDaysResponsibleFirm] [int] NULL,
[SubmittalReviewDaysApprovingFirm] [int] NULL,
[SubmittalReviewDaysRequestingFirm] [int] NULL,
[SubmittalReviewDaysAutoCalcYN] [dbo].[bYN] NULL CONSTRAINT [DF_bJCJM_SubmittalReviewDaysAutoCalcYN] DEFAULT ('Y'),
[SubmittalApprovingFirm] [dbo].[bFirm] NULL,
[SubmittalApprovingFirmContact] [dbo].[bEmployee] NULL,
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL,
[udDatePhaseDelete] [smalldatetime] NULL,
[udCGCJob] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[udBET] [varchar] (6) COLLATE Latin1_General_BIN NULL,
[udBuildNum] [dbo].[bUnits] NULL,
[udSquFootage] [dbo].[bUnits] NULL,
[udBuildOwn] [dbo].[bCustomer] NULL,
[udBuildOcc] [dbo].[bDesc] NULL,
[udOccOwn] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udPrevailWage] [dbo].[bYN] NULL CONSTRAINT [DF__bJCJM__udPrevailWage__DEFAULT] DEFAULT ('N'),
[udDTReqd] [dbo].[bYN] NULL CONSTRAINT [DF__bJCJM__udDTReqd__DEFAULT] DEFAULT ('N'),
[udDTRespParty] [dbo].[bVendor] NULL,
[udEnergySRating] [tinyint] NULL,
[udLeedTarget] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udGovntYN] [dbo].[bYN] NULL CONSTRAINT [DF__bJCJM__udGovntYN__DEFAULT] DEFAULT ('N'),
[udAARAYN] [dbo].[bYN] NULL CONSTRAINT [DF__bJCJM__udAARAYN__DEFAULT] DEFAULT ('N'),
[udJobsNowYN] [dbo].[bYN] NULL CONSTRAINT [DF__bJCJM__udJobsNowYN__DEFAULT] DEFAULT ('N'),
[udEnable84YN] [dbo].[bYN] NULL CONSTRAINT [DF__bJCJM__udEnable84YN__DEFAULT] DEFAULT ('N'),
[udBuyAmericanYN] [dbo].[bYN] NULL CONSTRAINT [DF__bJCJM__udBuyAmericanYN__DEFAULT] DEFAULT ('N'),
[udGovSector] [smallint] NULL,
[udGovtOwner] [dbo].[bDesc] NULL,
[udAwardAgency] [smallint] NULL,
[udPubFundTrail] [smallint] NULL,
[udSINNum] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[udProcVeh] [dbo].[bDesc] NULL,
[udFAR] [dbo].[bFormattedNotes] NULL,
[udDEAR] [dbo].[bFormattedNotes] NULL,
[udIFFFeeYN] [dbo].[bYN] NULL CONSTRAINT [DF__bJCJM__udIFFFeeYN__DEFAULT] DEFAULT ('N'),
[udCRMNum] [dbo].[bDesc] NULL,
[udProjWrkstrm] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udBLocAddress] [dbo].[bItemDesc] NULL,
[udBLocAddress2] [dbo].[bItemDesc] NULL,
[udBLocCity] [dbo].[bDesc] NULL,
[udBLocState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[udBLocZip] [dbo].[bZip] NULL,
[udAcctMngr] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udRFPDueDate] [smalldatetime] NULL,
[udDesignStrt] [smalldatetime] NULL,
[udDesignEnd] [smalldatetime] NULL,
[udConstStrt] [smalldatetime] NULL,
[udConstEnd] [smalldatetime] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/**************************************************/
CREATE trigger [dbo].[btJCJMd] on [dbo].[bJCJM] for DELETE as
/*--------------------------------------------------------------
* Created: JRE  07/11/97
* Modified: DanF 04/12/00 Added Delete of data type security
*			DanF 04/27/04 Issue 17370 - Use VA Purge Security Entries to purge security entries.
*			DanF 01/19/06 Issue 119673 - Correct Key string that updates the HQMA table.
*			GP	 05/20/08 Issue 127448 - Add entire job delete for all related PM tables.
*			GF	 10/01/08 Issue 127448 - changed PM checks to disallow if in main PM tables and status not pending.
*			CHS	 11/07/08 - #130950
*			GF 01/29/2010 - issue #135527 job roles
*			JG 11/29/2010 - TFS# 1300 - Added deleting of Related PC records when record removed.
*			JG 01/06/2011 - TFS# 1662 - Removed command to delete the Related PC records when record removed.
*			GF 03/24/2011 - TK-03291
*			GF 04/06/2011 - TK-03569
*			GP	1/20/2012 - TK-11894 Added check for SM Service Site entries
*			GP 09/05/2012 - TK-17612  Removed deletes from PMPA, PMPC, and PMPF, moved to cascade in foreign keys
*
*  Delete trigger for JCJM
*
* deletes bPMPA when Job is deleted
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- Check bJCAJ for detail
if exists(select top 1 1 from deleted d JOIN dbo.bJCAJ o (nolock) ON d.JCCo = o.JCCo and d.Job = o.Job)
	begin
	select @errmsg = 'Entries exist in bJCAJ'
	goto error
	end
	
---- Check bJCJP for detail
if exists(select top 1 1 from deleted d JOIN dbo.bJCJP o (nolock) ON d.JCCo = o.JCCo and d.Job = o.Job)
	begin
	select @errmsg = 'Entries exist in bJCJP'
	goto error
	end	

---- Check bJCOH for detail
if exists(select top 1 1 from deleted d JOIN dbo.bJCOH o (nolock) ON d.JCCo = o.JCCo and d.Job = o.Job)
	begin
	select @errmsg = 'Entries exist in bJCOH'
	goto error
	end

---- need to check PM tables for detail, but these checks only apply if the job status is not pending
if exists(select top 1 1 from deleted d join dbo.bPMOP o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
	begin
	select @errmsg = 'Entries exist in bPMOP'
	goto error
	end

---- need to check PM tables for detail, but these checks only apply if the job status is not pending
if exists(select top 1 1 from deleted d join dbo.bPMOH o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
	begin
	select @errmsg = 'Entries exist in bPMOH'
	goto error
	end

/* not needed, by phase and we previously check JCJP */
-------- need to check PM tables for detail, but these checks only apply if the job status is not pending
----if exists(select top 1 1 from deleted d join dbo.bPMMF o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
----	begin
----	select @errmsg = 'Entries exist in bPMMF'
----	goto error
----	end
----
-------- need to check PM tables for detail, but these checks only apply if the job status is not pending
----if exists(select top 1 1 from deleted d join dbo.bPMSL o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
----	begin
----	select @errmsg = 'Entries exist in bPMSL'
----	goto error
----	end

---- need to check PM tables for detail, but these checks only apply if the job status is not pending
if exists(select top 1 1 from deleted d join dbo.bPMMM o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
	begin
	select @errmsg = 'Entries exist in bPMMM'
	goto error
	end

---- need to check PM tables for detail, but these checks only apply if the job status is not pending
if exists(select top 1 1 from deleted d join dbo.bPMPU o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
	begin
	select @errmsg = 'Entries exist in bPMPU'
	goto error
	end

---- need to check PM tables for detail, but these checks only apply if the job status is not pending
if exists(select top 1 1 from deleted d join dbo.bPMRI o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
	begin
	select @errmsg = 'Entries exist in bPMRI'
	goto error
	end

---- need to check PM tables for detail, but these checks only apply if the job status is not pending
if exists(select top 1 1 from deleted d join dbo.bPMSM o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
	begin
	select @errmsg = 'Entries exist in bPMSM'
	goto error
	end

---- need to check PM tables for detail, but these checks only apply if the job status is not pending
if exists(select top 1 1 from deleted d join dbo.bPMTM o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
	begin
	select @errmsg = 'Entries exist in bPMTM'
	goto error
	end

---- need to check PM tables for detail, but these checks only apply if the job status is not pending
if exists(select top 1 1 from deleted d join dbo.bPMDG o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
	begin
	select @errmsg = 'Entries exist in bPMDG'
	goto error
	end

---- need to check PM tables for detail, but these checks only apply if the job status is not pending
if exists(select top 1 1 from deleted d join dbo.bPMIL o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
	begin
	select @errmsg = 'Entries exist in bPMIL'
	goto error
	end

---- need to check PM tables for detail, but these checks only apply if the job status is not pending
if exists(select top 1 1 from deleted d join dbo.bPMTL o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
	begin
	select @errmsg = 'Entries exist in bPMTL'
	goto error
	end

---- need to check PM tables for detail, but these checks only apply if the job status is not pending
if exists(select top 1 1 from deleted d join dbo.bPMIM o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
	begin
	select @errmsg = 'Entries exist in bPMIM'
	goto error
	end

---- need to check PM tables for detail, but these checks only apply if the job status is not pending
if exists(select top 1 1 from deleted d join dbo.bPMPL o (nolock) ON d.JCCo=o.PMCo and d.Job=o.Project and d.JobStatus <> 0)
	begin
	select @errmsg = 'Entries exist in bPMPL'
	goto error
	end
   

   
-- CHS 11/07/08 - #130950
if exists(select * from EMLB b join deleted d on (b.ToJCCo = d.JCCo and b.ToJob = d.Job) or (b.FromJCCo = d.JCCo and b.FromJob = d.Job))
	 begin
	 select @errmsg = 'Entries exist in bEMLB'
	 goto error
	 end

-- CHS 11/07/08 - #130950
if exists(select * from EMLH h join deleted d on h.ToJCCo = d.JCCo and h.ToJob = d.Job and h.DateOut is Null)
	 begin
	 select @errmsg = 'Entries exist in bEMLH'
	 goto error
	 end

-- CHS 11/07/08 - #130950
if exists(select * from EMEM e join deleted d on e.EMCo = d.JCCo and e.Job = d.Job)
	 begin
	 select @errmsg = 'Entries exist in bEMEM'
	 goto error
	 end
	 
--Check for related Job use on the SM Service Site	 
if exists(select 1 from dbo.vSMServiceSite sm join deleted d on sm.JCCo = d.JCCo and sm.Job = d.Job where [Type] = 'Job')
begin
	select @errmsg = 'Entries exist in SM Service Site'
	goto error
end	 


---------------------------------------------
-- DELETE ALL RELATED RECORDS IN PM 127448 --
---------------------------------------------
delete bPMBC from bPMBC e join deleted d on e.Co = d.JCCo and e.Project = d.Job
delete bPMBE from bPMBE e join deleted d on e.Co = d.JCCo and e.Project = d.Job
delete bPMCD from bPMCD e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMDC from bPMDC e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMMD from bPMMD e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMMF from bPMMF e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMML from bPMML e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMOA from bPMOA e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMOC from bPMOC e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMOM from bPMOM e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job

delete bPMPD from bPMPD e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMQD from bPMQD e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMRD from bPMRD e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMSL from bPMSL e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMSI from bPMSI e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMSM from bPMSM e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMSS from bPMSS e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMTC from bPMTC e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMTS from bPMTS e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMDR from bPMDR e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMDG from bPMDG e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMIL from bPMIL e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMTL from bPMTL e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMED from bPMED e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMEH from bPMEH e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMDZ from bPMDZ e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job

delete bPMNR from bPMNR e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMPN from bPMPN e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMDD from bPMDD e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMDL from bPMDL e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMMI from bPMMI e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMMM from bPMMM e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMOD from bPMOD e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMOL from bPMOL e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMOI from bPMOI e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMOP from bPMOP e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMOH from bPMOH e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMPI from bPMPI e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMPL from bPMPL e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMPU from bPMPU e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMRI from bPMRI e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMRQ from bPMRQ e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMTM from bPMTM e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job

delete bPMDH from bPMDH e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMIH from bPMIH e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
delete bPMIM from bPMIM e join deleted d on e.PMCo = d.JCCo and e.Project = d.Job
----TK-03291
DELETE dbo.vPMSubcontractCO FROM dbo.vPMSubcontractCO e JOIN deleted d ON e.PMCo = d.JCCo and e.Project = d.Job
----TK-03569
DELETE dbo.vPMPOCO FROM dbo.vPMPOCO e JOIN deleted d ON e.PMCo=d.JCCo AND e.Project=d.Job

delete vJCJobRoles from vJCJobRoles e join deleted d on e.JCCo=d.JCCo and e.Job=d.Job

/*--------------------------------------*/
/* Audit inserts */
/*--------------------------------------*/
INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'bJCJM','JC Co#: ' + convert(char(3), d.JCCo) + ' Job: ' + d.Job, d.JCCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
FROM deleted d JOIN dbo.bJCCO c (nolock) ON d.JCCo = c.JCCo
where c.AuditJobs='Y'

return

error:
   select @errmsg = @errmsg + ' - cannot delete Job Master'
   RAISERROR(@errmsg, 11, -1);
   rollback transaction


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/***************************************************************/
CREATE trigger [dbo].[btJCJMi] on [dbo].[bJCJM] for INSERT as
/*--------------------------------------------------------------
* Created: JRE  07/12/97
* Modified: GG 04/22/99 - (SQL 7.0)
*  			GF 02/14/2000 
*			GF 10/11/2001 - insert bPMPF with ArchEngFirm and contact if not exists. #14840
*			SR 10/25/2001 - added DataType Security, DDDU, insertion if securing bJob in DDDT - #15041
*  			12/03/01 - Removed Data Type Security fix the insert should be done in VB. = # 15353  
*			GF 08/08/2002 - Issue #17355 added AutoAddItemYN flag. 
*			GG 01/20/2003 - #18703 - weighted avg OT  
*			DC 5/13/03  - Issue 18385 
*			DANF - 21616 - Do not allow duplicate job numbers, regardless of case.
*			GF 10/30/2003 - issue #22769 - added include into PMPA insert statement
*  			DANF 03/20/04 - Issue 20980 Assign security group by Job.
*			09/24/2004 - issue #25625 - insert audit into HQMA not checking JCCO.AuditJobs
*			GF 11/02/2004 - issue #24309 - added validation for DefaultStdDaysDue and DefaultRFIDaysDue
*			GF 12/19/2006 - issue #123360 - change to PMPA insert - addons.
*			DANF 02/19/07 - issue #123034 - Added validation for Rate Template.
*			GG 04/20/07 - #30116 - data security review
*			GF 10/28/2007 - issue #126008 insert PMPC costtype markup records
*			GF 12/08/2007 - issue #126426 added join to PMCo for PMPC insert.
*			GF 01/03/2008 - issue #120218 dropped 3 columns
*			GF 02/14/2008 - issue #127210 #127195 new columns in PMPA 6.1.0
*			GF 03/10/2008 - issue #127076 country and state validation
*			GF 04/27/2008 - issue #22100 more columns for PMPA
*			GF 08/03/2010 - issue #134354 more columns for PMPA and PMPC
*			GP 11/15/2010 - commented out Contract validation to allow nullable column entry
*
*
*
* Insert trigger for JCJM
*
*  PMPA rows are created when inserting a JCJM record
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int, @nullcnt int,
		@seq int, @jcco bCompany, @job bJob, @vendorgroup bGroup, @firm bFirm,
		@contact bEmployee, @secure bYN

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

---- Check if primary key has changed
select @validcnt = count(*) from dbo.bJCCO j (nolock) JOIN inserted i ON  i.JCCo = j.JCCo
if @validcnt<> @numrows
       begin
       select @errmsg = 'JCCo is Invalid '
       goto error
       end
---- Check for duplicate job number regardless of case.
if exists( select top 1 1 from inserted v1 join dbo.bJCJM v2 (nolock) on
   					v1.JCCo = v2.JCCo and UPPER(v1.Job) = UPPER(v2.Job) and v1.Job <> v2.Job)
       begin
       select @errmsg = 'Duplicate Job found in a upper or lower case.'
       goto error
       end
---- validate tax code
select @validcnt = count(*) from dbo.bHQTX r (nolock) join inserted i ON  i.TaxGroup=r.TaxGroup and i.TaxCode=r.TaxCode
select @nullcnt= count(*) from inserted where TaxCode is null
if @validcnt+@nullcnt <> @numrows
       begin
       select @errmsg = 'Tax Code is Invalid '
       goto error
       end
------ Validate Contract
--select @validcnt = count(*) from dbo.bJCCM r  (nolock) JOIN inserted i ON  i.JCCo = r.JCCo and i.Contract = r.Contract
--if @validcnt <> @numrows
--       begin
--       select @errmsg = 'Contract is Invalid '
--       goto error
--       end
------ Validate Status
--if exists (select top 1 1 from dbo.bJCCM r  (nolock) join inserted i on i.JCCo = r.JCCo
--			and i.Contract = r.Contract WHERE i.JobStatus<>r.ContractStatus)
--       begin
--       select @errmsg = 'Job Status must be same as Contract Status'
--       goto error
--       end
---- Validate ProjectMgr
select @validcnt = count(*) from dbo.bJCMP r  (nolock) JOIN inserted i ON  i.JCCo = r.JCCo and i.ProjectMgr = r.ProjectMgr
select @nullcnt = count(*) from inserted i where i.ProjectMgr is null
if @validcnt + @nullcnt <> @numrows
       begin
       select @errmsg = 'Project Manager is Invalid '
       goto error
       end
---- Validate LiabTemplate
select @validcnt = count(*) from dbo.bJCTH r (nolock) JOIN inserted i ON i.JCCo = r.JCCo and i.LiabTemplate = r.LiabTemplate
select @nullcnt = count(*) from inserted i where i.LiabTemplate is null
if @validcnt + @nullcnt <> @numrows
       begin
       select @errmsg = 'Liability Template is Invalid '
       goto error
       end
---- Validate InsTemplate
select @validcnt = count(*) from dbo.bJCTN r (nolock) JOIN inserted i ON i.JCCo = r.JCCo and i.InsTemplate = r.InsTemplate
select @nullcnt = count(*) from inserted i where i.InsTemplate is null
if @validcnt + @nullcnt <> @numrows
       begin
       select @errmsg = 'Insurance Template is Invalid '
       goto error
       end
---- Validate RateTemplate
select @validcnt = count(*) from dbo.bJCRT r (nolock) JOIN inserted i ON i.JCCo = r.JCCo and i.RateTemplate = r.RateTemplate
select @nullcnt = count(*) from inserted i where i.RateTemplate is null
if @validcnt + @nullcnt <> @numrows
       begin
       select @errmsg = 'Rate Template is Invalid '
       goto error
       end
---- Validate HaulTaxOpt
select @validcnt = count(*) from inserted where HaulTaxOpt in (0,1,2)
select @nullcnt = count(*) from inserted where HaulTaxOpt is null
if @validcnt + @nullcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Haul Tax Option - must be 0, 1, 2'
   	goto error
   	end

---- validate mail country
select @validcnt = count(*) from dbo.bHQCountry c with (nolock) join inserted i on i.MailCountry=c.Country
select @nullcnt = count(*) from inserted where MailCountry is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Mail Country'
	goto error
	end

---- validate ship country
select @validcnt = count(*) from dbo.bHQCountry c with (nolock) join inserted i on i.ShipCountry=c.Country
select @nullcnt = count(*) from inserted where ShipCountry is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Ship Country'
	goto error
	end

---- validate mail state
select @validcnt = count(*) from dbo.bHQST s with (nolock)
	join inserted i on i.MailCountry=s.Country and i.MailState=s.State
select @validcnt2 = count(*) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.JCCo
	join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.MailState
	where i.MailCountry is null and i.MailState is not null
select @nullcnt = count(*) from inserted i where isnull(i.MailState,'') = ''
if @validcnt + @validcnt2 + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Mail Country/State combination'
	goto error
	end

---- validate ship state
select @validcnt = count(*) from dbo.bHQST s with (nolock)
	join inserted i on i.ShipCountry=s.Country and i.ShipState=s.State
select @validcnt2 = count(*) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.JCCo
	join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.ShipState
	where i.ShipCountry is null and i.ShipState is not null
select @nullcnt = count(*) from inserted i where isnull(i.ShipState,'') = ''
if @validcnt + @validcnt2 + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Ship Country/State combination'
	goto error
	end



---- DC #18385 -------START-----------------------------------------
IF exists(select top 1 1 from dbo.bJCHJ h  (nolock) JOIN inserted i ON i.JCCo = h.JCCo and i.Job = h.Job)
   	BEGIN
   	select @errmsg = 'Job ID was previously used.  Cannot use Job ID until it is purged from Job History.'
   	goto error
   	END

---- Validate DefaultStdDaysDue
select @validcnt = count(*) from inserted where DefaultStdDaysDue between 0 and 100
select @nullcnt = count(*) from inserted where DefaultStdDaysDue is null
if @validcnt + @nullcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Default Standard Days Due - must be between (0 - 99)'
   	goto error
   	end

---- Validate DefaultRFIDaysDue
select @validcnt = count(*) from inserted where DefaultRFIDaysDue between 0 and 100
select @nullcnt = count(*) from inserted where DefaultRFIDaysDue is null
if @validcnt + @nullcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Default RFI Days Due - must be between (0 - 99)'
   	goto error
   	end

---- insert into PMPA - Project Addons #127210, #22100
insert dbo.bPMPA(PMCo, Project, AddOn, Description, Basis, Pct, Amount, PhaseGroup, Phase,
		CostType, Contract, Item, Notes, TotalType, Include, NetCalcLevel, BasisCostType,
		RevRedirect, RevItem, RevStartAtItem, RevFixedACOItem, RevUseItem,
		----#134354
		Standard, RoundAmount)
select p.PMCo, i.Job, p.Addon, p.Description, p.Basis, p.Pct, p.Amount,p.PhaseGroup, p.Phase,
		p.CostType, i.Contract, p.Item, p.Notes, p.TotalType, p.Include, p.NetCalcLevel, p.BasisCostType,
		p.RevRedirect, p.RevItem, p.RevStartAtItem, p.RevFixedACOItem, p.RevUseItem,
		----#134354
		p.Standard, p.RoundAmount
from dbo.bPMCA p (nolock) join inserted i on p.PMCo=i.JCCo
where not exists (select 1 from dbo.bPMPA q with (nolock) where q.PMCo=p.PMCo and q.Project=i.Job and q.AddOn=p.Addon)

---- insert Project firm record into PMPF - no records should exist
insert dbo.bPMPF (PMCo, Project, VendorGroup, FirmNumber, ContactCode, Seq)
select i.JCCo, i.Job, i.VendorGroup, i.ArchEngFirm, i.ContactCode,
		isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.JCCo, i.Job) 
from inserted i
join dbo.bPMCO p on p.PMCo=i.JCCo
left join dbo.bPMPF h on h.PMCo = i.JCCo and h.Project = i.Job
where i.VendorGroup is not null and i.ArchEngFirm is not null and i.ContactCode is not null
and not exists(select top 1 1 from dbo.bPMPF f where f.PMCo=i.JCCo and f.Project=i.Job and f.VendorGroup=i.VendorGroup
		and f.FirmNumber=i.ArchEngFirm and f.ContactCode=i.ContactCode)
group by i.JCCo, i.Job, i.VendorGroup, i.ArchEngFirm, i.ContactCode

---- insert project markups into PMPC - create a markup record for each costtype
insert dbo.bPMPC(PMCo, Project, PhaseGroup, CostType, Markup, RoundAmount)
----#134354
select i.JCCo, i.Job, h.PhaseGroup, c.CostType, 0, 'N'
from inserted i
join dbo.bHQCO h on h.HQCo=i.JCCo
join dbo.bPMCO p on p.PMCo=i.JCCo
join dbo.bJCCT c on c.PhaseGroup=h.PhaseGroup
where h.PhaseGroup is not null
and not exists(select top 1 1 from dbo.bPMPC m where m.PMCo=i.JCCo and m.Project=i.Job
			and m.PhaseGroup=h.PhaseGroup and m.CostType=c.CostType)


--#30116 - initialize Data Security for bJob - default security group
declare @dfltsecgroup smallint
select @dfltsecgroup = DfltSecurityGroup
from dbo.DDDTShared (nolock) where Datatype = 'bJob' and Secure = 'Y'
if @dfltsecgroup is not null
	begin
	insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
	select 'bJob', i.JCCo, i.Job, @dfltsecgroup
	from inserted i 
	where not exists(select 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bJob' and s.Qualifier = i.JCCo 
						and s.Instance = i.Job and s.SecurityGroup = @dfltsecgroup)
	end   
   
---- initialize Data Security for Security Group entered with Job
select @secure = Secure from dbo.DDDTShared with (nolock) where Datatype = 'bJob'
if @@rowcount = 1 and @secure = 'Y'
	begin
   	insert vDDDS(Datatype, Qualifier, Instance, SecurityGroup)
   	select 'bJob', i.JCCo, i.Job, i.SecurityGroup
   	from inserted i
   	where i.SecurityGroup is not null and not exists (select top 1 1 from dbo.vDDDS (nolock) where Datatype = 'bJob'
				and Qualifier = i.JCCo and Instance = i.Job and SecurityGroup = i.SecurityGroup)                
	end
   


---- Audit inserts
INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'A',
		NULL, NULL, NULL, getdate(), SUSER_SNAME() 
from inserted i join bJCCO c on i.JCCo = c.JCCo
where c.AuditJobs = 'Y'


return

error:
   	select @errmsg = @errmsg + ' - cannot insert Job Master'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  trigger [dbo].[btJCJMu] on [dbo].[bJCJM] for UPDATE as
/*--------------------------------------------------------------
* Created: JRE 07/12/97 
* Modified:	10/08/98  JRE - added checks for contract change
*          01/20/2000 GF - more contract change checks and updates
*          02/14/2000 GF - MS columns
*          04/18/2000 GR - validated reviewer only on update of reviewer issue# 6711
*          03/20/2001 GF - update PM change orders with contract if not in JC change orders.
*          10/11/2001 GF - insert bPMPF with ArchEngFirm and contact if not exists. #14840
*			08/08/2002 GF - Issue #17355 added AutoAddItemYN flag.
*			01/08/2003 GF - Issue #19913 changed item format to use the bContractItem input mask. Per Hazel conversion
*			01/20/2003 GG - #18703 - weighted avg OT
*			03/20/2004 DF - Issue #20980 - Added Group security to contract and job master.
*			GF 11/02/2004 - issue #24309 - added validation for DefaultStdDaysDue and DefaultRFIDaysDue
*			GF 11/16/2004 - issue #26136 - some fields not being audited. Added audit checks.
*			DANF 07/26/2005 - issue 29397 - Add aduiting of UpdateMSActualsYN and UpdateAPActualsYN
*			GG 11/13/06 - #123034 - added auditing and validation for RateTemplate
*			DANF 02/22/07 - #119868 - Corrected aduting for columns that can be nullable.
*			GG 04/28/07 - #30116 - data security review, cleanup, convert to ansi joins, removed cursors
*			GF 12/08/2007 - issue #126426 added join to PMCo for PMPF insert.
*			GF 01/03/2008 - issue #120218 dropped 3 columns.
*			GF 03/10/2008 - issue #127076 country and state validation
*			GP 04/25/2008 - issue #127628 - added auditing for CertDate
*			GG 05/13/08 - #127461 - leave data security entries for default security group
*			GF 03/16/2009 - issue #132485 audit AutoGenRFQNum
*			GF 03/20/2009 - issue #129409 price escalators
*			MH 07/15/2009 - issue #131373 Added audit entries for TimesheetRevGroup.  Also added
*							missing entries for RevGrpInv.
*			JG 11/30/10 - If a change to the PCVisibleInJC flag is being done, 
*			then the Job can change (from temp to perm and vise-versa)    
*
*
*  Update trigger on JC Job Master
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int, @nullcnt int,        
		@contractitem char(16), @itemformat varchar(10), @itemmask varchar(10),
		@ditem varchar(16), @itemlength varchar(10), @inputmask varchar(30)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- Check if primary key has changed
if UPDATE(JCCo)
    begin
    select @errmsg = 'JC Co# may not be updated'
    goto error
    end

-- JG 11/30/10 - If a change to the visible flag is being done, then the Job can change (from temp to perm and vise-versa)    
IF NOT UPDATE(PCVisibleInJC)
	BEGIN
	if UPDATE(Job)
		begin
		select @errmsg = 'Job may not be updated'
		goto error
		end
	END
	
-- validate other relationships
if UPDATE(TaxGroup) or UPDATE(TaxCode)
	begin
    select @validcnt = count(*) from dbo.bHQTX r
    JOIN inserted i ON  i.TaxGroup = r.TaxGroup and i.TaxCode = r.TaxCode
    select @nullcnt = count(*) from inserted where TaxCode is null
    if @validcnt + @nullcnt <> @numrows
        begin
        select @errmsg = 'Tax Code is invalid '
        goto error
        end
	END

-- Validate Status
if exists (select top 1 1 from dbo.bJCCM r (nolock)
			JOIN inserted i ON i.JCCo = r.JCCo and i.Contract = r.Contract
  	         WHERE i.JobStatus <> r.ContractStatus)
    begin
    select @errmsg = 'Job Status must match Contract Status'
    goto error
    end

-- Validate ProjectMgr
if UPDATE(ProjectMgr)
	begin
    select @validcnt = count(*) from dbo.bJCMP r (nolock)
    JOIN inserted i ON  i.JCCo = r.JCCo and i.ProjectMgr = r.ProjectMgr
    select @nullcnt = count(*) from inserted where ProjectMgr is null
    if @validcnt + @nullcnt <> @numrows
        begin
        select @errmsg = 'Project Manager is invalid '
        goto error
        end
	end
-- Validate LiabTemplate
if UPDATE(LiabTemplate)
	begin
    select @validcnt = count(*) from dbo.bJCTH r (nolock)
	JOIN inserted i ON i.JCCo = r.JCCo  and i.LiabTemplate = r.LiabTemplate
    select @nullcnt = count(*) from inserted where LiabTemplate is null
    if @validcnt + @nullcnt <> @numrows
        begin
        select @errmsg = 'Liability Template is invalid '
        goto error
        end
	end
-- Validate InsTemplate
if UPDATE(InsTemplate)
	BEGIN
    select @validcnt = count(*) from dbo.bJCTN r (nolock)
	JOIN inserted i ON i.JCCo = r.JCCo  and i.InsTemplate = r.InsTemplate
    select @nullcnt = count(*) from inserted where InsTemplate is null
    if @validcnt + @nullcnt <> @numrows
        begin
        select @errmsg = 'Insurance Template is invalid '
        goto error
        end
	end
-- Validate RateTemplate
if UPDATE(RateTemplate)
	BEGIN
    select @validcnt = count(*) from dbo.bJCRT r (nolock)
	JOIN inserted i ON i.JCCo = r.JCCo  and i.RateTemplate = r.RateTemplate
    select @nullcnt = count(*) from inserted where RateTemplate is null
    if @validcnt + @nullcnt <> @numrows
        begin
        select @errmsg = 'Rate Template is invalid '
        goto error
        end
	end
-- Validate HaulTaxOpt
if UPDATE(HaulTaxOpt)
	BEGIN
    select @validcnt = count(*) from inserted where HaulTaxOpt in (0,1,2)
	if @validcnt <> @numrows
		begin
		select @errmsg = 'Invalid Haul Tax Option - must be 0, 1, 2'
		goto error
		end
	END
-- Validate AutoAddItemYN
if UPDATE(AutoAddItemYN)
	BEGIN
    select @validcnt = count(*) from inserted i where i.AutoAddItemYN in ('Y','N')
    if @validcnt <> @numrows
	   begin
	   select @errmsg = 'Invalid Auto Add Item flag - must be (Y,N).'
	   goto error
	   end
	END
-- #18703 - Check Weighted Average OT option
if update(WghtAvgOT)
	begin
	if exists(select 1 from inserted where WghtAvgOT not in ('Y','N'))
		begin
        select @errmsg = 'Weighted Average Overtime option must ''Y'' or ''N''.'
        goto error
        end
	end
-- Validate DefaultStdDaysDue
if update(DefaultStdDaysDue)
	begin
	select @validcnt = count(*) from inserted i where i.DefaultStdDaysDue between 0 and 100
	select @nullcnt = count(*) from inserted i where i.DefaultStdDaysDue is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Default Standard Days Due - must be between (0 - 99)'
		goto error
		end
	end
-- Validate DefaultRFIDaysDue
if update(DefaultRFIDaysDue)
	begin
	select @validcnt = count(*) from inserted i where i.DefaultRFIDaysDue between 0 and 100
	select @nullcnt = count(*) from inserted i where i.DefaultRFIDaysDue is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Default RFI Days Due - must be between (0 - 99)'
		goto error
		end
	end

---- validate mail country
if update(MailCountry)
	begin
	select @validcnt = count(*) from dbo.bHQCountry c with (nolock) join inserted i on i.MailCountry=c.Country
	select @nullcnt = count(*) from inserted where MailCountry is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Mail Country'
		goto error
		end
	end

---- validate ship country
if update(ShipCountry)
	begin
	select @validcnt = count(*) from dbo.bHQCountry c with (nolock) join inserted i on i.ShipCountry=c.Country
	select @nullcnt = count(*) from inserted where ShipCountry is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Ship Country'
		goto error
		end
	end

---- validate mail state
if update(MailState)
	begin
	select @validcnt = count(*) from dbo.bHQST s with (nolock)
		join inserted i on i.MailCountry=s.Country and i.MailState=s.State
	select @validcnt2 = count(*) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.JCCo
		join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.MailState
		where i.MailCountry is null and i.MailState is not null
	select @nullcnt = count(*) from inserted i where i.MailState is null
	if @validcnt + @validcnt2 + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Mail Country/State combination'
		goto error
		end
	end

---- validate ship state
if update(ShipState)
	begin
	select @validcnt = count(*) from dbo.bHQST s with (nolock)
		join inserted i on i.ShipCountry=s.Country and i.ShipState=s.State
	select @validcnt2 = count(*) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.JCCo
		join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.ShipState
		where i.ShipCountry is null and i.ShipState is not null
	select @nullcnt = count(*) from inserted i where i.ShipState is null
	if @validcnt + @validcnt2 + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Ship Country/State combination'
		goto error
		end
	end


-- Under limited circumstances Contract can be changed on a Job.  If Job and Contract meet the
-- requirements, Job Phases will be redirected to the new Contract and matching Items if they exist.
-- All other Job Phases will be redirected to the first Item on the new Contract.
    
-- check for Contract change
if UPDATE(Contract) and exists (select 1 from inserted i join deleted d on i.JCCo = d.JCCo and i.Job = d.Job where i.Contract <> d.Contract)
	begin
    select @validcnt = count(*) from dbo.bJCCM r (nolock)
	JOIN inserted i ON i.JCCo = r.JCCo and i.Contract = r.Contract
    if @validcnt <> @numrows
        begin
        select @errmsg = 'Contract is Invalid'
        goto error
        end
    -- can't change Contract if found in Close
    if exists(select top 1 1 from dbo.bJCCC j (nolock) JOIN inserted i ON i.JCCo = j.Co and i.Job = j.Job)
        begin
        select @errmsg = 'Contract is marked to be closed, cannot be changed'
        goto error
        end
    -- can't change Contract if found in Job History
    if exists(select top 1 1 from dbo.bJCHJ j (nolock) JOIN inserted i ON i.JCCo = j.JCCo and i.Job = j.Job)
        begin
        select @errmsg = 'Job History exists, Contract may not be changed'
        goto error
        end
    -- can't change Contract if found in JC Change orders
    if exists(select 1 from dbo.bJCOH j (nolock) JOIN inserted i ON i.JCCo = j.JCCo and i.Job = j.Job)
        begin
        select @errmsg = 'Change Orders exist, Contract may not be changed'
        goto error
        end

	-- get input mask for bContractItem
	select @inputmask = InputMask, @itemlength = convert(varchar(10), InputLength)
	from dbo.DDDTShared (nolock)
	where Datatype = 'bContractItem'

	if isnull(@inputmask,'') = '' select @inputmask = 'R'
	if isnull(@itemlength,'') = '' select @itemlength = '16'
	if @inputmask in ('R','L')	select @inputmask = @itemlength + @inputmask + 'N'

	-- format Contract Item '1'  
	select @ditem = '1'
	exec bspHQFormatMultiPart @ditem, @inputmask, @contractitem output
    
    -- update Job Phases where Contract has changed and Item exists on new Contract
    update dbo.bJCJP set Contract = i.Contract
    from dbo.bJCJP p
	join inserted i on p.JCCo = i.JCCo and p.Job = i.Job and p.Contract <> i.Contract
	join dbo.bJCCI c (nolock) on i.JCCo = c.JCCo and i.Contract = c.Contract and p.Item = c.Item 
    
    --- add Contract Item '1' (formatted) if no Items exist
    insert dbo.bJCCI(JCCo, Contract, Item, Description, Department, TaxGroup,TaxCode, UM, RetainPCT, BillType)
    select distinct p.JCCo, i.Contract, @contractitem, c.Description, c.Department,
            c.TaxGroup, c.TaxCode, 'LS', c.RetainagePCT, c.DefaultBillType
	from dbo.bJCJP p
	join inserted i on p.JCCo = i.JCCo and p.Job = i.Job and p.Contract <> i.Contract
	join dbo.bJCCM c on c.JCCo = i.JCCo and c.Contract = i.Contract
		and not exists(select top 1 1 from dbo.bJCCI j where j.JCCo = i.JCCo and j.Contract = i.Contract)
    
    --- update remaining Job Phases to first Contract Item
    update dbo.bJCJP set Contract = i.Contract,
		Item = (select min(c.Item) from dbo.bJCCI c (nolock) where c.JCCo = i.JCCo and c.Contract = i.Contract)
    from dbo.bJCJP p
	join inserted i on p.JCCo = i.JCCo and p.Job = i.Job and p.Contract <> i.Contract
    
    -- update Contract in PM Add-ons
    update dbo.bPMPA set Contract = i.Contract
    from dbo.bPMPA a
	join inserted i on a.PMCo=i.JCCo and a.Project=i.Job and a.Contract <> i.Contract
    -- update PM Pending Change Orders
    update dbo.bPMOP set Contract = i.Contract
    from dbo.bPMOP a
	join inserted i on a.PMCo=i.JCCo and a.Project=i.Job and a.Contract <> i.Contract
    -- update PM Approved Change Orders
    update dbo.bPMOH set Contract = i.Contract
    from dbo.bPMOH a 
	join inserted i on a.PMCo=i.JCCo and a.Project=i.Job and a.Contract <> i.Contract
    -- update PM Change Order Items
    update dbo.bPMOI set Contract = i.Contract
    from dbo.bPMOI a 
	join inserted i on a.PMCo=i.JCCo and a.Project=i.Job and a.Contract <> i.Contract
    END
    
if UPDATE(ArchEngFirm) or UPDATE(ContactCode)
	begin
	 -- insert Project Firm and Contact Code into PMPF Project Firms
	insert dbo.bPMPF (PMCo, Project, VendorGroup, FirmNumber, ContactCode, Seq)
	select i.JCCo, i.Job, i.VendorGroup, i.ArchEngFirm, i.ContactCode,
		isnull(max(h.Seq),0) + ROW_NUMBER() OVER(ORDER BY i.JCCo, i.Job) 
	from inserted i
	join dbo.bPMCO p on p.PMCo=i.JCCo
	left join dbo.bPMPF h on h.PMCo = i.JCCo and h.Project = i.Job
	where i.VendorGroup is not null and i.ArchEngFirm is not null and i.ContactCode is not null
	and not exists(select top 1 1 from dbo.bPMPF f where f.PMCo=i.JCCo and f.Project=i.Job and f.VendorGroup=i.VendorGroup
		and f.FirmNumber=i.ArchEngFirm and f.ContactCode=i.ContactCode)
	group by i.JCCo, i.Job, i.VendorGroup, i.ArchEngFirm, i.ContactCode
	end

IF update(SecurityGroup)
	begin
	--if changing Security Groups, remove Data Security entries for 'old' group unless it matches Default Security Group
	delete dbo.vDDDS
	from deleted d
	join dbo.vDDDS s on s.Datatype = 'bJob' and s.Qualifier = d.JCCo and s.Instance = d.Job and s.SecurityGroup = d.SecurityGroup
	join inserted i on i.JCCo = d.JCCo and i.Job = d.Job
	where d.SecurityGroup is not null and isnull(i.SecurityGroup,-1) <> d.SecurityGroup
		and d.SecurityGroup not in (select DfltSecurityGroup from dbo.DDDTShared where Datatype = 'bJob') -- #127461

	-- if bJob is secure, add entries for 'new' Security Group
	if exists(select top 1 1 from dbo.DDDTShared (nolock) where Datatype = 'bJob' and Secure = 'Y')
		begin
		insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
		select 'bJob', i.JCCo, i.Job, i.SecurityGroup
		from inserted i 
		join deleted d on d.JCCo = i.JCCo and d.Job = i.Job
		where i.SecurityGroup is not null
			and not exists(select top 1 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bJob' and s.Qualifier = i.JCCo 
							and s.Instance = i.Job and s.SecurityGroup = i.SecurityGroup)
		end
	end

---------- Audit inserts ----------
IF UPDATE(Description)
	BEGIN
	INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
		'Description',  d.Description, i.Description, getdate(), SUSER_SNAME()
    FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
    JOIN dbo.bJCCO c ON i.JCCo=c.JCCo
	where c.AuditJobs='Y' and isnull(d.Description,'')<>isnull(i.Description,'')
	END
IF UPDATE(Contract)
	BEGIN
	INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
		'Contract',  d.Contract, i.Contract, getdate(), SUSER_SNAME()
    FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
    JOIN dbo.bJCCO c ON i.JCCo=c.JCCo
	where c.AuditJobs='Y' and d.Contract<>i.Contract
	END
IF UPDATE(JobStatus)
    BEGIN
    INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'JobStatus',  convert(char(1), d.JobStatus) , convert(char(1), i.JobStatus), getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE d.JobStatus<>i.JobStatus
    END
    IF UPDATE(BidNumber)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'BidNumber',  d.BidNumber, i.BidNumber, getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.BidNumber,'')<>isnull(i.BidNumber,'')
    END
    IF UPDATE(LockPhases)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'LockPhases',  d.LockPhases, i.LockPhases, getdate(), SUSER_SNAME()
    	FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
    	JOIN bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' 
    	WHERE isnull(d.LockPhases,'N') <> isnull(i.LockPhases,'N')
    END
    IF UPDATE(ProjectMgr)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'ProjectMgr',  convert(varchar(14), d.ProjectMgr), convert(varchar(14),i.ProjectMgr), getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.ProjectMgr,0)<>isnull(i.ProjectMgr,0)
    END
    IF UPDATE(JobPhone)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'JobPhone',  d.JobPhone, i.JobPhone, getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.JobPhone,'')<>isnull(i.JobPhone,'')
    END
    IF UPDATE(JobFax)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'JobFax',  d.JobFax, i.JobFax, getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.JobFax,'')<>isnull(i.JobFax,'')
    END
    IF UPDATE(MailAddress)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'MailAddress',  d.MailAddress, i.MailAddress, getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.MailAddress,'')<>isnull(i.MailAddress,'')
    END
    IF UPDATE(MailCity)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'MailCity',  d.MailCity, i.MailCity, getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.MailCity,'')<>isnull(i.MailCity,'')
    END
    IF UPDATE(MailState)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'MailState',  d.MailState, i.MailState, getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.MailState,'')<>isnull(i.MailState,'')
    END
    IF UPDATE(MailZip)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'MailZip',  d.MailZip, i.MailZip, getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.MailZip,'')<>isnull(i.MailZip,'')
    END
    IF UPDATE(MailAddress2)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'MailAddress2',  d.MailAddress2, i.MailAddress2, getdate(), SUSER_SNAME()
    	FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
    	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.MailAddress2,'') <> isnull(i.MailAddress2,'')
    END
    IF UPDATE(ShipAddress)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'ShipAddress',  d.ShipAddress, i.ShipAddress, getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.ShipAddress,'')<>isnull(i.ShipAddress,'')
    END
    IF UPDATE(ShipCity)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'ShipCity',  d.ShipCity, i.ShipCity, getdate(), SUSER_SNAME()
         FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.ShipCity,'')<>isnull(i.ShipCity,'')
    END
    IF UPDATE(ShipState)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'ShipState',  d.ShipState, i.ShipState, getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.ShipState,'')<>isnull(i.ShipState,'')
    END
    IF UPDATE(ShipZip)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'ShipZip',  d.ShipZip, i.ShipZip, getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.ShipZip,'')<>isnull(i.ShipZip,'')
    END
    IF UPDATE(ShipAddress2)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'ShipAddress2',  d.ShipAddress2, i.ShipAddress2, getdate(), SUSER_SNAME()
    	FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
    	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.ShipAddress2,'') <> isnull(i.ShipAddress2,'')
    END
    IF UPDATE(LiabTemplate)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'LiabTemplate', convert(char(3), d.LiabTemplate), convert(char(3), i.LiabTemplate), getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.LiabTemplate,0)<>isnull(i.LiabTemplate,0)
    END
    IF UPDATE(TaxGroup)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'TaxGroup', convert(char(3), d.TaxGroup), convert(char(3), i.TaxGroup), getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE d.TaxGroup<>i.TaxGroup
    END
    IF UPDATE(TaxCode)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'TaxCode',  d.TaxCode, i.TaxCode, getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
     JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.TaxCode,'')<>isnull(i.TaxCode,'')
    END
    IF UPDATE(InsTemplate)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'InsTemplate', convert(char(3), d.InsTemplate), convert(char(3), i.InsTemplate), getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.InsTemplate,0)<>isnull(i.InsTemplate,0)
    END
    IF UPDATE(MarkUpDiscRate)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'MarkUpDiscRate', convert(char(12), d.MarkUpDiscRate), convert(char(12), i.MarkUpDiscRate), getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE d.MarkUpDiscRate<>i.MarkUpDiscRate
    END
    IF UPDATE(PRLocalCode)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'PRLocalCode',  d.PRLocalCode, i.PRLocalCode, getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.PRLocalCode,'')<>isnull(i.PRLocalCode,'')
    END
    IF UPDATE(PRStateCode)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'PRStateCode',  d.PRStateCode, i.PRStateCode, getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.PRStateCode,'')<>isnull(i.PRStateCode,'')
    END
    IF UPDATE(Certified)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'Certified',  d.Certified, i.Certified, getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE d.Certified<>i.Certified
    END
	IF UPDATE(CertDate)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'CertDate',  d.CertDate, i.CertDate, getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.CertDate,'')<>isnull(i.CertDate,'')
    END
    IF UPDATE(EEORegion)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'EEORegion',  d.EEORegion, i.EEORegion, getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.EEORegion,'')<>isnull(i.EEORegion,'')
    END
    IF UPDATE(SMSACode)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'SMSACode',  d.SMSACode, i.SMSACode, getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
   
           JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.SMSACode,'')<>isnull(i.SMSACode,'')
    END
    IF UPDATE(CraftTemplate)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'CraftTemplate',  convert(varchar(6),d.CraftTemplate), convert(varchar(6),i.CraftTemplate), getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.CraftTemplate,0)<>isnull(i.CraftTemplate,0)
    END
    IF UPDATE(ProjMinPct)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'ProjMinPct', convert(char(12), d.ProjMinPct), convert(char(12), i.ProjMinPct), getdate(), SUSER_SNAME()
            FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
            JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE d.ProjMinPct<>i.ProjMinPct
    END
    IF UPDATE(SLCompGroup)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'SLCompGroup',  d.SLCompGroup, i.SLCompGroup, getdate(), SUSER_SNAME()
    	FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
    	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.SLCompGroup,'') <> isnull(i.SLCompGroup,'')
    END
    IF UPDATE(POCompGroup)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'POCompGroup',  d.POCompGroup, i.POCompGroup, getdate(), SUSER_SNAME()
    	FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
    	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.POCompGroup,'') <> isnull(i.POCompGroup,'')
    END
    IF UPDATE(ArchEngFirm)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'ArchEngFirm',  d.ArchEngFirm, i.ArchEngFirm, getdate(), SUSER_SNAME()
    	FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
    	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.ArchEngFirm,0) <> isnull(i.ArchEngFirm,0)
    END
    IF UPDATE(OTSched)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
  
    	'OTSched',  d.OTSched, i.OTSched, getdate(), SUSER_SNAME()
    	FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
    	JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y' WHERE isnull(d.OTSched,0) <> isnull(i.OTSched,0)
    END
    IF UPDATE(PriceTemplate)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'Price Template',  convert(varchar(6),d.PriceTemplate), convert(varchar(6),i.PriceTemplate), getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
        JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y'
        WHERE isnull(d.PriceTemplate,0) <> isnull(i.PriceTemplate,0)
    END
    IF UPDATE(HaulTaxOpt)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'Haul Tax Option',  convert(varchar(1), d.HaulTaxOpt), convert(varchar(1), i.HaulTaxOpt), getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
        JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y'
        WHERE isnull(d.HaulTaxOpt,0) <> isnull(i.HaulTaxOpt,0)
    END
    IF UPDATE(GeoCode)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'GeoCode',  d.GeoCode, i.GeoCode, getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
        JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y'
        WHERE isnull(d.GeoCode,'') <> isnull(i.GeoCode,'')
    END
    IF UPDATE(BaseTaxOn)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'BaseTaxOn',  d.BaseTaxOn, i.BaseTaxOn, getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
        JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y'
        WHERE isnull(d.BaseTaxOn,'') <> isnull(i.BaseTaxOn,'')
    END
    IF UPDATE(UpdatePlugs)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'UpdatePlugs',  d.UpdatePlugs, i.UpdatePlugs, getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
        JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y'
        WHERE isnull(d.UpdatePlugs,'') <> isnull(i.UpdatePlugs,'')
    END
    IF UPDATE(ContactCode)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'ContactCode',  convert(varchar(10),d.ContactCode), convert(varchar(10),i.ContactCode), getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
        JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y'
        WHERE isnull(d.ContactCode,0) <> isnull(i.ContactCode,0)
    END
    IF UPDATE(OurFirm)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'OurFirm',  convert(varchar(10),d.OurFirm), convert(varchar(10),i.OurFirm), getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
        JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y'
        WHERE isnull(d.OurFirm,0) <> isnull(i.OurFirm,0)
    END
    IF UPDATE(AutoAddItemYN)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'Auto Add Item Flag',  d.AutoAddItemYN, i.AutoAddItemYN, getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
        JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y'
        WHERE d.AutoAddItemYN<>i.AutoAddItemYN
    END
    if update(WghtAvgOT)
    BEGIN	-- #18703
    	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	select 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'WghtAvgOT',  d.WghtAvgOT, i.WghtAvgOT, getdate(), SUSER_SNAME()
        from inserted i
    	join deleted d on d.JCCo = i.JCCo  AND d.Job = i.Job
        join  bJCCO c on i.JCCo = c.JCCo 
        where d.WghtAvgOT <> i.WghtAvgOT and c.AuditJobs = 'Y'
    END
    IF UPDATE(HrsPerManDay)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'HrsPerManDay',  convert(varchar(16),d.HrsPerManDay), convert(varchar(16),i.HrsPerManDay), getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
        JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y'
        WHERE isnull(d.HrsPerManDay,0) <> isnull(i.HrsPerManDay,0)
    END
    if update(AutoGenSubNo)
    BEGIN
    	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	select 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'AutoGenSubNo',  d.AutoGenSubNo, i.AutoGenSubNo, getdate(), SUSER_SNAME()
        from inserted i join deleted d on d.JCCo = i.JCCo  AND d.Job = i.Job
        join bJCCO c on i.JCCo = c.JCCo and c.AuditJobs='Y'
        where isnull(d.AutoGenSubNo,'') <> isnull(i.AutoGenSubNo,'')
    END
    IF UPDATE(SecurityGroup)
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'Security Group',  convert(varchar(5), d.SecurityGroup), convert(varchar(5), i.SecurityGroup), getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
        JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y'
        WHERE isnull(d.SecurityGroup,-1) <> isnull(i.SecurityGroup,-1)
    END
    IF UPDATE(DefaultStdDaysDue)
    BEGIN
    	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'DefaultStdDaysDue',  isnull(convert(varchar(5), d.DefaultStdDaysDue),0), 
    	isnull(convert(varchar(5), i.DefaultStdDaysDue),0), getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
        JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y'
        WHERE isnull(d.DefaultStdDaysDue,0) <> isnull(i.DefaultStdDaysDue,0)
    END
    IF UPDATE(DefaultRFIDaysDue)
    BEGIN
    	INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'DefaultRFIDaysDue',  isnull(convert(varchar(5), d.DefaultRFIDaysDue),0), 
    	isnull(convert(varchar(5), i.DefaultRFIDaysDue),0), getdate(), SUSER_SNAME()
        FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
        JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y'
        WHERE isnull(d.DefaultRFIDaysDue,0) <> isnull(i.DefaultRFIDaysDue,0)
    END
     if update(UpdateAPActualsYN)
    BEGIN	-- #29397
    	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	select 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'UpdateAPActualsYN', d.UpdateAPActualsYN, i.UpdateAPActualsYN, getdate(), SUSER_SNAME()
        from inserted i
    	join deleted d on d.JCCo = i.JCCo  AND d.Job = i.Job
        join  bJCCO c on i.JCCo = c.JCCo 
        where d.UpdateAPActualsYN <> i.UpdateAPActualsYN and c.AuditJobs = 'Y'
    END
    if update(UpdateMSActualsYN)
    BEGIN	-- #29397
    	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	select 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'UpdateMSActualsYN', d.UpdateMSActualsYN, i.UpdateMSActualsYN, getdate(), SUSER_SNAME()
        from inserted i
    	join deleted d on d.JCCo = i.JCCo  AND d.Job = i.Job
        join  bJCCO c on i.JCCo = c.JCCo 
        where d.UpdateMSActualsYN <> i.UpdateMSActualsYN and c.AuditJobs = 'Y'
    END
if update(AutoGenPCONo)
	BEGIN
    	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	select 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'AutoGenPCONo', d.AutoGenPCONo, i.AutoGenPCONo, getdate(), SUSER_SNAME()
        from inserted i
    	join deleted d on d.JCCo = i.JCCo  AND d.Job = i.Job
        join  bJCCO c on i.JCCo = c.JCCo 
        where isnull(d.AutoGenPCONo,'') <> isnull(i.AutoGenPCONo,'') and c.AuditJobs = 'Y'
    END
if update(AutoGenMTGNo)
	BEGIN
    	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	select 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'AutoGenMTGNo', d.AutoGenMTGNo, i.AutoGenMTGNo, getdate(), SUSER_SNAME()
        from inserted i
    	join deleted d on d.JCCo = i.JCCo  AND d.Job = i.Job
        join  bJCCO c on i.JCCo = c.JCCo 
        where isnull(d.AutoGenMTGNo,'') <> isnull(i.AutoGenMTGNo,'') and c.AuditJobs = 'Y'
    END
if update(AutoGenRFINo)
	BEGIN
    	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
    	select 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
    	'AutoGenRFINo', d.AutoGenRFINo, i.AutoGenRFINo, getdate(), SUSER_SNAME()
        from inserted i
    	join deleted d on d.JCCo = i.JCCo  AND d.Job = i.Job
        join  bJCCO c on i.JCCo = c.JCCo 
        where isnull(d.AutoGenRFINo,'') <> isnull(i.AutoGenRFINo,'') and c.AuditJobs = 'Y'
    END
if update(AutoGenRFQNo) ---- #132485
	BEGIN
	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
	'AutoGenRFINo', d.AutoGenRFQNo, i.AutoGenRFQNo, getdate(), SUSER_SNAME()
    from inserted i
	join deleted d on d.JCCo = i.JCCo  AND d.Job = i.Job
    join  bJCCO c on i.JCCo = c.JCCo 
    where isnull(d.AutoGenRFQNo,'') <> isnull(i.AutoGenRFQNo,'') and c.AuditJobs = 'Y'
    END
IF UPDATE(RateTemplate) -- #123034
    BEGIN
    INSERT INTO bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
	'Rate Template',  convert(varchar(6),d.RateTemplate), convert(varchar(6),i.RateTemplate), getdate(), SUSER_SNAME()
    FROM inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
    JOIN  bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y'
    WHERE isnull(d.RateTemplate,0) <> isnull(i.RateTemplate,0)
    END
if update(MailCountry)
	begin
	insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
	'MailCountry',  d.MailCountry, i.MailCountry, getdate(), SUSER_SNAME()
	from inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
	join bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y'
	where isnull(d.MailCountry,'') <> isnull(i.MailCountry,'')
	end
if update(ShipCountry)
	begin
	insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
	'ShipCountry',  d.ShipCountry, i.ShipCountry, getdate(), SUSER_SNAME()
	from inserted i JOIN deleted d ON d.JCCo=i.JCCo  AND d.Job=i.Job
	join bJCCO ON i.JCCo=bJCCO.JCCo and bJCCO.AuditJobs='Y'
	where isnull(d.ShipCountry,'') <> isnull(i.ShipCountry,'')
	end
if update(ApplyEscalators) ---- #129409
	BEGIN
	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
	'ApplyEscalators', d.ApplyEscalators, i.ApplyEscalators, getdate(), SUSER_SNAME()
    from inserted i
	join deleted d on d.JCCo = i.JCCo  AND d.Job = i.Job
    join  bJCCO c on i.JCCo = c.JCCo 
    where isnull(d.ApplyEscalators,'') <> isnull(i.ApplyEscalators,'') and c.AuditJobs = 'Y'
    END

if update(TimesheetRevGroup) ---- #131373
	BEGIN
	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
	'TimesheetRevGroup', d.TimesheetRevGroup, i.TimesheetRevGroup, getdate(), SUSER_SNAME()
    from inserted i
	join deleted d on d.JCCo = i.JCCo  AND d.Job = i.Job
    join  bJCCO c on i.JCCo = c.JCCo 
    where isnull(d.TimesheetRevGroup,'') <> isnull(i.TimesheetRevGroup,'') and c.AuditJobs = 'Y'
    END

if update(RevGrpInv) ---- #Unk Issue
	BEGIN
	insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bJCJM','JC Co#: ' + convert(char(3), i.JCCo) + ' Job: ' + i.Job, i.JCCo, 'C',
	'RevGrpInv', d.RevGrpInv, i.RevGrpInv, getdate(), SUSER_SNAME()
    from inserted i
	join deleted d on d.JCCo = i.JCCo  AND d.Job = i.Job
    join  bJCCO c on i.JCCo = c.JCCo 
    where isnull(d.RevGrpInv,'') <> isnull(i.RevGrpInv,'') and c.AuditJobs = 'Y'
    END


return


error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update into Job Master (bJCJM)'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
ALTER TABLE [dbo].[bJCJM] WITH NOCHECK ADD CONSTRAINT [CK_bJCJM_AutoGenRFQNo] CHECK (([AutoGenRFQNo]='T' OR [AutoGenRFQNo]='C' OR [AutoGenRFQNo]='P'))
GO
ALTER TABLE [dbo].[bJCJM] WITH NOCHECK ADD CONSTRAINT [CK_bJCJM_BaseTaxOn] CHECK (([BaseTaxOn]='O' OR [BaseTaxOn]='V' OR [BaseTaxOn]='J'))
GO
CREATE UNIQUE CLUSTERED INDEX [biJCJM] ON [dbo].[bJCJM] ([JCCo], [Job]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCJM] ([KeyID]) WITH (FILLFACTOR=85, STATISTICS_NORECOMPUTE=ON) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCJM].[LockPhases]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCJM].[TaxGroup]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCJM].[MarkUpDiscRate]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCJM].[Certified]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bJCJM].[ProjMinPct]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCJM].[UpdatePlugs]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCJM].[ClosePurgeFlag]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCJM].[AutoAddItemYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCJM].[WghtAvgOT]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCJM].[UpdateAPActualsYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJCJM].[UpdateMSActualsYN]'
GO
