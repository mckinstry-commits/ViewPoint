SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBTandMGetCategory    Script Date: 8/28/99 9:32:34 AM ******/
   CREATE proc [dbo].[bspJBTandMGetCategory]
   /***********************************************************
   * CREATED BY	 : kb 5/10/00
   * MODIFIED BY : kb 2/19/01
   * 		bc 5/15/02 - issue #17369
   *		TJL 09/24/02 - Issue #18635, Limit search for Labor Category to only those
   *						relative to this template when Labor Rate Option is 'R'.	
   *		TJL 02/26/03 - Issue #19765, Category returning as NULL for Material from HQMT. Fix bspJBTandMGetCategory
   *		TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure
   *		TJL 04/12/04 - Issue #24304, Overrides can be used even if Category is not setup in Rates Table
   *		TJL 08/10/04 - Issue #25314, Separate PR Burden by Category if desired
   *		TJL 10/15/04 - Issue #25776, Repairs what Issue #24304 broke
   *		TJL 10/29/04 - Issue #25836, Allow Material Category NULL without error
   *
   * USED IN:
   *	bspJBJCCDDisplay
   *   bspJBJCCDInfo
   *	bspJBJCCDVal
   *	bspJBTandMAddJCTrans
   *	bspJBTandMInit
   *	form - JBTMBillLines
   *
   * USAGE:
   *   used if PR, EM or matl type JCCD record and your template uses category or rates
   *   Categories are required for labor & equip rates. Starts at most specific level
   *   to get template and then gets more general til a match is found. There will only
   *   be one category that will fit. Matl Category comes from HQMT,
   *   Equip Category comes from EMEM
   *
   * INPUT PARAMETERS
   * 	@co
   *  	@prco
   * 	@employee
   *  	@craft
   *  	@class
   * 	@earntype
   *  	@factor
   *  	@shift
   * 	@emco
   *  	@equip
   *  	@revcode
   *  	@source
   *  	@template
   *
   * OUTPUT PARAMETERS
   *	@currentcategory varchar(10) output,
   *   @msg      error message if error occurs
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/
   
   (@co bCompany, @prco bCompany, @employee bEmployee, @craft bCraft,
   	@class bClass, @earntype bEarnType, @factor bRate, @shift tinyint, @emco bCompany,
   	@equip bEquip, @matlgroup bGroup, @material bMatl, @revcode bRevCode, @source char(2), 
   	@template varchar(10), @ctcategory char(1), @currentcategory varchar(10) output,
   	@msg varchar(255) output)
   as
   
   set nocount on
   
   declare @rcode int, @laborcatyn bYN, @equipcatyn bYN, @matlcatyn bYN,
       @dfltcategory varchar(10),  @laborrateopt char(1),
       @rate bUnitCost, @dfltrateopt char(1), @dfltrate bUnitCost,
       @equiprateopt char(1), @laborrateoverride bYN, @rateopt char(1),
       @overriderateopt char(1), @overriderate bUnitCost,
       @dfltoverriderateopt char(1), @dfltoverriderate bUnitCost,
       @matloverrideopt char(1), @matlrate bUnitCost, @matlspecprice bUnitCost,
       @matlcostopt  char(1), @overridecategory varchar(10)
   
   select @rcode = 0, @currentcategory = null	--reset @currentcategory because the calling proc
   											--does not do so.
   
   select @laborrateopt = LaborRateOpt, @equiprateopt = EquipRateOpt,
       @laborrateoverride = LaborOverrideYN, @laborcatyn = LaborCatYN,
       @equipcatyn = EquipCatYN, @matlcatyn = MatlCatYN 
   from bJBTM with (nolock)
   where JBCo = @co and Template = @template
   
   /*** LABOR CATEGORIES ***/
   if @source = 'PR' and @ctcategory in ('L','B') and @laborrateopt = 'C'
   	/* Issue #18635, Added -- and @laborrateopt = 'C'--.  When determining Labor Category
   	   by 'C'ost, there is nothing to limit the records in bJBLX, to choose from, except
   	   Craft and Class.  Therefore if two Labor Categories contrain the same Craft & Class
   	   then the Last one encountered will be returned.  
   
   	   Users must be careful to use unique Craft & Class for each Labor Category if Labor
   	   is to be billed by 'C'ost.  (To change causes considerable design reconsideration) */ 
   	begin
   	select @currentcategory = LaborCategory 
   	from bJBLX with (nolock)
   	where JBCo = @co and Craft = @craft and Class = @class
   	if @@rowcount = 0
       	begin
		select @currentcategory = LaborCategory 
   		from bJBLX with (nolock)
		where JBCo = @co and Craft = @craft and Class is null
		if @@rowcount = 0
           	begin
			select @currentcategory = LaborCategory 
   			from bJBLX with (nolock)
			where JBCo = @co and Craft is null and Class = @class 
           	if @@rowcount = 0
				begin
				select @currentcategory = LaborCategory 
   				from bJBLX with (nolock)
				where JBCo = @co and Craft is null and Class is null
                	if @@rowcount = 0 and exists(select 1 from bJBTM with (nolock) where
                   		JBCo = @co and Template = @template and LaborRateOpt = 'C')
                   	begin
                   	select @rcode = 1, @msg = 'Labor Category not setup.'
					goto bspexit
					end
				end
           	end
		end
   	end
   
   if @source = 'PR' and @ctcategory in ('L','B') and @laborrateopt = 'R'
   	/* Issue #18635, Added 'join' to limit record set from JBLX to only those LaborCategories
      	   that exist for those Labor Rates associated with this template. - When determining Labor Category
   	   by 'R'ate, it is possible to limit the evaluation process to only those Labor Categories
   	   used in the Rates table for this Template.
   
   	   Therefore as long as the Labor Categories used in the Rates Table for a given template
   	   use unique Craft & Class as described above, there is no conflict.  This allows a little more
   	   flexibility when setting up bJBLX  (Than by 'C'ost) but still users must be careful not to
   	   mix Two Labor Categories in the Rates table on any one template that contain the same
   	   Craft & Class in bJBLX. (Again to change requires serious design reconsideration) */ 
   	begin	/* Begin PR Labor, Rate Evaluation */

   	select @currentcategory = x.LaborCategory 
   	from bJBLX x with (nolock)
   	join bJBLR r with (nolock) on r.JBCo = x.JBCo and r.LaborCategory = x.LaborCategory
   	where x.JBCo = @co and r.Template = @template and x.Craft = @craft and x.Class = @class 
   	if @@rowcount <> 0 goto bspexit		-- We have a Category value to work with. Get Out now.
   
    	select @currentcategory = x.LaborCategory 
   	from bJBLX x with (nolock) 
   	join bJBLR r with (nolock) on r.JBCo = x.JBCo and r.LaborCategory = x.LaborCategory
     	where x.JBCo = @co and r.Template = @template and x.Craft = @craft and x.Class is null 
    	if @@rowcount <> 0 goto bspexit	

    	select @currentcategory = x.LaborCategory 
   	from bJBLX x with (nolock) 
   	join bJBLR r with (nolock) on r.JBCo = x.JBCo and r.LaborCategory = x.LaborCategory
    	where x.JBCo = @co and r.Template = @template and x.Craft is null and x.Class = @class 
   	if @@rowcount <> 0 goto bspexit	
   
    	select @currentcategory = x.LaborCategory 
   	from bJBLX x with (nolock) 
   	join bJBLR r with (nolock) on r.JBCo = x.JBCo and r.LaborCategory = x.LaborCategory
    	where x.JBCo = @co and r.Template = @template and x.Craft is null and x.Class is null
   	if @@rowcount <> 0 
   		begin
   		goto bspexit	
   		end
   	else
   		begin
   		/* No Category value from Rates Table, potential Error. */
   		if exists(select 1 from bJBTM with (nolock) where
   				JBCo = @co and Template = @template and LaborRateOpt = 'R')
   			begin
   			select @rcode = 1, @msg = 'Labor Category not setup in Rate Table.'
   			goto Overrides		-- No Category value Established, evaluate Override Table for same
   			end
   		end
   
   Overrides: 
   	if @laborrateoverride = 'Y'
   	/* LaborCategory was not established using the Rates Table.  If template allows using Overrides then
   	   check Overrides table before giving an error. */
   		begin	/* Begin Override Evaluation */
   		select @rcode = 0, @msg = ''	--reset @rcode since we are not done looking.
   
   		select @overridecategory = x.LaborCategory 
   		from bJBLX x with (nolock)
   		join bJBLO o with (nolock) on o.JBCo = x.JBCo and o.LaborCategory = x.LaborCategory
   		where x.JBCo = @co and o.Template = @template and x.Craft = @craft and x.Class = @class 
   		if @@rowcount <> 0 		
   			begin				
   			select @currentcategory = @overridecategory
   			goto bspexit				-- We have a Category value to work with. Get Out now.
   			end

		select @overridecategory = x.LaborCategory 
   		from bJBLX x with (nolock) 
   		join bJBLO o with (nolock) on o.JBCo = x.JBCo and o.LaborCategory = x.LaborCategory
         	where x.JBCo = @co and o.Template = @template and x.Craft = @craft and x.Class is null 
        	if @@rowcount <> 0
   			begin
   			select @currentcategory = @overridecategory
   			goto bspexit
   			end
   
        	select @overridecategory = x.LaborCategory 
   		from bJBLX x with (nolock) 
   		join bJBLO o with (nolock) on o.JBCo = x.JBCo and o.LaborCategory = x.LaborCategory
        	where x.JBCo = @co and o.Template = @template and x.Craft is null and x.Class = @class 
       	if @@rowcount <> 0
   			begin
   			select @currentcategory = @overridecategory
   			goto bspexit
   			end
   
        	select @overridecategory = x.LaborCategory 
   		from bJBLX x with (nolock) 
   		join bJBLO o with (nolock) on o.JBCo = x.JBCo and o.LaborCategory = x.LaborCategory
        	where x.JBCo = @co and o.Template = @template and x.Craft is null and x.Class is null
   		if @@rowcount <> 0 
   			begin
   			select @currentcategory = @overridecategory
   			goto bspexit
   			end
   		else
   			begin
   			--if @currentcategory is not null		--Retrieved from Rate Table earlier.
   			--	begin
   			--	goto bspexit
   			--	end
   			--else
   			--	begin
   				/* No value from either the Rates Table or the Overrides Table. */
   				if exists(select 1 from bJBTM with (nolock) where
   						JBCo = @co and Template = @template and LaborRateOpt = 'R')
   					begin
   					select @rcode = 1, @msg = 'Labor Category not setup in Rate or Override table.'
   					goto bspexit
   					end
   			--	end
   			end
   		end		/* End Override Evaluation */
   	end		/* End PR Labor, Rate Evaluation */
   
   /*** EQUIPMENT CATEGORIES ***/
   if @source = 'EM' or (@source = 'PR' and @ctcategory = 'E')--and @equipcatyn = 'Y'
   	begin
   	select @currentcategory = Category 
   	from bEMEM with (nolock)  
   	where EMCo = @emco and Equipment = @equip
   	if @@rowcount = 0
   		begin
   		select @rcode = 1, @msg = 'Equipment Category not setup.'
   		goto bspexit
   		end
   	end
   
   /*** MATERIAL CATEGORIES ***/
   if @matlgroup is not null and @material is not null
   	begin
   	if @ctcategory = 'M'
   		begin
   		select @currentcategory = Category 
   		from bHQMT with (nolock)  
   		where MatlGroup = @matlgroup and Material = @material
   --		It is possible to have a NULL Material Category
   -- 		if @@rowcount = 0
   -- 			begin
   -- 			select @rcode = 1, @msg = 'Material Category not setup.'
   -- 			goto bspexit
   -- 			end
   		end
   
   	if @equip is not null and @emco is not null and @ctcategory = 'E'
   		begin
   		select @currentcategory = Category 
   		from bEMEM with (nolock)  
   		where EMCo = @emco and Equipment = @equip
   		if @@rowcount = 0
   			begin
   			select @rcode = 1, @msg = 'Equipment Category (MS) not setup.'
   			goto bspexit
   			end
   		end
   	end
   
   bspexit:
   return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJBTandMGetCategory] TO [public]
GO
