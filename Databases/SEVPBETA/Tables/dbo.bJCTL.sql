CREATE TABLE [dbo].[bJCTL]
(
[JCCo] [dbo].[bCompany] NOT NULL,
[LiabTemplate] [smallint] NOT NULL,
[LiabType] [dbo].[bLiabilityType] NOT NULL,
[PhaseGroup] [tinyint] NULL,
[Phase] [dbo].[bPhase] NULL,
[CostType] [dbo].[bJCCType] NULL,
[CalcMethod] [char] (1) COLLATE Latin1_General_BIN NULL,
[LiabilityRate] [dbo].[bRate] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btJCTLd    Script Date: 8/28/99 9:37:48 AM ******/
CREATE  trigger [dbo].[btJCTLd] on [dbo].[bJCTL] for DELETE as
/*-----------------------------------------------------------------
* This trigger rejects delete in bJCTL (JC Dept Liability Template Phase Cost Types)
* Created By:	GF 03/15/2010 - issue #136066
* Modified By:
*
*
* HQMA auditing
*
*********************************************************************/
    
declare @errmsg varchar(255), @numrows int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

	

/* Audit deletes */
insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bJCTL',  ' JCCo: ' + convert(varchar(3),deleted.JCCo) + ' Liab Template: ' + convert(varchar(10),deleted.LiabTemplate) +
				 ' Liab Type: ' + 	convert(varchar(10),deleted.LiabType) + ' Phase: ' + isnull(deleted.Phase,'') + ' CostType: ' + convert(varchar(3), isnull(deleted.CostType,'')),
		deleted.JCCo, 'D', null, null, null, getdate(), SUSER_SNAME()
from deleted inner join bJCCO WITH (NOLOCK) ON  deleted.JCCo=bJCCO.JCCo
where deleted.JCCo=bJCCO.JCCo and bJCCO.AuditLiabilityTemplate='Y'


return

error:
	select @errmsg = @errmsg + ' - cannot delete JCTL!'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







/****** Object:  Trigger dbo.btJCTLi    Script Date: 8/28/99 9:37:49 AM ******/
   CREATE   trigger [dbo].[btJCTLi] on [dbo].[bJCTL] for INSERT 
   /*-----------------------------------------------------------------
   * Created: ??
   * Modified: GG 09/20/02 - #18522 ANSI nulls
   *
   *	This trigger rejects insert in bJCTL (JC Liability Template Details)
   *	if any of the following error conditions exist:
   *
   *		invalid LiabTemplate vs JCTH.LiabTemplate
   *		invalid PhaseGroup vs JCPM.PhaseGroup
   *		invalid Phase vs JCPM.Phase
   *		invalid CostType vs JCCT.CostType
   *		CalcMethod must be 'E' or 'R'
   *		LiabRate can't be null if 'R'
   ****************************************************/
   as
   

declare @errmsg varchar(255), @validcnt int
   declare  @errno int, @numrows int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on

   begin
   /* validate LiabTemplate */
   select @validcnt = count(*) from bJCTH j, inserted i
   where j.LiabTemplate = i.LiabTemplate and j.JCCo = i.JCCo
   if @validcnt <>@numrows
   	begin
   	select @errmsg = 'Invalid Liability Template'
   	goto error
   	end
   /* validate Phase Group */
   select @validcnt = count(*) from bHQCO j, inserted i where j.PhaseGroup = i.PhaseGroup and j.HQCo = i.JCCo
   if @validcnt <>@numrows
   	begin
   	select @errmsg = 'Invalid Phase Group'
   	goto error
   	end
   /* validate Phase */
   /* Changed to not validate null Phases - Issue ID 779 */
   select @nullcnt = count(*) from inserted i where i.Phase is null
   select @validcnt = count(*) from bJCPM j, inserted i where j.PhaseGroup = i.PhaseGroup and j.Phase = i.Phase and i.Phase is not null
   if (@validcnt + @nullcnt)<>@numrows
   	begin
   	select @errmsg = 'Invalid Phase'
   	goto error
   	end
   /* validate CostType */
   /* changed to not validate null costtypes */
   select @nullcnt = count(*) from inserted i where i.CostType is null
   select @validcnt = count(*) from bJCCT j, inserted i where j.PhaseGroup = i.PhaseGroup
   and j.CostType = i.CostType
   if (@validcnt+@nullcnt) <>@numrows
   	begin
   	select @errmsg = 'Invalid Cost Type'
   	goto error
   	end
   /* validate CalcMethod (must be either 'E' or 'R') */
   select @validcnt = count(*) from inserted i where i.CalcMethod = 'E'
   or i.CalcMethod = 'R'
   if @validcnt <>@numrows
   	begin
   	select @errmsg = 'Calc Method must be ''E'' or ''R'''
   	goto error
   	end
   /* validate LiabilityRate (can't be null if 'R') */
   select @validcnt = count(*) from inserted i where i.CalcMethod = 'R' and i.LiabilityRate is	null	 -- #18522
   if @validcnt > 0
   	begin
   	select @errmsg = '''R'' Calc Method can''t be null'
   	goto error
   	end
   /* Audit inserts */
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bJCTL',  'Liab Templ Detail: ' + convert(char(3),inserted.LiabTemplate) +
   		' Liab Type: ' + 	convert(char(3),inserted.LiabType),
   		inserted.JCCo, 'A', null, null, null, getdate(), SUSER_SNAME()
   		from inserted, bJCCO
   		where inserted.JCCo=bJCCO.JCCo and bJCCO.AuditLiabilityTemplate='Y'
   return
   error:
       select @errmsg = @errmsg + ' - cannot insert Liability Template Detail!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   end
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





/****** Object:  Trigger dbo.btJCTLi    Script Date: 8/28/99 9:37:49 AM ******/
   CREATE     trigger [dbo].[btJCTLu] on [dbo].[bJCTL] for UPDATE 
   /*-----------------------------------------------------------------
   * Created: DANF 02/20/2006
   * Modified: 
   *	This trigger rejects insert in bJCTL (JC Liability Template Details)
   *	if any of the following error conditions exist:
   *
   *		invalid LiabTemplate vs JCTH.LiabTemplate
   *		invalid PhaseGroup vs JCPM.PhaseGroup
   *		invalid Phase vs JCPM.Phase
   *		invalid CostType vs JCCT.CostType
   *		CalcMethod must be 'E' or 'R'
   *		LiabRate can't be null if 'R'
   ****************************************************/
   as
   

declare @errmsg varchar(255), @validcnt int
   declare  @errno int, @numrows int, @nullcnt int
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on

   begin
	/* validate LiabTemplate */
	if update (LiabTemplate)
		begin
   		   select @validcnt = count(*) 
			from bJCTH j with (nolock)
			join inserted i
			on j.LiabTemplate = i.LiabTemplate and j.JCCo = i.JCCo
		   if @validcnt <>@numrows
		   	begin
		   	select @errmsg = 'Invalid Liability Template'
		   	goto error
		   	end
		end
   /* validate Phase Group */
	if update (PhaseGroup)
		begin
		   select @validcnt = count(*) 
			from bHQCO j with (nolock)
			join inserted i 
			on j.PhaseGroup = i.PhaseGroup and j.HQCo = i.JCCo
		   if @validcnt <>@numrows
		   	begin
		   	select @errmsg = 'Invalid Phase Group'
		   	goto error
		   	end
		end
   /* validate Phase */
	if update (Phase) 
		begin
		   /* Changed to not validate null Phases - Issue ID 779 */
		   select @nullcnt = count(*) 
			from inserted i where i.Phase is null
		   select @validcnt = count(*) 
			from bJCPM j with (nolock) 
			join inserted i 
			on j.PhaseGroup = i.PhaseGroup and j.Phase = i.Phase 
			where i.Phase is not null
		   if (@validcnt + @nullcnt)<>@numrows
		   	begin
		   	select @errmsg = 'Invalid Phase'
		   	goto error
		   	end
		end
   /* validate CostType */
	if update(CostType)
		begin
		   /* changed to not validate null costtypes */
		   select @nullcnt = count(*) from inserted i where i.CostType is null
		   select @validcnt = count(*) 
			from bJCCT j with (nolock)
	 		join inserted i 
			on j.PhaseGroup = i.PhaseGroup
		   and j.CostType = i.CostType
		   if (@validcnt+@nullcnt) <>@numrows
		   	begin
		   	select @errmsg = 'Invalid Cost Type'
		   	goto error
		   	end
		end
   /* validate CalcMethod (must be either 'E' or 'R') */
	if update(CalcMethod)
		begin
		   select @validcnt = count(*) from inserted i where i.CalcMethod = 'E'
		   or i.CalcMethod = 'R'
		   if @validcnt <>@numrows
		   	begin
		   	select @errmsg = 'Calc Method must be ''E'' or ''R'''
		   	goto error
		   	end
		end
   /* validate LiabilityRate (can't be null if 'R') */
	if update(LiabilityRate)
		begin
		   select @validcnt = count(*) from inserted i where i.CalcMethod = 'R' and i.LiabilityRate is	null	 -- #18522
		   if @validcnt > 0
		   	begin
		   	select @errmsg = 'Liability Rate for Calc Method of R cannot be null'
		   	goto error
		   	end
		end


    /* Insert records into HQMA for changes made to audited fields */

    insert into bHQMA select 'bJCTL',  'Liab Templ Detail: ' + convert(char(3),i.LiabTemplate) +
   		' Liab Type: ' + 	convert(char(3),i.LiabType),
   		i.JCCo, 'C', 'Phase', isnull(d.Phase,''), isnull(i.Phase,''),
    	getdate(), SUSER_SNAME()
    	from inserted i
		join deleted d on i.JCCo = d.JCCo
		join bJCCO c on i.JCCo = c.JCCo
    	where c.AuditLiabilityTemplate='Y' and isnull(i.Phase,'') <> isnull(d.Phase,'')


    insert into bHQMA select 'bJCTL',  'Liab Templ Detail: ' + convert(char(3),i.LiabTemplate) +
   		' Liab Type: ' + 	convert(char(3),i.LiabType),
   		i.JCCo, 'C', 'Cost Type', Convert(char(3),isnull(d.CostType,0)), Convert(char(3),isnull(i.CostType,0)),
    	getdate(), SUSER_SNAME()
    	from inserted i
		join deleted d on i.JCCo = d.JCCo
		join bJCCO c on i.JCCo = c.JCCo
    	where c.AuditLiabilityTemplate='Y' and isnull(i.CostType,0) <> isnull(d.CostType,0)

if update(CalcMethod)
    insert into bHQMA select 'bJCTL',  'Liab Templ Detail: ' + convert(char(3),i.LiabTemplate) +
   		' Liab Type: ' + 	convert(char(3),i.LiabType),
   		i.JCCo, 'C', 'Calculation Method', d.CalcMethod, i.CalcMethod,
    	getdate(), SUSER_SNAME()
    	from inserted i
		join deleted d on i.JCCo = d.JCCo
		join bJCCO c on i.JCCo = c.JCCo
    	where c.AuditLiabilityTemplate='Y' and isnull(i.CalcMethod,'') <> isnull(d.CalcMethod,'')

if update(LiabilityRate)
    insert into bHQMA select 'bJCTL',  'Liab Templ Detail: ' + convert(char(3),i.LiabTemplate) +
   		' Liab Type: ' + 	convert(char(3),i.LiabType),
   		i.JCCo, 'C', 'Liability Rate', Convert(char(30),d.LiabilityRate), Convert(char(30),i.LiabilityRate),
    	getdate(), SUSER_SNAME()
    	from inserted i
		join deleted d on i.JCCo = d.JCCo
		join bJCCO c on i.JCCo = c.JCCo
    	where c.AuditLiabilityTemplate='Y' and isnull(i.LiabilityRate,-1) <> isnull(d.LiabilityRate,-1)

   return
   error:
       select @errmsg = @errmsg + ' - cannot insert Liability Template Detail!'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   end
   
   
   
   
  
 







GO
CREATE UNIQUE CLUSTERED INDEX [biJCTL] ON [dbo].[bJCTL] ([JCCo], [LiabTemplate], [LiabType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJCTL] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
