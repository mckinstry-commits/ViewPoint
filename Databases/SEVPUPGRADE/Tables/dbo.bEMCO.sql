CREATE TABLE [dbo].[bEMCO]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[EMGroup] [tinyint] NOT NULL,
[INCo] [dbo].[bCompany] NULL,
[JCCo] [dbo].[bCompany] NULL,
[PRCo] [dbo].[bCompany] NULL,
[GLCo] [dbo].[bCompany] NOT NULL,
[AdjstGLLvl] [tinyint] NULL,
[AdjstGLSumDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[AdjstGLDetlDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[AdjstGLJrnl] [dbo].[bJrnl] NULL,
[UseAutoGL] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bEMCO_UseAutoGL] DEFAULT ('N'),
[UseGLLvl] [tinyint] NULL,
[UseGLSumDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[UseGLDetlDesc] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[UseGLJrnl] [dbo].[bJrnl] NULL,
[UseRateOride] [dbo].[bYN] NOT NULL,
[UseRevBkdwnCodeDefault] [dbo].[bRevCode] NULL,
[HoursUM] [dbo].[bUM] NULL,
[MatlGLLvl] [tinyint] NULL,
[MatlGLSumDesc] [varchar] (70) COLLATE Latin1_General_BIN NULL,
[MatlGLDetlDesc] [varchar] (70) COLLATE Latin1_General_BIN NULL,
[MatlGLJrnl] [dbo].[bJrnl] NULL,
[MatlMiscGLAcct] [dbo].[bGLAcct] NULL,
[MatlTax] [dbo].[bYN] NOT NULL,
[MatlValid] [dbo].[bYN] NOT NULL,
[DeprCalcReqd] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[DeprLstMnthCalc] [dbo].[bMonth] NULL,
[DeprLstMnthBdgted] [dbo].[bMonth] NULL,
[DeprCostCode] [dbo].[bCostCode] NULL,
[DeprCostType] [dbo].[bEMCType] NULL,
[GLOverride] [dbo].[bYN] NOT NULL,
[WOBeginStat] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[WOCostCodeChg] [dbo].[bYN] NOT NULL,
[WOPostFinal] [dbo].[bYN] NOT NULL,
[WOBeginPartStatus] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[WODefaultRepType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[LaborCT] [dbo].[bEMCType] NULL,
[LaborCostCodeChg] [dbo].[bYN] NOT NULL,
[PartsCT] [dbo].[bEMCType] NULL,
[OutsideRprCT] [dbo].[bEMCType] NULL,
[FuelCostCode] [dbo].[bCostCode] NULL,
[FuelCostType] [dbo].[bEMCType] NULL,
[CompPostCosts] [dbo].[bYN] NOT NULL,
[CompUnattachedEquip] [dbo].[bEquip] NULL,
[AuditCompany] [dbo].[bYN] NOT NULL,
[AuditEquipment] [dbo].[bYN] NOT NULL,
[AuditDepartmentGL] [dbo].[bYN] NOT NULL,
[AuditAsset] [dbo].[bYN] NOT NULL,
[AuditRevenueRateCateg] [dbo].[bYN] NOT NULL,
[AuditRevenueRateEquip] [dbo].[bYN] NOT NULL,
[AuditLocXfer] [dbo].[bYN] NOT NULL,
[AuditCompXfer] [dbo].[bYN] NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[WOAutoSeq] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bEMCO_WOAutoSeq] DEFAULT ('N'),
[WorkOrderOption] [char] (1) COLLATE Latin1_General_BIN NULL,
[LastWorkOrder] [dbo].[bWO] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[UsageMeterUpdate] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bEMCO_UsageMeterUpdate] DEFAULT ('U'),
[CostPartsMeterUpdate] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bEMCO_CostPartsMeterUpdate] DEFAULT ('U'),
[FuelMeterUpdate] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bEMCO_FuelMeterUpdate] DEFAULT ('U'),
[JobLocationUpdate] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bEMCO_JobLocationUpdate] DEFAULT ('U'),
[ShowAllWO] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bEMCO_ShowAllWO] DEFAULT ('Y'),
[AllSMG] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bEMCO_AllSMG] DEFAULT ('N'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[MatlLastUsedYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bEMCO_MatlLastUsedYN] DEFAULT ('N'),
[AttachBatchReportsYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bEMCO_AttachBatchReportsYN] DEFAULT ('N'),
[DefaultWarrantyStartDate] [varchar] (1) COLLATE Latin1_General_BIN NULL CONSTRAINT [DF_bEMCO_DefaultWarrantyStartDate] DEFAULT ('I'),
[AuditWarrantys] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bEMCO_AuditWarrantys] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btEMCOd] on [dbo].[bEMCO] for DELETE as
/*----------------------------------------------------------
*	CREATED BY: JM 5/14/99
*	MODIFIED BY: TV 02/11/04 - 23061 added isnulls
*
*	This trigger rejects delete in bEMCO (EM Companies) if a dependent record is found in:
*
* 		bEMAH - Allocation Header
* 		bEMCM - Category Master
* 		bEMDM - Dept Master
* 		bEMDP - Asset Master
* 		bEMEM - Equip Master
* 		bEMLM - Location Master
* 		bEMTH - Rev Template Header
* 		bEMUH - Auto Usage Template Header
*
*	Adds HQ Master Audit entry.
*/---------------------------------------------------------
   
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

/* Check bEMAH - Allocation Header. */
if exists(select 1 from dbo.bEMAH e (nolock) join deleted d on e.EMCo = d.EMCo)
	begin
	select @errmsg = 'Records exist in Allocation Header table (bEMAH) with this EMCo'
	goto error
	end
/* Check bEMCM - Category Master. */
if exists(select 1 from dbo.bEMCM e (nolock) join deleted d on e.EMCo = d.EMCo)
	begin
	select @errmsg = 'Records exist in Category Master table (bEMCM) with this EMCo'
	goto error
	end
