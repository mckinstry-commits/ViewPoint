CREATE TABLE [dbo].[bPMUC]
(
[Template] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[CostType] [dbo].[bJCCType] NOT NULL,
[CreateCostType] [dbo].[bJCCType] NOT NULL,
[UseUM] [dbo].[bYN] NOT NULL,
[UseUnits] [dbo].[bYN] NOT NULL,
[UseHours] [dbo].[bYN] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/****** Object:  Trigger dbo.btPMUCi    Script Date: 8/28/99 9:38:03 AM ******/
CREATE trigger [dbo].[btPMUCi] on [dbo].[bPMUC] for INSERT as

/*--------------------------------------------------------------
 *  Insert trigger for PMUC
 *  Created By:	GF 06/03/99
 *	Modified By:  JayR 03/28/2012 TK-00000 Change to use FKs for validation
 *
 *--------------------------------------------------------------*/
declare @numrows int, @validcnt int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on 


-- -- --  Validate Cost Type
select @validcnt = count(*) from inserted i where exists(select * from bJCCT r with (nolock) where r.CostType=i.CostType)
-- -- -- select @validcnt = count(*) from bJCCT r JOIN inserted i ON i.CostType = r.CostType
if @validcnt <> @numrows
	begin
	RAISERROR('Cost Type is Invalid  - cannot insert into PMUC', 11, -1)
	ROLLBACK TRANSACTION
	RETURN
	end

-- -- -- validate create cost type
select @validcnt = count(*) from inserted i where exists(select * from bJCCT r with (nolock) where r.CostType=i.CreateCostType)
-- -- -- select @validcnt = count(*) from bJCCT r JOIN inserted i ON i.CreateCostType = r.CostType
if @validcnt <> @numrows
	begin
	RAISERROR('Create Cost Type is Invalid  - cannot insert into PMUC', 11, -1)
	ROLLBACK TRANSACTION
	RETURN
	end

RETURN 






GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMUC] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMUC] ON [dbo].[bPMUC] ([Template], [PhaseGroup], [CostType], [CreateCostType]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMUC] WITH NOCHECK ADD CONSTRAINT [FK_bPMUC_bPMUT] FOREIGN KEY ([Template]) REFERENCES [dbo].[bPMUT] ([Template]) ON DELETE CASCADE
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMUC].[UseUM]'
GO
EXEC sp_bindefault N'[dbo].[bdNo]', N'[dbo].[bPMUC].[UseUM]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMUC].[UseUnits]'
GO
EXEC sp_bindefault N'[dbo].[bdNo]', N'[dbo].[bPMUC].[UseUnits]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMUC].[UseHours]'
GO
EXEC sp_bindefault N'[dbo].[bdNo]', N'[dbo].[bPMUC].[UseHours]'
GO
