CREATE TABLE [dbo].[bEMHC]
(
[EMCo] [dbo].[bCompany] NOT NULL,
[Component] [dbo].[bEquip] NOT NULL,
[Seq] [int] NOT NULL,
[ComponentOfEquip] [dbo].[bEquip] NOT NULL,
[DateXferOn] [dbo].[bDate] NOT NULL,
[DateXferOff] [dbo].[bDate] NULL,
[MasterEquipHoursOn] [dbo].[bHrs] NULL,
[MasterEquipHoursOff] [dbo].[bHrs] NULL,
[MasterEquipMilesOn] [dbo].[bHrs] NULL,
[MasterEquipMilesOff] [dbo].[bHrs] NULL,
[MasterEquipFuelOn] [dbo].[bUnits] NULL,
[MasterEquipFuelOff] [dbo].[bUnits] NULL,
[ComponentHoursOn] [dbo].[bHrs] NULL,
[ComponentHoursOff] [dbo].[bHrs] NULL,
[ComponentMilesOn] [dbo].[bHrs] NULL,
[ComponentMilesOff] [dbo].[bHrs] NULL,
[ComponentFuelOn] [dbo].[bUnits] NULL,
[ComponentFuelOff] [dbo].[bUnits] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Reason] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bEMHC] ADD
CONSTRAINT [FK_bEMHC_bEMEM_Component] FOREIGN KEY ([EMCo], [Component]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment])
ALTER TABLE [dbo].[bEMHC] ADD
CONSTRAINT [FK_bEMHC_bEMEM_ComponentOfEquip] FOREIGN KEY ([EMCo], [ComponentOfEquip]) REFERENCES [dbo].[bEMEM] ([EMCo], [Equipment])
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   /****** Object:  Trigger dbo.btEMHCd    Script Date: 3/5/2002 1:25:42 PM ******/
    
    /****** Object:  Trigger dbo.btEMHCd    Script Date: 2/25/2002 4:06:48 PM ******/
    
    /****** Object:  Trigger dbo.btEMHCd    Script Date: 2/8/2002 4:04:16 PM ******/
    /****** Object:  Trigger dbo.btEMHCd    Script Date: 1/21/2002 2:46:31 PM ******/
    
     /****** Object:  Trigger dbo.btEMHCd    Script Date: 12/21/2001 11:08:39 AM ******/
     CREATE         trigger [dbo].[btEMHCd] on [dbo].[bEMHC] for Delete
      as
      

/**************************************************************
      * Created: 3/15/00 ae
      *  Modified by: JM 1-2-02 - Changed Equipment to Component
      *		JM 2-8-02 - On deletion will null out following fields in this Components most prior Seq,
      *		making that Seq the most recent Seq:
      *			bEMHC.DateXferOff
      *			bEMHC.MasterEquipHoursOff
      *			bEMHC.MasterEquipMilesOff
      *			bEMHC.MasterEquipFuelOff
      *			bEMHC.ComponentHoursOff
      *			bEMHC.ComponentMilesOff
      *			bEMHC.ComponentFuelOff
      *		JM 10-09-02 - Added isnulls = '' for DateXferOn/Off in HQMA insert statement since this was
      *		throwing an error from an Equipment Master deletion of a Component because these values were null
      *		 TV 02/11/04 - 23061 added isnulls
      *
      *
      **************************************************************/
      declare @errmsg varchar(255),
    	@validcnt int,
    	@validcnt2 int,
    	@errno int,
    	@numrows int,
    	@nullcnt int,
    	@rcode int,
    	@seq int,
    	@emco bCompany,
    	@component bEquip
    
      select @numrows = @@rowcount
      if @numrows = 0 return
      set nocount on
    
    /*Need to do this in a cursor since each operation looks for a specific sequence to update per its own sequence.  */
    select @emco = min(EMCo) from inserted
    while @emco is not null
    	begin
    	select @component = min(Component) from inserted where EMCo = @emco
    	while @component is not null
    		begin
    		/* Update last sequence's 'Offs' to null, making it the most recent record */
    		select @seq = Max(c.Seq) from bEMHC c, deleted d where c.EMCo = d.EMCo and c.Component = d.Component
    		select @emco = EMCo, @component = Component from deleted
    		update bEMHC
    		set DateXferOff = null, MasterEquipHoursOff = null, MasterEquipMilesOff = null, MasterEquipFuelOff = null,
    			ComponentHoursOff = null, ComponentMilesOff = null, ComponentFuelOff = null
    		where EMCo = @emco and Component = @component and Seq = @seq
    
    		select @component = min(Component)
    		from inserted where EMCo = @emco and Component > @component
    		end
    
    	select @emco = min(EMCo) from inserted where EMCo > @emco
    	end
    
     /* Audit inserts */
     if not exists (select * from deleted i, EMCO e
      	where i.EMCo = e.EMCo and e.AuditCompXfer = 'Y')
      	return
    insert into bHQMA select 'bEMHC', 'EM Company: ' + convert(char(3),i.EMCo) + ' Component: ' + convert(varchar(10),i.Component) +
      	' ComponentOfEquip: ' + convert(varchar(20),i.ComponentOfEquip) + ' DateXferOn: ' + convert(varchar(10),isnull(i.DateXferOn,'')) +
         	' DateXferOff: ' + convert(varchar(10),isnull(i.DateXferOff,'')),
      	i.EMCo, 'D', '', null, null, getdate(), SUSER_SNAME()
      	from deleted i,  EMCO e
         where e.EMCo = i.EMCo and e.AuditCompXfer = 'Y'
    
      Return
      error:
      select @errmsg = (isnull(@errmsg,'') + ' - cannot insert audit record! ')
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
    
    
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   
   CREATE              trigger [dbo].[btEMHCi] on [dbo].[bEMHC] for insert as
    

