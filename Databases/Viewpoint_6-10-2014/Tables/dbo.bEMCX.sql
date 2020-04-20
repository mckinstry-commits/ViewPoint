CREATE TABLE [dbo].[bEMCX]
(
[EMGroup] [dbo].[bGroup] NOT NULL,
[CostType] [dbo].[bEMCType] NOT NULL,
[CostCode] [dbo].[bCostCode] NOT NULL,
[UM] [dbo].[bUM] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMCXd    Script Date: 8/28/99 9:37:14 AM ******/
   CREATE     trigger [dbo].[btEMCXd] on [dbo].[bEMCX] for delete as
   
   

/*--------------------------------------------------------------
   *
   *  delete trigger for EMCX
   *  Created By:  bc  04/17/99
   *            
   *  Modified by: 03/06/03 TV 20516 - Check that Detail amounts are zero before delete
   *				TV 02/11/04 - 23061 added isnulls
   *
   *--------------------------------------------------------------*/
   
   /***  basic declares for SQL Triggers ****/
   declare @numrows int, @oldnumrows int, @errmsg varchar(255), @bemsg varchar(15),
   @errno tinyint, @audit bYN, @validcnt int, @nullcnt int,
   @rcode int, @EMCo bCompany, @EMGroup bGroup, @CostCode bCostCode, @CostType bEMCType
   
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   
   --Needs to Check EMMC for detail. Not just header. TV 03/06/03 20516
   if exists(select * from deleted d 
   join EMCH e on d.EMGroup = e.EMGroup and d.CostCode = e.CostCode and d.CostType = e.CostType
   join EMMC m on m.EMCo = e.EMCo and m.EMGroup = e.EMGroup and m.CostCode = e.CostCode and m.CostType = e.CostType
   where e.EMGroup = d.EMGroup and e.CostCode = d.CostCode and  e.CostType = d.CostType
   and (m.ActUnits <> 0 or m.ActCost <> 0 or m.EstUnits <> 0 or m.EstCost <> 0))
       begin
       select @errmsg = 'Records exist in Cost Header / Detail '
       goto error
       end
   else
       begin
       declare  bcCostTypeDelete cursor
       for
       select e.EMCo, d.EMGroup, d.CostCode, d.CostType
       from deleted d 
       join EMCH e on d.EMGroup = e.EMGroup and d.CostCode = e.CostCode and d.CostType = e.CostType
       
       open bcCostTypeDelete
       fetchnext:
       fetch next from bcCostTypeDelete into @EMCo, @EMGroup, @CostCode, @CostType
       if @@fetch_status <> 0 goto fetchend
       
       exec @rcode = bspEMCostTypeDelete @EMCo, @EMGroup, @CostCode, @CostType, @errmsg output  
       
       goto fetchnext
       fetchend:
       close bcCostTypeDelete
       deallocate bcCostTypeDelete
       end
   
   return
   
   error:
   select @errmsg = isnull(@errmsg,'') + ' - cannot delete from EMCX'
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 

   CREATE  trigger [dbo].[btEMCXi] on [dbo].[bEMCX] for insert as

/*--------------------------------------------------------------
    *
    *  Insert trigger for EMCX
    *  Created By:  bc  04/17/99
    *  Modified by: TV 02/11/04 - 23061 added isnulls
	*				GF 05/05/2013 TFS-49039
    *
    *
    *--------------------------------------------------------------*/
   
    /***  basic declares for SQL Triggers ****/
   declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int, @rcode int
   
   
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
   

   
   /* Validate UM */
   select @validcnt = count(*) from bHQUM r JOIN inserted i ON i.UM = r.UM
   if @validcnt <> @numrows
      begin
      select @errmsg = 'UM is Invalid '
      goto error
      end
   
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMCX'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btEMCXu    Script Date: 8/28/99 9:37:14 AM ******/
CREATE  trigger [dbo].[btEMCXu] on [dbo].[bEMCX] for update as
/*--------------------------------------------------------------
*  Update trigger for EMCX
*  Created By:     bc  04/17/99
*  Modified by:    bc  07/13/00 - added section to update EMCH and EMMC when the UM is changed
*					TV 02/11/04 - 23061 added isnulls
*					GP 10/30/08 - Issue 130814, trigger performance changes.
*					GP 12/21/09 - Issue 137143, fixed endless loop from update_check.
*
*
*--------------------------------------------------------------*/
declare @numrows int, @errmsg varchar(255), @validcnt int, @nullcnt int,
		@emgroup bGroup, @costcode bCostCode, @costtype bEMCType, @cxum bUM, 
		@emco bCompany, @units bUnits

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on

/* No change to Key Fields */
if update(CostCode) or update(CostType) or update(EMGroup)
	begin
	select @errmsg = 'Primary key fields may not be changed '
	goto error
	end

if update(UM)
	BEGIN

	select @validcnt = count(*) from inserted i join bHQUM u on i.UM = u.UM
	if @validcnt <> @numrows
		begin
		select @errmsg = 'Invalid UM.'
		goto error
		end

	 end
		
	------------------
	-- CURSOR BEGIN --
	------------------
	if @numrows = 1
		begin
		select @emgroup = EMGroup, @costcode = CostCode, @costtype = CostType, @cxum = UM
		from inserted
		end
	else
		begin
		declare bEMCX_update cursor LOCAL FAST_FORWARD
		for select EMGroup, CostCode, CostType, UM from inserted

		open bEMCX_update

		fetch next from bEMCX_update into @emgroup, @costcode, @costtype, @cxum

		if @@fetch_status <> 0
   			begin
   			select @errmsg = 'Cursor error'
   			goto error
			end
		end

		update_check:

		if exists(select top 1 1 from bEMCH with(nolock) where EMGroup = @emgroup 
					and CostCode = @costcode and CostType = @costtype)
			begin
            update bEMCH
            set UM = @cxum
            where EMGroup = @emgroup and CostCode = @costcode and CostType = @costtype
			end
		else
			begin
			goto next_row
			end
		
		begin;

			-- CTE to hold bEMCD summed Units to update to bEMMC.
			with cteEMCD(EMCo, Mth, EMGroup, Equipment, CostCode, EMCostType, Units) as
				(select EMCo, Mth, EMGroup, Equipment, CostCode, EMCostType,
					'Units' = case when UM=@cxum then sum(Units) else 0 end
				from bEMCD with(nolock) 
				where EMGroup = @emgroup and CostCode = @costcode 
				and EMCostType = @costtype
			group by EMCo, Mth, EMGroup, Equipment, CostCode, EMCostType, UM)

			update bEMMC
				set ActUnits = d.Units
			from bEMMC c join cteEMCD d on c.EMCo = d.EMCo and c.Equipment = d.Equipment
				and c.EMGroup = d.EMGroup and c.CostCode = d.CostCode and c.CostType = d.EMCostType
				and c.Month = d.Mth

		end;

		next_row:

		if @numrows > 1
			begin

			fetch next from bEMCX_update into @emgroup, @costcode, @costtype, @cxum

			if @@fetch_status = 0
				begin
   				goto update_check
				end
   			else
   				begin
   				close bEMCX_update
   				deallocate bEMCX_update
   				end

			end
	
	----------------
	-- CURSOR END --
	----------------

----     select @emgroup = min(EMGroup) from inserted
----     while @emgroup is not null
----       begin
----       select @costcode = min(CostCode) from inserted where EMGroup = @emgroup
----       while @costcode is not null
----         begin
----         select @costtype = min(CostType) from inserted where EMGroup = @emgroup and CostCode = @costcode
----         while @costtype is not null
----           begin
----           select @cxum = null
----   		select @cxum = UM
----   		from inserted
----   		where EMGroup = @emgroup and CostCode = @costcode and CostType = @costtype
----   
----           if @cxum is null
----             begin
----             select @errmsg = 'UM cannot be null. '
----             goto error
----             end
   
----           if exists(select * from EMCH where EMGroup=@emgroup and CostCode=@costcode and CostType=@costtype)
----             Begin
----             update EMCH
----             set UM = @cxum
----             where EMGroup=@emgroup and CostCode=@costcode and CostType=@costtype
   
--             select @emco = min(EMCo)
--             from EMCD
--             where EMGroup=@emgroup and CostCode=@costcode and EMCostType=@costtype
--             while @emco is not null
--               begin
--               select @mth = min(Mth)
--               from EMCD
--               where EMCo=@emco and EMGroup=@emgroup and CostCode=@costcode and EMCostType=@costtype
--               while @mth is not null
--                 begin
--   
--                 /* clear out the values in EMMC for all pieces of equipment before recacluating for the new UM */
--                 Update bEMMC
--                 set ActUnits = 0, ActCost = 0
--                 where EMCo=@emco and EMGroup=@emgroup and CostCode=@costcode and CostType=@costtype and Month=@mth
--   
--                 select @emtrans = min(EMTrans)
--                 from EMCD
--                 where EMCo=@emco and Mth=@mth and EMGroup=@emgroup and CostCode=@costcode and EMCostType=@costtype
--                 while @emtrans is not null
--                   begin
--   
--                   select @cdum = null, @units = 0, @dollars = 0
--                   select @equipment = Equipment, @cdum = UM, @units = Units, @dollars = Dollars
--                   from EMCD
--                   where EMCo = @emco and Mth = @mth and EMTrans = @emtrans
--   
--                   /* if EMCX.UM is not the equal to EMCD.UM then zero out the units in EMMC */
--   		        if @cxum <> @cdum
--      		          begin
--                     select @units=0
--     		          end
--   
--                   Update bEMMC
--                   set ActUnits = ActUnits + @units, ActCost = ActCost + @dollars
--                   where EMCo=@emco and Equipment=@equipment and EMGroup=@emgroup and CostCode=@costcode and CostType=@costtype and Month=@mth
--   
--                   select @emtrans = min(EMTrans)
--                   from EMCD
--                   where EMCo=@emco and Mth=@mth and EMGroup=@emgroup and CostCode=@costcode and EMCostType=@costtype and EMTrans > @emtrans
--                   end
--   
--                 select @mth = min(Mth)
--                 from EMCD
--                 where EMCo=@emco and EMGroup=@emgroup and CostCode=@costcode and EMCostType=@costtype and Mth > @mth
--                 end
--   
--               select @emco = min(EMCo)
--               from EMCD
--               where EMGroup=@emgroup and CostCode=@costcode and EMCostType=@costtype and EMCo > @emco
--               end
--             End
   
----           select @costtype = min(CostType) from inserted where EMGroup = @emgroup and CostCode = @costcode and CostType > @costtype
----           end
----         select @costcode = min(CostCode) from inserted where EMGroup = @emgroup and CostCode > @costcode
----         end
----       select @emgroup = min(EMGroup) from inserted where EMGroup > @emgroup
----       end
----     END
   
   return
   
   error:
      select @errmsg = isnull(@errmsg,'') + ' - cannot udpate EMCX'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMCX] ON [dbo].[bEMCX] ([EMGroup], [CostType], [CostCode]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bEMCX] WITH NOCHECK ADD CONSTRAINT [FK_bEMCX_bHQGP_EMGroup] FOREIGN KEY ([EMGroup]) REFERENCES [dbo].[bHQGP] ([Grp])
GO
ALTER TABLE [dbo].[bEMCX] WITH NOCHECK ADD CONSTRAINT [FK_bEMCX_bEMCC_CostCode] FOREIGN KEY ([EMGroup], [CostCode]) REFERENCES [dbo].[bEMCC] ([EMGroup], [CostCode])
GO
ALTER TABLE [dbo].[bEMCX] WITH NOCHECK ADD CONSTRAINT [FK_bEMCX_bEMCT_CostType] FOREIGN KEY ([EMGroup], [CostType]) REFERENCES [dbo].[bEMCT] ([EMGroup], [CostType])
GO
ALTER TABLE [dbo].[bEMCX] NOCHECK CONSTRAINT [FK_bEMCX_bHQGP_EMGroup]
GO
ALTER TABLE [dbo].[bEMCX] NOCHECK CONSTRAINT [FK_bEMCX_bEMCC_CostCode]
GO
ALTER TABLE [dbo].[bEMCX] NOCHECK CONSTRAINT [FK_bEMCX_bEMCT_CostType]
GO
