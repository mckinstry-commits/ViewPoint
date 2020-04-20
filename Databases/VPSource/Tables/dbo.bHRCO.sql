CREATE TABLE [dbo].[bHRCO]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[PRCo] [dbo].[bCompany] NOT NULL,
[DependHistYN] [dbo].[bYN] NOT NULL,
[DependHistCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[BenefitHistYN] [dbo].[bYN] NOT NULL,
[BenefitHistCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[SalaryHistYN] [dbo].[bYN] NOT NULL,
[SalaryHistCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[ReviewHistYN] [dbo].[bYN] NOT NULL,
[ReviewHistCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[TrainHistYN] [dbo].[bYN] NOT NULL,
[TrainHistCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[SkillsHistYN] [dbo].[bYN] NOT NULL,
[SkillsHistCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[RewardHistYN] [dbo].[bYN] NOT NULL,
[RewardHistCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[DisciplineHistYN] [dbo].[bYN] NOT NULL,
[DisciplineHistCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[GrievHistYN] [dbo].[bYN] NOT NULL,
[GrievanceHistCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[AccidentHistYN] [dbo].[bYN] NOT NULL,
[AccidentHistCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[DrugHistYN] [dbo].[bYN] NOT NULL,
[DrugHistCode] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[FMLAReqMonths] [tinyint] NULL,
[FMLAReqHours] [dbo].[bHrs] NOT NULL,
[AuditCoYN] [dbo].[bYN] NOT NULL,
[AuditResourceYN] [dbo].[bYN] NOT NULL,
[AuditBenefitsYN] [dbo].[bYN] NOT NULL,
[AuditSalaryHistYN] [dbo].[bYN] NOT NULL,
[AuditReviewYN] [dbo].[bYN] NOT NULL,
[AuditSkillsYN] [dbo].[bYN] NOT NULL,
[AuditTrainingYN] [dbo].[bYN] NOT NULL,
[AuditRewardsYN] [dbo].[bYN] NOT NULL,
[AuditDisciplineYN] [dbo].[bYN] NOT NULL,
[AuditGrievanceYN] [dbo].[bYN] NOT NULL,
[AuditAccidentsYN] [dbo].[bYN] NOT NULL,
[AuditPositionsYN] [dbo].[bYN] NOT NULL,
[AuditEmplHistYN] [dbo].[bYN] NOT NULL,
[AuditDrugYN] [dbo].[bYN] NOT NULL,
[UpdateNameYN] [dbo].[bYN] NOT NULL,
[UpdateAddressYN] [dbo].[bYN] NOT NULL,
[UpdateHireDateYN] [dbo].[bYN] NOT NULL,
[UpdateActiveYN] [dbo].[bYN] NOT NULL,
[UpdatePRGroupYN] [dbo].[bYN] NOT NULL,
[UpdateTimecardYN] [dbo].[bYN] NOT NULL,
[UpdateW4YN] [dbo].[bYN] NOT NULL,
[UpdateSalaryYN] [dbo].[bYN] NOT NULL,
[UpdateBenefitsYN] [dbo].[bYN] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[UpdateOccupCatYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHRCO_UpdateOccupCatYN] DEFAULT ('N'),
[AuditAssetYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHRCO_AuditAssetYN] DEFAULT ('N'),
[UpdateSSNYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHRCO_UpdateSSNYN] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[AttachBatchReportsYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHRCO_AttachBatchReportsYN] DEFAULT ('N'),
[AuditPTOYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bHRCO_AuditPTOYN] DEFAULT ('N'),
[InitDrugTestStatus] [varchar] (10) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_AccidentHistYN] CHECK (([AccidentHistYN]='Y' OR [AccidentHistYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_AuditAccidentsYN] CHECK (([AuditAccidentsYN]='Y' OR [AuditAccidentsYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_AuditAssetYN] CHECK (([AuditAssetYN]='Y' OR [AuditAssetYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_AuditBenefitsYN] CHECK (([AuditBenefitsYN]='Y' OR [AuditBenefitsYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_AuditCoYN] CHECK (([AuditCoYN]='Y' OR [AuditCoYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_AuditDisciplineYN] CHECK (([AuditDisciplineYN]='Y' OR [AuditDisciplineYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_AuditDrugYN] CHECK (([AuditDrugYN]='Y' OR [AuditDrugYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_AuditEmplHistYN] CHECK (([AuditEmplHistYN]='Y' OR [AuditEmplHistYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_AuditGrievanceYN] CHECK (([AuditGrievanceYN]='Y' OR [AuditGrievanceYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_AuditPositionsYN] CHECK (([AuditPositionsYN]='Y' OR [AuditPositionsYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_AuditResourceYN] CHECK (([AuditResourceYN]='Y' OR [AuditResourceYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_AuditReviewYN] CHECK (([AuditReviewYN]='Y' OR [AuditReviewYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_AuditRewardsYN] CHECK (([AuditRewardsYN]='Y' OR [AuditRewardsYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_AuditSalaryHistYN] CHECK (([AuditSalaryHistYN]='Y' OR [AuditSalaryHistYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_AuditSkillsYN] CHECK (([AuditSkillsYN]='Y' OR [AuditSkillsYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_AuditTrainingYN] CHECK (([AuditTrainingYN]='Y' OR [AuditTrainingYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_BenefitHistYN] CHECK (([BenefitHistYN]='Y' OR [BenefitHistYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_DependHistYN] CHECK (([DependHistYN]='Y' OR [DependHistYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_DisciplineHistYN] CHECK (([DisciplineHistYN]='Y' OR [DisciplineHistYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_DrugHistYN] CHECK (([DrugHistYN]='Y' OR [DrugHistYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_GrievHistYN] CHECK (([GrievHistYN]='Y' OR [GrievHistYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_ReviewHistYN] CHECK (([ReviewHistYN]='Y' OR [ReviewHistYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_RewardHistYN] CHECK (([RewardHistYN]='Y' OR [RewardHistYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_SalaryHistYN] CHECK (([SalaryHistYN]='Y' OR [SalaryHistYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_SkillsHistYN] CHECK (([SkillsHistYN]='Y' OR [SkillsHistYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_TrainHistYN] CHECK (([TrainHistYN]='Y' OR [TrainHistYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_UpdateActiveYN] CHECK (([UpdateActiveYN]='Y' OR [UpdateActiveYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_UpdateAddressYN] CHECK (([UpdateAddressYN]='Y' OR [UpdateAddressYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_UpdateBenefitsYN] CHECK (([UpdateBenefitsYN]='Y' OR [UpdateBenefitsYN]='N' OR [UpdateBenefitsYN] IS NULL))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_UpdateHireDateYN] CHECK (([UpdateHireDateYN]='Y' OR [UpdateHireDateYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_UpdateNameYN] CHECK (([UpdateNameYN]='Y' OR [UpdateNameYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_UpdateOccupCatYN] CHECK (([UpdateOccupCatYN]='Y' OR [UpdateOccupCatYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_UpdatePRGroupYN] CHECK (([UpdatePRGroupYN]='Y' OR [UpdatePRGroupYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_UpdateSSNYN] CHECK (([UpdateSSNYN]='Y' OR [UpdateSSNYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_UpdateSalaryYN] CHECK (([UpdateSalaryYN]='Y' OR [UpdateSalaryYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_UpdateTimecardYN] CHECK (([UpdateTimecardYN]='Y' OR [UpdateTimecardYN]='N'))
ALTER TABLE [dbo].[bHRCO] ADD
CONSTRAINT [CK_bHRCO_UpdateW4YN] CHECK (([UpdateW4YN]='Y' OR [UpdateW4YN]='N'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btHRCOd] on [dbo].[bHRCO] for Delete   as
/**************************************************************
* Created: 04/03/00 ae
* Modified: 3/16/04 - 23061 mh 
*			GG 04/20/07 - #30116 - data security review, added validation checks
*
* Delete trigger on HR Companies; rollsback if any of the following conditions exist:
*	HR References exist
*	HR Benefit codes exist
*	HR Company Assets exist
*
*	Audits deletions in bHQMA	
*
**************************************************************/
declare @errmsg varchar(255), @numrows int
   
select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

-- check HR References
if exists(select top 1 1 from dbo.bHRRM r (nolock) join deleted d on r.HRCo = d.HRCo)
    begin
   	select @errmsg = 'HR References exist'
   	goto error
   	end
-- check HR Benefit Codes
if exists(select top 1 1 from dbo.bHRBC r (nolock) join deleted d on r.HRCo = d.HRCo)
    begin
   	select @errmsg = 'HR Benefit Codes exist'
   	goto error
   	end
-- check HR Company Assets
if exists(select top 1 1 from dbo.bHRCA r (nolock) join deleted d on r.HRCo = d.HRCo)
    begin
   	select @errmsg = 'HR Company Assets exist'
   	goto error
   	end
   
/* Audit inserts */
insert dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bHRCO', 'HRCo: ' + convert(char(3),HRCo), HRCo, 'D', null, null, null, getdate(), SUSER_SNAME()
from deleted 

return

error:
    select @errmsg = (@errmsg + ' - cannot delete HR Company! ')
    RAISERROR(@errmsg, 11, -1);
    rollback transaction

GO

GO

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE trigger [dbo].[btHRCOi] on [dbo].[bHRCO] for INSERT as
/*-----------------------------------------------------------------
* Created: kb 2/25/99
* Modified: mh 3/16/04 - #23061
*			GG 04/20/07 - #30116 - data security review
*			  TRL 02/18/08 --#21452
*
* This trigger rejects update in bHRCO (HR Company) if the
*	following error condition exists:
*
*		Invalid HQ Company number
*
* Audits inserted HR Company records
*
*/----------------------------------------------------------------
 declare @errmsg varchar(255), @numrows int, @validcnt int


select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

/* validate HR Company */
select @validcnt = count(*) from inserted i join dbo.bHQCO h (nolock) on i.HRCo = h.HQCo
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid HR Company, must be setup in HQ first.'
	goto error
	end
   
/* add HQ Master Audit entry */
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bHRCO', 'HR Co#: ' + convert(char(3), isnull(HRCo,'')), HRCo, 'A', null, null, null, getdate(), SUSER_SNAME()
from inserted

--#21452
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bHRCO',  'HR Co#: ' + convert(char(3), HRCo), HRCo, 'A', 'Attach Batch Reports YN', AttachBatchReportsYN, null, getdate(), SUSER_SNAME()
from inserted

--#30116 - initialize Data Security
declare @dfltsecgroup int
select @dfltsecgroup = DfltSecurityGroup
from dbo.DDDTShared (nolock) where Datatype = 'bHRCo' and Secure = 'Y'
if @dfltsecgroup is not null
	begin
	insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
	select 'bHRCo', i.HRCo, i.HRCo, @dfltsecgroup
	from inserted i 
	where not exists(select 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bHRCo' and s.Qualifier = i.HRCo 
						and s.Instance = convert(char(30),i.HRCo) and s.SecurityGroup = @dfltsecgroup)
	end 
    
return

error:
	select @errmsg = @errmsg + ' - cannot insert HR Company!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

GO
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  trigger [dbo].[btHRCOu] on [dbo].[bHRCO] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: kb 2/25/99
    * 	Modified: mh 3/16/04 23061
    *			GG 2/22/05 - #27048 - fixed for multi record update
    *			MH 10/03/05 - #28966 - Add auditing for UpdateSSNYN
	*			Dan So 01/21/08 - #123780 - Add auditing for AuditPTOYN
	*			TRL 02/18/08 --#21452
    *
    *	This trigger rejects update in bHRCO (Companies) if the
    *	following error condition exists:
    *
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int
   declare @hrco bCompany, @hrref bHRRef, @seq int, @code varchar(10)
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* check for key changes */
   if update(HRCo)
   	begin
   	select @validcnt = count(*) from inserted i, deleted d
   		where i.HRCo = d.HRCo
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Cannot change HR Company'
   		goto error
   		end
   	end
   
   select @numrows = count(*) from inserted i where i.DependHistYN='Y'
   if @numrows > 0
   	begin
   	select @validcnt = count(*)
   	from inserted i
   	join bHRCM h on i.HRCo = h.HRCo and	i.DependHistCode = h.Code
   	where h.Type = 'H' and i.DependHistYN='Y'
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Dependent History Code' 
   		goto error
   		end
   	end
   select @numrows = count(*) from inserted i where i.BenefitHistYN='Y'
   if @numrows > 0
   	begin
   	select @validcnt = count(*)
   	from inserted i
   	join bHRCM h on i.HRCo = h.HRCo and	i.BenefitHistCode = h.Code
   	where h.Type = 'H' and i.BenefitHistYN='Y'
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Benefit History Code'
   		goto error
   		end
   	end
   select @numrows = count(*) from inserted i where i.SalaryHistYN='Y'
   if @numrows > 0
   	begin
   	select @validcnt = count(*)
   	from inserted i
   	join bHRCM h on i.HRCo = h.HRCo and	i.SalaryHistCode = h.Code
   	where h.Type = 'H' and i.SalaryHistYN='Y'
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Salary History Code'
   		goto error
   		end
   	end
   select @numrows = count(*) from inserted i where i.ReviewHistYN='Y'
   if @numrows > 0
   	begin
   	select @validcnt = count(*)
   	from inserted i
   	join bHRCM h on i.HRCo = h.HRCo and	i.ReviewHistCode = h.Code
   	where h.Type = 'H' and i.ReviewHistYN='Y'
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Review History Code'
   		goto error
   		end
   	end
   select @numrows = count(*) from inserted i where i.TrainHistYN='Y'
   if @numrows > 0
   	begin
   	select @validcnt = count(*)
   	from inserted i
   	join bHRCM h on i.HRCo = h.HRCo and	i.TrainHistCode = h.Code
   	where h.Type = 'H' and i.TrainHistYN='Y'
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Training History Code'
   		goto error
   		end
   	end
   select @numrows = count(*) from inserted i where i.SkillsHistYN='Y'
   if @numrows > 0
   	begin
   	select @validcnt = count(*)
   	from inserted i
   	join bHRCM h on i.HRCo = h.HRCo and	i.SkillsHistCode = h.Code
   	where h.Type = 'H' and i.SkillsHistYN='Y'
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Skills History Code'
   		goto error
   		end
   	end
   select @numrows = count(*) from inserted i where i.RewardHistYN='Y'
   if @numrows > 0
   	begin
   	select @validcnt = count(*)
   	from inserted i
   	join bHRCM h on i.HRCo = h.HRCo and	i.RewardHistCode = h.Code
   	where h.Type = 'H' and i.RewardHistYN='Y'
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Reward History Code'
   		goto error
   		end
   	end
   select @numrows = count(*) from inserted i where i.DisciplineHistYN='Y'
   if @numrows > 0
   	begin
   	select @validcnt = count(*)
   	from inserted i
   	join bHRCM h on i.HRCo = h.HRCo and	i.DisciplineHistCode = h.Code
   	where h.Type = 'H' and i.DisciplineHistYN='Y'
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Discipline History Code'
   		goto error
   		end
   	end
   select @numrows = count(*) from inserted i where i.GrievHistYN='Y'
   if @numrows > 0
   	begin
   	select @validcnt = count(*) from inserted i
   	join bHRCM h on i.HRCo = h.HRCo and	i.GrievanceHistCode = h.Code
   	where h.Type = 'H' and i.GrievHistYN='Y'
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Grievance History Code'
   		goto error
   
   		end
   	end
   select @numrows = count(*) from inserted i where i.AccidentHistYN='Y'
   if @numrows > 0
   	begin
   	select @validcnt = count(*)
   	from inserted i
   	join bHRCM h on i.HRCo = h.HRCo and	i.AccidentHistCode = h.Code
   	where h.Type = 'H' and i.AccidentHistYN='Y'
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Accident History Code'
   		goto error
   		end
   	end
   select @numrows = count(*) from inserted i where i.DrugHistYN='Y'
   if @numrows > 0
   	begin
   	select @validcnt = count(*)
   	from inserted i
   	join bHRCM h on i.HRCo = h.HRCo and	i.DrugHistCode = h.Code
   	where h.Type = 'H' and i.DrugHistYN='Y'
   	if @validcnt <> @numrows
   		begin
   		select @errmsg = 'Invalid Drug Testing History Code'
   		goto error
   		end
   	end
   
   -- audit changes to Company parameters
   if update(PRCo)
   	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHRCO', 'HR Co#: ' + convert(char(3),i.HRCo), i.HRCo, 'C', 'PR Company',
   		convert(varchar(3),d.PRCo), Convert(varchar(3),i.PRCo),	getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo
   	where i.PRCo <> d.PRCo
   if update(DependHistYN)
   	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHRCO', 'HR Co#: ' + convert(char(3),i.HRCo), i.HRCo, 'C', 'DependHistYN',
   		d.DependHistYN, i.DependHistYN,	getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo
   	where i.DependHistYN <> d.DependHistYN
   if update(DependHistCode)
   	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHRCO', 'HR Co#: ' + convert(char(3),i.HRCo), i.HRCo, 'C', 'DependHistCode',
   		d.DependHistCode, i.DependHistCode,	getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo
   	where isnull(i.DependHistCode,'') <> isnull(d.DependHistCode,'')
   if update(BenefitHistYN)
   	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHRCO', 'HR Co#: ' + convert(char(3),i.HRCo), i.HRCo, 'C','BenefitHistYN',
   		d.BenefitHistYN, i.BenefitHistYN, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo
   	where i.BenefitHistYN <> d.BenefitHistYN
   if update(BenefitHistCode)
   	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHRCO', 'HR Co#: ' + convert(char(3),i.HRCo), i.HRCo, 'C','BenefitHistCode',
   		d.BenefitHistCode, i.BenefitHistCode, getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo
   	where isnull(i.BenefitHistCode,'') <> isnull(d.BenefitHistCode,'')
   if update(SalaryHistYN)
   	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHRCO', 'HR Co#: ' + convert(char(3),i.HRCo), i.HRCo, 'C','SalaryHistYN',
   		d.SalaryHistYN, i.SalaryHistYN,	getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo
   	where i.SalaryHistYN <> d.SalaryHistYN
   if update(SalaryHistCode)
   	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHRCO', 'HR Co#: ' + convert(char(3),i.HRCo), i.HRCo, 'C','SalaryHistCode',
   		d.SalaryHistCode, i.SalaryHistCode,	getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo
   	where isnull(i.SalaryHistCode,'') <> isnull(d.SalaryHistCode,'')
   if update(ReviewHistYN)
   	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHRCO', 'HR Co#: ' + convert(char(3),i.HRCo), i.HRCo, 'C','ReviewHistYN',
   		d.ReviewHistYN, i.ReviewHistYN,	getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo
   	where i.ReviewHistYN <> d.ReviewHistYN
   if update(ReviewHistCode)
   	insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHRCO', 'HR Co#: ' + convert(char(3),i.HRCo), i.HRCo, 'C','ReviewHistCode',
   		d.ReviewHistCode, i.ReviewHistCode,	getdate(), SUSER_SNAME()
   	from inserted i
   	join deleted d on i.HRCo = d.HRCo
   	where isnull(i.ReviewHistCode,'') <> isnull(d.ReviewHistCode,'')
   
   
   ----------------------------------------------------------------------
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'SkillsHistYN', d.SkillsHistYN, i.SkillsHistYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.SkillsHistYN <> d.SkillsHistYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'SkillsHistCode', d.SkillsHistCode, i.SkillsHistCode,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.SkillsHistCode <> d.SkillsHistCode
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'RewardHistYN', d.RewardHistYN, i.RewardHistYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.RewardHistYN <> d.RewardHistYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'RewardHistCode', d.RewardHistCode, i.RewardHistCode,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.RewardHistCode <> d.RewardHistCode
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'DisciplineHistYN', d.DisciplineHistYN, i.DisciplineHistYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.DisciplineHistYN <> d.DisciplineHistYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'DisciplineHistCode',d.DisciplineHistCode, i.DisciplineHistCode,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.DisciplineHistCode <> d.DisciplineHistCode
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'GrievHistYN', d.GrievHistYN, i.GrievHistYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.GrievHistYN <> d.GrievHistYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'GrievanceHistCode', d.GrievanceHistCode, i.GrievanceHistCode,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.GrievanceHistCode <> d.GrievanceHistCode
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'AccidentHistYN', d.AccidentHistYN, i.AccidentHistYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.AccidentHistYN <> d.AccidentHistYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'AccidentHistCode', d.AccidentHistCode, i.AccidentHistCode,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.AccidentHistCode <> d.AccidentHistCode
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'DrugHistYN', d.DrugHistYN, i.DrugHistYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.DrugHistYN <> d.DrugHistYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'DrugHistCode', d.DrugHistCode, i.DrugHistCode,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.DrugHistCode <> d.DrugHistCode
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'FMLAReqMonths', convert(varchar(3),d.FMLAReqMonths), Convert(varchar(3),i.FMLAReqMonths),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.FMLAReqMonths <> d.FMLAReqMonths
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'FMLAReqHours', convert(varchar(15),d.FMLAReqHours), Convert(varchar(15),i.FMLAReqHours),
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.FMLAReqHours <> d.FMLAReqHours
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'AuditCoYN', d.AuditCoYN, i.AuditCoYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.AuditCoYN <> d.AuditCoYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'AuditResourceYN', d.AuditResourceYN, i.AuditResourceYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.AuditResourceYN <> d.AuditResourceYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'AuditBenefitsYN', d.AuditBenefitsYN, i.AuditBenefitsYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.AuditBenefitsYN <> d.AuditBenefitsYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'AuditSalaryHistYN', d.AuditSalaryHistYN, i.AuditSalaryHistYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.AuditSalaryHistYN <> d.AuditSalaryHistYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'AuditReviewYN', d.AuditReviewYN, i.AuditReviewYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.AuditReviewYN <> d.AuditReviewYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'AuditTrainingYN', d.AuditTrainingYN, i.AuditTrainingYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.AuditTrainingYN <> d.AuditTrainingYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'AuditRewardsYN',d.AuditRewardsYN, i.AuditRewardsYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.AuditRewardsYN <> d.AuditRewardsYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'AuditDisciplineYN',d.AuditDisciplineYN, i.AuditDisciplineYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.AuditDisciplineYN <> d.AuditDisciplineYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'AuditGrievanceYN', d.AuditGrievanceYN,i.AuditGrievanceYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.AuditGrievanceYN <> d.AuditGrievanceYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'AuditAccidentsYN', d.AuditAccidentsYN, i.AuditAccidentsYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.AuditAccidentsYN <> d.AuditAccidentsYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'AuditPositionsYN', d.AuditPositionsYN, i.AuditPositionsYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.AuditPositionsYN <> d.AuditPositionsYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'AuditEmplHistYN', d.AuditEmplHistYN, i.AuditEmplHistYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.AuditEmplHistYN <> d.AuditEmplHistYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'AuditDrugYN', d.AuditDrugYN, i.AuditDrugYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.AuditDrugYN <> d.AuditDrugYN

-- Dan So 01/21/08 UPDATE --
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'AuditPTOYN', d.AuditPTOYN, i.AuditPTOYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.AuditPTOYN <> d.AuditPTOYN
-------------------

   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'UpdateNameYN', d.UpdateNameYN, i.UpdateNameYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.UpdateNameYN <> d.UpdateNameYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'UpdateAddressYN', d.UpdateAddressYN, i.UpdateAddressYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.UpdateAddressYN <> d.UpdateAddressYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'UpdateHireDateYN', d.UpdateHireDateYN,i.UpdateHireDateYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.UpdateHireDateYN <> d.UpdateHireDateYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'UpdateActiveYN', d.UpdateActiveYN, i.UpdateActiveYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.UpdateActiveYN <> d.UpdateActiveYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'UpdatePRGroupYN', d.UpdatePRGroupYN, i.UpdatePRGroupYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.UpdatePRGroupYN <> d.UpdatePRGroupYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'UpdateTimecardYN', d.UpdateTimecardYN, i.UpdateTimecardYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.UpdateTimecardYN <> d.UpdateTimecardYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'UpdateW4YN', d.UpdateW4YN, i.UpdateW4YN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.UpdateW4YN <> d.UpdateW4YN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'UpdateSalaryYN', d.UpdateSalaryYN, i.UpdateSalaryYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.UpdateSalaryYN <> d.UpdateSalaryYN
   insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
   	'UpdateBenefitsYN', d.UpdateBenefitsYN, i.UpdateBenefitsYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.UpdateBenefitsYN <> d.UpdateBenefitsYN
    insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),isnull(i.HRCo,'')), i.HRCo, 'C',
    	'UpdateSSNYN', d.UpdateSSNYN, i.UpdateSSNYN,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.HRCo = d.HRCo and i.UpdateSSNYN <> d.UpdateSSNYN
--#21452
If update(AttachBatchReportsYN)
begin
	insert into bHQMA select 'bHRCO', 'HR Co#: ' + convert(char(3),i.HRCo), i.HRCo, 'C',
   	'Attach Batch Reports YN', d.AttachBatchReportsYN, i.AttachBatchReportsYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.HRCo = d.HRCo and i.AttachBatchReportsYN <> d.AttachBatchReportsYN
end
  

   return
   error:
   	select @errmsg = @errmsg + ' - cannot update HR Company!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction

GO
CREATE UNIQUE CLUSTERED INDEX [biHRCO] ON [dbo].[bHRCO] ([HRCo]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRCO] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[DependHistYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[BenefitHistYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[SalaryHistYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[ReviewHistYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[TrainHistYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[SkillsHistYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[RewardHistYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[DisciplineHistYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[GrievHistYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[AccidentHistYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[DrugHistYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[AuditCoYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[AuditResourceYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[AuditBenefitsYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[AuditSalaryHistYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[AuditReviewYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[AuditSkillsYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[AuditTrainingYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[AuditRewardsYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[AuditDisciplineYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[AuditGrievanceYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[AuditAccidentsYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[AuditPositionsYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[AuditEmplHistYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[AuditDrugYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[UpdateNameYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[UpdateAddressYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[UpdateHireDateYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[UpdateActiveYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[UpdatePRGroupYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[UpdateTimecardYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[UpdateW4YN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[UpdateSalaryYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[UpdateBenefitsYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[UpdateOccupCatYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[AuditAssetYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bHRCO].[UpdateSSNYN]'
GO
