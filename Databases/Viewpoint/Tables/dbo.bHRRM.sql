CREATE TABLE [dbo].[bHRRM]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NOT NULL,
[PRCo] [dbo].[bCompany] NULL,
[PREmp] [dbo].[bEmployee] NULL,
[LastName] [varchar] (30) COLLATE Latin1_General_BIN NOT NULL,
[FirstName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[MiddleName] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[SortName] [varchar] (15) COLLATE Latin1_General_BIN NOT NULL,
[Address] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[City] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[State] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[Zip] [dbo].[bZip] NULL,
[Address2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Phone] [dbo].[bPhone] NULL,
[WorkPhone] [dbo].[bPhone] NULL,
[Pager] [dbo].[bPhone] NULL,
[CellPhone] [dbo].[bPhone] NULL,
[SSN] [char] (11) COLLATE Latin1_General_BIN NULL,
[Sex] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Race] [char] (2) COLLATE Latin1_General_BIN NULL,
[BirthDate] [smalldatetime] NULL,
[HireDate] [dbo].[bDate] NULL,
[TermDate] [dbo].[bDate] NULL,
[TermReason] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[ActiveYN] [dbo].[bYN] NOT NULL,
[Status] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[PRGroup] [dbo].[bGroup] NULL,
[PRDept] [dbo].[bDept] NULL,
[StdCraft] [dbo].[bCraft] NULL,
[StdClass] [dbo].[bClass] NULL,
[StdInsCode] [dbo].[bInsCode] NULL,
[StdTaxState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[StdUnempState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[StdInsState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[StdLocal] [dbo].[bLocalCode] NULL,
[W4CompleteYN] [dbo].[bYN] NOT NULL,
[PositionCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[NoRehireYN] [dbo].[bYN] NOT NULL,
[MaritalStatus] [char] (1) COLLATE Latin1_General_BIN NULL,
[MaidenName] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[SpouseName] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[PassPort] [dbo].[bYN] NOT NULL,
[RelativesYN] [dbo].[bYN] NOT NULL,
[HandicapYN] [dbo].[bYN] NOT NULL,
[HandicapDesc] [dbo].[bDesc] NULL,
[VetJobCategory] [varchar] (2) COLLATE Latin1_General_BIN NULL,
[PhysicalYN] [dbo].[bYN] NOT NULL,
[PhysDate] [dbo].[bDate] NULL,
[PhysExpireDate] [dbo].[bDate] NULL,
[PhysResults] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[LicNumber] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[LicType] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[LicState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[LicExpDate] [dbo].[bDate] NULL,
[DriveCoVehiclesYN] [dbo].[bYN] NOT NULL,
[I9Status] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[I9Citizen] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[I9ReviewDate] [dbo].[bDate] NULL,
[TrainingBudget] [dbo].[bDollar] NULL,
[CafeteriaPlanBudget] [dbo].[bDollar] NULL,
[HighSchool] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[HSGradDate] [dbo].[bDate] NULL,
[College1] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[College1BegDate] [dbo].[bDate] NULL,
[College1EndDate] [dbo].[bDate] NULL,
[College1Degree] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[College2] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[College2BegDate] [dbo].[bDate] NULL,
[College2EndDate] [dbo].[bDate] NULL,
[College2Degree] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[ApplicationDate] [dbo].[bDate] NULL,
[AvailableDate] [dbo].[bDate] NULL,
[LastContactDate] [dbo].[bDate] NULL,
[ContactPhone] [dbo].[bPhone] NULL,
[AltContactPhone] [dbo].[bPhone] NULL,
[ExpectedSalary] [dbo].[bDollar] NULL,
[Source] [dbo].[bDesc] NULL,
[SourceCost] [dbo].[bDollar] NULL,
[CurrentEmployer] [dbo].[bDesc] NULL,
[CurrentTime] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[PrevEmployer] [dbo].[bDesc] NULL,
[PrevTime] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[NoContactEmplYN] [dbo].[bYN] NOT NULL,
[HistSeq] [int] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[ExistsInPR] [dbo].[bYN] NOT NULL,
[EarnCode] [dbo].[bEDLCode] NULL,
[PhotoName] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[TempWorker] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHRRM_TempWorker] DEFAULT ('N'),
[Email] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Suffix] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[DisabledVetYN] [dbo].[bYN] NULL CONSTRAINT [DF_bHRRM_DisabledVetYN] DEFAULT ('N'),
[VietnamVetYN] [dbo].[bYN] NULL CONSTRAINT [DF_bHRRM_VietnamVetYN] DEFAULT ('N'),
[OtherVetYN] [dbo].[bYN] NULL CONSTRAINT [DF_bHRRM_OtherVetYN] DEFAULT ('N'),
[VetDischargeDate] [dbo].[bDate] NULL,
[OccupCat] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CatStatus] [char] (1) COLLATE Latin1_General_BIN NULL,
[LicClass] [char] (1) COLLATE Latin1_General_BIN NULL,
[DOLHireState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[NonResAlienYN] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bHRRM_NonResAlienYN] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[Country] [char] (2) COLLATE Latin1_General_BIN NULL,
[LicCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[OTOpt] [char] (1) COLLATE Latin1_General_BIN NULL,
[OTSched] [tinyint] NULL,
[Shift] [tinyint] NULL,
[PTOAppvrGrp] [dbo].[bGroup] NULL,
[HDAmt] [dbo].[bDollar] NULL,
[F1Amt] [dbo].[bDollar] NULL,
[LCFStock] [dbo].[bDollar] NULL,
[LCPStock] [dbo].[bDollar] NULL,
[AFServiceMedalVetYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHRRM_AFServiceMedalVetYN] DEFAULT ('N'),
[WOTaxState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[WOLocalCode] [dbo].[bLocalCode] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
CREATE UNIQUE CLUSTERED INDEX [biHRRM] ON [dbo].[bHRRM] ([HRCo], [HRRef]) WITH (FILLFACTOR=90) ON [PRIMARY]

CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRRM] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btHRRMd] on [dbo].[bHRRM] for DELETE as
/*--------------------------------------------------------------
* Created: ae 05/14/99
* Modified: ae 04/03/00  -added audits.
*			DANF 04/05/01 - Added the ability to delete security entries in DDDU, DDDS if PREMPL does not exists.
*           DANF 04/11/02 - Added bHRRef Data type delete.
*			MarkH 1/27/05 - Issue 26521.  Delete any entries in HRHP
*			GG 04/20/07 - #30116 - data security review
*
*  Delete trigger for HR Resource Master
*
* Audits HR Reference # deletions in HQ Master Audit
*--------------------------------------------------------------*/
declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
    @errno tinyint, @audit bYN, @validcnt int, @validcnt2 int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

/* Check bHRWI for detail */
if exists(select top 1 1 from deleted d JOIN dbo.bHRWI o (nolock)  ON d.HRCo = o.HRCo  and d.HRRef = o.HRRef)
   begin
   select @errmsg = 'Entries exist in bHRWI.  Remove using Resource Master.'
   goto error
   end
/* Check bHREC for detail */
if exists(select top 1 1 from deleted d JOIN dbo.bHREC o (nolock) ON d.HRCo = o.HRCo  and d.HRRef = o.HRRef)
   begin
   select @errmsg = 'Entries exist in bHREC.  Remove using Resource Contacts.'
   goto error
   end
/* Check bHRDP for detail */
if exists(select * from deleted d JOIN bHRDP o ON d.HRCo = o.HRCo  and d.HRRef = o.HRRef)
   begin
   select @errmsg = 'Entries exist in bHRDP.  Remove using Resource Dependents.'
   goto error
   end
/* Check bHREB for detail */
if exists(select top 1 1 from deleted d JOIN dbo.bHREB o (nolock) ON d.HRCo = o.HRCo  and d.HRRef = o.HRRef)
   begin
   select @errmsg = 'Entries exist in bHREB.  Remove using Resource Benefits.'
   goto error
   end
/* Check bHREH for detail */
if exists(select top 1 1 from deleted d JOIN dbo.bHREH o (nolock) ON d.HRCo = o.HRCo  and d.HRRef = o.HRRef)
   begin
   select @errmsg = 'Entries exist in bHREH.  Remove using Employment History.'
   goto error
   end
/* Check bHRSP for detail */
if exists(select top 1 1 from deleted d JOIN dbo.bHRSP o (nolock) ON d.HRCo = o.HRCo  and d.HRRef = o.HRRef)
   begin
   select @errmsg = 'Entries exist in bHRSP.  Remove using Resource Salary.'
   goto error
   end
/* Check bHRSH for detail */
if exists(select top 1 1 from deleted d JOIN dbo.bHRSH o (nolock) ON d.HRCo = o.HRCo  and d.HRRef = o.HRRef)
	begin
	select @errmsg = 'Entries exist in bHRSH. Remove using Resource Salary.'
	goto error
	end
/* Check bHRER for detail */
if exists(select top 1 1 from deleted d JOIN dbo.bHRER o (nolock) ON d.HRCo = o.HRCo  and d.HRRef = o.HRRef)
   begin
   select @errmsg = 'Entries exist in bHRER.  Remove using Resource Review.'
   goto error
   end
/* Check bHRES for detail */
if exists(select top 1 1 from deleted d JOIN dbo.bHRES o (nolock) ON d.HRCo = o.HRCo  and d.HRRef = o.HRRef)
   begin
   select @errmsg = 'Entries exist in bHRES.  Remove using Resource Schedule.'
   goto error
   end
/* Check bHRET for detail */
if exists(select top 1 1 from deleted d JOIN dbo.bHRET o (nolock) ON d.HRCo = o.HRCo  and d.HRRef = o.HRRef)
   begin
   select @errmsg = 'Entries exist in bHRET.  Remove using Resource Training.'
   goto error
   end
/* Check bHRRS for detail */
if exists(select top 1 1 from deleted d JOIN dbo.bHRRS o (nolock) ON d.HRCo = o.HRCo  and d.HRRef = o.HRRef)
   begin
   select @errmsg = 'Entries exist in bHRRS.  Remove using Resource Skills.'
   goto error
   end
/* Check bHRRD for detail */
if exists(select top 1 1 from deleted d JOIN dbo.bHRRD o (nolock) ON d.HRCo = o.HRCo  and d.HRRef = o.HRRef)
   begin
   select @errmsg = 'Entries exist in bHRRD.  Remove using Resource Rewards.'
   goto error
   end
/* Check bHRED for detail */
if exists(select top 1 1 from deleted d JOIN dbo.bHRED o (nolock) ON d.HRCo = o.HRCo  and d.HRRef = o.HRRef)
begin
   select @errmsg = 'Entries exist in bHRED.  Remove using Resource Discipline.'
   goto error
   end
/* Check bHREG for detail */
if exists(select top 1 1 from deleted d JOIN dbo.bHREG o (nolock) ON d.HRCo = o.HRCo  and d.HRRef = o.HRRef)
   begin
   select @errmsg = 'Entries exist in bHREG.  Remove using Resource Grievances.'
   goto error
   end
/* Check bHRBE for detail */
if exists(select top 1 1 from deleted d JOIN dbo.bHRBE o (nolock) ON d.HRCo = o.HRCo  and d.HRRef = o.HRRef)
   begin
   select @errmsg = 'Entries exist in bHRBE.  Remove using Resource Benefits.'
   goto error
   end
/* Check bHRRC for detail */
if exists(select top 1 1 from deleted d JOIN dbo.bHRRC o (nolock) ON d.HRCo = o.HRCo  and d.HRRef = o.HRRef)
   begin
   select @errmsg = 'Entries exist in bHRRC.  Remove using Resource COBRA.'
   goto error
   end
/* Check bHRBL for detail */
if exists(select top 1 1 from deleted d JOIN dbo.bHRBL o (nolock) ON d.HRCo = o.HRCo  and d.HRRef = o.HRRef)
   begin
   select @errmsg = 'Entries exist in bHRBL.  Remove using Resource Benefits.'
   goto error
   end
/* Check bHRRP for detail */
if exists(select top 1 1 from deleted d JOIN dbo.bHRRP o (nolock) ON d.HRCo = o.HRCo  and d.HRRef = o.HRRef)
   begin
   select @errmsg = 'Entries exist in bHRRP.  Remove using Resource Review.'
   goto error
   end
/* Check bHRAR for detail */
if exists(select top 1 1 from deleted d JOIN dbo.bHRAR o (nolock) ON d.HRCo = o.HRCo  and d.HRRef = o.HRRef)
   begin
   select @errmsg = 'Entries exist in bHRAR.  Remove using Application References.'
   goto error
   end
/* Check bHRAP for detail */
if exists(select top 1 1 from deleted d JOIN dbo.bHRAP o (nolock) ON d.HRCo = o.HRCo  and d.HRRef = o.HRRef)
   begin
   select @errmsg = 'Entries exist in bHRAP.  Remove using Application Positions.'
   goto error
   end
/* Check bHREI for detail */
if exists(select top 1 1 from deleted d JOIN dbo.bHREI o (nolock) ON d.HRCo = o.HRCo  and d.HRRef = o.HRRef)
   begin
   select @errmsg = 'Entries exist in bHREI.  Remove using Resource Interview.'
   goto error
   end
/* Check bHRDT for detail */
if exists(select top 1 1 from deleted d JOIN dbo.bHRDT o (nolock) ON d.HRCo = o.HRCo  and d.HRRef = o.HRRef)
   begin
   select @errmsg = 'Entries exist in bHRDT.  Remove using Drug Testing.'
   goto error
   end
/* Check bHRAI for detail */
if exists(select top 1 1 from deleted d JOIN dbo.bHRAI o (nolock) ON d.HRCo = o.HRCo and d.HRRef = o.HRRef)
    begin
    select @errmsg = 'Involved in an accident and cannot be removed.  Entries exist in bHRAI'
    goto error
    end
/* Check bHRBL for detail */
if exists(select top 1 1 from deleted d JOIN dbo.bHRBL o (nolock) ON d.HRCo = o.HRCo  and d.HRRef = o.HRRef)
   begin
   select @errmsg = 'Entries exist in bHRBL.  Remove using Resource Benefits.'
   goto error
   end

/* Clear HR to PR update status entries - Issue 26521*/
delete dbo.bHRHP
from dbo.bHRHP h
join deleted d on h.HRCo = d.HRCo and h.HRRef = d.HRRef

-- #30116 - leave data security for bHRRef but remove bEmployee if employee doesn't exist in PR
-- remove group level data security 
delete dbo.vDDDS
from dbo.vDDDS s
join deleted d on s.Qualifier = d.PRCo and s.Instance = convert(char(30),d.PREmp)
where s.Datatype = 'bEmployee'
	and not exists(select top 1 1 from dbo.bPREH h (nolock) where d.PRCo = h.PRCo and d.PREmp = h.Employee)

-- remove user level data security for entries added based on bPRGS
delete dbo.vDDDU
from dbo.vDDDU u
join deleted d on u.Qualifier = d.PRCo and u.Instance = convert(char(30),d.PREmp)
where u.Datatype = 'bEmployee'
   and not exists (select top 1 1 from dbo.bPREH h (nolock) where d.PRCo = h.PRCo and d.PREmp = h.Employee)


-- Add Master Audit   
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bHRRM', 'HRCo: ' + convert(char(3),d.HRCo) + ' HRRef: ' + convert(varchar(6),d.HRRef),
	d.HRCo, 'D', '', null, null, getdate(), SUSER_SNAME()
from deleted d join dbo.bHRCO e on e.HRCo = d.HRCo
where e.AuditResourceYN = 'Y'
   
return
   
error:
   select @errmsg = @errmsg + ' - cannot delete from HRRM'
   RAISERROR(@errmsg, 11, -1);
   rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btHRRMi] on [dbo].[bHRRM] for INSERT as


/*-----------------------------------------------------------------
* Created: ae  3/31/00
* Modified: mh 7/20/00 Need to update bHREH if HRST.UpdateHistYN flag is set to yes.
*			RM 09/21/01 Changed DDDU Entries to use PREmp rather than HRRef
*			mh 11/26/01 Insert entry into bHRDP with seq 0 per issue 14855
*          DANF 04/11/02 Added HR Reference Data type Security.
*			MH 1/8/03 Issue 19136 Include PositionChangedYN in insert to bHREH
*			MH 1/21/03 19540 - Include 'Type' in bHREH insert, remove PositionChangedYN.
*			MH 8/5/03 21948
*			DANF 03/19/04 - 20980 Expanded Security Group
*			mh 2/7/07 -123806 - Switch DDDT to DDDTShared.  @secure from tinyint to bYN
*			GG 04/20/07 - #30116 - data security review
*			Dan Sochacki 03/04/2008 - #123780 - Validate PTO Approval Group
*								****** Due to localization, the word "PTO" has been changed to "Leave" anywhere it would be displayed to the User.
*			mh 6/4/2008 - 127577.  Copied cross update code from update trigger to insert trigger.
*					modified default security to accomidate no PR Group.  See comments below.
*			mh 7/21/2008 - 129060.  Corrected validation against HRAG.  Need to account for null values.
*			mh 8/6/2008 - 129198 - Added cross updates and audit for HDAmt, F1Amt, LCFStock, LCPStock
*			TJL 03/08/10 - #135490, Add new fields for Work Office Tax State and Work Office Local Code
*			MV	04/11/11 - Backlog Item# B-04112 - Add cellphone to HR/PR cross update.
*
*	Insert trigger on HR Resource Master
*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @count int, @validcnt int, @validcnt2 int, @nullcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- check for uniqueness - PR Co# and Employee can only be used once per HR Co#
if exists(select count(*) from dbo.bHRRM h with (nolock)
			join inserted i on h.HRCo = i.HRCo and h.PRCo = i.PRCo and h.PREmp = i.PREmp
			group by h.HRCo, h.PRCo, h.PREmp
			having count(*) > 1)
	begin
	select @errmsg = 'PR Employee # already in use, must be unique within an HR Co#'
	goto error
	end

--Issue #135490, WOTaxState & WOLocalCode
-- validate Work Office Tax State
select @validcnt = count(*) from inserted where WOTaxState is not null
select @validcnt2 = count(*) from inserted i join dbo.bHQCO c with (nolock) on c.HQCo=i.HRCo
	join dbo.bHQST s with (nolock) on c.DefaultCountry=s.Country and s.State=i.WOTaxState
if isnull(@validcnt2,0) <> isnull(@validcnt,0)
	begin
	select @errmsg = 'Invalid Work Office Tax State'
	goto error
	end
-- validate Work Office Local Code 
select @nullcnt = count(*) from inserted i where i.WOLocalCode is null
select @validcnt = count(*) from dbo.bPRLI c (nolock) join inserted i on c.PRCo = i.PRCo and c.LocalCode = i.WOLocalCode
if isnull(@nullcnt,0) + isnull(@validcnt,0) <> isnull(@numrows,0)
	begin
	select @errmsg = 'Invalid Work Office Local Code'
	goto error
	end
	
--begin issue 129060
-- VALIDATE PTO/LEAVE APPROVAL GROUP - #123780
--IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.bHRAG h left JOIN inserted i ON h.HRCo = i.HRCo
--               WHERE h.PTOAppvrGrp = i.PTOAppvrGrp OR i.PTOAppvrGrp IS NULL)
--		BEGIN
--		   SELECT @errmsg = 'Leave Approval Group NOT valid '
--		   GOTO error
--		END

declare @numPTOAppGrpRows int, @numNoPTOAppGrpRows int
select @numPTOAppGrpRows = count(1) from inserted i join bHRAG h on i.HRCo = h.HRCo and i.PTOAppvrGrp = h.PTOAppvrGrp
select @numNoPTOAppGrpRows = count(1) from inserted i where PTOAppvrGrp is null

if @numPTOAppGrpRows + @numNoPTOAppGrpRows <> @numrows
begin
	select @errmsg = 'Leave Approval Group NOT valid '
	goto error
end
--end issue 129060

-- prepare to add HR Reference History entries 
declare @datechanged bDate
set @datechanged = convert(varchar(11), getdate())

-- add History entries for Status
insert dbo.bHREH (HRCo, HRRef, DateChanged, Seq, Code, Type)
select i.HRCo, i.HRRef, convert(varchar(11), getdate()),
	isnull(max(h.Seq),0) + row_number() over(partition by h.HRCo, h.HRRef order by i.HRCo, i.HRRef),
	t.HistoryCode,'H'
from inserted i
left join dbo.bHREH h on h.HRCo = i.HRCo and i.HRRef = h.HRRef
join dbo.bHRST t (nolock) on t.HRCo = i.HRCo and t.StatusCode = i.Status and t.UpdateHistYN = 'Y'
group by i.HRCo, i.HRRef, t.HistoryCode, h.HRCo, h.HRRef

-- add History entries for Position
insert dbo.bHREH(HRCo, HRRef, DateChanged, Seq, Code, Type)
select i.HRCo, i.HRRef, convert(varchar(11), getdate()),
	isnull(max(h.Seq),0) + row_number() over(partition by h.HRCo, h.HRRef order by i.HRCo, i.HRRef),
	i.PositionCode, 'P'
from inserted i
left join dbo.bHREH h on h.HRCo = i.HRCo and i.HRRef = h.HRRef
where i.PositionCode is not null 
group by i.HRCo, i.HRRef, i.PositionCode, h.HRCo, h.HRRef

   
/* Setup default security group to have access if securing bHRRef */
declare @dfltsecgroup smallint
select @dfltsecgroup = DfltSecurityGroup
from dbo.DDDTSecurable (nolock) where Datatype = 'bHRRef' and Secure = 'Y'
if @dfltsecgroup is not null
	begin
	-- add security entries for default security group
	insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
	select 'bHRRef', i.HRCo, i.HRRef, @dfltsecgroup
	from inserted i 
	where not exists(select 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bHRRef' and s.Qualifier = i.HRCo 
						and s.Instance = i.HRRef and s.SecurityGroup = @dfltsecgroup)
	end

-- handle data security for Employee#s so users can view HRRM records 
select @dfltsecgroup = null
select @dfltsecgroup = DfltSecurityGroup
from dbo.DDDTShared (nolock) where Datatype = 'bEmployee' and Secure = 'Y'
if @@rowcount > 0
	begin 	-- check if Employee security applied to HR Resource Master table
	if exists(select top 1 1 from dbo.DDSLShared (nolock) where TableName = 'bHRRM' and Datatype = 'bEmployee' and InUse = 'Y')
		begin
--Issue 127577 - excluding i.PRGroup is not null.  If it is null we want to add a default security group record.
		-- if new Employee doesn't exist in PR add security entries 
 		if exists(select top 1 1 from inserted i left join dbo.bPREH e (nolock) on i.PRCo = e.PRCo and i.PREmp = e.Employee
 					where i.PRCo is not null and i.PREmp is not null --and i.PRGroup is not null 
 					and e.Employee is null)	-- Employee not in bPREH
 			begin
 			-- add security entries for users assigned to the PRGroup
  			insert dbo.vDDDU (Datatype, Qualifier, Instance, VPUserName)
  			select 'bEmployee', i.PRCo, convert(char(30),i.PREmp), s.VPUserName
  			from inserted i
  			join dbo.bPRGS s (nolock) on i.PRCo = s.PRCo and i.PRGroup = s.PRGroup
 				and not exists (select 1 from dbo.vDDDU u (nolock)
 						where u.Qualifier = i.PRCo and u.Instance = convert(char(30),i.PREmp)
 						and u.Datatype = 'bEmployee' and u.VPUserName = s.VPUserName)
 			left join dbo.bPREH e (nolock) on i.PRCo = e.PRCo and i.PREmp = e.Employee
 			where i.PRCo is not null and i.PREmp is not null and i.PRGroup is not null 
 				and e.Employee is null	-- Employee not in bPREH
 		
			if @dfltsecgroup is not null
				begin
				-- add security entries for default security group
				insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
				select 'bEmployee', i.PRCo, convert(char(30),i.PREmp), @dfltsecgroup
				from inserted i 
				where i.PRCo is not null and i.PREmp is not null 
					and not exists(select top 1 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bEmployee' and s.Qualifier = i.PRCo 
									and s.Instance = convert(char(30),i.PREmp) and s.SecurityGroup = @dfltsecgroup)
				end
			end
		end
	end

/** HR to PR Cross Updates **/

if (update(LastName) or update(FirstName) or update(MiddleName) or update(SortName)
	or update(BirthDate) or update(Race) or update(Sex) or update(Suffix))
	begin
	update dbo.bPREH
	set LastName = i.LastName, FirstName = i.FirstName, MidName = i.MiddleName, 
		Suffix=i.Suffix, SortName = i.SortName, BirthDate = i.BirthDate, 
		Race = i.Race, Sex = i.Sex
	from inserted i
	join dbo.bPREH p (nolock) on i.PRCo = p.PRCo and i.PREmp = p.Employee
	join dbo.bHRCO o (nolock) on i.HRCo = o.HRCo and o.UpdateNameYN = 'Y'
	where p.LastName <> i.LastName or isnull(p.FirstName,'') <> isnull(i.FirstName,'') 
		or isnull(p.MidName,'') <> isnull(i.MiddleName,'') or isnull(p.Suffix,'') <> isnull(i.Suffix,'')
		or isnull(p.SortName,'') <> isnull(i.SortName,'') or isnull(p.BirthDate,'') <> isnull(i.BirthDate,'')
		or p.Race <> i.Race or p.Sex <> i.Sex
	end

--Update Address
if (update([Address]) or update(City) or update([State]) or update(Zip) or update(Phone)
	or update(Email) or update(Address2) or update(Country) or update (CellPhone))
	begin
	update dbo.bPREH
	set Address = i.Address, City = i.City, State = i.State, Zip = i.Zip,
		Address2 = i.Address2, Phone = i.Phone, Email = i.Email, Country = i.Country,
		CellPhone = i.CellPhone
	from inserted i
	join dbo.bPREH p (nolock) on i.PRCo = p.PRCo and i.PREmp = p.Employee
	join dbo.bHRCO o (nolock) on i.HRCo = o.HRCo and o.UpdateAddressYN = 'Y'
	where isnull(p.Address,'') <> isnull(i.Address,'') or isnull(p.City,'') <> isnull(i.City,'') 
		or isnull(p.State,'') <> isnull(i.State,'') or isnull(p.Zip, '') <> isnull(i.Zip,'')
		or isnull(p.Address2, '') <> isnull(i.Address2, '') or isnull(p.Phone,'') <> isnull(i.Phone,'')
		or isnull(p.Email,'') <> isnull(i.Email,'') or isnull(p.Country, '') <> isnull(i.Country, '')
		or isnull(p.CellPhone,'') <> isnull(i.CellPhone,'')
	end
--Update Hire Date
if update(HireDate)
	begin
	update dbo.bPREH
	set HireDate = i.HireDate 
	from inserted i
	join dbo.bPREH p (nolock) on i.PRCo = p.PRCo and i.PREmp = p.Employee
	join dbo.bHRCO o (nolock) on i.HRCo = o.HRCo and o.UpdateHireDateYN = 'Y'
	where isnull(p.HireDate,'1/1/00') <> isnull(i.HireDate,'1/1/00') 
	end

--Update Term Date
if update(TermDate)
	begin
	update dbo.bPREH
	set TermDate = i.TermDate
	from inserted i
	join dbo.bPREH p (nolock) on i.PRCo = p.PRCo and i.PREmp = p.Employee
	join dbo.bHRCO o (nolock) on i.HRCo = o.HRCo and o.UpdateHireDateYN = 'Y'
	where isnull(p.TermDate,'1/1/00') <> isnull(i.TermDate,'1/1/00')
	end

--Update Active Flag
if (update(ActiveYN))
	begin
	update dbo.bPREH
	set ActiveYN = i.ActiveYN
	from inserted i
	join dbo.bPREH p (nolock) on i.PRCo = p.PRCo and i.PREmp = p.Employee
	join dbo.bHRCO o (nolock) on i.HRCo = o.HRCo and o.UpdateActiveYN = 'Y'
	where p.ActiveYN <> i.ActiveYN
	end

--Update Timecard Defaults
--Issue #135490, Added WOTaxState & WOLocalCode
if (update(PRDept) or update(StdCraft) or update(StdClass) or update(StdInsCode)
	or update(StdTaxState) or update(StdUnempState) or update(StdInsState)
	or update(StdLocal) or update(EarnCode) or update(Shift) or update(HDAmt)
	or update(F1Amt) or update(LCFStock) or update(LCPStock) 
	or update(WOTaxState) or update(WOLocalCode))
	begin
	update dbo.bPREH
	set PRDept = i.PRDept, Craft = i.StdCraft, Class = i.StdClass, InsCode = i.StdInsCode,
		TaxState = i.StdTaxState, UnempState = i.StdUnempState, InsState = i.StdInsState, 
		LocalCode = i.StdLocal, EarnCode = i.EarnCode, Shift = i.Shift,
		WOTaxState = i.WOTaxState, WOLocalCode = i.WOLocalCode
	from inserted i
	join dbo.bPREH p (nolock) on i.PRCo = p.PRCo and i.PREmp = p.Employee
	join dbo.bHRCO o (nolock) on i.HRCo = o.HRCo and o.UpdateTimecardYN = 'Y'
	where p.PRDept <> isnull(i.PRDept, '') or isnull(p.Craft, '') <> isnull(i.StdCraft,'') or
		isnull(p.Class, '') <> isnull(i.StdClass,'') or isnull(p.InsCode,'') <> isnull(i.StdInsCode, '') or
		isnull(p.TaxState, '') <> isnull(i.StdTaxState, '') or isnull(p.UnempState,'') <> isnull(i.StdUnempState, '') or
		isnull(p.InsState,'') <> isnull(i.StdInsState,'') or isnull(p.LocalCode, '') <> isnull(i.StdLocal, '') or
		isnull(p.EarnCode,'') <> isnull(i.EarnCode, '') or isnull(p.Shift,'') <> isnull(i.Shift, '') or
		isnull(p.HDAmt, -999) <> isnull(i.HDAmt, -999) or isnull(p.F1Amt, -999) <> isnull(i.F1Amt, -999) or
		isnull(p.LCFStock, -999) <> isnull(i.LCFStock, -999) or isnull(p.LCPStock, -999) <> isnull(i.LCPStock, -999) or
		isnull(p.WOTaxState, '') <> isnull(i.WOTaxState, '') or isnull(p.WOLocalCode, '') <> isnull(i.WOLocalCode, '')
	end

--Update W4 Info (Not HRWI - that is handled in its triggers)
if (update(NonResAlienYN))
	begin
	update dbo.bPREH
	set NonResAlienYN = i.NonResAlienYN
	from inserted i
	join dbo.bPREH p (nolock) on i.PRCo = p.PRCo and i.PREmp = p.Employee
	join dbo.bHRCO o (nolock) on i.HRCo = o.HRCo and o.UpdateW4YN = 'Y'
	where p.NonResAlienYN <> i.NonResAlienYN
	end
--Update Occup Cat
if (update(OccupCat) or update(CatStatus) or update(OTOpt) or update(OTSched))
	begin
	update dbo.bPREH
	set OccupCat = i.OccupCat, CatStatus = i.CatStatus, OTOpt = i.OTOpt, OTSched = i.OTSched
	from inserted i
	join dbo.bPREH p (nolock) on i.PRCo = p.PRCo and i.PREmp = p.Employee
	join dbo.bHRCO o (nolock) on i.HRCo = o.HRCo and o.UpdateOccupCatYN = 'Y'
	where isnull(p.OccupCat,'') <> isnull(i.OccupCat, '') or isnull(p.CatStatus, '') <> isnull(i.CatStatus, '') or
	isnull(p.OTOpt, '') <> isnull(i.OTOpt, '') or isnull(p.OTSched, '') <> isnull(i.OTSched, '')
	end

--Update SSN
if (update(SSN))
	begin
	update dbo.bPREH
	set SSN = i.SSN
	from inserted i
	join dbo.bPREH p (nolock) on i.PRCo = p.PRCo and i.PREmp = p.Employee
	join dbo.bHRCO o (nolock) on i.HRCo = o.HRCo and o.UpdateSSNYN = 'Y'
	where p.SSN <> isnull(i.SSN,'')
	end

--End Cross Updates
   
-- Master Audit
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bHRRM', 'HRCo: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
   	i.HRCo, 'A', '', null, null, getdate(), SUSER_SNAME()
from inserted i
join dbo.bHRCO e (nolock) on e.HRCo = i.HRCo
where e.AuditResourceYN = 'Y'
   
return
   
error:
   	select @errmsg = @errmsg + ' - cannot insert HR Resource Master!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  trigger [dbo].[btHRRMu] on [dbo].[bHRRM] for UPDATE as
/*-----------------------------------------------------------------
* Created: ae 4/3/00
* Modified: mh 7/20/00 Need to update bHREH if HRST.UpdateHistYN flag is set to yes.
*         	mh 8/3/00  Insure PREmployee number is not duplicated in HRRM
*           kb 8/15/00 -  issue #10229
*           RM 05/30/01 - update DDDU when update prgroup, only delete if employee does not exist in bPREH for that group.
*	        gh 7/2/01 - Change PREmp validation to Update(PREmp) Issue #13885
*			RM 09/21/01 - Changed update to DDDU to use PREmp instead of HRRef
*			GG 11/07/01 - #15198 - Removed TermDate update when HireDate changed
*			SR 07/11/02 - #17850 add an employment history record for Termimation
*			MH 09/26/02 17850 cont...see notes below
*			MH 1/8/03 19136 - Update bHREH.Position code.
*			MH 1/21/03 19540 - Include 'Type' in bHREH insert, remove PositionChangedYN
*			mh 5/07/03 19538 - Security issue
*			MH 8/5/03 21948
*			mh 11/16/03 18913
*			mh 3/17/04 23061
*			mh 4/18/04 22628
*			mh 4/29/05 - Issue 28581.  Corrected varchar conversion of HRRef/PREmp from varchar(5) to varchar(6).
*			GG 10/20/05 - #28967 - rewritten to improve data security updates and validation
*			mh 2/7/07 - 123806 - Switch DDDT to DDDTShared.  Secure changed from tinyint to bYN datatype.
*			GG 04/20/07 - #30116 - data security review, leave data security entries in vDDDS
*			mh 6/8/07 - #122823 - Allow Lic Class Code 'D'
*			mh 9/26/07 - #29630 - Adding cross update for OTSched, OTOpt, Shift.
*			MH 02/22/2008 - Issue 29630 cross update Shift was not working
*			Dan Sochacki 03/04/2008 - #123780 - Validate PTO Approval Group
*								****** Due to localization, the word "PTO" has been changed to "Leave" anywhere it would be displayed to the User.
*			mh 3/11/2008 - #127081 - Added country cross update and audit code.
*			mh 7/21/2008 - 129060.  Corrected validation against HRAG.  Need to account for null values.
*			mh 8/6/2008 - 129198 - Added cross updates and audit for HDAmt, F1Amt, LCFStock, LCPStock
*			mh 03/02/2009 - 129493 - Added audit entries for AFServiceMedalVetYN.
*			TJL 03/08/10 - #135490, Add new fields for Work Office Local Code 
*			MV	04/11/11 - Backlog Item# B-04112 - Add cellphone to HR/PR cross update.
*	Update trigger on HR Resource Master
*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int, @nullcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- check for key changes 
if update(HRCo)
	begin
	select @validcnt = count(*) from deleted d join inserted i on d.HRCo = i.HRCo
	if @validcnt <> @numrows
		begin
		select @errmsg = 'Cannot change HR Company'
		goto error
		end
	end
if update(HRRef)
	begin
	select @validcnt = count(*) from deleted d join inserted i on d.HRCo = i.HRCo and d.HRRef = i.HRRef
	if @validcnt <> @numrows
		begin
		select @errmsg = 'Cannot change Resource #'
		goto error
		end
	end
-- validate License Class
--#122823
if update(LicClass)
	begin
	if exists (select top 1 1 from inserted where isnull(LicClass,'') not in ('A', 'B', 'C', 'D',''))
		begin
		select @errmsg = 'License Class must be ''A'', ''B'', ''C'', ''D'', or null.'
		goto error
		end
	end

if update(PRCo) or update(PREmp) 
	begin
	-- check for uniqueness - PR Co# and Employee can only be used once per HR Co#
	if exists (select count(*) from dbo.bHRRM h with (nolock)
				join inserted i on h.HRCo = i.HRCo and h.PRCo = i.PRCo and h.PREmp = i.PREmp
				group by h.HRCo, h.PRCo, h.PREmp
				having count(*) > 1)
		begin
		select @errmsg = 'PR Employee number already in use in HR.'
		goto error
		end
	end

-- Issue #135490, validate Work Office Local Code   
 if update(WOLocalCode)
   	begin
   	select @nullcnt = count(*) from inserted i where i.WOLocalCode is null
	select @validcnt = count(*) from dbo.bPRLI c (nolock)
		join inserted i on c.PRCo = i.PRCo and c.LocalCode = i.WOLocalCode
   	if isnull(@nullcnt,0) + isnull(@validcnt,0) <> isnull(@numrows,0)
   		begin
   		select @errmsg = 'Invalid Work Office Local Code'
   		goto error
   		end
   	end  
   	
--begin issue 129060
-- VALIDATE PTO/LEAVE APPROVAL GROUP - #123780
IF UPDATE(PTOAppvrGrp)
	BEGIN
--		IF NOT EXISTS(SELECT TOP 1 1 FROM dbo.bHRAG h left JOIN inserted i ON h.HRCo = i.HRCo
--					   WHERE h.PTOAppvrGrp = i.PTOAppvrGrp OR i.PTOAppvrGrp IS NULL)
--				BEGIN
--				   SELECT @errmsg = 'Leave Approval Group NOT valid '
--				   GOTO error
--				END
		declare @numPTOAppGrpRows int, @numNoPTOAppGrpRows int
		select @numPTOAppGrpRows = count(1) from inserted i join bHRAG h on i.HRCo = h.HRCo and i.PTOAppvrGrp = h.PTOAppvrGrp
		select @numNoPTOAppGrpRows = count(1) from inserted i where PTOAppvrGrp is null

		if @numPTOAppGrpRows + @numNoPTOAppGrpRows <> @numrows
		begin
			select @errmsg = 'Leave Approval Group NOT valid '
			goto error
		end
	END
--end issue 129060
 
 if update(PRCo) or update(PREmp) or update(PRGroup)
 	begin
   	-- update PRGroup on Employees linked to HR Resource, Employee data security handled in bPREH update trigger
   	update dbo.bPREH
   	set PRGroup = i.PRGroup
   	from dbo.bPREH p 
   	join inserted i on p.PRCo = i.PRCo and p.Employee = i.PREmp
  	where p.PRGroup <> i.PRGroup	-- update only if PR Groups don't match

	-- handle data security for Employee #s not in PR so users can view HRRM records 
 	-- check if bEmployee is a secure datatype
	declare @dfltsecgroup smallint
	select @dfltsecgroup = DfltSecurityGroup  
 	from dbo.DDDTShared (nolock) where Datatype = 'bEmployee' and Secure = 'Y'
	if @@rowcount > 0
 		begin 	-- check if security applied to HR Resource Master table
 		if exists(select top 1 1 from dbo.DDSLShared (nolock) where TableName = 'bHRRM' and Datatype = 'bEmployee' and InUse = 'Y')
  			begin	
 			-- if old Employee doesn't exist in PR remove security entries 
 			if exists(select top 1 1 from deleted d left join dbo.bPREH e (nolock) on d.PRCo = e.PRCo and d.PREmp = e.Employee
 					where d.PRCo is not null and d.PREmp is not null and d.PRGroup is not null 
 					and e.Employee is null)	-- Employee not in bPREH
 				begin
 				delete dbo.vDDDU 
  				from dbo.vDDDU u
 				join deleted d on u.Qualifier = d.PRCo and u.Instance = convert(char(30), d.PREmp)
 				left join dbo.bPREH e (nolock) on d.PRCo = e.PRCo and d.PREmp = e.Employee
 				where d.PRCo is not null and d.PREmp is not null and d.PRGroup is not null 
 					and e.Employee is null	-- Employee not in bPREH
  					and u.Datatype = 'bEmployee'
 					and u.VPUserName in (select VPUserName from dbo.bPRGS g (nolock)
 								where g.PRCo = d.PRCo and g.PRGroup = d.PRGroup)
				-- remove security entries from default security group
				if @dfltsecgroup is not null
					begin
					delete dbo.vDDDS
					from dbo.vDDDS s
					join deleted d on s.Qualifier = d.PRCo and s.Instance = convert(char(30),d.PREmp)
					left join dbo.bPREH e on e.PRCo = d.PRCo and e.Employee = d.PREmp
					where s.Datatype = 'bEmployee' and d.PRCo is not null and d.PREmp is not null
						and d.PRGroup is not null and e.Employee is null  -- Employee not in bPREH
					end
 				end
 			-- if new Employee doesn't exist in PR add security entries 
 			if exists(select top 1 1 from inserted i left join dbo.bPREH e (nolock) on i.PRCo = e.PRCo and i.PREmp = e.Employee
 					where i.PRCo is not null and i.PREmp is not null and i.PRGroup is not null 
 					and e.Employee is null)	-- Employee not in bPREH
 				begin
 				-- add security entries for users assigned to the PRGroup
  				insert dbo.vDDDU (Datatype, Qualifier, Instance, VPUserName)
  				select 'bEmployee', i.PRCo, convert(char(30),i.PREmp), s.VPUserName
  				from inserted i
  				join dbo.bPRGS s (nolock) on i.PRCo = s.PRCo and i.PRGroup = s.PRGroup
 					and not exists (select 1 from dbo.vDDDU u (nolock)
 						where u.Qualifier = i.PRCo and u.Instance = convert(char(30),i.PREmp)
 							and u.Datatype = 'bEmployee' and u.VPUserName = s.VPUserName)
 				left join dbo.bPREH e (nolock) on i.PRCo = e.PRCo and i.PREmp = e.Employee
 				where i.PRCo is not null and i.PREmp is not null and i.PRGroup is not null 
 					and e.Employee is null	-- Employee not in bPREH
				-- add security entries for default security group
				if @dfltsecgroup is not null
					begin
					insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
					select 'bEmployee', i.PRCo, convert(char(30),i.PREmp), @dfltsecgroup
					from inserted i 
					where i.PRCo is not null and i.PREmp is not null 
						and not exists(select top 1 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bEmployee' and s.Qualifier = i.PRCo 
										and s.Instance = convert(char(30),i.PREmp) and s.SecurityGroup = @dfltsecgroup)
					end
 				end
 			end
 		end
 	end
 
/** HR to PR Cross Updates **/

--Update Name
if (update(LastName) or update(FirstName) or update(MiddleName) or update(SortName)
	or update(BirthDate) or update(Race) or update(Sex) or update(Suffix))
	begin
	update dbo.bPREH
	set LastName = i.LastName, FirstName = i.FirstName, MidName = i.MiddleName, 
		Suffix=i.Suffix, SortName = i.SortName, BirthDate = i.BirthDate, 
		Race = i.Race, Sex = i.Sex
	from inserted i
	join dbo.bPREH p (nolock) on i.PRCo = p.PRCo and i.PREmp = p.Employee
	join dbo.bHRCO o (nolock) on i.HRCo = o.HRCo and o.UpdateNameYN = 'Y'
	where p.LastName <> i.LastName or isnull(p.FirstName,'') <> isnull(i.FirstName,'') 
		or isnull(p.MidName,'') <> isnull(i.MiddleName,'') or isnull(p.Suffix,'') <> isnull(i.Suffix,'')
		or isnull(p.SortName,'') <> isnull(i.SortName,'') or isnull(p.BirthDate,'') <> isnull(i.BirthDate,'')
		or p.Race <> i.Race or p.Sex <> i.Sex
	end

--Update Address
if (update([Address]) or update(City) or update([State]) or update(Zip) or update(Phone)
	or update(Email) or update(Address2) or update(Country) or update (CellPhone))
	begin
	update dbo.bPREH
	set Address = i.Address, City = i.City, State = i.State, Zip = i.Zip,
		Address2 = i.Address2, Phone = i.Phone, Email = i.Email, Country = i.Country,
		CellPhone = i.CellPhone
	from inserted i
	join dbo.bPREH p (nolock) on i.PRCo = p.PRCo and i.PREmp = p.Employee
	join dbo.bHRCO o (nolock) on i.HRCo = o.HRCo and o.UpdateAddressYN = 'Y'
	where isnull(p.Address,'') <> isnull(i.Address,'') or isnull(p.City,'') <> isnull(i.City,'') 
		or isnull(p.State,'') <> isnull(i.State,'') or isnull(p.Zip, '') <> isnull(i.Zip,'')
		or isnull(p.Address2, '') <> isnull(i.Address2, '') or isnull(p.Phone,'') <> isnull(i.Phone,'')
		or isnull(p.Email,'') <> isnull(i.Email,'') or isnull(p.Country, '') <> isnull(i.Country, '')
		or isnull(p.CellPhone,'') <> isnull(i.CellPhone,'')
	end

--Update Hire Date
if update(HireDate)
	begin
	update dbo.bPREH
	set HireDate = i.HireDate 
	from inserted i
	join dbo.bPREH p (nolock) on i.PRCo = p.PRCo and i.PREmp = p.Employee
	join dbo.bHRCO o (nolock) on i.HRCo = o.HRCo and o.UpdateHireDateYN = 'Y'
	where isnull(p.HireDate,'1/1/00') <> isnull(i.HireDate,'1/1/00') 
	end

--Update Term Date
if update(TermDate)
	begin
	update dbo.bPREH
	set TermDate = i.TermDate
	from inserted i
	join dbo.bPREH p (nolock) on i.PRCo = p.PRCo and i.PREmp = p.Employee
	join dbo.bHRCO o (nolock) on i.HRCo = o.HRCo and o.UpdateHireDateYN = 'Y'
	where isnull(p.TermDate,'1/1/00') <> isnull(i.TermDate,'1/1/00')
	end

--Update Active Flag
if (update(ActiveYN))
	begin
	update dbo.bPREH
	set ActiveYN = i.ActiveYN
	from inserted i
	join dbo.bPREH p (nolock) on i.PRCo = p.PRCo and i.PREmp = p.Employee
	join dbo.bHRCO o (nolock) on i.HRCo = o.HRCo and o.UpdateActiveYN = 'Y'
	where p.ActiveYN <> i.ActiveYN
	end

--Update Timecard Defaults
--Issue #135490 - Add WOTaxState & WOLocalCode
if (update(PRDept) or update(StdCraft) or update(StdClass) or update(StdInsCode)
	or update(StdTaxState) or update(StdUnempState) or update(StdInsState)
	or update(StdLocal) or update(EarnCode) or update(Shift) or update(HDAmt)
	or update(F1Amt) or update(LCFStock) or update(LCPStock)
	or update(WOTaxState) or update(WOLocalCode))		
	begin
	update dbo.bPREH
	set PRDept = i.PRDept, Craft = i.StdCraft, Class = i.StdClass, InsCode = i.StdInsCode,
		TaxState = i.StdTaxState, UnempState = i.StdUnempState, InsState = i.StdInsState, 
		LocalCode = i.StdLocal, EarnCode = i.EarnCode, Shift = i.Shift, HDAmt = i.HDAmt,
		F1Amt = i.F1Amt, LCFStock = i.LCFStock, LCPStock = i.LCPStock,
		WOTaxState = i.WOTaxState, WOLocalCode = i.WOLocalCode
	from inserted i
	join dbo.bPREH p (nolock) on i.PRCo = p.PRCo and i.PREmp = p.Employee
	join dbo.bHRCO o (nolock) on i.HRCo = o.HRCo and o.UpdateTimecardYN = 'Y'
	where p.PRDept <> isnull(i.PRDept, '') or isnull(p.Craft, '') <> isnull(i.StdCraft,'') or
		isnull(p.Class, '') <> isnull(i.StdClass,'') or isnull(p.InsCode,'') <> isnull(i.StdInsCode, '') or
		isnull(p.TaxState, '') <> isnull(i.StdTaxState, '') or isnull(p.UnempState,'') <> isnull(i.StdUnempState, '') or
		isnull(p.InsState,'') <> isnull(i.StdInsState,'') or isnull(p.LocalCode, '') <> isnull(i.StdLocal, '') or
		isnull(p.EarnCode,'') <> isnull(i.EarnCode, '') or isnull(p.Shift,'') <> isnull(i.Shift, '') or
		isnull(p.HDAmt, -999) <> isnull(i.HDAmt, -999) or isnull(p.F1Amt, -999) <> isnull(i.F1Amt, -999) or
		isnull(p.LCFStock, -999) <> isnull(i.LCFStock, -999) or isnull(p.LCPStock, -999) <> isnull(i.LCPStock, -999) or
		isnull(p.WOTaxState, '') <> isnull(i.WOTaxState, '') or isnull(p.WOLocalCode, '') <> isnull(i.WOLocalCode, '')
	end

--Update W4 Info (Not HRWI - that is handled in its triggers)
if (update(NonResAlienYN))
	begin
	update dbo.bPREH
	set NonResAlienYN = i.NonResAlienYN
	from inserted i
	join dbo.bPREH p (nolock) on i.PRCo = p.PRCo and i.PREmp = p.Employee
	join dbo.bHRCO o (nolock) on i.HRCo = o.HRCo and o.UpdateW4YN = 'Y'
	where p.NonResAlienYN <> i.NonResAlienYN
	end
--Update Occup Cat
if (update(OccupCat) or update(CatStatus) or update(OTOpt) or update(OTSched))
	begin
	update dbo.bPREH
	set OccupCat = i.OccupCat, CatStatus = i.CatStatus, OTOpt = i.OTOpt, OTSched = i.OTSched
	from inserted i
	join dbo.bPREH p (nolock) on i.PRCo = p.PRCo and i.PREmp = p.Employee
	join dbo.bHRCO o (nolock) on i.HRCo = o.HRCo and o.UpdateOccupCatYN = 'Y'
	where isnull(p.OccupCat,'') <> isnull(i.OccupCat, '') or isnull(p.CatStatus, '') <> isnull(i.CatStatus, '') or
	isnull(p.OTOpt, '') <> isnull(i.OTOpt, '') or isnull(p.OTSched, '') <> isnull(i.OTSched, '')
	end

--Update SSN
if (update(SSN))
	begin
	update dbo.bPREH
	set SSN = i.SSN
	from inserted i
	join dbo.bPREH p (nolock) on i.PRCo = p.PRCo and i.PREmp = p.Employee
	join dbo.bHRCO o (nolock) on i.HRCo = o.HRCo and o.UpdateSSNYN = 'Y'
	where p.SSN <> isnull(i.SSN,'')
	end

/** end HR to PR cross updates **/

   
-- add Employment History entries on Status change
if update(Status)
	begin
	if exists(select top 1 1 from inserted where Status is not null)
		begin
		-- add History entries for Status
		insert dbo.bHREH (HRCo, HRRef, DateChanged, Seq, Code, Type)
		select i.HRCo, i.HRRef, convert(varchar(11), getdate()),
			isnull(max(h.Seq),0) + row_number() over(partition by h.HRCo, h.HRRef order by i.HRCo, i.HRRef),
			t.HistoryCode,'H'
		from inserted i
		join deleted d on d.HRCo = i.HRCo and d.HRRef = i.HRRef and isnull(d.Status,'') <> isnull(i.Status,'')
		left join dbo.bHREH h on h.HRCo = i.HRCo and i.HRRef = h.HRRef
		join dbo.bHRST t (nolock) on t.HRCo = i.HRCo and t.StatusCode = i.Status and t.UpdateHistYN = 'Y'
		group by i.HRCo, i.HRRef, t.HistoryCode, h.HRCo, h.HRRef
 		end
	end
 
 -- add Employment History entries on Termination Date change - Issue #17850
 if update(TermDate) 
 	begin
   	if exists(select top 1 1 from inserted where TermReason is not null and TermDate is not null)
   		begin
   		insert dbo.bHREH (HRCo, HRRef, DateChanged, Seq, Code, Type)
   		select i.HRCo, i.HRRef, i.TermDate,
			isnull(max(h.Seq),0) + row_number() over(partition by h.HRCo, h.HRRef order by i.HRCo, i.HRRef),
 			i.TermReason, 'N'
 		from inserted i
		left join dbo.bHREH h on h.HRCo = i.HRCo and i.HRRef = h.HRRef
 		where i.TermReason is not null
		group by i.HRCo, i.HRRef, i.TermDate, i.TermReason, h.HRCo, h.HRRef
   		end
   	end
   
 -- add Employement History entries on Position Code change.
 if update(PositionCode)
 	begin
	if exists(select top 1 1 from inserted where PositionCode is not null)
		begin
		insert dbo.bHREH(HRCo, HRRef, DateChanged, Seq, Code, Type)
		select i.HRCo, i.HRRef, convert(varchar(11), getdate()),
			isnull(max(h.Seq),0) + row_number() over(partition by h.HRCo, h.HRRef order by i.HRCo, i.HRRef),
			i.PositionCode, 'P'
		from inserted i
		join deleted d on d.HRCo = i.HRCo and d.HRRef = i.HRRef and isnull(d.PositionCode,'') <> isnull(i.PositionCode,'')
		left join dbo.bHREH h on h.HRCo = i.HRCo and i.HRRef = h.HRRef
		where i.PositionCode is not null 
		group by i.HRCo, i.HRRef, i.PositionCode, h.HRCo, h.HRRef
 		end
	end
   
 /*Insert HQMA record*/
 --Issue #135490 - Add WOTaxState & WOLocalCode
 if update(PRCo)
 	begin
 	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3), i.HRCo) + ' HRRef: ' + convert(varchar,i.HRRef),
 		i.HRCo, 'C','PRCo', convert(varchar(3),d.PRCo), Convert(varchar(3),i.PRCo),	getdate(), SUSER_SNAME()
   	from inserted i 
 	join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
 	join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   	where isnull(i.PRCo, 0) <> isnull(d.PRCo, 0) and e.AuditResourceYN = 'Y'
 	end
 if update(PREmp) 
 	begin 
 	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6), i.HRRef),
 		i.HRCo, 'C','PREmp', convert(varchar(6),d.PREmp), Convert(varchar(6),i.PREmp),
   		getdate(), SUSER_SNAME()
   	from inserted i 
 	join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
 	join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
   	where isnull(i.PREmp, 0) <> isnull(d.PREmp, 0) and e.AuditResourceYN = 'Y'
 	end
 if update(LastName)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' +	convert(varchar,i.HRRef),
 		i.HRCo, 'C','LastName', convert(varchar(30),d.LastName), Convert(varchar(30),i.LastName),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where i.LastName <> d.LastName and e.AuditResourceYN = 'Y'
     end
 if update(FirstName)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','FirstName', convert(varchar(30),d.FirstName), Convert(varchar(30),i.FirstName),
 		getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.FirstName, '') <> isnull(d.FirstName, '') and e.AuditResourceYN = 'Y'
     end
 if update(MiddleName)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','MiddleName', convert(varchar(15),d.MiddleName), Convert(varchar(15),i.MiddleName),
 		getdate(), SUSER_SNAME()
    	from inserted i	
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.MiddleName, '') <> isnull(d.MiddleName, '') and e.AuditResourceYN = 'Y'
    	end
 if update(SortName)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','SortName', convert(varchar(15),d.SortName), Convert(varchar(15),i.SortName),
 		getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where i.SortName <> d.SortName and e.AuditResourceYN = 'Y'
     end
 if update(Address)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','Address', convert(varchar(60),d.Address), Convert(varchar(60),i.Address),
 		getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.Address, '') <> isnull(d.Address, '') and e.AuditResourceYN = 'Y'
    	end
 if update(City)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' +	convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','City', convert(varchar(30),d.City), Convert(varchar(30),i.City),
     	getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.City, '') <> isnull(d.City, '') and e.AuditResourceYN = 'Y'
     end
 if update(State)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','State', convert(varchar(4),d.State), Convert(varchar(4),i.State),
     	getdate(), SUSER_SNAME()
     from inserted i
    	join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.State, '') <> isnull(d.State, '') and e.AuditResourceYN = 'Y'
     end
 if update(Zip)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','Zip', convert(varchar(12),d.Zip), Convert(varchar(12),i.Zip),
     	getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.Zip, '') <> isnull(d.Zip, '') and e.AuditResourceYN = 'Y'
     end

 if update(Country)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','Country', convert(varchar(12),d.Country), Convert(varchar(12),i.Country),
     	getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.Country, '') <> isnull(d.Country, '') and e.AuditResourceYN = 'Y'
     end

 if update(Address2)  
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','Address2', convert(varchar(60),d.Address2), Convert(varchar(60),i.Address2),
 		getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.Address2, '') <> isnull(d.Address2, '') and e.AuditResourceYN = 'Y'
     end
 if update(Phone)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','Phone', convert(varchar(20),d.Phone), Convert(varchar(20),i.Phone),
     	getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.Phone, '') <> isnull(d.Phone, '') and e.AuditResourceYN = 'Y'
     end
 if update(WorkPhone)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','WorkPhone', convert(varchar(20),d.WorkPhone), Convert(varchar(20),i.WorkPhone),
 		getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.WorkPhone, '') <> isnull(d.WorkPhone, '') and e.AuditResourceYN = 'Y'
     end
 if update(Pager)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','Pager', convert(varchar(20),d.Pager), Convert(varchar(20),i.Pager),
     	getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.Pager, '') <> isnull(d.Pager, '') and e.AuditResourceYN = 'Y'
     end
 if update(CellPhone)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','CellPhone', convert(varchar(20),d.CellPhone), Convert(varchar(20),i.CellPhone),
 		getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.CellPhone, '') <> isnull(d.CellPhone, '') and e.AuditResourceYN = 'Y'
     end
 if update(SSN)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','SSN', convert(varchar(11),d.SSN), Convert(varchar(11),i.SSN),
 		getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.HRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.SSN, '') <> isnull(d.SSN, '') and e.AuditResourceYN = 'Y'
     end
 if update(Sex)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','Sex', convert(varchar(1),d.Sex), Convert(varchar(1),i.Sex),
 		getdate(), SUSER_SNAME()
     from inserted i
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where i.Sex <> d.Sex and e.AuditResourceYN = 'Y'
     end
 if update(Race)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','Race', convert(varchar(2),d.Race), Convert(varchar(2),i.Race),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.Race, '') <> isnull(d.Race, '') and e.AuditResourceYN = 'Y'
     end
 if update(BirthDate)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6), i.HRRef),
 		i.HRCo, 'C','BirthDate', convert(varchar(20),d.BirthDate), Convert(varchar(20),i.BirthDate),
 		getdate(), SUSER_SNAME() 
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.BirthDate, '') <> isnull(d.BirthDate, '') and e.AuditResourceYN = 'Y'
     end
 if update(HireDate)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','HireDate', convert(varchar(20),d.HireDate), Convert(varchar(20),i.HireDate),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.HireDate, '') <> isnull(d.HireDate, '') and e.AuditResourceYN = 'Y'
     end
 if update(TermDate)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','TermDate', convert(varchar(20),d.TermDate), Convert(varchar(20),i.TermDate),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.TermDate, '') <> isnull(d.TermDate, '') and e.AuditResourceYN = 'Y'
     end
 if update(TermReason)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','TermReason', convert(varchar(20),d.TermReason), Convert(varchar(20),i.TermReason),
 		getdate(), SUSER_SNAME() 
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.TermReason, '') <> isnull(d.TermReason, '') and e.AuditResourceYN = 'Y'
     end
 if update(ActiveYN)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' +	convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','ActiveYN', convert(varchar(1),d.ActiveYN), Convert(varchar(1),i.ActiveYN),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where i.ActiveYN <> d.ActiveYN and e.AuditResourceYN = 'Y'
     end
 if update(Status)
     begin	  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','Status', convert(varchar(10),d.Status), Convert(varchar(10),i.Status),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.Status, '') <> isnull(d.Status, '') and e.AuditResourceYN = 'Y'
     end
 if update(PRGroup)
     begin  
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','PRGroup', convert(varchar(5),d.PRGroup), Convert(varchar(5),i.PRGroup),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.PRGroup, 0) <> isnull(d.PRGroup, 0) and e.AuditResourceYN = 'Y'
     end
 if update(PRDept)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','PRDept', convert(varchar(10),d.PRDept), Convert(varchar(10),i.PRDept),
 		getdate(), SUSER_SNAME() 
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.PRDept, '') <> isnull(d.PRDept, '') and e.AuditResourceYN = 'Y'
     end
 if update(StdCraft)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','StdCraft', convert(varchar(10),d.StdCraft), Convert(varchar(10),i.StdCraft),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.StdCraft, '') <> isnull(d.StdCraft, '') and e.AuditResourceYN = 'Y'
     end
 if update(StdClass)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','StdClass', convert(varchar(10),d.StdClass), Convert(varchar(10),i.StdClass),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.StdClass, '') <> isnull(d.StdClass, '') and e.AuditResourceYN = 'Y'
     end
 if update(StdInsCode)  
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','StdInsCode', convert(varchar(10),d.StdInsCode), Convert(varchar(10),i.StdInsCode),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.StdInsCode, '') <> isnull(d.StdInsCode, '') and e.AuditResourceYN = 'Y'
     end
 if update(StdTaxState)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','StdTaxState', convert(varchar(4),d.StdTaxState), Convert(varchar(4),i.StdTaxState),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.StdTaxState, '') <> isnull(d.StdTaxState, '') and e.AuditResourceYN = 'Y'
     end
 if update(StdUnempState)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','StdUnempState', convert(varchar(4),d.StdUnempState), Convert(varchar(4),i.StdUnempState),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.StdUnempState, '') <> isnull(d.StdUnempState,'') and e.AuditResourceYN = 'Y'
     end
 if update(StdInsState)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','StdInsState', convert(varchar(4),d.StdInsState), Convert(varchar(4),i.StdInsState),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.StdInsState,'') <> isnull(d.StdInsState,'') and e.AuditResourceYN = 'Y'
     end
 if update(StdLocal)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','StdLocal', convert(varchar(10),d.StdLocal), Convert(varchar(10),i.StdLocal),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.StdLocal, '') <> isnull(d.StdLocal, '') and e.AuditResourceYN = 'Y'
     end