/* Check bEMDM - Dept Master. */
if exists(select 1 from dbo.bEMDM e (nolock) join deleted d on e.EMCo = d.EMCo)
	begin
	select @errmsg = 'Records exist in Dept Master table (bEMDM) with this EMCo'
	goto error
	end
/* Check bEMDP - Asset Master. */
if exists(select 1 from dbo.bEMDP e (nolock) join deleted d on e.EMCo = d.EMCo)
	begin
	select @errmsg = 'Records exist in Asset Master table (bEMDP) with this EMCo'
	goto error
	end
/* Check bEMEM - Equip Master. */
if exists(select 1 from dbo.bEMEM e (nolock) join deleted d on e.EMCo = d.EMCo)
	begin
	select @errmsg = 'Records exist in Equip Master table (bEMEM) with this EMCo'
	goto error
	end
/* Check bEMLM - Location Master. */
if exists(select 1 from bEMLM e (nolock) join deleted d on e.EMCo = d.EMCo)
	begin
	select @errmsg = 'Records exist in Location Master table (bEMLM) with this EMCo'
	goto error
	end
/* Check bEMTH - Rev Template Header. */
if exists(select 1 from dbo.bEMTH e (nolock) join deleted d on e.EMCo = d.EMCo)
	begin
	select @errmsg = 'Records exist in Rev Template Header table (bEMTH) with this EMCo'
	goto error
	end
/* Check bEMUH - Auto Usage Template Header. */
if exists(select 1 from dbo.bEMUH e (nolock) join deleted d on e.EMCo = d.EMCo)
	begin
	select @errmsg = 'Records exist in Auto Usage Template Header table (bEMUH) with this EMCo'
	goto error
	end

-- Master Audit
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bEMCO',  'EM Co#: ' + convert(char(3), EMCo), EMCo, 'D',
	null, null, null, getdate(), SUSER_SNAME()
from deleted

return

error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot delete EM Company!'
    RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE trigger [dbo].[btEMCOi] on [dbo].[bEMCO] for INSERT as
/*-----------------------------------------------------------------
* CREATED BY: 	JM 5/14/99
* MODIFIED BY:	GG 02/16/02 - #11997 - moved Labor Burden related columns to bEMPB
*				GG 03/08/02 - #16459 - removed LaborPRUseEMDept from bEMCO
*				TV 02/11/04 - 23061 added isnulls
*				GG 04/18/07 - #30116 - data security
*				DANF 06/13/07 - 124114 Remove Automatic GL on Usage
*			  TRL 02/18/08 --#21452	
*				Dan So - 03/25/08 - #127535 - removed AuditDepartmentOver - not used
*
*	This trigger rejects insertion in bEMCO (Companies) if the
*	following error condition exists:
*
*		Invalid EMCo vs HQCO
*		AdjstGLLvl, UseGLLvl or MatlGLLvl not 0, 1 or 2
*		UseRateOride, MatlTax, MatlValid, GLOverride,
*			WOCostCodeChg, WOPostFinal, LaborCostCodeChg,
*			CompPostCosts, AuditCompany,
*			AuditEquipment, AuditDepartmentGL, 
*			AuditAsset, AuditRevenueRateCateg, AuditRevenuRateEquip,
*			AuditLocXfer, AuditCompXfer notY or N
*		DeprCalcReqd not in 'M', 'A' or 'N'
*		LaborBurdenOption not in 'A' or 'R'
*
*	Adds HQ Master Audit entry.
*/----------------------------------------------------------------
   
declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int

select @numrows = @@rowcount
if @numrows = 0 return

set nocount on

/* ************************************* */
/* Validate EM Company vs bHQCO. */
/* ************************************* */
select @validcnt = count(*) from dbo.bHQCO h (nolock) join inserted i on h.HQCo = i.EMCo
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid EMCo - not in HQCO'
	goto error
	end

/* ******************** */
/* Validate GL levels. */
/* ******************** */
select @validcnt = count(*) from inserted where AdjstGLLvl in (0,1,2)
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid AdjstGLLvl - must be 0, 1 or 2'
	goto error
	end
select @validcnt = count(*) from inserted where UseGLLvl in (0,1,2)
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid UseGLLvl - must be 0, 1 or 2'
	goto error
	end
select @validcnt = count(*) from inserted where MatlGLLvl in (0,1,2)
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid MatlGLLvl - must be 0, 1 or 2'
	goto error
	end
/* ************************** */
/* Validate UseRateOride. */
/* ************************** */
select @validcnt = count(*) from inserted where UseRateOride in ('Y','N')
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid UseRateOride - must be Y or N'
	goto error
	end
/* ********************************** */
/* Validate MatlTax and MatlValid. */
/* ********************************** */
select @validcnt = count(*) from inserted where MatlTax in ('Y','N')
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid MatlTax - must be Y or N'
	goto error
	end
select @validcnt = count(*) from inserted where MatlValid in ('Y','N')
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid MatlValid - must be Y or N'
	goto error
	end
/* ************************** */
/* Validate DeprCalcReqd. */
/* ************************** */
select @validcnt = count(*) from inserted where DeprCalcReqd in ('M','A','N')
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid DeprCalcReqd - must be M, A or N'
	goto error
	end
/* *********************** */
/* Validate GLOverride. */
/* *********************** */
select @validcnt = count(*) from inserted where GLOverride in ('Y','N')
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid GLOverride - must be Y or N'
	goto error
	end
/* ****************************** */
/* Validate WOCostCodeChg. */
/* ****************************** */
select @validcnt = count(*) from inserted where WOCostCodeChg in ('Y','N')
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid WOCostCodeChg - must be Y or N'
	goto error
	end
/* ************************* */
/* Validate WOPostFinal. */
/* ************************* */
select @validcnt = count(*) from inserted where WOPostFinal in ('Y','N')
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid WOPostFinal - must be Y or N'
	goto error
	end
/* ******************************** */
/* Validate LaborCostCodeChg. */
/* ******************************** */
select @validcnt = count(*) from inserted where LaborCostCodeChg in ('Y','N')
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid LaborCostCodeChg - must be Y or N'
	goto error
	end
