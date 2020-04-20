CREATE TABLE [dbo].[bHQMU]
(
[MatlGroup] [dbo].[bGroup] NOT NULL,
[Material] [dbo].[bMatl] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[Conversion] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bHQMU_Conversion] DEFAULT ((0)),
[Cost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bHQMU_Cost] DEFAULT ((0)),
[CostECM] [dbo].[bECM] NOT NULL,
[Price] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bHQMU_Price] DEFAULT ((0)),
[PriceECM] [dbo].[bECM] NOT NULL,
[PayDiscRate] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_bHQMU_PayDiscRate] DEFAULT ((0)),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
ALTER TABLE [dbo].[bHQMU] ADD
CONSTRAINT [CK_bHQMU_CostECM] CHECK (([CostECM]='E' OR [CostECM]='C' OR [CostECM]='M'))
ALTER TABLE [dbo].[bHQMU] ADD
CONSTRAINT [CK_bHQMU_PriceECM] CHECK (([PriceECM]='E' OR [PriceECM]='C' OR [PriceECM]='M'))
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   
   /****** Object:  Trigger dbo.btHQMUd    Script Date: 8/28/99 9:37:35 AM ******/
   CREATE   trigger [dbo].[btHQMUd] on [dbo].[bHQMU] for DELETE as
   

