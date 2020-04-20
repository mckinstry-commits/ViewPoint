CREATE TABLE [dbo].[bEMRH]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Equipment] [dbo].[bEquip] NOT NULL,
[RevCode] [dbo].[bRevCode] NOT NULL,
[EMGroup] [dbo].[bGroup] NOT NULL,
[WorkUM] [dbo].[bUM] NULL,
[UpdtHrMeter] [dbo].[bYN] NOT NULL,
[PostWorkUnits] [dbo].[bYN] NOT NULL,
[ORideRate] [dbo].[bYN] NOT NULL,
[AllowPostOride] [dbo].[bYN] NOT NULL,
[Rate] [dbo].[bDollar] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[udSource] [varchar] (305) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY]
ALTER TABLE [dbo].[bEMRH] ADD
CONSTRAINT [CK_bEMRH_AllowPostOride] CHECK (([AllowPostOride]='N' OR [AllowPostOride]='Y'))
ALTER TABLE [dbo].[bEMRH] ADD
CONSTRAINT [CK_bEMRH_ORideRate] CHECK (([ORideRate]='N' OR [ORideRate]='Y'))
ALTER TABLE [dbo].[bEMRH] ADD
CONSTRAINT [CK_bEMRH_PostWorkUnits] CHECK (([PostWorkUnits]='N' OR [PostWorkUnits]='Y'))
ALTER TABLE [dbo].[bEMRH] ADD
CONSTRAINT [CK_bEMRH_UpdtHrMeter] CHECK (([UpdtHrMeter]='N' OR [UpdtHrMeter]='Y'))
ALTER TABLE [dbo].[bEMRH] ADD
CONSTRAINT [FK_bEMRH_bEMCO_EMCo] FOREIGN KEY ([EMCo]) REFERENCES [dbo].[bEMCO] ([EMCo])
ALTER TABLE [dbo].[bEMRH] ADD
CONSTRAINT [FK_bEMRH_bEMEM_Equipment] FOREIGN KEY ([EMCo], [Equipment]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment]) ON UPDATE CASCADE
ALTER TABLE [dbo].[bEMRH] ADD
CONSTRAINT [FK_bEMRH_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
ALTER TABLE [dbo].[bEMRH] ADD
CONSTRAINT [FK_bEMRH_bEMRC_RevCode] FOREIGN KEY ([EMGroup], [RevCode]) REFERENCES [dbo].[bEMRC] ([EMGroup], [RevCode])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btEMRHd    Script Date: 8/28/99 9:37:19 AM ******/
   
    CREATE  trigger [dbo].[btEMRHd] on [dbo].[bEMRH] for DELETE as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
            @errno tinyint, @audit bYN, @validcnt int, @nullcnt int
   
    /*--------------------------------------------------------------
     *
     *  Delete trigger for EMRH
     *  Created By: bc 10/02/98
     *  Modified by:  TV 02/11/04 - 23061 added isnulls
     *
     *
     *--------------------------------------------------------------*/
   
     /*** declare local variables ***/
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   
     /* delete all rev bdown codes for this rev code */
    delete bEMBE
    from bEMBE e, deleted d
    where e.EMCo = d.EMCo and e.Equipment = d.Equipment and e.EMGroup = d.EMGroup and e.RevCode = d.RevCode
   
   /* Audit insert */
   insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bEMRH','EM Company: ' + convert(char(3), d.EMCo) + ' Equipment: ' + d.Equipment +
       ' EMGroup: ' + convert(varchar(3),d.EMGroup) + ' RevCode: ' + d.RevCode,
       d.EMCo, 'D', null, null, null, getdate(), SUSER_SNAME()
   	from deleted d, EMCO e
       where d.EMCo = e.EMCo and e.AuditRevenueRateEquip = 'Y'
   
    return
   
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot delete from EMRH'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
   
   
  
 



GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE trigger [dbo].[btEMRHi] on [dbo].[bEMRH] for insert as
/*--------------------------------------------------------------
*1
*  insert trigger for EMRH (EM Revenue Rates by Equipment)
*  Created By: bc 10/02/98
*  Modified by: bc 05/02/01
*               TV 03/17/03 20588 connot insert unless it exists in EMRR.
*               TV 09/26/03 22478 Not overriding Rate in EMBE
*			   TV 02/11/04 - 23061 added isnulls
*				TRL 05/20/2008 - Issue 131254,  Use EMCo default Revbdown code when Category has no rate or RevBdown Codes
*				GF 01/09/2013 TK-20670 changed validation for revenue code by category for multiple rows
*				GF 05/05/2013 TFS-49039
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255),
		@validcnt int, @nullcnt INT,
		@revbdowncode varchar(10), @bdowncodedesc varchar(30), @rateflag bYN

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on


/* validate WorkUM */
select @validcnt = count(*) from bHQUM e join inserted i on e.UM = i.WorkUM
select @nullcnt = count(*) from inserted i where i.WorkUM is null
if @validcnt + @nullcnt <> @numrows
begin
	select @errmsg = 'Invalid Work Unit of Measure '
	goto error
end



/* insert default Bdown code(s) into EMBE when a new entry is made into EMRH
based on whatever breakdown codes exists for this equipment's category in EMRR/EMBG and the override flag from inserted*/
IF (select count(1) from inserted i
	join EMEM m on m.EMCo = i.EMCo and m.Equipment = i.Equipment
	join EMBG g on g.EMCo = i.EMCo and g.EMGroup = i.EMGroup and g.Category = m.Category and g.RevCode = i.RevCode
	join EMRT t on t.EMGroup = g.EMGroup and t.RevBdownCode = g.RevBdownCode
	where i.ORideRate = 'Y') = 1
	BEGIN
		insert into bEMBE (EMCo, EMGroup, Equipment, RevCode, RevBdownCode, Description, Rate)
		select i.EMCo, i.EMGroup, i.Equipment, i.RevCode, g.RevBdownCode, t.Description, 
		case when isnull(i.Rate,0) = 0 then g.Rate else i.Rate end
		from inserted i
		join EMEM m on m.EMCo = i.EMCo and m.Equipment = i.Equipment
		join EMBG g on g.EMCo = i.EMCo and g.EMGroup = i.EMGroup and g.Category = m.Category and g.RevCode = i.RevCode
		join EMRT t on t.EMGroup = g.EMGroup and t.RevBdownCode = g.RevBdownCode
		where i.ORideRate = 'Y'
	END
ELSE
	BEGIN
			--Issue 131254 start
			If  ( select top 1 1 	from inserted i
				join EMEM m on m.EMCo = i.EMCo and m.Equipment = i.Equipment
				join EMBG g on g.EMCo = i.EMCo and g.EMGroup = i.EMGroup and g.Category = m.Category and g.RevCode = i.RevCode
				join EMRT t on t.EMGroup = g.EMGroup and t.RevBdownCode = g.RevBdownCode
				where i.ORideRate = 'Y') =1
				Begin
					insert into bEMBE (EMCo, EMGroup, Equipment, RevCode, RevBdownCode, Description, Rate)
					select i.EMCo, i.EMGroup, i.Equipment, i.RevCode, g.RevBdownCode, t.Description, g.Rate 
					from inserted i
					join EMEM m on m.EMCo = i.EMCo and m.Equipment = i.Equipment
					join EMBG g on g.EMCo = i.EMCo and g.EMGroup = i.EMGroup and g.Category = m.Category and g.RevCode = i.RevCode
					join EMRT t on t.EMGroup = g.EMGroup and t.RevBdownCode = g.RevBdownCode
					where i.ORideRate = 'Y'
				End
			Else
				Begin
					 /* snag the default revenue breakdown code rom EM Company file */
					select @revbdowncode = UseRevBkdwnCodeDefault    from EMCO e, inserted i
					 where e.EMCo = i.EMCo
   
					if @revbdowncode is null
					begin
							select @errmsg = 'Missing default revenue breakdown code in Company form!'
							goto error
					end
   
					/* the revbdowncode description for new EMBG entries */
					select @bdowncodedesc = Description		from EMRT e, inserted i
					where e.EMGroup = i.EMGroup and e.RevBdownCode = @revbdowncode

					insert into EMBE (EMCo, EMGroup, Equipment, RevCode, RevBdownCode, Description, Rate)
					select distinct i.EMCo, i.EMGroup, i.Equipment, i.RevCode, @revbdowncode, @bdowncodedesc, i.Rate 
					from inserted i
					join EMEM m on m.EMCo = i.EMCo and m.Equipment = i.Equipment
					where i.ORideRate = 'Y'
				End
				--Issue 131254 End
	END

/* Audit insert */
insert into bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bEMRH','EM Company: ' + convert(char(3), i.EMCo) + ' Equipment: ' + i.Equipment +
' EMGroup: ' + convert(varchar(3),i.EMGroup) + ' RevCode: ' + i.RevCode,
i.EMCo, 'A', null, null, null, getdate(), SUSER_SNAME()
from inserted i, EMCO e
where i.EMCo = e.EMCo and e.AuditRevenueRateEquip = 'Y'


return

error:
select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMRH'
RAISERROR(@errmsg, 11, -1);
rollback transaction


GO
GO

GO

GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
  
/*--------------------------------------------------------------
 *
 *  update trigger for EMRH
 *  Created By: bc 10/12/98
 *  Modified by: bc 05/02/01
 *				 TV 02/11/04 - 23061 added isnulls
 *				 DAN SO 11/05/2008 - Issue: #130918 - Clean up trigger
 *				TRL 05/20/2008 - Issue 131254,  Use EMCo default Revbdown code when Category has no rate or RevBdown Codes
 *				GF 05/05/2013 TFS-49039
 *
 *--------------------------------------------------------------*/
    
    CREATE   trigger [dbo].[btEMRHu] on [dbo].[bEMRH] for update as
   
     

	-- SET UP LOCAL VARIABLE --
    DECLARE @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int,
	@revbdowncode varchar(10), @bdowncodedesc varchar(30)
   
	-- CHECK TO SEE IF ANY ROWS WERE UPDATED --
    select @numrows = @@rowcount
    if @numrows = 0 return
   
    set nocount on
   
----TFS-49039  
SELECT @validcnt = COUNT(*) FROM dbo.bEMEM EMEM JOIN inserted i ON i.EMCo = EMEM.EMCo AND i.Equipment = EMEM.Equipment and EMEM.ChangeInProgress = 'Y'
IF @validcnt = @numrows RETURN
	
	---- CHECK FOR UPDATES TO KEY FIELDS --
	IF UPDATE(EMGroup) OR UPDATE(RevCode)
		BEGIN
			SET @errmsg = 'Cannot change key fields '
			GOTO error
	END
     
   
   /* validate WorkUM */
   select @validcnt = count(*) from bHQUM e join inserted i on e.UM = i.WorkUM
   select @nullcnt = count(*) from inserted i where i.WorkUM is null
   if @validcnt + @nullcnt <> @numrows
     begin
     select @errmsg = 'Invalid Work Unit of Measure '
     goto error
     end
   
   
-- ************************************* --
-- CHECK FOR OVERRIDE RATES FLAG UPDATES --
-- ************************************* --
IF update(ORideRate)
BEGIN
	-- REMOVE EXISTING ENTRIES --
	DELETE bEMBE
	FROM bEMBE e
    JOIN inserted i on e.EMCo = i.EMCo  AND e.Equipment = i.Equipment 
	  AND e.EMGroup = i.EMGroup   AND e.RevCode = i.RevCode
   
	/* insert default Bdown code(s) into EMBE when a new entry is made into EMRH
	based on whatever breakdown codes exists for this equipment's category in 
	EMRR/EMBG based on override flag from inserted */
	--Issue 131254 start
	If  ( select top 1 1 	from inserted i
			join EMEM m on m.EMCo = i.EMCo and m.Equipment = i.Equipment
			join EMBG g on g.EMCo = i.EMCo and g.EMGroup = i.EMGroup and g.Category = m.Category and g.RevCode = i.RevCode
			join EMRT t on t.EMGroup = g.EMGroup and t.RevBdownCode = g.RevBdownCode
			where i.ORideRate = 'Y') =1
			Begin
				INSERT INTO EMBE (EMCo, EMGroup, Equipment, RevCode, RevBdownCode, Description, Rate)
				SELECT i.EMCo, i.EMGroup, i.Equipment, i.RevCode, g.RevBdownCode, t.Description, g.Rate   FROM inserted i 
				JOIN EMEM m WITH (NOLOCK) on m.EMCo = i.EMCo and m.Equipment = i.Equipment
				JOIN EMBG g WITH (NOLOCK) on g.EMCo = i.EMCo and g.EMGroup = i.EMGroup and g.Category = m.Category and g.RevCode = i.RevCode
				JOIN EMRT t WITH (NOLOCK) on t.EMGroup = g.EMGroup and t.RevBdownCode = g.RevBdownCode
				 WHERE i.ORideRate = 'Y'
			End
	Else
			Begin
					/* snag the default revenue breakdown code rom EM Company file */
					select @revbdowncode = UseRevBkdwnCodeDefault    from EMCO e, inserted i
					 where e.EMCo = i.EMCo
   
					if @revbdowncode is null
					begin
							select @errmsg = 'Missing default revenue breakdown code in Company form!'
							goto error
					end
   
					/* the revbdowncode description for new EMBG entries */
					select @bdowncodedesc = Description		from EMRT e, inserted i
					where e.EMGroup = i.EMGroup and e.RevBdownCode = @revbdowncode

					insert into EMBE (EMCo, EMGroup, Equipment, RevCode, RevBdownCode, Description, Rate)
					select distinct i.EMCo, i.EMGroup, i.Equipment, i.RevCode, @revbdowncode, @bdowncodedesc, i.Rate 
					from inserted i
					join EMEM m on m.EMCo = i.EMCo and m.Equipment = i.Equipment
					where i.ORideRate = 'Y'
			End
				--Issue 131254 End
END --IF update(ORideRate)
   
if update(Rate)
	/* update lone Revenue Breakdown Code in EMBE when a change is made to the rate in EMRH */
	begin

		BEGIN;
			-- GET ONLY REVENUE BREAKDOWN CODES THAT ONLY HAVE 1 RECORD WITH OVERRIDE RATE (Y) --
			WITH cteUnique (EMGroup, EMCo, Equipment, RevCode, Rate) AS
				(SELECT i.EMGroup, i.EMCo, i.Equipment, i.RevCode, i.Rate
				   FROM inserted i
				   JOIN bEMBE e WITH (NOLOCK) ON e.EMCo = i.EMCo 
					AND e.Equipment = i.Equipment 
					AND e.EMGroup = i.EMGroup 
					AND e.RevCode = i.RevCode
				  WHERE i.ORideRate = 'Y' 
			   GROUP BY i.EMGroup, i.EMCo, i.Equipment, i.RevCode, i.Rate
				 HAVING COUNT(*) = 1)

			UPDATE bEMBE
			   SET Rate = c.Rate
			  FROM bEMBE b
			  JOIN cteUnique c ON c.EMCo = b.EMCo 
			   AND c.EMGroup = b.EMGroup 
			   AND c.Equipment = b.Equipment 
			   AND c.RevCode = b.RevCode
		END;
 
	end --if update(Rate)
   

/* Audit inserts */
if not exists (select * from inserted i, EMCO e where i.EMCo = e.EMCo and e.AuditRevenueRateEquip = 'Y')
return


IF UPDATE(WorkUM)
	BEGIN
		insert into bHQMA select 'bEMRH', 'EM Company: ' + convert(char(3), i.EMCo) + ' Equipment: ' + i.Equipment +
					' EMGroup: ' + convert(varchar(3),i.EMGroup) + ' RevCode: ' + i.RevCode,
					i.EMCo, 'C', 'WorkUM', d.WorkUM, i.WorkUM, getdate(), SUSER_SNAME()
				from inserted i, deleted d, EMCO e
				where i.EMCo = d.EMCo and i.Equipment = d.Equipment	and i.EMGroup = d.EMGroup and i.RevCode = d.RevCode and i.WorkUM <> d.WorkUM and
						e.EMCo = i.EMCo and e.AuditRevenueRateEquip = 'Y'
	END

IF UPDATE(UpdtHrMeter)
	BEGIN
		insert into bHQMA select 'bEMRH', 'EM Company: ' + convert(char(3), i.EMCo) + ' Equipment: ' + i.Equipment +
					' EMGroup: ' + convert(varchar(3),i.EMGroup) + ' RevCode: ' + i.RevCode,
					i.EMCo, 'C', 'UpdtHrMeter', d.UpdtHrMeter, i.UpdtHrMeter, getdate(), SUSER_SNAME()
				from inserted i, deleted d, EMCO e
				where i.EMCo = d.EMCo and i.Equipment = d.Equipment	and i.EMGroup = d.EMGroup and i.RevCode = d.RevCode and i.UpdtHrMeter <> d.UpdtHrMeter and
					e.EMCo = i.EMCo and e.AuditRevenueRateEquip = 'Y'
	END

IF UPDATE(PostWorkUnits)
	BEGIN
		insert into bHQMA select 'bEMRH', 'EM Company: ' + convert(char(3), i.EMCo) + ' Equipment: ' + i.Equipment +
					' EMGroup: ' + convert(varchar(3),i.EMGroup) + ' RevCode: ' + i.RevCode,
					i.EMCo, 'C', 'PostWorkUnits', d.PostWorkUnits, i.PostWorkUnits, getdate(), SUSER_SNAME()
				from inserted i, deleted d, EMCO e
				where i.EMCo = d.EMCo and i.Equipment = d.Equipment	and i.EMGroup = d.EMGroup and i.RevCode = d.RevCode and i.PostWorkUnits <> d.PostWorkUnits and
					e.EMCo = i.EMCo and e.AuditRevenueRateEquip = 'Y'
	END

IF UPDATE(AllowPostOride)
	BEGIN
		insert into bHQMA select 'bEMRH', 'EM Company: ' + convert(char(3), i.EMCo) + ' Equipment: ' + i.Equipment +
					' EMGroup: ' + convert(varchar(3),i.EMGroup) + ' RevCode: ' + i.RevCode,
					i.EMCo, 'C', 'AllowPostOride', d.AllowPostOride, i.AllowPostOride, getdate(), SUSER_SNAME()
				from inserted i, deleted d, EMCO e
				where i.EMCo = d.EMCo and i.Equipment = d.Equipment	and i.EMGroup = d.EMGroup and i.RevCode = d.RevCode and i.AllowPostOride <> d.AllowPostOride and
					e.EMCo = i.EMCo and e.AuditRevenueRateEquip = 'Y'
	END

IF UPDATE(ORideRate)
	BEGIN
		insert into bHQMA select 'bEMRH', 'EM Company: ' + convert(char(3), i.EMCo) + ' Equipment: ' + i.Equipment +
					' EMGroup: ' + convert(varchar(3),i.EMGroup) + ' RevCode: ' + i.RevCode,
					i.EMCo, 'C', 'ORideRate', d.ORideRate, i.ORideRate, getdate(), SUSER_SNAME()
				from inserted i, deleted d, EMCO e
				where i.EMCo = d.EMCo and i.Equipment = d.Equipment	and i.EMGroup = d.EMGroup and i.RevCode = d.RevCode and i.ORideRate <> d.ORideRate and
					e.EMCo = i.EMCo and e.AuditRevenueRateEquip = 'Y'
	END

IF UPDATE(Rate)
	BEGIN
		insert into bHQMA select 'bEMRH', 'EM Company: ' + convert(char(3), i.EMCo) + ' Equipment: ' + i.Equipment +
					' EMGroup: ' + convert(varchar(3),i.EMGroup) + ' RevCode: ' + i.RevCode,
					i.EMCo, 'C', 'Rate', d.Rate, i.Rate, getdate(), SUSER_SNAME()
				from inserted i, deleted d, EMCO e
				where i.EMCo = d.EMCo and i.Equipment = d.Equipment	and i.EMGroup = d.EMGroup and i.RevCode = d.RevCode and i.Rate <> d.Rate and
					e.EMCo = i.EMCo and e.AuditRevenueRateEquip = 'Y'
	END
   
   

return
   
error:
	select @errmsg = isnull(@errmsg,'') + ' - cannot update EMRH'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
   
   







   
   
  
 




GO

CREATE UNIQUE CLUSTERED INDEX [biEMRH] ON [dbo].[bEMRH] ([EMCo], [Equipment], [RevCode], [EMGroup]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMRH] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMRH].[UpdtHrMeter]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMRH].[PostWorkUnits]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMRH].[ORideRate]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bEMRH].[AllowPostOride]'
GO