/* ***************************** */
/* Validate CompPostCosts. */
/* ***************************** */
select @validcnt = count(*) from inserted where CompPostCosts in ('Y','N')
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid CompPostCosts - must be Y or N'
	goto error
	end
/* ************************ */
/* Validate Audit options. */
/* ************************ */
select @validcnt = count(*) from inserted where AuditCompany in ('Y','N')
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid AuditCompany - must be Y or N'
	goto error
	end
select @validcnt = count(*) from inserted where AuditEquipment in ('Y','N')
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid AuditEquipment - must be Y or N'
	goto error
	end
select @validcnt = count(*) from inserted where AuditDepartmentGL in ('Y','N')
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid AuditDepartmentGL - must be Y or N'
	goto error
	end
select @validcnt = count(*) from inserted where AuditAsset in ('Y','N')
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid AuditAsset - must be Y or N'
	goto error
	end
select @validcnt = count(*) from inserted where AuditRevenueRateCateg in ('Y','N')
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid AuditRevenueRateCateg - must be Y or N'
	goto error
	end
select @validcnt = count(*) from inserted where AuditRevenueRateEquip in ('Y','N')
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid AuditRevenueRateEquip - must be Y or N'
	goto error
	end
select @validcnt = count(*) from inserted where AuditLocXfer in ('Y','N')
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid AuditLocXfer - must be Y or N'
	goto error
	end
select @validcnt = count(*) from inserted where AuditCompXfer in ('Y','N')
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid AuditCompXfer - must be Y or N'
	goto error
	end

-- Master Audit
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bEMCO',  'EM Co#: ' + convert(char(3), EMCo), EMCo, 'A',
	null, null, null, getdate(), SUSER_SNAME()
from inserted


--#21452
insert dbo.bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bEMCO',  'EM Co#: ' + convert(char(3), EMCo), EMCo, 'A', 'Attach Batch Reports YN', AttachBatchReportsYN, null, getdate(), SUSER_SNAME()
from inserted

--initialize Data Security
declare @dfltsecgroup smallint
select @dfltsecgroup = DfltSecurityGroup
from dbo.DDDTShared (nolock) where Datatype = 'bEMCo' and Secure = 'Y'
if @dfltsecgroup is not null
	begin
	insert dbo.vDDDS (Datatype, Qualifier, Instance, SecurityGroup)
	select 'bEMCo', i.EMCo, i.EMCo, @dfltsecgroup
	from inserted i 
	where not exists(select 1 from dbo.vDDDS s (nolock) where s.Datatype = 'bEMCo' and s.Qualifier = i.EMCo 
						and s.Instance = convert(char(30),i.EMCo) and s.SecurityGroup = @dfltsecgroup)
	end 

return

error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot insert EM Company!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   
   CREATE      trigger [dbo].[btEMCOu] on [dbo].[bEMCO] for UPDATE as
    

/*-----------------------------------------------------------------
     *	CREATED BY: 	JM 5/14/99
     *	MODIFIED BY:    bc 11/1/99  allowed PRCo to be null
     *					GG 02/16/02 - #11997 - moved Labor Burden columns to bEMPB
     *					GG 03/08/02 - #16459 - removed LaborPRUseEMDept from bEMCO
     *					TV 06/26/03 - #21021 - Allow record to save with Invalid fuel CostCode and CostType
     *					TV 02/11/04 - 23061 added isnulls
	 *					DANF 06/13/07 - 124114 Remove Automatic GL on Usage
	 *					CHS	01/04/08 - #125194
	 *		TJL 01/28/08 - Issue #126814, Add HQMA audit for new EMCO flags MatlLastUsedYN
	 *					TRL 02/18/08 --#21452	
	 *					CHS 2/29/08 - #127152 erroneous trigger error
	 *					Dan So - 03/25/08 - #127535 - removed AuditDepartmentOver - not used
	 *					GP	05/02/2008 - #128165 fixed trigger error in EMCompany occuring when removing Journal
	 *										from Usage, Adjustments, and Parts tabs.
	 *					TRL 12/10/08 Issue 130859 Added audit entry for DefaultWarrantyStartDate
	 *
     *	This trigger rejects update in bEMCO (EM Companies) if the
     *	following error condition exists:
     *
     *		Change made to key field.
     *		Change made to GLCo if records exist in bEMDM or bEMAH
     *		Invalid EMGroup vs HQGP
     *		Invalid sub-company (INCo, JCCo, PRCo, GLCo) vs company tables
     *		GLLvl not 0, 1, or 2 (AdjstGLLvl, UseGLLvl, MatlGLLvl)
     *		Invalid GLJrnl if GLLvl Summary or Detail (AdjstGLJrnl, UseGLJrnl, MatlGLJrnl)
     *		MatlTax, MatlValid, GLOverride, WOCostCodeChg, WOPostFinal,
     *			LaborCostCodeChg,CompPostCosts, AuditCompany,
     *			AuditEquipment, AuditDepartmentGL, AuditAsset,
     *			AuditRevenueRateCateg, AuditRevenueRateEquip, AuditLocXfer,
     *			AuditCompXfer not Y or N
     *		Invalid HoursUM vs bHQUM
     *		Invalid MatlMiscGLAcct vs bGLAC by GLCo
     *		DeprCalcReqd not 'M', 'A' or 'N'
     *		Invalid DeprCostCode or FuelCostCode vs bEMCC by EMGroup
     *		Invalid DeprCostType, LaborCT, PartsCT, OutsideRprCT or FuelCostType vs bEMCT by EMGroup
     *		Invalid WOBeginStat vs bEMWS by EMGroup
     *		Invalid WOBeginPartStatus vs bEMPS by EMGroup
     *		Invalid WODefaultRepType vs bEMRX by EMGroup
     *		LaborBurdenOption not 'A' or 'R'
     *		Invalid CompUnattachedEquip vs bEMEM by EMCo
     *
     *	Adds record to HQ Master Audit for any updated non-key field.
     */----------------------------------------------------------------
    declare @errmsg varchar(255),
    @numrows int,
    @validcount int,
    @validcount2 int,
    @nullcnt int
    
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on

    /* ************************* */
    /* Check for key changes.    */
    /* ************************* */
    select @validcount = count(*) from deleted d, inserted i
    	where d.EMCo = i.EMCo
    if @validcount <> @numrows
    	begin
    	select @errmsg = 'Cannot change EM Company'
    	goto error
    	end
    
    /* *************************************************************** */
    /* Cannot change GLCo if records exist in bEMDM or bEMAH.          */
    /* *************************************************************** */
    select @validcount = count(*) from deleted d, inserted i, bEMDM a
    	where d.EMCo = i.EMCo and d.GLCo <> i.GLCo and a.EMCo = d.EMCo and a.GLCo = d.GLCo
    if @validcount <> 0
    	begin
    	select @errmsg = 'Cannot change GL Company, Department records exist'
    	goto error
    	end
    select @validcount = count(*) from deleted d, inserted i, bEMAH a
    	where d.EMCo = i.EMCo and d.GLCo <> i.GLCo and a.EMCo = d.EMCo and a.GLCo = d.GLCo
    if @validcount <> 0
    	begin
    	select @errmsg = 'Cannot change GL Company, Allocation records exist'
    	goto error
    	end

    /* ******************** */    
    /* Validate EMGroup.    */
    /* ******************** */
    if update(EMGroup)
    	begin
    	select @validcount = count(*) from bHQGP h, inserted i where h.Grp = i.EMGroup
    	if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid EMGroup - not in HQGP'
    		goto error
    		end
    	end
    /* ******************************* */
    /* Validate all sub Companies.     */
    /* ******************************* */
    /* LATER if update(INCo)
    	begin
    	select @validcount = count(*) from bINCO h, inserted i where h.INCo = i.INCo
    	if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid IN Company - not in bINCO'
    		goto error
    		end
    	end */

    if update(JCCo)
    	begin
    	select @validcount = count(*) from bJCCO h join inserted i on h.JCCo = i.JCCo
        select @nullcnt = count(*) from inserted i where i.JCCo is null
    	if @validcount + @nullcnt <> @numrows
    		begin
    		select @errmsg = 'Invalid JC Company - not in JCCO'
    		goto error
    		end
    	end