if update(WOTaxState)
	begin
   	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHRRM', 'HR Co#: ' + convert(char,i.HRCo) + ' HRRef: ' + convert(varchar,i.HRRef),
		i.HRCo, 'C', 'WOTaxState', d.WOTaxState, i.WOTaxState, getdate(), SUSER_SNAME()
    from inserted i
    join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
    join dbo.bHRCO a (nolock) on i.HRCo = a.HRCo
    where isnull(i.WOTaxState,'') <> isnull(d.WOTaxState,'') and a.AuditResourceYN = 'Y'
	end
if update(WOLocalCode)
	begin
	insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
		i.HRCo, 'C', 'WOLocalCode', d.WOLocalCode, i.WOLocalCode, getdate(), SUSER_SNAME()
	from inserted i 
	join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
	join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
	where isnull(i.WOLocalCode, '') <> isnull(d.WOLocalCode, '') and e.AuditResourceYN = 'Y'
	end
 if update(W4CompleteYN)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','W4CompleteYN', convert(varchar(1),d.W4CompleteYN), Convert(varchar(1),i.W4CompleteYN),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where i.W4CompleteYN <> d.W4CompleteYN and e.AuditResourceYN = 'Y'
     end
 if update(PositionCode)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','PositionCode', convert(varchar(10),d.PositionCode), Convert(varchar(10),i.PositionCode),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.PositionCode, '') <> isnull(d.PositionCode, '') and e.AuditResourceYN = 'Y'
     end
 if update(NoRehireYN)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','NoRehireYN', convert(varchar(1),d.NoRehireYN), Convert(varchar(1),i.NoRehireYN),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where i.NoRehireYN <> d.NoRehireYN and e.AuditResourceYN = 'Y'
     end
 if update(MaritalStatus)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','MaritalStatus', convert(varchar(1),d.MaritalStatus), Convert(varchar(1),i.MaritalStatus),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.MaritalStatus, '') <> isnull(d.MaritalStatus, '') and e.AuditResourceYN = 'Y'
    	end
 if update(MaidenName)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','MaidenName', convert(varchar(20),d.MaidenName), Convert(varchar(20),i.MaidenName), getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.MaidenName,'') <> isnull(d.MaidenName,'') and e.AuditResourceYN = 'Y'
     end
 if update(SpouseName)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','SpouseName', convert(varchar(30),d.SpouseName), Convert(varchar(30),i.SpouseName),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.SpouseName, '') <> isnull(d.SpouseName,'') and e.AuditResourceYN = 'Y'
     end
 if update(PassPort)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','PassPort', convert(varchar(1),d.PassPort), Convert(varchar(1),i.PassPort),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where i.PassPort <> d.PassPort  and e.AuditResourceYN = 'Y'
    	end
 if update(RelativesYN)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','RelativesYN', convert(varchar(1),d.RelativesYN), Convert(varchar(1),i.RelativesYN),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where i.RelativesYN  <> d.RelativesYN and e.AuditResourceYN = 'Y'
     end
 if update(HandicapYN)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','HandicapYN', convert(varchar(1),d.HandicapYN), Convert(varchar(1),i.HandicapYN),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.HRCO e with (nolock) on i.HRCo = e.HRCo
     where i.HandicapYN  <> d.HandicapYN and e.AuditResourceYN = 'Y'
     end
 if update(HandicapDesc)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','HandicapDesc', convert(varchar(30),d.HandicapDesc), Convert(varchar(30),i.HandicapDesc),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.HandicapDesc,'')  <> isnull(d.HandicapDesc,'') and e.AuditResourceYN = 'Y'
     end
 if update(VetJobCategory)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','VetJobCategory', convert(varchar(1),d.VetJobCategory), Convert(varchar(1),i.VetJobCategory),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.VetJobCategory,'')  <> isnull(d.VetJobCategory,'') and e.AuditResourceYN = 'Y'
     end
 if update(PhysicalYN)
     begin	  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','PhysicalYN', convert(varchar(1),d.PhysicalYN), Convert(varchar(1),i.PhysicalYN),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where i.PhysicalYN  <> d.PhysicalYN and e.AuditResourceYN = 'Y'
     end
 if update(PhysDate)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','PhysDate', convert(varchar(20),d.PhysDate), Convert(varchar(20),i.PhysDate),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.PhysDate, '')  <> isnull(d.PhysDate, '') and e.AuditResourceYN = 'Y'
     end
 if update(PhysExpireDate)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','PhysExpireDate', convert(varchar(20),d.PhysExpireDate), Convert(varchar(20),i.PhysExpireDate),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.PhysExpireDate, '')  <> isnull(d.PhysExpireDate, '') and e.AuditResourceYN = 'Y'
     end
 if update(LicNumber)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','LicNumber', convert(varchar(20),d.LicNumber), Convert(varchar(20),i.LicNumber),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.LicNumber, '')  <> isnull(d.LicNumber, '') and e.AuditResourceYN = 'Y'
     end  
 if update(LicType)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','LicType', convert(varchar(20),d.LicType), Convert(varchar(20),i.LicType),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.LicType, '')  <> isnull(d.LicType, '') and e.AuditResourceYN = 'Y'
     end
 if update(LicState)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','LicState', convert(varchar(2),d.LicState), Convert(varchar(2),i.LicState),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.LicState, '')  <> isnull(d.LicState, '') and e.AuditResourceYN = 'Y'
     end
 if update(LicExpDate)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' +	convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','LicExpDate', convert(varchar(20),d.LicExpDate), Convert(varchar(20),i.LicExpDate),
 		getdate(), SUSER_SNAME() 
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.LicExpDate, '')  <> isnull(d.LicExpDate, '') and e.AuditResourceYN = 'Y'
     end
 if update(DriveCoVehiclesYN)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','DriveCoVehiclesYN', convert(varchar(1),d.DriveCoVehiclesYN), Convert(varchar(1),i.DriveCoVehiclesYN),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where i.DriveCoVehiclesYN  <> d.DriveCoVehiclesYN and e.AuditResourceYN = 'Y'
     end
 if update(I9Status)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','I9Status', convert(varchar(20),d.I9Status), Convert(varchar(20),i.I9Status),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.I9Status, '')  <> isnull(d.I9Status, '') and e.AuditResourceYN = 'Y'
    	end
 if update(I9Citizen)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','I9Citizen', convert(varchar(20),d.I9Citizen), Convert(varchar(20),i.I9Citizen),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.I9Citizen, '')  <> isnull(d.I9Citizen, '') and e.AuditResourceYN = 'Y'
     end
 if update(I9ReviewDate)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','I9ReviewDate', convert(varchar(20),d.I9ReviewDate), Convert(varchar(20),i.I9ReviewDate),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.I9ReviewDate, '')  <> isnull(d.I9ReviewDate, '') and e.AuditResourceYN = 'Y'
     end
 if update(TrainingBudget)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','TrainingBudget', convert(varchar(12),d.TrainingBudget), Convert(varchar(12),i.TrainingBudget),
 		getdate(), SUSER_SNAME() 
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.TrainingBudget, 0)  <> isnull(d.TrainingBudget, 0) and e.AuditResourceYN = 'Y'
     end
 if update(CafeteriaPlanBudget)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','CafeteriaPlanBudget', convert(varchar(12),d.CafeteriaPlanBudget), Convert(varchar(12),i.CafeteriaPlanBudget),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.CafeteriaPlanBudget, 0)  <> isnull(d.CafeteriaPlanBudget, 0) and e.AuditResourceYN = 'Y'
     end
 if update(HighSchool)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','HighSchool', convert(varchar(30),d.HighSchool), Convert(varchar(30),i.HighSchool),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.HighSchool, '')  <> isnull(d.HighSchool, '') and e.AuditResourceYN = 'Y'
 end
 if update(HSGradDate)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','HSGradDate', convert(varchar(20),d.HSGradDate), Convert(varchar(20),i.HSGradDate),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.HSGradDate, '')  <> isnull(d.HSGradDate, '') and e.AuditResourceYN = 'Y'
     end
 if update(College1)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','College1', convert(varchar(30),d.College1), Convert(varchar(30),i.College1),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.College1, '')  <> isnull(d.College1, '') and e.AuditResourceYN = 'Y'
     end
 if update(College1BegDate)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','College1BegDate', convert(varchar(20),d.College1BegDate), Convert(varchar(20),i.College1BegDate),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.College1BegDate, '')  <> isnull(d.College1BegDate, '') and e.AuditResourceYN = 'Y'
     end
 if update(College1EndDate)  
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','College1EndDate', convert(varchar(20),d.College1EndDate), Convert(varchar(20),i.College1EndDate),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.College1EndDate, '')  <> isnull(d.College1EndDate, '') and e.AuditResourceYN = 'Y'
     end
 if update(College1Degree)  
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' +	convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','College1Degree', convert(varchar(20),d.College1Degree), Convert(varchar(20),i.College1Degree),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.College1Degree, '')  <> isnull(d.College1Degree, '') and e.AuditResourceYN = 'Y'
     end
 if update(College2)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','College2', convert(varchar(30),d.College2), Convert(varchar(30),i.College2),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.College2, '')  <> isnull(d.College2, '') and e.AuditResourceYN = 'Y'
     end
 if update(College2BegDate)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','College2BegDate', convert(varchar(20),d.College2BegDate), Convert(varchar(20),i.College2BegDate),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.College2BegDate, '')  <> isnull(d.College2BegDate, '') and e.AuditResourceYN = 'Y'
     end
 if update(College2EndDate)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','College2EndDate', convert(varchar(20),d.College2EndDate), Convert(varchar(20),i.College2EndDate),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.College2EndDate, '')  <> isnull(d.College2EndDate, '') and e.AuditResourceYN = 'Y'
     end
 if update(College2Degree)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','College2Degree', convert(varchar(20),d.College2Degree), Convert(varchar(20),i.College2Degree),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.College2Degree, '')  <> isnull(d.College2Degree, '') and e.AuditResourceYN = 'Y'
     end
 if update(ApplicationDate)
     begin	  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','ApplicationDate', convert(varchar(20),d.ApplicationDate), Convert(varchar(20),i.ApplicationDate),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.ApplicationDate, '')  <> isnull(d.ApplicationDate, '') and e.AuditResourceYN = 'Y'
     end
 if update(AvailableDate)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','AvailableDate', convert(varchar(20),d.AvailableDate), Convert(varchar(20),i.AvailableDate),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.AvailableDate, '')  <> isnull(d.AvailableDate, '') and e.AuditResourceYN = 'Y'
     end
 if update(LastContactDate)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','LastContactDate', convert(varchar(20),d.LastContactDate), Convert(varchar(20),i.LastContactDate),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.HRCO e with (nolock) on i.HRCo = e.HRCo
    	where isnull(i.LastContactDate,'')  <> isnull(d.LastContactDate,'') and e.AuditResourceYN = 'Y'
     end
 if update(ContactPhone)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','ContactPhone', convert(varchar(20),d.ContactPhone), Convert(varchar(20),i.ContactPhone),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.ContactPhone,'')  <> isnull(d.ContactPhone,'') and e.AuditResourceYN = 'Y'
     end
 if update(AltContactPhone)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','AltContactPhone', convert(varchar(20),d.AltContactPhone), Convert(varchar(20),i.AltContactPhone),
 		getdate(), SUSER_SNAME()
    	from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.AltContactPhone, '')  <> isnull(d.AltContactPhone, '') and e.AuditResourceYN = 'Y'
     end
 if update(ExpectedSalary)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','ExpectedSalary', convert(varchar(12),d.ExpectedSalary), Convert(varchar(12),i.ExpectedSalary),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.ExpectedSalary, 0)  <> isnull(d.ExpectedSalary, 0) and e.AuditResourceYN = 'Y'
     end
 if update(Source)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','Source', convert(varchar(30),d.Source), Convert(varchar(30),i.Source),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.Source, '')  <> isnull(d.Source, '') and e.AuditResourceYN = 'Y'
     end
 if update(SourceCost)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','SourceCost', convert(varchar(20),d.SourceCost), Convert(varchar(20),i.SourceCost),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.SourceCost, 0)  <> isnull(d.SourceCost, 0) and e.AuditResourceYN = 'Y'
     end
 if update(CurrentEmployer)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','CurrentEmployer', convert(varchar(30),d.CurrentEmployer), Convert(varchar(30),i.CurrentEmployer),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.CurrentEmployer, '')  <> isnull(d.CurrentEmployer, '') and e.AuditResourceYN = 'Y'
     end
 if update(CurrentTime)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','CurrentTime', convert(varchar(20),d.CurrentTime), Convert(varchar(20),i.CurrentTime),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.CurrentTime, '')  <> isnull(d.CurrentTime, '') and e.AuditResourceYN = 'Y'
     end
 if update(PrevEmployer)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','PrevEmployer', convert(varchar(30),d.PrevEmployer), Convert(varchar(30),i.PrevEmployer),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.PrevEmployer, '')  <> isnull(d.PrevEmployer, '') and e.AuditResourceYN = 'Y'
     end
 if update(PrevTime)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','PrevTime', convert(varchar(20),d.PrevTime), Convert(varchar(20),i.PrevTime),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.PrevTime, '')  <> isnull(d.PrevTime, '') and e.AuditResourceYN = 'Y'
     end
 if update(NoContactEmplYN)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','NoContactEmplYN', convert(varchar(1),d.NoContactEmplYN), Convert(varchar(1),i.NoContactEmplYN),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where i.NoContactEmplYN  <> d.NoContactEmplYN and e.AuditResourceYN = 'Y'
     end
 if update(HistSeq)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' +	convert(varchar(6),i.HRRef),
  		i.HRCo, 'C','HistSeq', convert(varchar(6),d.HistSeq), Convert(varchar(6),i.HistSeq),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.HistSeq,0)  <> isnull(d.HistSeq,0)  and e.AuditResourceYN = 'Y'
     end
 if update(ExistsInPR)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','ExistsInPR', convert(varchar(1),d.ExistsInPR), Convert(varchar(1),i.ExistsInPR),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where i.ExistsInPR  <> d.ExistsInPR and e.AuditResourceYN = 'Y'
     end
 if update(EarnCode)
     begin  
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','EarnCode', convert(varchar(6),d.EarnCode), Convert(varchar(6),i.EarnCode),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.EarnCode, '')  <> isnull(d.EarnCode, '') and e.AuditResourceYN = 'Y'
     end
 if update(TempWorker)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3), i.HRCo) + ' HRRef: ' + convert(varchar(6), i.HRRef),
     	i.HRCo, 'C', 'TempWorker', d.TempWorker, i.TempWorker, getdate(), suser_sname()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where i.TempWorker <> d.TempWorker and e.AuditResourceYN = 'Y'
     end
 if update(Email)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3), i.HRCo) + ' HRRef: ' + convert(varchar(6), i.HRRef),
     	i.HRCo, 'C', 'Email', d.Email, i.Email, getdate(), suser_sname()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.Email, '') <> isnull(d.Email, '') and e.AuditResourceYN = 'Y'
     end
 if update(Suffix)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3), i.HRCo) + ' HRRef: ' + convert(varchar(6), i.HRRef),
     	i.HRCo, 'C', 'Suffix', d.Suffix, i.Suffix, getdate(), suser_sname()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.Suffix, '') <> isnull(d.Suffix, '') and e.AuditResourceYN = 'Y'
    	end
 if update(DisabledVetYN)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3), i.HRCo) + ' HRRef: ' + convert(varchar(6), i.HRRef),
     	i.HRCo, 'C', 'DisabledVetYN', d.DisabledVetYN, i.DisabledVetYN, getdate(), suser_sname()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.DisabledVetYN, '') <> isnull(d.DisabledVetYN, '') and e.AuditResourceYN = 'Y'
     end
 if update(VietnamVetYN)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3), i.HRCo) + ' HRRef: ' + convert(varchar(6), i.HRRef),
     	i.HRCo, 'C', 'VietnamVetYN', d.VietnamVetYN, i.VietnamVetYN, getdate(), suser_sname()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.VietnamVetYN, '') <> isnull(d.VietnamVetYN, '') and e.AuditResourceYN = 'Y'
     end
 if update(OtherVetYN)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3), i.HRCo) + ' HRRef: ' + convert(varchar(6), i.HRRef),
     	i.HRCo, 'C', 'OtherVetYN', d.OtherVetYN, i.OtherVetYN, getdate(), suser_sname()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.OtherVetYN, '') <> isnull(d.OtherVetYN, '') and e.AuditResourceYN = 'Y'
     end
 if update(AFServiceMedalVetYN)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3), i.HRCo) + ' HRRef: ' + convert(varchar(6), i.HRRef),
     	i.HRCo, 'C', 'AFServiceMedalVetYN', d.AFServiceMedalVetYN, i.AFServiceMedalVetYN, getdate(), suser_sname()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.AFServiceMedalVetYN, '') <> isnull(d.AFServiceMedalVetYN, '') and e.AuditResourceYN = 'Y'
     end
 if update(VetDischargeDate)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3), i.HRCo) + ' HRRef: ' + convert(varchar(6), i.HRRef),
     	i.HRCo, 'C', 'VetDischargeDate', d.VetDischargeDate, i.VetDischargeDate, getdate(), suser_sname()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.VetDischargeDate, '') <> isnull(d.VetDischargeDate, '') and e.AuditResourceYN = 'Y'
     end
 if update(OccupCat)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','OccupCat', d.OccupCat, i.OccupCat, getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.OccupCat, '')  <> isnull(d.OccupCat, '') and e.AuditResourceYN = 'Y'
     end
 if update(CatStatus)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','CatStatus', convert(varchar(6),d.CatStatus), Convert(varchar(6),i.CatStatus),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.CatStatus, '')  <> isnull(d.CatStatus, '') and e.AuditResourceYN = 'Y'
     end
 if update(LicClass)
     begin 
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','LicClass', convert(varchar(1),d.LicClass), Convert(varchar(1),i.LicClass),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.LicClass, '') <> isnull(d.LicClass, '') and e.AuditResourceYN = 'Y'
     end
 if update(DOLHireState)
     begin
     insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
 	select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
 		i.HRCo, 'C','DOLHireState', convert(varchar(2),d.DOLHireState), Convert(varchar(2),i.DOLHireState),
 		getdate(), SUSER_SNAME()
     from inserted i 
     join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
     join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
     where isnull(i.DOLHireState,'')  <> isnull(d.DOLHireState,'') and e.AuditResourceYN = 'Y'
     end

	if update(HDAmt)
	begin
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
		i.HRCo, 'C','HDAmt', convert(varchar(100),d.HDAmt), Convert(varchar(100),i.HDAmt),
		getdate(), SUSER_SNAME()
		from inserted i 
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
		where isnull(i.HDAmt,-999)  <> isnull(d.HDAmt,-999) and e.AuditResourceYN = 'Y'
	end

	if update(F1Amt)
	begin
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
		i.HRCo, 'C','HDAmt', convert(varchar(100),d.F1Amt), Convert(varchar(100),i.F1Amt),
		getdate(), SUSER_SNAME()
		from inserted i 
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
		where isnull(i.F1Amt,-999)  <> isnull(d.F1Amt,-999) and e.AuditResourceYN = 'Y'
	end

	if update(LCFStock)
	begin
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
		i.HRCo, 'C','HDAmt', convert(varchar(100),d.LCFStock), Convert(varchar(100),i.LCFStock),
		getdate(), SUSER_SNAME()
		from inserted i 
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
		where isnull(i.LCFStock,-999)  <> isnull(d.LCFStock,-999) and e.AuditResourceYN = 'Y'
	end

	if update(LCPStock)
	begin
		insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
		select 'bHRRM', 'HR Co#: ' + convert(char(3),i.HRCo) + ' HRRef: ' + convert(varchar(6),i.HRRef),
		i.HRCo, 'C','HDAmt', convert(varchar(100),d.LCPStock), Convert(varchar(100),i.LCPStock),
		getdate(), SUSER_SNAME()
		from inserted i 
		join deleted d on i.HRCo = d.HRCo and i.HRRef = d.HRRef
		join dbo.bHRCO e with (nolock) on i.HRCo = e.HRCo
		where isnull(i.LCPStock,-999)  <> isnull(d.LCPStock,-999) and e.AuditResourceYN = 'Y'
	end
     
 return
     
 error:
 	select @errmsg = @errmsg + ' - cannot update HR Resource Master!'
     RAISERROR(@errmsg, 11, -1);
     rollback transaction

GO
ALTER TABLE [dbo].[bHRRM] ADD CONSTRAINT [PK_bHRRM_KeyID] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO

EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRRM].[ActiveYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRRM].[W4CompleteYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRRM].[NoRehireYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRRM].[PassPort]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRRM].[RelativesYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRRM].[HandicapYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRRM].[PhysicalYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRRM].[DriveCoVehiclesYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRRM].[NoContactEmplYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRRM].[ExistsInPR]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRRM].[TempWorker]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRRM].[DisabledVetYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRRM].[VietnamVetYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRRM].[OtherVetYN]'
GO
