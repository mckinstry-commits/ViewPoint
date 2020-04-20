SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE           procedure [dbo].[bspEMStdMaintGroupCopyPreexisting]
   /*******************************************************************
    * CREATED: 3/20/01 JM
    * LAST MODIFIED:  09/17/01 JM - Changed creation method for temp tables from 'select * into' to discrete declaration
    *	of specific fields. Also changed inserts into temp tables to discrete declaration of fields. 
    *	Ref Issue 14227.
    *	TV 02/11/04 - 23061 added isnulls
    *	JVH 6/9/11 - Added sql to get the replaced odometer and replace hour meter reading when creating a new SMI
	*		GF 01/17/2013 TK-20837 options to copy ud columns for EMSH, EMSI, and EMSP
	*		GF 04/26/2013 TFS-48552 EMSH/EMSI description expanded
	*
    *
    * USAGE:  Called by bspEMStdMaintGroupCopy to copy a Std Maint Group (or set) where target SMG alredy 
    *	exists. Based on param @updateoption, will either overwrite existing items/parts (Replace) or add any 
    *	new to the existing set (AddNew). Based on @savelastdone will save last done meter data at item level.
    *
    *	3 Cases	@updateoption		@savelastdone
    *	---------------------------------------------------------------------
    *			AddNew		Not applicable	
    *			Replace				Y
    *			Replace:			N
    *		
    * INPUT PARAMS:
    *	@emco			EMSH.EMCo
    *	@targetequip		EMSH.Equipment whose StdMaintGroup(s) are to be copied from
    *	@targetsmg		Beginning of range of EMSH.StdMaintGroups to be copied from
    *  	@updateoption       	Either 'A' for 'Add New Items/Parts Only' or 'R' for 'Replace Existing Items/Parts'
    *  	@savelastdone       	'Save 'Last Done' Meter Data' at Item level:
    *					if @updateoption = 'R' for 'Replace Existing Items/Parts' - can be either 'Y' or 'N'
    *						if 'N' will set LastDoneMeter/Odometer/Gallons to 0 and LastDoneDate to null
    *					if @updateoption = 'A' for 'Add New Items/Parts Only' - not appl
    *
    * OUTPUT PARAMS:
    *	@rcode			Return code; 0 = success, 1 = failure
    *	@errms
   g		Error message; # copied if success, error message if failure
    ********************************************************************/
   (@emco bCompany = null,
   @sourceequip bEquip = null,
   @targetequip bEquip = null,
   @copyfromsmg varchar(10) = null,
   @updateoption char(1),
   @savelastdone char(1),
   ----TK-20837
   @EMSIud_flag CHAR(1) = 'N',
   @EMSPud_flag CHAR(1) = 'N',
   @CopyEMSICustom CHAR(1) = 'N',
   @CopyEMSPCustom CHAR(1) = 'N',
   @errmsg varchar(255) output)
   
   as
   
   set nocount on
   
   
   /* Initialize general local variables. */
   declare @autodelete bYN,
   	@basis char(1),
	----TFS-48552	
   	@description bItemDesc,
   	@fixeddateday tinyint,
   	@fixeddatemonth tinyint,
   	@interval int,
   	@intervaldays smallint,
   	@matlgroup bGroup,
   	@rcode int,
   	@smicopy bItem,
   	@smpcopy bMatl,
   	@variance int,
   	@lasthourmeter bHrs,
   	@lastodometer bHrs,
   	@lastgallons bHrs,
   	@lastdonedate bDate,
	----TK-20837
	@Joins VARCHAR(MAX),
	@Where VARCHAR(MAX)

   
   select @rcode = 0
   
   
   /* Verify necessary parameters passed. */
   if @emco is null
   	begin
   	select @errmsg = 'Missing EM Company!', @rcode = 1
   	goto bspexit
   	end
   if @sourceequip is null
   	begin
   	select @errmsg = 'Missing Source Equipment!', @rcode = 1
   	goto bspexit
   	end
   if @targetequip is null
   	begin
   	select @errmsg = 'Missing Target Equipment!', @rcode = 1
   	goto bspexit
   	end
   if @copyfromsmg is null
   	begin
   	select @errmsg = 'Missing Copy From Std Maint Group!', @rcode = 1
   	goto bspexit
   	end
   
   /* Get @matlgroup from bHQCO for this @emco. */
   select @matlgroup = MatlGroup
   from bHQCO
   where HQCo = @emco
   
   /* Create temp tables for SMItems, SMParts to be copied. */
   select EMCo, Equipment, StdMaintGroup, StdMaintItem, EMGroup, CostCode, RepairType, InOutFlag, 
   	Description, EstHrs, EstCost, LastHourMeter, LastOdometer, LastGallons, LastDoneDate, Notes
   	into #ItemsToCopy from bEMSI where 1=2
   
   select EMCo, Equipment, StdMaintGroup, StdMaintItem, MatlGroup, Material, Description, UM, QtyNeeded, PSFlag, Required
   	into #PartsToCopy from bEMSP where 1=2
   
   -----------------------------------------------------------------------------------------------------------------
   
   /*  If @updateoption = 'R' we'll need to do the following
   	1. Update SMG non-key columns from @copyfromsmg
   	2. If @savelastdone = 'Y', update last done columns in #ItemsToCopy from existing SMI
   	3. Delete the parts and items for the SMG
   	4. Insert parts for new SMI from #ItemsToCopy*/
   
   /* Go to the Item level. Refresh #ItemsToCopy, and then work through each
   SMI to either add the Item with its Parts if it doesnt exist or check its Parts. */
   insert into #ItemsToCopy (EMCo, Equipment, StdMaintGroup, StdMaintItem, EMGroup, CostCode, RepairType, InOutFlag, Description, EstHrs, 
   	EstCost, LastHourMeter, LastOdometer, LastGallons, LastDoneDate, Notes)
   select EMCo, Equipment, StdMaintGroup, StdMaintItem, EMGroup, CostCode, RepairType, InOutFlag, Description, EstHrs, EstCost, LastHourMeter, LastOdometer, LastGallons, LastDoneDate, Notes 
   	from bEMSI 
   	where EMCo = @emco and Equipment = @sourceequip and StdMaintGroup = @copyfromsmg
   /* Loop thru SMI's in #ItemsToCopy. */
   select @smicopy=min(StdMaintItem) from #ItemsToCopy
   while @smicopy is not null
   	begin
   	if @updateoption = 'R'
   		begin
   		/* Update SMG non-key info. */
   		select @description = Description, @basis = Basis, @interval = Interval, @intervaldays = IntervalDays, @variance = Variance,  
   			@fixeddatemonth = FixedDateMonth, @fixeddateday = FixedDateDay, @autodelete = AutoDelete--, @notes = Notes
   		from bEMSH
   		where EMCo = @emco and Equipment = @sourceequip and StdMaintGroup = @copyfromsmg
   		update bEMSH
   		set Description = @description, Basis = @basis, Interval = @interval, IntervalDays = @intervaldays, Variance = @variance,
   			 FixedDateMonth = @fixeddatemonth, FixedDateDay = @fixeddateday, AutoDelete = @autodelete--, Notes = @notes*/
   		where EMCo = @emco and Equipment = @targetequip and StdMaintGroup = @copyfromsmg
   
   		/* Set LastDoneHourMeter/Odometer/Gallons to 0 and LastDoneDate to null for all conditions - will be reset to Last Done
   		 if @savelastdone = 'Y'. */
   		update #ItemsToCopy 
   		set LastHourMeter = 0, LastOdometer = 0, LastGallons = 0, LastDoneDate = null
   		where StdMaintItem = @smicopy
   
   		if exists(select * from bEMSI where EMCo = @emco and Equipment = @targetequip and StdMaintGroup = @copyfromsmg and StdMaintItem = @smicopy)
   			begin
   			if @savelastdone = 'Y'
   				/* Save LastDone info for Items into temp SMI table. */
   				begin
   				select @lasthourmeter = LastHourMeter,	@lastodometer = LastOdometer, 	@lastgallons = LastGallons, @lastdonedate = LastDoneDate
   				from bEMSI
   				where EMCo = @emco and Equipment = @targetequip and StdMaintGroup = @copyfromsmg and StdMaintItem = @smicopy
   				update #ItemsToCopy 
   				set LastHourMeter = @lasthourmeter, LastOdometer = @lastodometer, LastGallons = @lastgallons, LastDoneDate = @lastdonedate
   				where StdMaintItem = @smicopy
   				end
   			end
   
   		/* Delete current SMI and parts from parts up. */
   		delete bEMSP
   		where EMCo = @emco and Equipment = @targetequip and StdMaintGroup = @copyfromsmg and StdMaintItem = @smicopy
   		delete bEMSI
   		where EMCo = @emco and Equipment = @targetequip and StdMaintGroup = @copyfromsmg and StdMaintItem = @smicopy
   	
   		/* Insert into bEMSI for target Equipment, SMG copy and SMI copy; LastDone info will be correct from update above. */
   		insert into bEMSI (EMCo, Equipment, StdMaintGroup, StdMaintItem, EMGroup, CostCode, RepairType, InOutFlag, Description, EstHrs, EstCost, LastHourMeter, LastReplacedHourMeter, LastOdometer, LastReplacedOdometer, LastGallons, LastDoneDate, Notes)
   		select @emco, @targetequip, @copyfromsmg, StdMaintItem, #ItemsToCopy.EMGroup, CostCode, RepairType, InOutFlag, #ItemsToCopy.[Description], EstHrs, EstCost, LastHourMeter, bEMEM.ReplacedHourReading, LastOdometer, bEMEM.ReplacedOdoReading, LastGallons, LastDoneDate, #ItemsToCopy.Notes
   		from #ItemsToCopy
   		LEFT JOIN dbo.bEMEM ON bEMEM.EMCo = @emco AND bEMEM.Equipment = @targetequip
   		where StdMaintItem = @smicopy
   		----TK-20837
		IF @@ROWCOUNT <> 0 and @EMSIud_flag = 'Y' AND @CopyEMSICustom = 'Y'
			BEGIN
  			-- build joins and where clause
  			select @Joins = ' from EMSI join EMSI z with (nolock) on z.EMCo = ' + convert(varchar(3), @emco) 
  							+ ' and z.Equipment = ' + CHAR(39) + @sourceequip + CHAR(39) 
  							+ ' and z.StdMaintGroup = ' + CHAR(39) + @copyfromsmg + CHAR(39)
							+ ' AND z.StdMaintItem = ' + convert(varchar(10), @smicopy) 
  			select @Where = ' where EMSI.EMCo = ' + convert(varchar(3),@emco) 
  							+ ' and EMSI.Equipment = ' + CHAR(39) + @targetequip + CHAR(39) 
  							+ ' and EMSI.StdMaintGroup = ' + CHAR(39) + @copyfromsmg + CHAR(39)
							+ ' and EMSI.StdMaintItem = ' + convert(varchar(10), @smicopy) 
  			-- execute user memo update
  			exec @rcode = bspPMProjectCopyUserMemos 'EMSI', @Joins, @Where, @errmsg output
  			END

   		/* Insert into bEMSP for target Equipment and SMG copy. */
   		insert bEMSP (EMCo, Equipment, StdMaintGroup, StdMaintItem, MatlGroup, Material, Description, UM, QtyNeeded, PSFlag, Required)
   		select @emco, @targetequip, @copyfromsmg, StdMaintItem, MatlGroup, Material, Description, UM, QtyNeeded, PSFlag, Required
   		from bEMSP
   		where EMCo = @emco and Equipment = @sourceequip and StdMaintGroup = @copyfromsmg and StdMaintItem = @smicopy
   		----TK-20837
		IF @@ROWCOUNT <> 0 and @EMSPud_flag = 'Y' AND @CopyEMSPCustom = 'Y'
			BEGIN
  			-- build joins and where clause
  			select @Joins = ' from EMSP join EMSP z with (nolock) on z.EMCo = ' + convert(varchar(3), @emco) 
  							+ ' and z.Equipment = ' + CHAR(39) + @sourceequip + CHAR(39) 
  							+ ' and z.StdMaintGroup = ' + CHAR(39) + @copyfromsmg + CHAR(39)
							+ ' AND z.StdMaintItem = ' + convert(varchar(10), @smicopy) 
							+ ' AND z.MatlGroup = EMSP.MatlGroup'
							+ ' AND z.Material = EMSP.Material'
  			select @Where = ' where EMSP.PECo = ' + convert(varchar(3),@emco) 
  							+ ' and EMSP.Equipment = ' + CHAR(39) + @targetequip + CHAR(39) 
  							+ ' and EMSP.StdMaintGroup = ' + CHAR(39) + @copyfromsmg + CHAR(39)
							+ ' and EMSP.StdMaintItem = ' + convert(varchar(10), @smicopy) 
  			-- execute user memo update
  			exec @rcode = bspPMProjectCopyUserMemos 'EMSP', @Joins, @Where, @errmsg output
  			END
   		end
   
   -----------------------------------------------------------------------------------------------------------------
   
   	/* If @updateoption = 'A' we have to add Items with their Parts that dont exist yet and
   	add Parts that dont exist for existing Items. So (1) add each Item with its Parts if the Item doesnt exist
   	(2) loop thru Parts and add each Part if it doesnt exist for a given Item. */
   	If @updateoption = 'A'
   		begin
   			/* If SMI doesnt exist for this SMG, add it and its Parts and get the next @smicopy. */
   			if not exists (select * from bEMSI where EMCo = @emco and Equipment = @targetequip and StdMaintGroup = @copyfromsmg and StdMaintItem = @smicopy)
   				begin
   				/* Insert into bEMSI for target Equipment, SMG copy and SMI copy;	set LastDone columns to 0 since this is a brand new SMG. */
   				insert into bEMSI (EMCo, Equipment, StdMaintGroup, StdMaintItem, EMGroup, CostCode, RepairType, InOutFlag, Description, EstHrs, EstCost, LastHourMeter, LastReplacedHourMeter,
   					LastOdometer, LastReplacedOdometer, LastGallons, LastDoneDate, Notes)
   				select @emco, @targetequip, StdMaintGroup, StdMaintItem, #ItemsToCopy.EMGroup, CostCode, RepairType, InOutFlag, #ItemsToCopy.Description, EstHrs, EstCost, 0, bEMEM.ReplacedHourReading, 0, bEMEM.ReplacedOdoReading, 0, null, #ItemsToCopy.Notes
   				from #ItemsToCopy
   				LEFT JOIN dbo.bEMEM ON bEMEM.EMCo = @emco AND bEMEM.Equipment = @targetequip
   				where #ItemsToCopy.EMCo = @emco and #ItemsToCopy.Equipment = @sourceequip and StdMaintGroup = @copyfromsmg and StdMaintItem = @smicopy
   				----TK-20837
				IF @@ROWCOUNT <> 0 and @EMSIud_flag = 'Y' AND @CopyEMSICustom = 'Y'
					BEGIN
  					-- build joins and where clause
  					select @Joins = ' from EMSI join EMSI z with (nolock) on z.EMCo = ' + convert(varchar(3), @emco) 
  									+ ' and z.Equipment = ' + CHAR(39) + @sourceequip + CHAR(39) 
  									+ ' and z.StdMaintGroup = ' + CHAR(39) + @copyfromsmg + CHAR(39)
									+ ' AND z.StdMaintItem = ' + convert(varchar(10), @smicopy) 
  					select @Where = ' where EMSI.EMCo = ' + convert(varchar(3),@emco) 
  									+ ' and EMSI.Equipment = ' + CHAR(39) + @targetequip + CHAR(39) 
  									+ ' and EMSI.StdMaintGroup = ' + CHAR(39) + @copyfromsmg + CHAR(39)
									+ ' and EMSI.StdMaintItem = ' + convert(varchar(10), @smicopy) 
  					-- execute user memo update
  					exec @rcode = bspPMProjectCopyUserMemos 'EMSI', @Joins, @Where, @errmsg output
  					END
				
				/* Add all parts into bEMSP since they won't exist yet. */
   				insert into bEMSP (EMCo, Equipment, StdMaintGroup, StdMaintItem, MatlGroup, Material, Description, UM, QtyNeeded, PSFlag, Required)
   				select @emco, @targetequip, @copyfromsmg, @smicopy, MatlGroup, Material, Description, UM, QtyNeeded, PSFlag, Required
   				from bEMSP
   				where EMCo = @emco and Equipment = @sourceequip and StdMaintGroup = @copyfromsmg and StdMaintItem = @smicopy
   				----TK-20837
				IF @@ROWCOUNT <> 0 and @EMSPud_flag = 'Y' AND @CopyEMSPCustom = 'Y'
					BEGIN
  					-- build joins and where clause
  					select @Joins = ' from EMSP join EMSP z with (nolock) on z.EMCo = ' + convert(varchar(3), @emco) 
  									+ ' and z.Equipment = ' + CHAR(39) + @sourceequip + CHAR(39) 
  									+ ' and z.StdMaintGroup = ' + CHAR(39) + @copyfromsmg + CHAR(39)
									+ ' AND z.StdMaintItem = ' + convert(varchar(10), @smicopy) 
									+ ' AND z.MatlGroup = EMSP.MatlGroup'
									+ ' AND z.Material = EMSP.Material'
  					select @Where = ' where EMSP.EMCo = ' + convert(varchar(3),@emco) 
  									+ ' and EMSP.Equipment = ' + CHAR(39) + @targetequip + CHAR(39) 
  									+ ' and EMSP.StdMaintGroup = ' + CHAR(39) + @copyfromsmg + CHAR(39)
									+ ' and EMSP.StdMaintItem = ' + convert(varchar(10), @smicopy) 
  					-- execute user memo update
  					exec @rcode = bspPMProjectCopyUserMemos 'EMSP', @Joins, @Where, @errmsg output
  					END
				END
                
   			/* If SMI does exist for this SMG, add any parts that don't exist yet. */
   			else
   				begin
   				/* SMI does exist, so go to the Parts level and work through each SMP to add the Part if it doesnt exist. */
   				delete #PartsToCopy
   				insert into #PartsToCopy (EMCo, Equipment, StdMaintGroup, StdMaintItem, MatlGroup, Material, Description, UM, QtyNeeded, PSFlag, Required)
   				select EMCo, Equipment, StdMaintGroup, StdMaintItem, MatlGroup, Material, Description, UM, QtyNeeded, PSFlag, Required from bEMSP
   				where EMCo = @emco and Equipment = @sourceequip and StdMaintGroup = @copyfromsmg and StdMaintItem = @smicopy and MatlGroup = @matlgroup
   				/* Add any parts in #PartsToCopy that don't exist yet in bEMSI. */
   				select @smpcopy=min(Material) from #PartsToCopy
   				while @smpcopy is not null
   					begin
   					/* If Part doesnt exist for this SMI, add it. */
   					if not exists (select * from bEMSP where EMCo = @emco and Equipment = @targetequip and StdMaintGroup = @copyfromsmg and StdMaintItem = @smicopy and MatlGroup = @matlgroup and Material = @smpcopy)
   						/* Insert into bEMSP for target Equipment, SMG copy and SMI copy. */
   						insert into bEMSP (EMCo, Equipment, StdMaintGroup, StdMaintItem, MatlGroup, Material, Description, UM, QtyNeeded, PSFlag, Required)
   						select @emco, @targetequip, @copyfromsmg, @smicopy, @matlgroup, @smpcopy, Description, UM, QtyNeeded, PSFlag, Required
   						from #PartsToCopy
   						where Material = @smpcopy
   						----TK-20837
						IF @@ROWCOUNT <> 0 and @EMSPud_flag = 'Y' AND @CopyEMSPCustom = 'Y'
							BEGIN
  							-- build joins and where clause
  							select @Joins = ' from EMSP join EMSP z with (nolock) on z.EMCo = ' + convert(varchar(3), @emco) 
  											+ ' and z.Equipment = ' + CHAR(39) + @sourceequip + CHAR(39) 
  											+ ' and z.StdMaintGroup = ' + CHAR(39) + @copyfromsmg + CHAR(39)
											+ ' AND z.StdMaintItem = ' + convert(varchar(10), @smicopy) 
											+ ' AND z.MatlGroup = ' + convert(varchar(3), @matlgroup) 
											+ ' AND z.Material = ' + CHAR(39) + @smpcopy + CHAR(39)
  							select @Where = ' where EMSP.EMCo = ' + convert(varchar(3),@emco) 
  											+ ' and EMSP.Equipment = ' + CHAR(39) + @targetequip + CHAR(39) 
  											+ ' and EMSP.StdMaintGroup = ' + CHAR(39) + @copyfromsmg + CHAR(39)
											+ ' and EMSP.StdMaintItem = ' + convert(varchar(10), @smicopy) 
											+ ' AND EMSP.MatlGroup = ' + convert(varchar(3), @matlgroup) 
											+ ' AND EMSP.Material = ' + CHAR(39) + @smpcopy + CHAR(39)

  							-- execute user memo update
  							exec @rcode = bspPMProjectCopyUserMemos 'EMSP', @Joins, @Where, @errmsg output
  							END

   					/* Get the next Part to copy from #PartsToCopy. */
   					select @smpcopy=min(Material)
   					from #PartsToCopy
   					where Material > @smpcopy
   					end
   				end
   		end
   
   getnextsmicopy:
   		/* Get the next StdMaintItem to copy from #ItemsToCopy. */
   		select @smicopy=min(StdMaintItem)
   		from #ItemsToCopy
   		where StdMaintItem > @smicopy
   	end
   
   bspexit:
   
   if @rcode<>0 select @errmsg=isnull(@errmsg,'')
   
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMStdMaintGroupCopyPreexisting] TO [public]
GO