-- #127152
--    if update(PRCo)
--    	begin
--    	select @validcount = count(*) from bPRCO h join inserted i on h.PRCo = i.PRCo
--        select @nullcnt = count(*) from inserted i where i.PRCo is null
--    	if @validcount + @nullcnt <> @numrows
--    		begin
--    		select @errmsg = 'Invalid PR Company - not in PRCO'
--    		goto error
--    		end
--    	end

    if update(GLCo)
    	begin
    	select @validcount = count(*) from bGLCO h join inserted i on h.GLCo = i.GLCo
    	if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid GL Company - not in GLCO'
    		goto error
    		end
    	end

    /* ******************** */
    /* Validate GL levels.  */
    /* ******************** */
    if update(AdjstGLLvl)
    	begin
		select @validcount = count(*) from inserted i where i.AdjstGLLvl in(0,1,2)
		select @nullcnt = count(*) from inserted i where i.AdjstGLLvl is null
		if @validcount + @nullcnt <> @numrows
    		begin
    		select @errmsg = 'Invalid Adjustment GL Level - must be 0, 1 or 2'
    		goto error
    		end
    	end

    if update(UseGLLvl)
    	begin
		select @validcount = count(*) from inserted i where i.UseGLLvl in(0,1,2)
		select @nullcnt = count(*) from inserted i where i.UseGLLvl is null
		if @validcount + @nullcnt <> @numrows
    		begin
       		select @errmsg = 'Invalid Usage GL Level - must be 0, 1 or 2'
    		goto error
    		end
    	end

    if update(MatlGLLvl)
    	begin
		select @validcount = count(*) from inserted i where i.MatlGLLvl in(0,1,2)
		select @nullcnt = count(*) from inserted i where i.MatlGLLvl is null
		if @validcount + @nullcnt <> @numrows
    		begin
    		select @errmsg = 'Invalid Parts (Material) GL Level - must be 0, 1 or 2'
    		goto error
    		end
    	end

	/* ********************************************************* */
    /* A Journal must exist if GLLvl is 1 or 2 - Issue #128165   */
    /* ********************************************************* */
	IF update(AdjstGLLvl)
	BEGIN
		IF(SELECT AdjstGLLvl FROM inserted) in (1,2) and (SELECT AdjstGLJrnl FROM inserted) is null
		BEGIN
			SELECT @errmsg = 'Journal entry required if Interface Level is Summary or Detail'
    		GOTO error
		END	
	END

	IF update(UseGLLvl)
	BEGIN
		IF(SELECT UseGLLvl FROM inserted) in (1,2) and (SELECT UseGLJrnl FROM inserted) is null
		BEGIN
			SELECT @errmsg = 'Journal entry required if Interface Level is Summary or Detail'
    		GOTO error
		END	
	END

	IF update(MatlGLLvl)
	BEGIN
		IF(SELECT MatlGLLvl FROM inserted) in (1,2) and (SELECT MatlGLJrnl FROM inserted) is null
		BEGIN
			SELECT @errmsg = 'Journal entry required if Interface Level is Summary or Detail'
    		GOTO error
		END	
	END

    /* ******************************************************** */
    /* If any GLLvl = Summary or Detail, validate its GLJrnl    */
    /* ******************************************************** */
    if update(AdjstGLJrnl)
    	begin
    	select @validcount = count(*) from bGLJR h join inserted i
			on h.GLCo = i.GLCo and h.Jrnl = i.AdjstGLJrnl and i.AdjstGLLvl in(1,2)
    	select @validcount2 = count(*) from inserted i where i.AdjstGLLvl = 0
		select @nullcnt = count(*) from inserted i where i.AdjstGLLvl is null
		if @validcount + @validcount2 + @nullcnt <> @numrows
    		begin
    		select @errmsg = 'Invalid Adjustments (GL) Journal'
    		goto error
    		end
    	end


    if update(UseGLJrnl)
    	begin
    	select @validcount = count(*) from bGLJR h join inserted i
			on h.GLCo = i.GLCo and h.Jrnl = i.UseGLJrnl and i.UseGLLvl in(1,2)
    	select @validcount2 = count(*) from inserted i where i.UseGLLvl = 0
		select @nullcnt = count(*) from inserted i where i.UseGLLvl is null
		if @validcount + @validcount2 + @nullcnt <> @numrows
    		begin
    		select @errmsg = 'Invalid Usage (GL) Journal'
    		goto error
    		end
    	end

    if update(MatlGLJrnl)
    	begin
    	select @validcount = count(*) from bGLJR h, inserted i
			where h.GLCo = i.GLCo and h.Jrnl = i.MatlGLJrnl and i.MatlGLLvl in(1,2)
    	select @validcount2 = count(*) from inserted i where i.MatlGLLvl = 0
		select @nullcnt = count(*) from inserted i where i.MatlGLLvl is null
		if @validcount + @validcount2 + @nullcnt <> @numrows
    		begin
    		select @errmsg = 'Invalid Parts (Material GL) Journal'
    		goto error
    		end
    	end

    /* ************************** */
    /* Validate HoursUM.          */
    /* ************************** */
    if update(HoursUM)
    	begin
    	select @validcount = count(*) from bHQUM h join inserted i on h.UM = i.HoursUM
        select @nullcnt = count(*) from inserted i where i.HoursUM is null
    	if @validcount + @nullcnt <> @numrows
    		begin
    		select @errmsg = 'Invalid UM for Hours - not in HQUM'
    		goto error
    		end
    	end
    /* ************************** */
    /* Validate MatlMiscGLAcct.   */
    /* ************************** */
    if update(MatlMiscGLAcct)
    	begin
    	select @validcount = count(*) from bGLAC g join inserted i 
			on g.GLCo = i.GLCo and g.GLAcct = i.MatlMiscGLAcct
        select @nullcnt = count(*) from inserted i where i.MatlMiscGLAcct is null
    	if @validcount + @nullcnt <> @numrows
    		begin
    		select @errmsg = 'Invalid Misc Parts GL Acct - not in GLAC'
    		goto error
    		end
    	end

    /* ********************************** */
    /* Validate MatlTax and MatlValid.    */
    /* ********************************** */
    if update(MatlTax)
    	begin
    	select @validcount = count(*) from inserted i where i.MatlTax in('Y','N')
		if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid Use Tax on Materials - must be Y or N'
    		goto error
    		end
    	end

    if update(MatlValid)
    	begin
    	select @validcount = count(*) from inserted i where i.MatlValid in('Y','N')
    	if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid Valid Parts - must be Y or N'
    		goto error
    		end
    	end

    /* ************************** */
    /* Validate DeprCalcReqd.     */
    /* ************************** */    
    if update(DeprCalcReqd)
    	begin
    	select @validcount = count(*) from inserted i where i.DeprCalcReqd in('M','A','N')
    	if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid Calculations Required - must be M, A or N'
    		goto error
    		end
    	end

    /* *********************** */
    /* Validate CostCodes.     */
    /* *********************** */
    /*if update(DeprCostCode)
    	begin
    	select @validcount = count(*) from bEMCC e, inserted i
    	where e.EMGroup = i.EMGroup and e.CostCode = i.DeprCostCode
    	if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid DeprCostCode - not in bEMCC'
    		goto error
    		end
    	end*/
    --TV 06/26/03 - #21021 - Allow record to save with Invalid CostCode and CostType
    /*if update(FuelCostCode)
    	begin
    	select @validcount = count(*) from bEMCC e, inserted i
    	where e.EMGroup = i.EMGroup and e.CostCode = i.FuelCostCode
    	if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid FuelCostCode - not in bEMCC'
    		goto error
    		end
    	end*/
    /* ************************* */
    /* Validate all CostTypes.   */
    /* ************************* */
    /*if update(DeprCostType)
    	begin
    	select @validcount = count(*) from bEMCT e, inserted i
    	where e.EMGroup = i.EMGroup and e.CostType = i.DeprCostType
    	if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid DeprCostType - not in bEMCT'
    		goto error
    		end
    	end*/

    if update(LaborCT)
    	begin
    	select @validcount = count(*) from bEMCT e join inserted i
    		on e.EMGroup = i.EMGroup and e.CostType = i.LaborCT
        select @nullcnt = count(*) from inserted i where i.LaborCT is null
    	if @validcount + @nullcnt <> @numrows
    		begin
    		select @errmsg = 'Invalid Labor Cost Type - not in EMCT'
    		goto error
    		end
    	end

    if update(PartsCT)
    	begin
    	select @validcount = count(*) from bEMCT e join inserted i
			on e.EMGroup = i.EMGroup and e.CostType = i.PartsCT
        select @nullcnt = count(*) from inserted i where i.PartsCT is null
    	if @validcount + @nullcnt <> @numrows
    		begin
    		select @errmsg = 'Invalid Parts Cost Type - not in EMCT'
    		goto error
    		end
    	end

    if update(OutsideRprCT)
    	begin
    	select @validcount = count(*) from bEMCT e join inserted i
			on e.EMGroup = i.EMGroup and e.CostType = i.OutsideRprCT
        select @nullcnt = count(*) from inserted i where i.OutsideRprCT is null
    	if @validcount + @nullcnt <> @numrows
    		begin
    		select @errmsg = 'Invalid Outside Repair Cost Type - not in EMCT'
    		goto error
    		end
    	end

    --TV 06/26/03 - #21021 - Allow record to save with Invalid CostCode and CostType
    /*if update(FuelCostType)
    	begin
    	select @validcount = count(*) from bEMCT e, inserted i
    	where e.EMGroup = i.EMGroup and e.CostType = i.FuelCostType
    	if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid FuelCostType - not in bEMCT'
    		goto error
    		end
    	end*/

    /* *********************** */
    /* Validate GLOverride.    */
    /* *********************** */
    if update(GLOverride)
    	begin
    	select @validcount = count(*) from inserted where GLOverride in('Y','N')
    	if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid GL Account Override - must be Y or N'
    		goto error
    		end
    	end

    /* ************************* */
    /* Validate WOBeginStat.     */   
    /* ************************* */
    if update(WOBeginStat)
    	begin
    	select @validcount = count(*) from bEMWS e join inserted i
			on e.EMGroup = i.EMGroup and e.StatusCode = i.WOBeginStat
        select @nullcnt = count(*) from inserted i where i.WOBeginStat is null
    	if @validcount + @nullcnt <> @numrows
    		begin
    		select @errmsg = 'Invalid Beginning Work Order Status - not in EMWS'
    		goto error
    		end
        end

    /* ****************************** */
    /* Validate WOCostCodeChg.        */
    /* ****************************** */
    if update(WOCostCodeChg)
    	begin
    	select @validcount = count(*) from inserted where WOCostCodeChg in('Y','N')
    	if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid Allow Cost Code Change - must be Y or N'
    
    		goto error
    		end
    	end

    /* ************************* */
    /* Validate WOPostFinal.     */
    /* ************************* */
    if update(WOPostFinal)
    	begin
       	select @validcount = count(*) from inserted where WOPostFinal in('Y','N')
       	if @validcount <> @numrows
       		begin
       		select @errmsg = 'Invalid Allow Cost posting to Items - must be Y or N'
       		goto error
       		end
        end
    
    /* ******************************** */
    /* Validate WOBeginPartStatus.      */
    /* ******************************** */
    if update(WOBeginPartStatus)
    	begin
			select @validcount = count(*) from bEMPS e join inserted i 
				on e.EMGroup = i.EMGroup and e.PartsStatusCode = i.WOBeginPartStatus
			select @nullcnt = count(*) from inserted i where i.WOBeginPartStatus is null
    		if @validcount + @nullcnt <> @numrows
    	       	begin
        		select @errmsg = 'Invalid Beginning Parts Status - not in EMPS'
        	   	goto error
    	       	end
		end
    
    /* ******************************** */
    /* Validate WODefaultRepType.       */
    /* ******************************** */
    if update(WODefaultRepType)
    	begin
    	select @validcount = count(*) from bEMRX e join inserted i
    		on e.EMGroup = i.EMGroup and e.RepType = i.WODefaultRepType
		select @nullcnt = count(*) from inserted i where i.WODefaultRepType is null
		if @validcount + @nullcnt <> @numrows
    		begin
    		select @errmsg = 'Invalid Default Repair Type - not in EMRX'
    		goto error
    		end
    	end

    /* ******************************** */
    /* Validate LaborCostCodeChg.       */
    /* ******************************** */
    if update(LaborCostCodeChg)
    	begin
    	select @validcount = count(*) from inserted where LaborCostCodeChg in('Y','N')
    	if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid Allow Cost Code Change - must be Y or N'
    		goto error
    		end
    	end
    
    /* ***************************** */
    /* Validate CompPostCosts.       */
    /* ***************************** */
    if update(CompPostCosts)
    	begin
    	select @validcount = count(*) from inserted where CompPostCosts in('Y','N')
    	if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid Post Costs to Components - must be Y or N'
    		goto error
    		end
    	end

    /* ************************************ */
    /* Validate CompUnattachedEquip.        */
    /* ************************************ */
    if update(CompUnattachedEquip)
    	begin
    	select @validcount = count(*) from bEMEM e join inserted i
    		on e.EMCo = i.EMCo and e.Equipment = i.CompUnattachedEquip
		select @nullcnt = count(*) from inserted i where i.CompUnattachedEquip is null
		if @validcount + @nullcnt <> @numrows
    		begin
    		select @errmsg = 'Invalid Unattached Component Equipment Number - not in EMEM'
    		goto error
    		end
    	end



    /* ************************ */
    /* Validate Audit options.  */
    /* ************************ */
    if update(AuditCompany)
    	begin
    	select @validcount = count(*) from inserted
    	where AuditCompany = 'Y' or AuditCompany = 'N'
    	if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid AuditCompany - must be Y or N'
    		goto error
    		end
    	end
    if update(AuditEquipment)
    	begin
    	select @validcount = count(*) from inserted
    	where AuditEquipment = 'Y' or AuditEquipment = 'N'
    	if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid AuditEquipment - must be Y or N'
    		goto error
    		end
    	end
    if update(AuditDepartmentGL)
    	begin
    	select @validcount = count(*) from inserted
    	where AuditDepartmentGL = 'Y' or AuditDepartmentGL = 'N'
    	if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid AuditDepartmentGL - must be Y or N'
    		goto error
    		end
    	end
    if update(AuditAsset)
    	begin
    	select @validcount = count(*) from inserted
    
    	where AuditAsset = 'Y' or AuditAsset = 'N'
    	if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid AuditAsset - must be Y or N'
    		goto error
    		end
    	end
    if update(AuditRevenueRateCateg)
    	begin
    	select @validcount = count(*) from inserted
    	where AuditRevenueRateCateg = 'Y' or AuditRevenueRateCateg = 'N'
    	if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid AuditRevenueRateCateg - must be Y or N'
    		goto error
    		end
    	end
    if update(AuditRevenueRateEquip)
    	begin
    	select @validcount = count(*) from inserted
    	where AuditRevenueRateEquip = 'Y' or AuditRevenueRateEquip = 'N'
    	if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid AuditRevenueRateEquip - must be Y or N'
    		goto error
    		end
    	end
    if update(AuditLocXfer)
    	begin
    	select @validcount = count(*) from inserted
    	where AuditLocXfer = 'Y' or AuditLocXfer = 'N'
    	if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid AuditLocXfer - must be Y or N'
    		goto error
    		end
    	end
    if update(AuditCompXfer)
    	begin
    	select @validcount = count(*) from inserted
    	where AuditCompXfer = 'Y' or AuditCompXfer = 'N'
    	if @validcount <> @numrows
    		begin
    		select @errmsg = 'Invalid AuditCompXfer - must be Y or N'
    		goto error
    
    		end
    	end


    /* *********************************************************** */
    /* Insert records into HQMA for changes made to non-key fields */
    /* *********************************************************** */
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'EMGroup', Convert(char(30),d.EMGroup), Convert(char(30),i.EMGroup),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.EMGroup <> d.EMGroup
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'INCo', Convert(char(30),d.INCo), Convert(char(30),i.INCo),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.INCo <> d.INCo
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'JCCo', Convert(char(30),d.JCCo), Convert(char(30),i.JCCo),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.JCCo <> d.JCCo
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'PRCo', Convert(char(30),d.PRCo), Convert(char(30),i.PRCo),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.PRCo <> d.PRCo
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'GLCo', Convert(char(30),d.GLCo), Convert(char(30),i.GLCo),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.GLCo <> d.GLCo
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'AdjstGLLvl', Convert(char(30),d.AdjstGLLvl), Convert(char(30),i.AdjstGLLvl),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.AdjstGLLvl <> d.AdjstGLLvl
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'AdjstGLSumDesc', d.AdjstGLSumDesc, i.AdjstGLSumDesc,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.AdjstGLSumDesc <> d.AdjstGLSumDesc
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'AdjstGLDetlDesc', d.AdjstGLDetlDesc, i.AdjstGLDetlDesc,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.AdjstGLDetlDesc <> d.AdjstGLDetlDesc
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'AdjstGLJrnl', d.AdjstGLJrnl, i.AdjstGLJrnl,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.AdjstGLJrnl <> d.AdjstGLJrnl
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'UseGLLvl', Convert(char(30),d.UseGLLvl), Convert(char(30),i.UseGLLvl),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.UseGLLvl <> d.UseGLLvl
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'UseGLSumDesc', d.UseGLSumDesc, i.UseGLSumDesc,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.UseGLSumDesc <> d.UseGLSumDesc
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'UseGLDetlDesc', d.UseGLDetlDesc, i.UseGLDetlDesc,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.UseGLDetlDesc <> d.UseGLDetlDesc
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'UseGLJrnl', d.UseGLJrnl, i.UseGLJrnl,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.UseGLJrnl <> d.UseGLJrnl
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'UseRateOride', d.UseRateOride, i.UseRateOride,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.UseRateOride <> d.UseRateOride
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'UseRevBkdwnCodeDefault', d.UseRevBkdwnCodeDefault, i.UseRevBkdwnCodeDefault,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.UseRevBkdwnCodeDefault <> d.UseRevBkdwnCodeDefault
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'HoursUM', d.HoursUM, i.HoursUM,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.HoursUM <> d.HoursUM
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'MatlGLLvl', Convert(char(30),d.MatlGLLvl), Convert(char(30),i.MatlGLLvl),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.MatlGLLvl <> d.MatlGLLvl
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'MatlGLSumDesc', d.MatlGLSumDesc, i.MatlGLSumDesc,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.MatlGLSumDesc <> d.MatlGLSumDesc
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'MatlGLDetlDesc', d.MatlGLDetlDesc, i.MatlGLDetlDesc,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.MatlGLDetlDesc <> d.MatlGLDetlDesc
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'MatlGLJrnl', d.MatlGLJrnl, i.MatlGLJrnl,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.MatlGLJrnl <> d.MatlGLJrnl
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'MatlMiscGLAcct', d.MatlMiscGLAcct, i.MatlMiscGLAcct,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.MatlMiscGLAcct <> d.MatlMiscGLAcct
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'MatlLastUsedYN', d.MatlLastUsedYN, i.MatlLastUsedYN,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.MatlLastUsedYN <> d.MatlLastUsedYN
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'MatlTax', d.MatlTax, i.MatlTax,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.MatlTax <> d.MatlTax
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'MatlValid', d.MatlValid, i.MatlValid,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.MatlValid <> d.MatlValid
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'DeprCalcReqd', d.DeprCalcReqd, i.DeprCalcReqd,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.DeprCalcReqd <> d.DeprCalcReqd
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'DeprLstMnthCalc', Convert(char(30),d.DeprLstMnthCalc), Convert(char(30),i.DeprLstMnthCalc),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.DeprLstMnthCalc <> d.DeprLstMnthCalc
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'DeprLstMnthBdgted', Convert(char(30),d.DeprLstMnthBdgted), Convert(char(30),i.DeprLstMnthBdgted),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.DeprLstMnthBdgted <> d.DeprLstMnthBdgted
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'DeprCostCode', d.DeprCostCode, i.DeprCostCode,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.DeprCostCode <> d.DeprCostCode
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'DeprCostType', Convert(char(3),d.DeprCostType), Convert(char(3),i.DeprCostType),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.DeprCostType <> d.DeprCostType
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'GLOverride', d.GLOverride, i.GLOverride,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.GLOverride <> d.GLOverride
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'WOBeginStat', d.WOBeginStat, i.WOBeginStat,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.WOBeginStat <> d.WOBeginStat
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'WOCostCodeChg', d.WOCostCodeChg, i.WOCostCodeChg,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.WOCostCodeChg <> d.WOCostCodeChg
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'WOPostFinal', d.WOPostFinal, i.WOPostFinal,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.WOPostFinal <> d.WOPostFinal
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'WOBeginPartStatus', d.WOBeginPartStatus, i.WOBeginPartStatus,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.WOBeginPartStatus <> d.WOBeginPartStatus
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'WODefaultRepType', d.WODefaultRepType, i.WODefaultRepType,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.WODefaultRepType <> d.WODefaultRepType
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'LaborCT', Convert(char(30),d.LaborCT), Convert(char(30),i.LaborCT),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.LaborCT <> d.LaborCT
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'LaborCostCodeChg', d.LaborCostCodeChg, i.LaborCostCodeChg,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.LaborCostCodeChg <> d.LaborCostCodeChg
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'PartsCT', Convert(char(30),d.PartsCT), Convert(char(30),i.PartsCT),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.PartsCT <> d.PartsCT
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'OutsideRprCT', Convert(char(30),d.OutsideRprCT), Convert(char(30),i.OutsideRprCT),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.OutsideRprCT <> d.OutsideRprCT
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'FuelCostCode', d.FuelCostCode, i.FuelCostCode,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.FuelCostCode <> d.FuelCostCode
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'FuelCostType', Convert(char(30),d.FuelCostType), Convert(char(30),i.FuelCostType),
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.FuelCostType <> d.FuelCostType
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'CompPostCosts', d.CompPostCosts, i.CompPostCosts,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.CompPostCosts <> d.CompPostCosts
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'CompUnattachedEquip', d.CompUnattachedEquip, i.CompUnattachedEquip,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.CompUnattachedEquip <> d.CompUnattachedEquip
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'AuditCompany', d.AuditCompany, i.AuditCompany,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.AuditCompany <> d.AuditCompany
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'AuditEquipment', d.AuditEquipment, i.AuditEquipment,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.AuditEquipment <> d.AuditEquipment
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'AuditDepartmentGL', d.AuditDepartmentGL, i.AuditDepartmentGL,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.AuditDepartmentGL <> d.AuditDepartmentGL
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'AuditAsset', d.AuditAsset, i.AuditAsset,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.AuditAsset <> d.AuditAsset
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'AuditRevenueRateCateg', d.AuditRevenueRateCateg, i.AuditRevenueRateCateg,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.AuditRevenueRateCateg <> d.AuditRevenueRateCateg
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'AuditRevenueRateEquip', d.AuditRevenueRateEquip, i.AuditRevenueRateEquip,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.AuditRevenueRateEquip <> d.AuditRevenueRateEquip
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'AuditLocXfer', d.AuditLocXfer, i.AuditLocXfer,
    
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.AuditLocXfer <> d.AuditLocXfer
    insert into bHQMA select 'bEMCO', 'EMCo: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
    	'AuditCompXfer', d.AuditCompXfer, i.AuditCompXfer,
    	getdate(), SUSER_SNAME()
    	from inserted i, deleted d
    	where i.EMCo = d.EMCo and i.AuditCompXfer <> d.AuditCompXfer

