CREATE TABLE [dbo].[bHRSP]
(
[HRCo] [dbo].[bCompany] NOT NULL,
[HRRef] [dbo].[bHRRef] NOT NULL,
[EffectiveDate] [dbo].[bDate] NOT NULL,
[ReasonSeq] [int] NOT NULL,
[ReasonCode] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[PctIncrease] [dbo].[bPct] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btAPVAi    Script Date: 8/28/99 9:36:59 AM ******/
   CREATE   trigger [dbo].[btHRSPd] on [dbo].[bHRSP] for DELETE as
   

/*-----------------------------------------------------------------
    *  Created: kb 2/25/3
    *  Modified: 
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   declare @hrco bCompany, @hrref bHRRef, @effectivedate bDate, 
     @oldsalary bDollar, @pctincrease bPct
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   -- =============================================
   -- Declare and using a local fast_forward cursor
   -- =============================================
   declare bcHRSP cursor local fast_forward for
   
   select i.HRCo, i.HRRef, i.EffectiveDate, h.OldSalary, 
   sum(i.PctIncrease)
   from bHRSP i
   join bHRSH h on h.HRCo = i.HRCo and h.HRRef = i.HRRef 
   and h.EffectiveDate = i.EffectiveDate
   where h.CalcYN = 'Y' and i.HRCo = 1 and i.HRRef = 10
   group by i.HRCo, i.HRRef, i.EffectiveDate, h.OldSalary, h.NewSalary
   
   
   
   OPEN bcHRSP
   
   FETCH NEXT FROM bcHRSP INTO @hrco, @hrref, @effectivedate, @oldsalary,
     @pctincrease
   WHILE (@@fetch_status <> -1)
   BEGIN
   	IF (@@fetch_status <> -2)
   	BEGIN
   	update bHRSH set NewSalary = OldSalary * (1+@pctincrease)
   	  from bHRSH where HRCo = @hrco and HRRef = @hrref 
   	  and EffectiveDate = @effectivedate
   	END
   	FETCH NEXT FROM bcHRSP INTO @hrco, @hrref, @effectivedate, @oldsalary,
     @pctincrease
   END
   
   CLOSE bcHRSP
   DEALLOCATE bcHRSP
   
   return
   error:
   	select @errmsg = @errmsg + ' - cannot insert HR Resource Salary History Detail!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btAPVAi    Script Date: 8/28/99 9:36:59 AM ******/
   CREATE   trigger [dbo].[btHRSPi] on [dbo].[bHRSP] for INSERT as
   

/*-----------------------------------------------------------------
    *  Created: kb 2/25/3
    *  Modified: 
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   
   declare @hrco bCompany, @hrref bHRRef, @effectivedate bDate, 
     @oldsalary bDollar, @pctincrease bPct
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   
   -- =============================================
   -- Declare and using a local fast_forward cursor
   -- =============================================
   declare bcHRSP cursor local fast_forward for
   
   select i.HRCo, i.HRRef, i.EffectiveDate, h.OldSalary, 
   sum(i.PctIncrease)
   from bHRSP i
   join bHRSH h on h.HRCo = i.HRCo and h.HRRef = i.HRRef 
   and h.EffectiveDate = i.EffectiveDate
   where h.CalcYN = 'Y' and i.HRCo = 1 and i.HRRef = 10
   group by i.HRCo, i.HRRef, i.EffectiveDate, h.OldSalary, h.NewSalary
   
   
   
   OPEN bcHRSP
   
   FETCH NEXT FROM bcHRSP INTO @hrco, @hrref, @effectivedate, @oldsalary,
     @pctincrease
   WHILE (@@fetch_status <> -1)
   BEGIN
   	IF (@@fetch_status <> -2)
   	BEGIN
   	update bHRSH set NewSalary = OldSalary * (1+@pctincrease)
   	  from bHRSH where HRCo = @hrco and HRRef = @hrref 
   	  and EffectiveDate = @effectivedate
   	END
   	FETCH NEXT FROM bcHRSP INTO @hrco, @hrref, @effectivedate, @oldsalary,
     @pctincrease
   END
   
   CLOSE bcHRSP
   DEALLOCATE bcHRSP
   
   return
   error:
   	select @errmsg = @errmsg + ' - cannot insert HR Resource Salary History Detail!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   /****** Object:  Trigger dbo.btAPVAi    Script Date: 8/28/99 9:36:59 AM ******/
   CREATE   trigger [dbo].[btHRSPu] on [dbo].[bHRSP] for UPDATE as
   

/*-----------------------------------------------------------------
    *  Created: kb 2/25/3
    *  Modified: 
    */----------------------------------------------------------------
   declare @errmsg varchar(255), @numrows int, @validcnt int
   declare @hrco bCompany, @hrref bHRRef, @effectivedate bDate, 
     @oldsalary bDollar, @pctincrease bPct
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   -- =============================================
   -- Declare and using a local fast_forward cursor
   -- =============================================
   declare bcHRSP cursor local fast_forward for
   
   select i.HRCo, i.HRRef, i.EffectiveDate, h.OldSalary, 
   sum(i.PctIncrease)
   from bHRSP i
   join bHRSH h on h.HRCo = i.HRCo and h.HRRef = i.HRRef 
   and h.EffectiveDate = i.EffectiveDate
   where h.CalcYN = 'Y' and i.HRCo = 1 and i.HRRef = 10
   group by i.HRCo, i.HRRef, i.EffectiveDate, h.OldSalary, h.NewSalary
   
   
   
   OPEN bcHRSP
   
   FETCH NEXT FROM bcHRSP INTO @hrco, @hrref, @effectivedate, @oldsalary,
     @pctincrease
   WHILE (@@fetch_status <> -1)
   BEGIN
   	IF (@@fetch_status <> -2)
   	BEGIN
   	update bHRSH set NewSalary = OldSalary * (1+@pctincrease)
   	  from bHRSH where HRCo = @hrco and HRRef = @hrref 
   	  and EffectiveDate = @effectivedate
   	END
   	FETCH NEXT FROM bcHRSP INTO @hrco, @hrref, @effectivedate, @oldsalary,
     @pctincrease
   END
   
   CLOSE bcHRSP
   DEALLOCATE bcHRSP
   
   return
   error:
   	select @errmsg = @errmsg + ' - cannot insert HR Resource Salary History Detail!'
       	RAISERROR(@errmsg, 11, -1);
       	rollback transaction
   
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biHRSP] ON [dbo].[bHRSP] ([HRCo], [HRRef], [EffectiveDate], [ReasonSeq]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHRSP] ([KeyID]) ON [PRIMARY]
GO
