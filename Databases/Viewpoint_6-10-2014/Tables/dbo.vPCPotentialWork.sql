CREATE TABLE [dbo].[vPCPotentialWork]
(
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[JCCo] [dbo].[bCompany] NOT NULL,
[PotentialProject] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[ProjectMgr] [dbo].[bProjectMgr] NULL,
[GoProbPct] [dbo].[bPct] NOT NULL CONSTRAINT [DF_vPCPotentialWork_GoProbPct] DEFAULT ((0)),
[AwardProbPct] [dbo].[bPct] NOT NULL CONSTRAINT [DF_vPCPotentialWork_AwardProbPct] DEFAULT ((0)),
[ProjectedChase] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPCPotentialWork_ProjectedChase] DEFAULT ((0)),
[StartDate] [dbo].[bDate] NOT NULL CONSTRAINT [DF_vPCPotentialWork_StartDate] DEFAULT (dateadd(day,(0),datediff(day,(0),getdate()))),
[CompletionDate] [dbo].[bDate] NOT NULL,
[RevenueEst] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPCPotentialWork_RevenueEst] DEFAULT ((0)),
[CostEst] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPCPotentialWork_CostEst] DEFAULT ((0)),
[ProfitEst] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vPCPotentialWork_ProfitEst] DEFAULT ((0)),
[AllowForecast] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vPCPotentialWork_AllowForecast] DEFAULT ('N'),
[Awarded] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vPCPotentialWork_Awarded] DEFAULT ('N'),
[AwardedDate] [dbo].[bDate] NULL,
[Contract] [dbo].[bContract] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[ProjectDetails] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[ProjectType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ProjectStatus] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[JobSiteStreet] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[JobSiteCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[JobSiteState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[JobSiteZip] [dbo].[bZip] NULL,
[JobSiteRegion] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[DocURL] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[DocOtherPlanLoc] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[ProjectSize] [dbo].[bUnits] NULL,
[ProjectSizeUM] [dbo].[bUM] NULL,
[WorkType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ClientType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ProjectValue] [dbo].[bDollar] NULL,
[PrimeSub] [char] (1) COLLATE Latin1_General_BIN NULL,
[ContractType] [char] (1) COLLATE Latin1_General_BIN NULL,
[BidResult] [char] (1) COLLATE Latin1_General_BIN NULL,
[BidAwardedDate] [dbo].[bDate] NULL,
[Competitor] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[CompetitorBid] [dbo].[bDollar] NULL,
[JobSiteCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[BidNumber] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[BidEstimator] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[BidBondReqYN] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vPCPotentialWork_BidBondReqYN] DEFAULT ('N'),
[BidPrequalReqYN] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_vPCPotentialWork_BidPrequalReqYN] DEFAULT ('N'),
[BidDate] [dbo].[bDate] NULL,
[BidTime] [dbo].[bDate] NULL,
[BidStatus] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[BidStarted] [dbo].[bDate] NULL,
[BidCompleted] [dbo].[bDate] NULL,
[BidSubmitted] [dbo].[bDate] NULL,
[BidPlanOrdered] [dbo].[bDate] NULL,
[BidPlanReceived] [dbo].[bDate] NULL,
[BidPlanCost] [dbo].[bDollar] NULL,
[BidLaborCost] [dbo].[bDollar] NULL,
[BidLaborHours] [dbo].[bHrs] NULL,
[BidMaterialCost] [dbo].[bDollar] NULL,
[BidEquipCost] [dbo].[bDollar] NULL,
[BidSubCost] [dbo].[bDollar] NULL,
[BidOtherCost] [dbo].[bDollar] NULL,
[BidTotalCost] [dbo].[bDollar] NULL,
[BidProfit] [dbo].[bDollar] NULL,
[BidMarkup] [dbo].[bPct] NULL,
[BidTotalPrice] [dbo].[bDollar] NULL,
[BidEquipHours] [dbo].[bHrs] NULL,
[BidPreMeeting] [dbo].[bDate] NULL,
[BidPreMeetingTime] [dbo].[bDate] NULL,
[BidPreMeetingNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[BidJCDept] [dbo].[bDept] NULL,
[BidPreMeetingLoc] [dbo].[bLoc] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/***************************************/
CREATE trigger [dbo].[vtPCPotentialWorkd] ON [dbo].[vPCPotentialWork] for DELETE as
/*-----------------------------------------------------------------
* Created By:	GF 09/03/2009
* Modified By:	JG 01/06/2011 - Delete trigger handles deleting the related records
*				JG 01/06/2011 - Delete trigger handles setting JCJM PotentialProjectID to null
*				GP 09/10/2012 - TK-17498 Update to bJCCM should nulll PotentialProject, not Contract
*
*
* Audits deletes in HQMA
* updates bJCCM and null out Potential Project
* deletes related rows in vPCForecastMonth
*
*----------------------------------------------------------------*/
declare @errmsg varchar(255), @numrows int
    
select @numrows = @@rowcount
if @numrows = 0 return

set nocount on
  
---- update bJCCM and null out potential project if assigned to contract
update bJCCM set PotentialProject = null
from bJCCM c join deleted d on d.JCCo = c.JCCo and d.PotentialProject = c.PotentialProject
   
---- delete the forecast months for potential projects
delete dbo.vPCForecastMonth
from dbo.vPCForecastMonth m
join deleted d on d.JCCo=m.JCCo and d.PotentialProject=m.PotentialProject

-- Delete all records in PC with a matching company and potential project id
delete e from vPCBidPackageScopes e join deleted d on e.JCCo = d.JCCo and e.PotentialProject = d.PotentialProject
delete e from vPCBidPackageBidList e join deleted d on e.JCCo = d.JCCo and e.PotentialProject = d.PotentialProject
delete e from vPCBidPackageScopeNotes e join deleted d on e.JCCo = d.JCCo and e.PotentialProject = d.PotentialProject
delete e from vPCBidMessageHistory e join deleted d on e.JCCo = d.JCCo and e.PotentialProject = d.PotentialProject
delete e from vPCBidCoverage e join deleted d on e.JCCo = d.JCCo and e.PotentialProject = d.PotentialProject
delete e from vPCBidPackage e join deleted d on e.JCCo = d.JCCo and e.PotentialProject = d.PotentialProject
delete e from vPCForecastMonth e join deleted d on e.JCCo = d.JCCo and e.PotentialProject = d.PotentialProject
delete e from vPCPotentialProjectCertificate e join deleted d on e.JCCo = d.JCCo and e.PotentialProject = d.PotentialProject
delete e from vPCPotentialProjectTeam e join deleted d on e.JCCo = d.JCCo and e.PotentialProject = d.PotentialProject

-- Set possible related PM Project's PotentialProjectID to null
update j
set PotentialProjectID = null
from bJCJM j
join deleted d on j.JCCo = d.JCCo and j.PotentialProjectID = d.KeyID
 
---- Audit inserts
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'vPCPotentialWork', 'Co: ' + convert(varchar(3), d.JCCo) + ' Potential Project:' + d.PotentialProject,
		d.JCCo, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d 
   
return
   
error:
   	select @errmsg = isnull(@errmsg,'') + ' - cannot delete Potential Project!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************/
CREATE TRIGGER [dbo].[vtPCPotentialWorki] on [dbo].[vPCPotentialWork] for INSERT AS 
/*-----------------------------------------------------------------
* Created By:		CHS 09/2/2009
* Modified By:		GP	01/06/2011 - Added insert to bJCJM for temp job record
*					GF  05/04/2011 - TK-04879 tax group is missing
*
*
* Trigger validates project manager and completion date.
* Then initialize procedure is run for each potential project
* where the allow forecast flag = 'Y' and has not been awarded
*
*
* Adds HQ Master Audit entry.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @rcode int, @validcnt int, @validcnt2 int,
		@jcco bCompany, @potentialproject varchar(20), @allowforecast char(1),
		@awarded char(1)

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


---- validate project manager
select @validcnt = count(*) from bJCMP p with (nolock) join inserted i on i.JCCo=p.JCCo and i.ProjectMgr=p.ProjectMgr
select @validcnt2 = count(*) from inserted i where i.ProjectMgr is null
if @validcnt + @validcnt2 <> @numrows
	begin
	select @errmsg = 'Invalid Project Manager'
	goto error
	end

---- validate Completion Date is not less than Start Date
if exists(select top 1 1 from inserted i where i.CompletionDate < i.StartDate)
	begin
	select @errmsg = 'Invalid completion date, must not preced Start Date'
	goto error
	end


---- create cursor to initialize forecast months for potential projects
if @numrows = 1
	begin
	select @jcco = JCCo, @potentialproject=PotentialProject, @awarded=Awarded, @allowforecast=AllowForecast
    from inserted
    end
else
    begin
	-- use a cursor to process each inserted row
	declare vPotentialWork_insert cursor FAST_FORWARD
	for select JCCo, PotentialProject, Awarded, AllowForecast
	from inserted

	open vPotentialWork_insert

    fetch next from vPotentialWork_insert into @jcco, @potentialproject, @awarded, @allowforecast

    if @@fetch_status <> 0
		begin
		select @errmsg = 'Cursor error'
		goto error
		end
    end

insert_check:

---- when forecasting allowed - execute initialize procedure
if @allowforecast = 'Y' and @awarded = 'N'
	begin
	exec @rcode = dbo.vspPCPotentialProjectInit @jcco, 'P', @potentialproject, @potentialproject, @errmsg output
	if @rcode <> 0
		begin
		select @errmsg = @errmsg + ' - unable to initialize forecast months into PC Forecast Month.'
		goto error
		end
	end


if @numrows > 1
	begin
	fetch next from vPotentialWork_insert into @jcco, @potentialproject, @awarded, @allowforecast

	if @@fetch_status = 0
		goto insert_check
	else
		begin
		close vPotentialWork_insert
		deallocate vPotentialWork_insert
		end
	end
	

--Insert temp job record - TK-04879
insert bJCJM (JCCo, Job, VendorGroup, [Description], PotentialProjectID, PCVisibleInJC,
			TaxGroup)
select i.JCCo, dbo.vfJCJMGetNextTempProjID(i.JCCo), i.VendorGroup, i.Description, i.KeyID, 'N',
			h.TaxGroup
from inserted i
JOIN dbo.bHQCO h ON h.HQCo=i.JCCo


---- Audit inserts 
INSERT dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
SELECT 'vPCPotentialWork','Co: ' + convert(char(3), i.JCCo) + ' Potential Project: ' + i.PotentialProject, 
   		i.JCCo, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME() 
FROM inserted i
----join dbo.bJCCO c (nolock) on c.JCCo=i.JCCo
----where c.AuditContracts = 'Y'


return

error:
	select @errmsg = @errmsg + ' - cannot insert PC Potential Work!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/********************************/
CREATE TRIGGER [dbo].[vtPCPotentialWorku] on [dbo].[vPCPotentialWork] for update AS 
/*-----------------------------------------------------------------
* Created By:		CHS 09/2/2009
* Modified By: 
*
*
* Trigger validates project manager and completion date.
* Then initialize procedure is run for each potential project
* where the allow forecast flag = 'Y' and has not been awarded
*
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------
declare @errmsg varchar(255), @rcode int, @numrows int, @validcnt int, @validcnt2 int,
		@jcco bCompany, @potentialproject varchar(20), @allowforecast char(1),
		@awarded char(1), @projectmgr bProjectMgr, @startdate bDate, @enddate bDate

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


---- validate project manager
if update(ProjectMgr)
	begin
	select @validcnt = count(*) from bJCMP p with (nolock) join inserted i on i.JCCo=p.JCCo and i.ProjectMgr=p.ProjectMgr
	select @validcnt2 = count(*) from inserted i where i.ProjectMgr is null
	if @validcnt + @validcnt2 <> @numrows
		begin
		select @errmsg = 'Invalid Project Manager'
		goto error
		end
	end

---- validate Completion Date is not less than Start Date
if update(StartDate) or update(CompletionDate)
	begin
	if exists(select top 1 1 from inserted i where i.CompletionDate < i.StartDate)
		begin
		select @errmsg = 'Invalid completion date, must not preced Start Date'
		goto error
		end
	end
	
	
---- create cursor to initialize forecast months for potential projects
if @numrows = 1
	begin
	select @jcco = JCCo, @potentialproject=PotentialProject, @awarded=Awarded, @allowforecast=AllowForecast
    from inserted
    end
else
    begin
	-- use a cursor to process each inserted row
	declare vPotentialWork_update cursor FAST_FORWARD
	for select JCCo, PotentialProject, Awarded, AllowForecast
	from inserted

	open vPotentialWork_update

    fetch next from vPotentialWork_update into @jcco, @potentialproject, @awarded, @allowforecast

    if @@fetch_status <> 0
		begin
		select @errmsg = 'Cursor error'
		goto error
		end
    end

update_check:

---- when forecasting allowed - execute initialize procedure when no records exist in vPCForecastMonth
if not exists(select top 1 1 from dbo.vPCForecastMonth with (nolock)
			where JCCo=@jcco and PotentialProject=@potentialproject)
	begin
	if @allowforecast = 'Y' and @awarded = 'N'
		begin
		exec @rcode = dbo.vspPCPotentialProjectInit @jcco, 'P', @potentialproject, @potentialproject, @errmsg output
		if @rcode <> 0
			begin
			select @errmsg = @errmsg + ' - unable to initialize forecast months into PC Forecast Month.'
			goto error
			end
		end
	end


if @numrows > 1
	begin
	fetch next from vPotentialWork_update into @jcco, @potentialproject, @awarded, @allowforecast

	if @@fetch_status = 0
		goto update_check
	else
		begin
		close vPotentialWork_update
		deallocate vPotentialWork_update
		end
	end


---- Audit inserts
IF UPDATE(Description)
	BEGIN
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'vJCPotentialWork','Co: ' + convert(char(3), i.JCCo) + ' Potential Project: ' + i.PotentialProject,
			i.JCCo, 'C', 'Description',  d.Description, i.Description, getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.PotentialProject=i.PotentialProject
	----JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.Description,'') <> isnull(i.Description,'')
	END
IF UPDATE(ProjectMgr)
	BEGIN
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'vJCPotentialWork','Co: ' + convert(char(3), i.JCCo) + ' Potential Project: ' + i.PotentialProject,
			i.JCCo, 'C', 'ProjectMgr',  convert(varchar(10),d.ProjectMgr), convert(varchar(10),i.ProjectMgr), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.PotentialProject=i.PotentialProject
	----JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.ProjectMgr,'') <> isnull(i.ProjectMgr,'')
	END
IF UPDATE(GoProbPct)
	BEGIN
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'vJCPotentialWork','Co: ' + convert(char(3), i.JCCo) + ' Potential Project: ' + i.PotentialProject,
			i.JCCo, 'C', 'GoProbPct',  convert(varchar(10),d.GoProbPct), convert(varchar(10),i.GoProbPct), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.PotentialProject=i.PotentialProject
	----JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.GoProbPct,'') <> isnull(i.GoProbPct,'')
	END
IF UPDATE(AwardProbPct)
	BEGIN
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'vJCPotentialWork','Co: ' + convert(char(3), i.JCCo) + ' Potential Project: ' + i.PotentialProject,
			i.JCCo, 'C', 'AwardProbPct',  convert(varchar(10),d.AwardProbPct), convert(varchar(10),i.AwardProbPct), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.PotentialProject=i.PotentialProject
	----JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.AwardProbPct,'') <> isnull(i.AwardProbPct,'')
	END
--IF UPDATE(OwnerName)
--	BEGIN
--	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
--	SELECT 'vJCPotentialWork','Co: ' + convert(char(3), i.JCCo) + ' Potential Project: ' + i.PotentialProject,
--			i.JCCo, 'C', 'OwnerName',  d.OwnerName, i.OwnerName, getdate(), SUSER_SNAME()
--	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.PotentialProject=i.PotentialProject
--	----JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
--	WHERE isnull(d.OwnerName,'') <> isnull(i.OwnerName,'')
--	END
--IF UPDATE(OwnerContact)
--	BEGIN
--	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
--	SELECT 'vJCPotentialWork','Co: ' + convert(char(3), i.JCCo) + ' Potential Project: ' + i.PotentialProject,
--			i.JCCo, 'C', 'OwnerContact',  d.OwnerContact, i.OwnerContact, getdate(), SUSER_SNAME()
--	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.PotentialProject=i.PotentialProject
--	----JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
--	WHERE isnull(d.OwnerContact,'') <> isnull(i.OwnerContact,'')
--	END
--IF UPDATE(OwnerPhone)
--	BEGIN
--	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
--	SELECT 'vJCPotentialWork','Co: ' + convert(char(3), i.JCCo) + ' Potential Project: ' + i.PotentialProject,
--			i.JCCo, 'C', 'OwnerPhone',  d.OwnerPhone, i.OwnerPhone, getdate(), SUSER_SNAME()
--	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.PotentialProject=i.PotentialProject
--	----JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
--	WHERE isnull(d.OwnerPhone,'') <> isnull(i.OwnerPhone,'')
--	END
IF UPDATE(AllowForecast)
	BEGIN
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'vJCPotentialWork','Co: ' + convert(char(3), i.JCCo) + ' Potential Project: ' + i.PotentialProject,
			i.JCCo, 'C', 'AllowForecast',  d.AllowForecast, i.AllowForecast, getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.PotentialProject=i.PotentialProject
	----JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.AllowForecast,'') <> isnull(i.AllowForecast,'')
	END
IF UPDATE(Awarded)
	BEGIN
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'vJCPotentialWork','Co: ' + convert(char(3), i.JCCo) + ' Potential Project: ' + i.PotentialProject,
			i.JCCo, 'C', 'Awarded',  d.Awarded, i.Awarded, getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.PotentialProject=i.PotentialProject
	----JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.Awarded,'') <> isnull(i.Awarded,'')
	END
IF UPDATE(Contract)
	BEGIN
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'vJCPotentialWork','Co: ' + convert(char(3), i.JCCo) + ' Potential Project: ' + i.PotentialProject,
			i.JCCo, 'C', 'Contract',  d.Contract, i.Contract, getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.PotentialProject=i.PotentialProject
	----JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.Contract,'') <> isnull(i.Contract,'')
	END
IF UPDATE(ProjectedChase)
	BEGIN
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'vJCPotentialWork','Co: ' + convert(char(3), i.JCCo) + ' Potential Project: ' + i.PotentialProject,
			i.JCCo, 'C', 'ProjectedChase',  convert(varchar(20),d.ProjectedChase), convert(varchar(20),i.ProjectedChase), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.PotentialProject=i.PotentialProject
	----JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.ProjectedChase,'') <> isnull(i.ProjectedChase,'')
	END
IF UPDATE(RevenueEst)
	BEGIN
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'vJCPotentialWork','Co: ' + convert(char(3), i.JCCo) + ' Potential Project: ' + i.PotentialProject,
			i.JCCo, 'C', 'RevenueEst',  convert(varchar(20),d.RevenueEst), convert(varchar(20),i.RevenueEst), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.PotentialProject=i.PotentialProject
	----JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.RevenueEst,'') <> isnull(i.RevenueEst,'')
	END
IF UPDATE(CostEst)
	BEGIN
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'vJCPotentialWork','Co: ' + convert(char(3), i.JCCo) + ' Potential Project: ' + i.PotentialProject,
			i.JCCo, 'C', 'CostEst',  convert(varchar(20),d.CostEst), convert(varchar(20),i.CostEst), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.PotentialProject=i.PotentialProject
	----JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.CostEst,'') <> isnull(i.CostEst,'')
	END
IF UPDATE(ProfitEst)
	BEGIN
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'vJCPotentialWork','Co: ' + convert(char(3), i.JCCo) + ' Potential Project: ' + i.PotentialProject,
			i.JCCo, 'C', 'ProfitEst',  convert(varchar(20),d.ProfitEst), convert(varchar(20),i.ProfitEst), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.PotentialProject=i.PotentialProject
	----JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.ProfitEst,'') <> isnull(i.ProfitEst,'')
	END
IF UPDATE(StartDate)
	BEGIN
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'vJCPotentialWork','Co: ' + convert(char(3), i.JCCo) + ' Potential Project: ' + i.PotentialProject,
			i.JCCo, 'C', 'StartDate',  convert(varchar(30),d.StartDate), convert(varchar(30),i.StartDate), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.PotentialProject=i.PotentialProject
	----JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.StartDate,'') <> isnull(i.StartDate,'')
	END
IF UPDATE(CompletionDate)
	BEGIN
	INSERT INTO bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'vJCPotentialWork','Co: ' + convert(char(3), i.JCCo) + ' Potential Project: ' + i.PotentialProject,
			i.JCCo, 'C', 'CompletionDate',  convert(varchar(30),d.CompletionDate), convert(varchar(30),i.CompletionDate), getdate(), SUSER_SNAME()
	FROM inserted i JOIN deleted d  ON d.JCCo=i.JCCo  AND d.PotentialProject=i.PotentialProject
	----JOIN  bJCCO with (nolock) ON i.JCCo=bJCCO.JCCo and bJCCO.AuditContracts='Y'
	WHERE isnull(d.CompletionDate,'') <> isnull(i.CompletionDate,'')
	END




return

error:
	select @errmsg = @errmsg + ' - cannot update PC Potential Work!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction


GO
ALTER TABLE [dbo].[vPCPotentialWork] WITH NOCHECK ADD CONSTRAINT [CK_vPCPotentialWork_AllowForecast] CHECK (([AllowForecast]='Y' OR [AllowForecast]='N'))
GO
ALTER TABLE [dbo].[vPCPotentialWork] WITH NOCHECK ADD CONSTRAINT [CK_vPCPotentialWork_Awarded] CHECK (([Awarded]='Y' OR [Awarded]='N'))
GO
ALTER TABLE [dbo].[vPCPotentialWork] ADD CONSTRAINT [PK_vPCPotentialWork] PRIMARY KEY CLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_vPCPotentialWork_Project] ON [dbo].[vPCPotentialWork] ([JCCo], [PotentialProject]) ON [PRIMARY]
GO