/*--------------------------------------------------------------
     *
     *  Insert trigger for EMHC
     *  Created By:  ae  03/15/00
     *  Modified by: JM 1-2-02 - Changed Equipment to Component
     *		JM 1-8-02 - Added update of meters 'Offs' to prior transaciton.
     *		JM 2-8-02 - Added update of new ComponentOfEquip to bEMEM.CompOfEquip
     *		JM 2-25-02 - Corrected update of prior record's MasterEquip Off's to come from On's in EMHC rather
     *		than currents from EMEM.
     *		JM 5/7/02 - Corrected update of prior record to current meter readings from EMEM for Component and
     *		Master Equip rather than values from EMHC.
     *		JM 10-09-02 - Added isnulls = '' for DateXferOn/Off in HQMA insert statement since this was
     *		throwing an error from an Equipment Master insertion of a Component because these values were null
     *		 TV 02/11/04 - 23061 added isnulls
     *--------------------------------------------------------------*/
     /***  basic declares for SQL Triggers ****/
    declare @numrows int,
    	@oldnumrows int,
    	@errmsg varchar(255),
    	@bemsg varchar(15),
    	@errno tinyint,
    	@audit bYN,
    	@validcnt int,
    	@nullcnt int,
    	@rcode int
    
    declare 	@ComponentOfEquip bEquip,
    	@ComponentHoursOff bHrs,
    	@ComponentMilesOff bHrs,
    	@ComponentFuelOff bHrs,
    	@EMCo bCompany,
    	@Component bEquip,
    	@DateXferOff bDate,
    	@Seq int,	
    	@LastTransSeq int
    
    declare @MasterEquipOdoReading bHrs,
    	@MasterEquipReplacedOdoReading bHrs,
    	@MasterEquipHourReading bHrs,
    	@MasterEquipReplacedHourReading bHrs,
    	@MasterEquipFuelUsed bUnits,
    	@MasterEquip bEquip,
    	@ComponentOdoReading bHrs,
    	@ComponentReplacedOdoReading bHrs,
    	@ComponentHourReading bHrs,
    	@ComponentReplacedHourReading bHrs,
    	@ComponentFuelUsed bUnits
    
    select @numrows = @@rowcount
    if @numrows = 0 return
    set nocount on
    
    
    /* Update Component and MasterEquip Meter Off's on most recent prior record for Component.
    Also update bEMEM.CompOfEquipment. Need to do this in a cursor since each operation looks
     for a specific sequence to update per its own sequence.  */
    select @EMCo = min(EMCo) from inserted
    while @EMCo is not null
    	begin
    
    	select @Component = min(Component) from inserted where EMCo = @EMCo
    	while @Component is not null
    		begin
    
    		select @Seq = min(Seq) from inserted where EMCo = @EMCo and Component = @Component
    		while @Seq is not null
    			begin
    
    			/* Find the last transaction for this EMCo/Component. */
    			select @LastTransSeq = Max(Seq) from bEMHC
    			where EMCo = @EMCo and Component = @Component and Seq < @Seq
    	
    			/* Read the Prior Master Equip's current meter info from bEMEM */
    			select @MasterEquip = ComponentOfEquip from bEMHC where EMCo = @EMCo and Component = @Component and Seq = @LastTransSeq
    			select @MasterEquipOdoReading = OdoReading, @MasterEquipReplacedOdoReading = ReplacedOdoReading,
    				@MasterEquipHourReading = HourReading, @MasterEquipReplacedHourReading = ReplacedHourReading,
    				@MasterEquipFuelUsed = FuelUsed from bEMEM where EMCo = @EMCo and Equipment = @MasterEquip
    	
    			/* Read the Component's current meter info */
    			select @ComponentOdoReading = OdoReading, @ComponentReplacedOdoReading = ReplacedOdoReading,
    				@ComponentHourReading = HourReading, @ComponentReplacedHourReading = ReplacedHourReading,
    				@ComponentFuelUsed = FuelUsed from bEMEM where EMCo = @EMCo and Equipment = @Component
    	
    			/* Update the MasterEquip and Component's Off's in the last transaction. */
    			if @LastTransSeq is not null
    				update bEMHC
    				set DateXferOff = (select DateXferOn from inserted where EMCo = @EMCo and Component = @Component and Seq = @Seq),
    					MasterEquipHoursOff = @MasterEquipHourReading + @MasterEquipReplacedHourReading,
    					MasterEquipMilesOff = @MasterEquipOdoReading + @MasterEquipReplacedOdoReading,
    					MasterEquipFuelOff = @MasterEquipFuelUsed,
    					ComponentHoursOff = @ComponentHourReading + @ComponentReplacedHourReading,
    					ComponentMilesOff = @ComponentOdoReading + @ComponentReplacedHourReading,
    					ComponentFuelOff = @ComponentFuelUsed
    				where EMCo = @EMCo and Component = @Component and Seq = @LastTransSeq
    	
    			/* Update bEMEM.CompOfEquip */
    			update bEMEM
    			set CompOfEquip = (select ComponentOfEquip from inserted where EMCo = @EMCo and Component = @Component and Seq = @Seq)
    			where EMCo = @EMCo and Equipment = @Component
    
    			/* Get next Seq */
    			select @Seq = min(Seq) from inserted where EMCo = @EMCo and Component = @Component and Seq > @Seq
    			end
    
    		/* Get next Component */
    		select @Component = min(Component) from inserted where EMCo = @EMCo and Component > @Component
    		end
    
    	/* Get next EMCo */
    	select @EMCo = min(EMCo) from inserted where EMCo > @EMCo
    	end
    
    /* Audit inserts */
    if not exists (select * from inserted i, EMCO e
     	where i.EMCo = e.EMCo and e.AuditCompXfer = 'Y')
     	return
   
    insert into bHQMA select 'bEMHC', 'EM Company: ' + convert(char(3),i.EMCo) + ' Component: ' + convert(varchar(10),i.Component) +
     	' ComponentOfEquip: ' + convert(varchar(20),i.ComponentOfEquip) + ' DateXferOn: ' + convert(varchar(10),isnull(i.DateXferOn,'')) +
        	' DateXferOff: ' + convert(varchar(10),isnull(i.DateXferOff,'')),
     	i.EMCo, 'A', '', null, null, getdate(), SUSER_SNAME()
     	from inserted i,  EMCO e
    where e.EMCo = i.EMCo and e.AuditCompXfer = 'Y'
    
    return
    
    error:
       select @errmsg = isnull(@errmsg,'') + ' - cannot insert into EMHC'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
    
    
    
    
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   
   
   CREATE             trigger [dbo].[btEMHCu] on [dbo].[bEMHC] for update as
    
    

