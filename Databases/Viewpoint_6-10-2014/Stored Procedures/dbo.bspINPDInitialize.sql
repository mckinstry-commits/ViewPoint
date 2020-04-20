SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspINPDInitialize]
   /*******************************************************************************************
   * CREATED: GR 12/02/99
   * Modified: GR 6/21/00 - fixed the unitprice calculations
   *			GG 10/07/00 - added Category to search on bINLO
   *			RM 05/29/02 - Changed UM from bUnits to numeric(14,5)
   *			GG 06/05/02 - #17403 - fixed to pull correct cost method	
   *			GG 10/16/02 - #16039 - added output param for count of components with negative on-hand	qtys
   *			GG 01/13/05 - #14689 - use MS Price Template and Quote pricing for component sales
   *			GP 06/09/2008 - Issue #127986 - added @MatlVendor and @VendorGroup params to bspMSTicMatlPriceGet
   *
   * USAGE:
   * This routine is used to insert records into IN Production
   * batch detail table INPD using either a standard or override Bill
   * of Materials
   *
   * INPUT PARAMETERS
   * @inco        	IN Company
   * @mth         	Batch Month
   * @batchid     	Batch Id
   * @batchseq    	Batch Seq
   * @matlgroup   	Material Group
   * @finmatl     	Finished Material
   * @prodloc     	Production Location
   * @produnits   	Production Units
   * @proddate		Production Date		- #14689 new parameter
   *
   * OUTPUT PARAMETERS
   * @inactivematl    To display an error message if one or more component materials are not active
   * @negunits			Count of components whose on-hand qty is negative
   *
   * Return 0 success
   *        1 error
   *
   ********************************************************************************************/
        (@inco bCompany = null, @mth bMonth = null, @batchid int = null , @batchseq int = null,
        @matlgroup bGroup = null, @finmatl bMatl = null, @prodloc bLoc = null, @produnits numeric(14,5)=null,
   	 @proddate bDate = null, @inactivematl int output, @negunits int output,  @msg varchar(255) output )
    as
    
   set nocount on
    
   declare @numrows int, @rcode int, @errmsg varchar(255), @validcnt int, @locgroup bGroup,
        @comploc bLoc, @compmatl bMatl,@autoseq int, @units numeric(14,5), @unitcost bUnitCost,
        @unitprice bUnitCost, @ecm bECM, @pecm bECM, @um bUM, @costmethod int, @active bYN,
        @invpriceopt int, @usageopt char(1), @curunits numeric(14,5),
        @openinbo int, @openinbm int, @category varchar(10), @incocostmethod tinyint, @onhand bUnits,
   	 @locpricetemplate smallint, @pricetemplate smallint, @quote varchar(10), @minamt bDollar, 
		@MatlVendor bVendor, @VendorGroup bGroup
   
   select @rcode = 0, @openinbo = 0, @openinbm = 0, @autoseq = 1, @inactivematl = 0, @negunits = 0
    
   if @mth is null
   	begin
   	select @msg='Missing Batch Month', @rcode=1
   	goto bspexit
   	end
   if @batchid is null
   	begin
   	select @msg='Missing Batch Id', @rcode=1
   	goto bspexit
   	end
   if @batchseq is null
   	begin
   	select @msg='Missing Batch Seq', @rcode=1
   	goto bspexit
   	end
   if @matlgroup is null
   	begin
   	select @msg='Missing Material Group', @rcode=1
   	goto bspexit
   	end
   if @finmatl is null
   	begin
   	select @msg='Missing Production Material', @rcode=1
   	goto bspexit
   	end
   if @prodloc is null
       begin
       select @msg='Missing Production Location', @rcode=1
       goto bspexit
       end
    
   -- skip if Production Detail already exists for this Batch Sequence
   if exists(select top 1 1 from dbo.bINPD (nolock)
   			where Co=@inco and Mth=@mth and BatchId=@batchid and BatchSeq=@batchseq) goto bspexit
    
   --get info from IN Company
   select @usageopt = UsageOpt, @invpriceopt = InvPriceOpt, @incocostmethod = CostMethod
   from dbo.bINCO (nolock)
   where INCo = @inco
   if @@rowcount = 0
   	begin
   	select @msg = 'Invalid IN Company#: ' + convert(varchar,@inco), @rcode = 1
   	goto bspexit
   	end
   
   -- #14689 - look for MS Price Template assigned to Production Location
   select @locpricetemplate = PriceTemplate, @locgroup = LocGroup
   from dbo.bINLM (nolock)
   where INCo = @inco and Loc = @prodloc
   
   -- #14689 - look for MS Quote overrides
   select @quote = Quote, @pricetemplate = PriceTemplate
   from dbo.bMSQH (nolock)
   where MSCo = @inco and QuoteType = 'I' and INCo = @inco and Loc = @prodloc and Active = 'Y'
   
   -- Price Template in Quote overrides Location
   if @pricetemplate is null set @pricetemplate = @locpricetemplate
   
    
   -- use Bill of Materials override if one exists 
   if exists(select top 1 1 from dbo.bINBO (nolock) where FinMatl = @finmatl and MatlGroup=@matlgroup and INCo=@inco and Loc=@prodloc)
       begin
   	-- use a cursor to process each component in override bill of materials
       declare INBO_cursor cursor LOCAL FAST_FORWARD for
       select CompLoc, CompMatl, Units
       from dbo.bINBO 
       where FinMatl = @finmatl and MatlGroup = @matlgroup and INCo = @inco and Loc = @prodloc
    
       open INBO_cursor
       select @openinbo=1
    
       INBO_cursor_loop:      -- loop through all the components
   		fetch next from INBO_cursor into @comploc, @compmatl, @units
         	if @@fetch_status = 0
            	begin
   			-- get component category and standard unit of measure
            	select @category = Category, @um = StdUM
            	from dbo.bHQMT (nolock)
            	where MatlGroup = @matlgroup and Material = @compmatl
   			if @@rowcount = 0
   				begin
   				select @msg = 'Component material: ' + @compmatl + ' not setup in HQ Materials.', @rcode = 1
   				goto bspexit
   				end
             	-- check for active component at production location, get on-hand qty
            	select @onhand = OnHand
   			from dbo.bINMT (nolock)
   			where Loc = @prodloc and Material = @compmatl and INCo = @inco and MatlGroup = @matlgroup and Active = 'Y'
   			if @@rowcount = 0
                	begin
                	select @inactivematl = @inactivematl + 1
                	goto INBO_cursor_loop       -- skip if component not setup or inactive at production location
      				end
   
   			if @comploc <> @prodloc
   				begin
             		-- check for active component at component location
            		select @onhand = OnHand		-- get on-hand qty from component loction
   				from dbo.bINMT (nolock)
   				where Loc = @comploc and Material = @compmatl and INCo = @inco and MatlGroup = @matlgroup
   					and Active = 'Y'
   				if @@rowcount = 0
                		begin
                		select @inactivematl = @inactivematl + 1
                		goto INBO_cursor_loop       -- skip if component not setup or inactive at component location
      					end
   				end
    
            	-- if component is 'sold' to production location get unit price and ecm from source location
       		if @usageopt = 'S' and @prodloc <> @comploc
                	begin
   				-- #14689 - use MS pricing hierarchy to determine unit price
   				exec @rcode = bspMSTicMatlPriceGet @inco, @matlgroup, @compmatl, @locgroup, @comploc,
   					@um, @quote, @pricetemplate, @proddate, null, null, null, null, @inco, @prodloc, 
   					@invpriceopt, 'I', null, null, @MatlVendor, @VendorGroup,
					@unitprice output, @pecm output, @minamt output, @msg output
   				if @rcode <> 0 goto bspexit
   				end
            	else
                	begin
                	select @unitprice = 0, @pecm = 'E'
                	end
    
            	-- get component cost method
   			select @costmethod = null
            	select @costmethod = CostMethod
            	from dbo.bINLO (nolock)		-- Location/Cateogry override
            	where INCo = @inco and Loc = @comploc and MatlGroup = @matlgroup and Category = @category
             	if isnull(@costmethod,0)= 0
                	begin
                	select @costmethod = CostMethod
                	from bINLM	-- Location override
                	where INCo = @inco and Loc = @comploc
                 	if isnull(@costmethod,0)= 0 select @costmethod = @incocostmethod	-- default cost method
                	end
   
    			-- assign component unit cost and ecm based on cost method
            	select @unitcost = case @costmethod when 1 then AvgCost when 2 then LastCost else StdCost end,
               	@ecm = case @costmethod when 1 then AvgECM when 2 then LastECM else StdECM end
            	from bINMT
            	where Loc = @comploc and Material = @compmatl and INCo = @inco 
   				and MatlGroup = @matlgroup 
    	
   			-- add Production Detail for component
               insert bINPD (Co, Mth, BatchId, BatchSeq, ProdSeq, CompLoc, MatlGroup, CompMatl,
               	UM, Units, UnitCost, ECM, UnitPrice, PECM)
               values (@inco, @mth, @batchid, @batchseq, @autoseq, @comploc, @matlgroup, @compmatl,
                   @um, @units * @produnits, @unitcost, @ecm, @unitprice, @pecm)
   
               select @autoseq = @autoseq + 1       -- increment Prod seq#
   
   			-- check for negative units and increment warning count
   			if @onhand - (@units * @produnits) < 0 select @negunits = @negunits + 1
   
            	goto INBO_cursor_loop             -- get next component
            	end
   		else
   			begin 
   			-- close and deallocate cursor
   	        close INBO_cursor
   	        deallocate INBO_cursor
   	        select @openinbo = 0
   	        end
   	end  -- end of Bll of Materials Override
   else
       begin 	-- use standard Bill of Materials for the Location Group
       -- get Location Group for the Production Location
       select @locgroup = LocGroup
       from dbo.bINLM (nolock) where INCo = @inco and Loc = @prodloc
   	if @@rowcount = 0
   		begin
   		select @msg = 'Invalid Production Location: ' + @prodloc, @rcode = 1
   		goto bspexit
   		end
    	-- check for standard Bill of Materials
       if not exists(select top 1 1 from dbo.bINBM (nolock) where FinMatl = @finmatl and MatlGroup = @matlgroup
        		and INCo = @inco and LocGroup = @locgroup)
            begin
            select @msg = 'No standard Bill of Materials found for Location Group: ' + convert(varchar,@locgroup)
   			+ ' and Material: ' + @finmatl, @rcode=1
            goto bspexit
            end
   
    	-- use a cursor to process each component
       declare INBM_cursor cursor LOCAL FAST_FORWARD for
       select CompMatl, Units
       from dbo.bINBM 
       where FinMatl = @finmatl and MatlGroup = @matlgroup and INCo = @inco and LocGroup = @locgroup
    
       open INBM_cursor
       select @openinbm = 1
    
       INBM_cursor_loop:      --loop through all the components
         	fetch next from INBM_cursor into @compmatl, @units
         	if @@fetch_status = 0
           	begin
             	-- check for active component at production location, get on-hand qty
            	select @onhand = OnHand
   			from dbo.bINMT (nolock)
   			where Loc = @prodloc and Material = @compmatl and INCo = @inco and MatlGroup = @matlgroup and Active = 'Y'
   			if @@rowcount = 0
                	begin
                	select @inactivematl = @inactivematl + 1
                	goto INBM_cursor_loop         -- skip if component not setup or inactive at production location
       			end
    
            	-- get component info from HQ Material
            	select @category = Category, @um = StdUM
            	from dbo.bHQMT (nolock)
            	where MatlGroup = @matlgroup and Material = @compmatl
   			if @@rowcount = 0
   				begin
   				select @msg = 'Component material: ' + @compmatl + ' not setup in HQ Materials.', @rcode = 1
   				goto bspexit
   				end
    
            	--get unit cost based on cost method
   			select @costmethod = null
            	select @costmethod = CostMethod
            	from bINLO		-- check for Location/Category override
            	where INCo = @inco and Loc = @prodloc and MatlGroup = @matlgroup and Category = @category
             	if isnull(@costmethod,0) = 0
                	begin
                	select @costmethod = CostMethod
                	from dbo.bINLM	(nolock)	-- check for Location override
                	where INCo = @inco and Loc = @prodloc
                 	if isnull(@costmethod,0) = 0 select @costmethod = @incocostmethod	-- default cost method
                	end
    
   			-- get component unit cost
            	select @unitcost = case @costmethod when 1 then AvgCost when 2 then LastCost else StdCost end,
                   @ecm = case @costmethod when 1 then AvgECM when 2 then LastECM else StdECM end
            	from dbo.bINMT (nolock)
            	where Loc = @prodloc and Material = @compmatl and INCo = @inco and MatlGroup = @matlgroup
   
             	-- unit price and ecm are 0.00 and 'E' because source and production location are equal
     
   			-- add Production detail for component
               insert bINPD (Co, Mth, BatchId, BatchSeq, ProdSeq, CompLoc, MatlGroup, CompMatl,
               	UM, Units, UnitCost, ECM, UnitPrice, PECM)
               values (@inco, @mth, @batchid, @batchseq, @autoseq, @prodloc, @matlgroup, @compmatl,
                   @um, @units * @produnits, @unitcost, @ecm, 0, 'E')
    
               select @autoseq = @autoseq + 1       -- increment Prod seq#
   
   			-- check for negative units and increment warning count
   			if @onhand - (@units * @produnits) < 0 select @negunits = @negunits + 1
   	
               goto INBM_cursor_loop            -- get next component
            	end
   		else
   			begin 
   			-- close and deallocate cursor
   	        close INBM_cursor
   	        deallocate INBM_cursor
   	        select @openinbm = 0
   			end
        end   -- finished with standard Bill of Materials
    
   bspexit:
       if @openinbo=1
           begin
           close INBO_cursor
           deallocate INBO_cursor
           end
       if @openinbm=1
           begin
           close INBM_cursor
           deallocate INBM_cursor
           end
    
--       if @rcode <> 0 select @msg
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINPDInitialize] TO [public]
GO