/*----------------------------------------------------------
    *  Created by:  ??
    *  Modified By: CMW 04/11/02 - Replaced NULL for HQMA.Company with MaterialGroup (issue # 16840).
    *               CMW 08/12/02 - Fixed string/integer problem (issue # 18249).
    *               CMW 08/16/02 - Fixed multiple entry problem (issue # 18279).
    *
    *	This trigger adds HQ Master Audit entry for all deletes
    *	in bHQMU (HQ Material Units of Measure)
    *
    *	No record validation is performed.
    *
    *	Audit deletions if any HQ Company using the Mat'l Group has the
    *	AuditMatl option set.
    */---------------------------------------------------------
   declare @errmsg varchar(255), @numrows int
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   /* Audit HQ Material U/M deletions */
   insert into bHQMA
       (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
   	select 'bHQMU', 'Matl. Group: ' + convert(varchar(3),d.MatlGroup) + ' Matl: ' + min(d.Material) + ' U/M: ' + min(d.UM), d.MatlGroup,
   		'D', null, null, null, getdate(), SUSER_SNAME()
   		from deleted d, bHQCO c
   		where d.MatlGroup = c.MatlGroup and c.AuditMatl = 'Y'
           group by d.MatlGroup
   
   return
   
   
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btHQMUi    Script Date: 8/28/99 9:37:35 AM ******/
   CREATE  trigger [dbo].[btHQMUi] on [dbo].[bHQMU] for INSERT as
   

declare @audit bYN, @cnt int, @co bCompany, @date bDate, @errmsg varchar(255),
   	@errno int, @field char(30), @key varchar(60), @material bMatl,
   	@matlgroup tinyint, @new varchar(30), @numrows int, @old varchar(30),
   	@rectype char(1), @stdum bUM, @tablename char(20), @um bUM, @user bVPUserName
   
   /*-----------------------------------------------------------------
    *  Created by:  ??
    *  Modified By: CMW 04/11/02 - Replaced NULL for HQMA.Company with MaterialGroup (issue # 16840).
    *               CMW 08/12/02 - Fixed string/integer problem (issue # 18249).
    *
    *	This trigger rejects insertion in bHQMU (Material Units of Measure)
    *	if any of the following error conditions exist:
    *
    *		Invalid UM vs bHQUM.UM
    *		Invalid Matl vs bHQMT.Material
    *		Exists as bHQMT.StdUM for bHQMT.MatlGroup/Material key value
    *
    *	Audit inserts if any HQ Company using the Mat'l Group has the AuditMatl
    *	option set.
    */----------------------------------------------------------------
   
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   if @numrows = 1
   	select @matlgroup = MatlGroup, @material = Material, @um = UM from inserted
   
   else
   	begin
   	/* use a cursor to process each inserted row */
   	declare bHQMU_insert cursor for select MatlGroup, Material, UM from inserted
   	open bHQMU_insert
   	fetch next from bHQMU_insert into @matlgroup, @material, @um
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   insert_check:
   	/* validate UM */
	--Issue 28325
	If @um = 'LS' 
		begin
   			select @errmsg = 'LS is invalid Material Unit of Measure'
   			goto error
   		end
		
   	exec @errno = bspHQUMVal @um, @errmsg output
   	if @errno <> 0 goto error
   
   	/* reject if std UM for this MatlGroup/Material */
   	select @stdum =StdUM from bHQMT where MatlGroup = @matlgroup and
   		Material = @material
   	if @@rowcount = 0
   		begin
   		select @errmsg = 'Invalid Material'
   		goto error
   		end
   
   	if @stdum = @um
   		begin
   		select @errmsg = 'Unit of Measure used as a Std U/M for this Material Group/Material'
   		goto error
   		end
   
   	/* add HQ Master Audit entry - see note in header re selection of @audit */
   	if exists(select * from bHQCO where MatlGroup = @matlgroup and AuditMatl = 'Y')
   		begin
   		select @tablename = 'bHQMU',
   				@key = 'MatlGroup: ' + convert(varchar(3), @matlgroup) +
   				', Material: ' + @material + ', UM: ' + @um,
   				@co = @matlgroup, @rectype = 'A',
   				@field = null, @old = null,
   				@new = null, @date = getdate(),
   				@user = SUSER_SNAME()
   		exec @errno = bspHQMAInsert @tablename,@key,@co,@rectype,
   				@field,@old,@new,@date,@user,@errmsg output
   		if @errno <> 0 goto error
   		end
   
   	if @numrows > 1
   		begin
   		fetch next from bHQMU_insert into @matlgroup, @material, @um
   		if @@fetch_status = 0
   			goto insert_check
   
   		else
   
   			begin
   			close bHQMU_insert
   			deallocate bHQMU_insert
   			end
   		end
   
   return
   
   error:
   	if @numrows > 1
   		begin
   		close bHQMU_insert
   		deallocate bHQMU_insert
   		end
   
   	select @errmsg = @errmsg + ' - cannot insert Material Unit of Measure!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btHQMUu    Script Date: 8/28/99 9:37:35 AM ******/
   CREATE  trigger [dbo].[btHQMUu] on [dbo].[bHQMU] for UPDATE as
   

declare @audit bYN, @cnt int, @co bCompany, @date bDate, @errmsg varchar(255),
   	@errno int, @field char(30), @hqco bCompany,
   	@key varchar(60), @new varchar(30), @newmatlgroup tinyint, @newmaterial bMatl,
   	@newum bUM,	@newconversion bUnits, @newprice bUnitCost, @newpriceecm bECM,
   	@newpaydiscrate bUnitCost,	@numrows int, @old varchar(30), @oldmatlgroup tinyint,
   	@oldmaterial bMatl, @oldum bUM, @oldconversion bUnits, @oldprice bUnitCost,
   	@oldpriceecm bECM, @oldpaydiscrate bUnitCost, @opencursor tinyint, @rectype char(1),
   	@stdum bUM, @tablename char(20), @user bVPUserName, @validcount int
   
   /*-----------------------------------------------------------------
    *  Created By:  ??
    *  Modified By: GF 02/15/2000
    *               CMW 04/11/02 - Replaced NULL for HQMA.Company with MaterialGroup (issue # 16840).
    *               CMW 08/12/02 - Fixed string/integer problem (issue # 18249).
    *
    *	This trigger rejects update in bHQMU (HQ Material Units of Measue)
    *	if any of the following error conditions exist:
    *
    *		Cannot change MatlGroup
    *		Cannot change Material
    *		Cannot change UM
    *		UM cannot exist in HQMT.StdUM for MatlGroup/Material
    *
    *	Audit inserts if any HQ Company using the Mat'l Group has the AuditMatl
    *	option set.
    */----------------------------------------------------------------
   
   /* initialize */
   select @numrows = @@rowcount
   if @numrows = 0 return
   set nocount on
   
   select @opencursor = 0
   
   /* reject key changes */
   select @validcount = count(*) from deleted d, inserted i
   	where d.MatlGroup = i.MatlGroup and d.Material = i.Material and
   	d.UM = i.UM
   if @numrows <> @validcount
   	begin
   	select @errmsg = 'Cannot change Material Group, Material, or Unit of Measure'
   
   	goto error
   
   	end
   
   if @numrows = 1
   	select @newmatlgroup = i.MatlGroup,
   		@oldmatlgroup = d.MatlGroup,
   		@newmaterial = i.Material, @oldmaterial = d.Material,
   		@newum = i.UM, @oldum = d.UM,
   		@newconversion = i.Conversion, @oldconversion = d.Conversion,
   		@newprice = i.Price, @oldprice = d.Price,
   		@newpriceecm = i.PriceECM, @oldpriceecm = d.PriceECM,
   		@newpaydiscrate = i.PayDiscRate, @oldpaydiscrate = d.PayDiscRate
   		from deleted d, inserted i where d.MatlGroup = i.MatlGroup and
   			d.Material = i.Material and d.UM = i.UM
   else
   	begin
   	/* use a cursor to process each updated row */
   	declare bHQMU_update cursor for select
   		NewMatlGroup = i.MatlGroup, OldMatlGroup = d.MatlGroup,
   		NewMaterial = i.Material, OldMaterial = d.Material,
   		NewUM = i.UM, OldUM = d.UM,
   		NewConversion = i.Conversion, OldConversion = d.Conversion,
   		NewPrice = i.Price, OldPrice = d.Price,
   		NewPriceECM = i.PriceECM, OldPriceECM = d.PriceECM,
   		NewPayDiscRate = i.PayDiscRate, OldPayDiscRate = d.PayDiscRate
   		from deleted d, inserted i
   		where d.MatlGroup = i.MatlGroup and
   			d.Material = i.Material and d.UM = i.UM
   	open bHQMU_update
   	select @opencursor = 1	/*set open cursor flag */
   	fetch next from bHQMU_update into
   		@newmatlgroup, @oldmatlgroup, @newmaterial, @oldmaterial,
   		@newum, @oldum, @newconversion, @oldconversion,
   		@newprice, @oldprice, @newpriceecm, @oldpriceecm,
   		@newpaydiscrate, @oldpaydiscrate
   	if @@fetch_status <> 0
   		begin
   		select @errmsg = 'Cursor error'
   		goto error
   		end
   	end
   
   
   update_check:
   
   	/* validate UM */
		--Issue 28325
	If @newum = 'LS' 
		begin
   			select @errmsg = 'LS is invalid Material Unit of Measure'
   			goto error
   		end
		
   	exec @errno = bspHQUMVal @newum, @errmsg output
   	if @errno <> 0 goto error
   
   	/* reject if std UM for this MatlGroup/Material */
   	select @stdum = StdUM from bHQMT where MatlGroup = @newmatlgroup and
   		Material = @newmaterial
   	if @@rowcount = 0
   		begin
   		select @errmsg = 'Invalid Material'
   		goto error
   		end
   
   	if @stdum = @newum
   		begin
   		select @errmsg = 'Unit of Measure used as a Std U/M for this Material Group/Material'
   		goto error
   		end
   
   
   	/* update HQ Master Audit - see note in header re selection of @audit */
   	if exists(select * from bHQCO where MatlGroup = @newmatlgroup and AuditMatl = 'Y')
   		begin
   		select @tablename = 'bHQMU',
   			@key = 'MatlGroup: ' + convert(varchar(3),@newmatlgroup) +
   			', Material: ' + @newmaterial + ', UM: ' + @newum,
   			@co = @newmatlgroup, @rectype = 'C',
   			@date = getdate(), @user = SUSER_SNAME()
   		if @newconversion <> @oldconversion
   			begin
   			select @field = 'Conversion', @old = convert(varchar(12),@oldconversion),
   				@new = convert(varchar(12),@newconversion)
   			exec @errno = bspHQMAInsert @tablename, @key, @co, @rectype, @field,
   				@old, @new, @date, @user, @errmsg output
   			if @errno <> 0 goto error
   			end
   		if @newprice <> @oldprice
   			begin
   			select @field = 'Price', @old = convert(varchar(12),@oldprice),
   				@new = convert(varchar(12),@newprice)
   			exec @errno = bspHQMAInsert @tablename, @key, @co, @rectype, @field,
   				@old, @new, @date, @user, @errmsg output
   			if @errno <> 0 goto error
   			end
   		if @newpriceecm <> @oldpriceecm
   			begin
   			select @field = 'PriceECM', @old = @oldpriceecm, @new = @newpriceecm
   			exec @errno = bspHQMAInsert @tablename, @key, @co, @rectype, @field,
   				@old, @new, @date, @user, @errmsg output
   			if @errno <> 0 goto error
   			end
   		if @newpaydiscrate <> @oldpaydiscrate
   			begin
   			select @field = 'PayDiscRate', @old = convert(varchar(12),@oldpaydiscrate),
   				@new = convert(varchar(12),@newpaydiscrate)
   			exec @errno = bspHQMAInsert @tablename, @key, @co, @rectype, @field,
   				@old, @new, @date, @user, @errmsg output
   			if @errno <> 0 goto error
   			end
   		end
   
   	if @numrows > 1
   		begin
   		fetch next from bHQMU_update into
   			@newmatlgroup, @oldmatlgroup, @newmaterial, @oldmaterial,
   			@newum, @oldum, @newconversion, @oldconversion,
   			@newprice, @oldprice, @newpriceecm, @oldpriceecm,
   			@newpaydiscrate, @oldpaydiscrate
   		if @@fetch_status = 0
   			goto update_check
   		else
   			begin
   			close bHQMU_update
   			deallocate bHQMU_update
   			end
   		end
   
   return
   
   error:
   	if @opencursor = 1
   		begin
   		close bHQMU_update
   		deallocate bHQMU_update
   		end
   
   	select @errmsg = @errmsg + ' - cannot update Material Unit of Measure!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   
   
   
   
  
 




GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bHQMU] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biHQMU] ON [dbo].[bHQMU] ([MatlGroup], [Material], [UM]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bHQMU].[Conversion]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bHQMU].[Cost]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bHQMU].[CostECM]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bHQMU].[Price]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bHQMU].[PriceECM]'
GO