--#21452
If update(AttachBatchReportsYN)
begin
	insert into bHQMA select 'bEMCO', 'EM Co#: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
   	'Attach Batch Reports YN', d.AttachBatchReportsYN, i.AttachBatchReportsYN,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.EMCo = d.EMCo and i.AttachBatchReportsYN <> d.AttachBatchReportsYN
end

-------------------------------------
-- EMCO Update Tab Audits, 129081. --
-------------------------------------
IF update(UsageMeterUpdate)
BEGIN
	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName) 
	SELECT 'bEMCO', 'EM Co#: ' + convert(char(3), i.EMCo), i.EMCo, 'C',
	'UsageMeterUpdate', d.UsageMeterUpdate, i.UsageMeterUpdate, 
	getdate(), SUSER_SNAME()
	FROM inserted i join deleted d on i.EMCo = d.EMCo
	WHERE i.UsageMeterUpdate <> d.UsageMeterUpdate
END

IF update(CostPartsMeterUpdate)
BEGIN
	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bEMCO', 'EM Co#: ' + convert(char(3), i.EMCo), i.EMCo, 'C',
	'CostPartsMeterUpdate', d.CostPartsMeterUpdate, i.CostPartsMeterUpdate, 
	getdate(), SUSER_SNAME()
	FROM inserted i join deleted d on i.EMCo = d.EMCo
	WHERE i.CostPartsMeterUpdate <> d.CostPartsMeterUpdate