/*--------------------------------------------------------------
    *
    *  Insert trigger for EMHC
    *  Created By:  ae 03/3/00
    *  Modified by: JM 1-2-02 - Changed Equipment to Component
    *		JM 1-9-02 - Added update of meter Off's on most recent prior record for Component.
    *		JM 2-1102 - Added update to bEMEM of Equip and Component meter info
    *		JM 2-25-02 - Corrected update of prior record's MasterEquip Off's to come from On's in EMHC rather
    *		than currents from EMEM.
    *		JM 5/7/02 - Corrected update of prior record to current meter readings from EMEM for Component and
    *		Master Equip rather than values from EMHC.
    *		 TV 02/11/04 - 23061 added isnulls
    *--------------------------------------------------------------*/
    
    declare @audit bYN,
    	@bemsg varchar(15),
    	@errmsg varchar(255),
    	@errno tinyint,
    	@nullcnt int,
    	@numrows int,
    	@oldnumrows int,
    	@rcode int,
    	@validcnt int
    
    declare	@EMCo bCompany,
    	@Component bEquip,
    	@DateXferOff bDate,
    	@LastTransSeq int,
    	@Seq int,
    	@ComponentOfEquip bEquip
    
    declare @MasterEquipOdoReading bHrs,
    	@MasterEquipReplacedOdoReading bHrs,
    	@MasterEquipHourReading bHrs,
    	@MasterEquipReplacedHourReading bHrs,
    	@MasterEquipFuelUsed bUnits,
    	@MasterEquip bEquip,
    	@ComponentOdoReading bHrs,
    	@ComponentReplacedOdoReading bHrs,
    	@ComponentHourReading bHrs,
    	@ComponentReplacedHourReading bHrs,
    	@ComponentFuelUsed bUnits
    
    select @numrows = @@rowcount
    if @numrows = 0 return
    
    set nocount on
    
    /* If updating any of the meters On, update prior transfer's Offs (do them all even though they might
    not have changed for performance) */
    if update(ComponentHoursOn) or update(ComponentMilesOn) or update(ComponentFuelOn)
     or update(MasterEquipHoursOn) or update(MasterEquipMilesOn) or update(MasterEquipFuelOn)
    	begin
    	/* Update Component and MasterEquip Meter Off's on most recent prior record for Component.
    	Also update bEMEM.CompOfEquipment. Need to do this in a cursor since each operation looks
    	 for a specific sequence to update per its own sequence.  */
    	select @EMCo = min(EMCo) from inserted
    	while @EMCo is not null
    		begin
    	
    		select @Component = min(Component) from inserted where EMCo = @EMCo
    		while @Component is not null
    			begin
    	
    			select @Seq = min(Seq) from inserted where EMCo = @EMCo and Component = @Component
    			while @Seq is not null
    				begin
    	
    				/* Find the last transaction for this EMCo/Component. */
    				select @LastTransSeq = Max(Seq) from bEMHC
    				where EMCo = @EMCo and Component = @Component and Seq < @Seq
    		
    				/* Read the Prior Master Equip's current meter info from bEMEM */
    				select @MasterEquip = ComponentOfEquip from bEMHC where EMCo = @EMCo and Component = @Component and Seq = @LastTransSeq
    				select @MasterEquipOdoReading = OdoReading, @MasterEquipReplacedOdoReading = ReplacedOdoReading,
    					@MasterEquipHourReading = HourReading, @MasterEquipReplacedHourReading = ReplacedHourReading,
    					@MasterEquipFuelUsed = FuelUsed from bEMEM where EMCo = @EMCo and Equipment = @MasterEquip
    		
    				/* Read the Component's current meter info */
    				select @ComponentOdoReading = OdoReading, @ComponentReplacedOdoReading = ReplacedOdoReading,
    					@ComponentHourReading = HourReading, @ComponentReplacedHourReading = ReplacedHourReading,
    					@ComponentFuelUsed = FuelUsed from bEMEM where EMCo = @EMCo and Equipment = @Component
    		
    				/* Update the MasterEquip and Component's Off's in the last transaction. */
    				if @LastTransSeq is not null
    					update bEMHC
    					set DateXferOff = (select DateXferOn from inserted where EMCo = @EMCo and Component = @Component and Seq = @Seq),
    						MasterEquipHoursOff = @MasterEquipHourReading + @MasterEquipReplacedHourReading,
    						MasterEquipMilesOff = @MasterEquipOdoReading + @MasterEquipReplacedOdoReading,
    						MasterEquipFuelOff = @MasterEquipFuelUsed,
    						ComponentHoursOff = @ComponentHourReading + @ComponentReplacedHourReading,
    						ComponentMilesOff = @ComponentOdoReading + @ComponentReplacedHourReading,
    						ComponentFuelOff = @ComponentFuelUsed
    					where EMCo = @EMCo and Component = @Component and Seq = @LastTransSeq
    		
    				/* Update bEMEM.CompOfEquip */
    				update bEMEM
    				set CompOfEquip = (select ComponentOfEquip from inserted where EMCo = @EMCo and Component = @Component and Seq = @Seq)
    				where EMCo = @EMCo and Equipment = @Component
    	
    				/* Get next Seq */
    				select @Seq = min(Seq) from inserted where EMCo = @EMCo and Component = @Component and Seq > @Seq
    				end
    	
    			/* Get next Component */
    			select @Component = min(Component) from inserted where EMCo = @EMCo and Component > @Component
    			end
    	
    		/* Get next EMCo */
    		select @EMCo = min(EMCo) from inserted where EMCo > @EMCo
    		end
    	end
    
    /* If updating ComponentOfEquip, update bEMEM.CompOfEquip */
    if update(ComponentOfEquip)
    	begin
    	/* Read the Component's meter info */
    	select @EMCo = i.EMCo, @Component = i.Component, @ComponentOfEquip = i.ComponentOfEquip from inserted i
    	/* Update bEMEM */
    	update bEMEM set CompOfEquip = @ComponentOfEquip where EMCo = @EMCo and Equipment = @Component
    	end
    
    /* Audit inserts */
    if not exists (select * from inserted i, EMCO e where i.EMCo = e.EMCo and e.AuditCompXfer = 'Y')
    	return
    
    if update(DateXferOn)
    	begin
    	insert into bHQMA select 'bEMHC', 'EM Company: ' + convert(char(3),i.EMCo) + ' Component: ' + convert(varchar(10),i.Component) +
    		' ComponentOfEquip: ' + convert(varchar(20),i.ComponentOfEquip) + ' DateXferOn: ' + convert(varchar(10),i.DateXferOn) +
    		' DateXferOff: ' + convert(varchar(10),isnull(i.DateXferOff,'')),
    		i.EMCo, 'C', 'DateXferOn', d.DateXferOn, i.DateXferOn, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.Component = d.Component and i.ComponentOfEquip = d.ComponentOfEquip
    		and e.EMCo = i.EMCo and e.AuditCompXfer = 'Y'
    	end
    
    if update(DateXferOff)
    	begin
    	insert into bHQMA select 'bEMHC', 'EM Company: ' + convert(char(3),i.EMCo) + ' Component: ' + convert(varchar(10),i.Component) +
    		' ComponentOfEquip: ' + convert(varchar(20),i.ComponentOfEquip) + ' DateXferOn: ' + convert(varchar(10),isnull(i.DateXferOn,'')) +
    		' DateXferOff: ' + convert(varchar(10),isnull(i.DateXferOff,'')),
    		i.EMCo, 'C', 'DateXferOff', d.DateXferOff, i.DateXferOff, getdate(), SUSER_SNAME()
    	from inserted i, deleted d, EMCO e
    	where i.EMCo = d.EMCo and i.Component = d.Component and i.ComponentOfEquip = d.ComponentOfEquip
    		and e.EMCo = i.EMCo and e.AuditCompXfer = 'Y'
    	end
    
    return
    error:
    	select @errmsg = isnull(@errmsg,'') + ' - cannot update EMHC'
    	RAISERROR(@errmsg, 11, -1);
    	rollback transaction
    
    
    
   
   
   
   
  
 



GO
CREATE UNIQUE CLUSTERED INDEX [biEMHC] ON [dbo].[bEMHC] ([EMCo], [Component], [Seq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bEMHC] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