END

IF update(FuelMeterUpdate)
BEGIN
	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bEMCO', 'EM Co#: ' + convert(char(3), i.EMCo), i.EMCo, 'C',
	'FuelMeterUpdate', d.FuelMeterUpdate, i.FuelMeterUpdate, 
	getdate(), SUSER_SNAME()
	FROM inserted i join deleted d on i.EMCo = d.EMCo
	WHERE i.FuelMeterUpdate <> d.FuelMeterUpdate
END

IF update(JobLocationUpdate)
BEGIN
	INSERT dbo.bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	SELECT 'bEMCO', 'EM Co#: ' + convert(char(3), i.EMCo), i.EMCo, 'C',
	'JobLocationUpdate', d.JobLocationUpdate, i.JobLocationUpdate, 
	getdate(), SUSER_SNAME()
	FROM inserted i join deleted d on i.EMCo = d.EMCo
	WHERE i.JobLocationUpdate <> d.JobLocationUpdate
END

--Issue 130859
If update(DefaultWarrantyStartDate)
begin
	insert into bHQMA select 'bEMCO', 'EM Co#: ' + convert(char(3),i.EMCo), i.EMCo, 'C',
   	'DefaultWarrantyStartDate', d.DefaultWarrantyStartDate, i.DefaultWarrantyStartDate,
   	getdate(), SUSER_SNAME()
   	from inserted i, deleted d
   	where i.EMCo = d.EMCo and IsNull(i.DefaultWarrantyStartDate,'') <> IsNull(d.DefaultWarrantyStartDate,'')
end
   
return
	error:
    select @errmsg = isnull(@errmsg,'') + ' - cannot update EM Company!'
    RAISERROR(@errmsg, 11, -1);
    rollback transaction
    
    
    
    
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMCO] ON [dbo].[bEMCO] ([EMCo]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMCO] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMCO].[UseAutoGL]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMCO].[UseRateOride]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMCO].[MatlTax]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMCO].[MatlValid]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMCO].[GLOverride]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMCO].[WOCostCodeChg]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMCO].[WOPostFinal]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMCO].[LaborCostCodeChg]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMCO].[CompPostCosts]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMCO].[AuditCompany]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMCO].[AuditEquipment]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMCO].[AuditDepartmentGL]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMCO].[AuditAsset]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMCO].[AuditRevenueRateCateg]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMCO].[AuditRevenueRateEquip]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMCO].[AuditLocXfer]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMCO].[AuditCompXfer]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMCO].[WOAutoSeq]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMCO].[ShowAllWO]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMCO].[AllSMG]'
GO
