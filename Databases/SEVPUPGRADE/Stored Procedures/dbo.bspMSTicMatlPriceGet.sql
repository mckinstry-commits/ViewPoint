SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/********************************************/
CREATE     proc [dbo].[bspMSTicMatlPriceGet]
   /*************************************
    * Created By:	GF 07/11/2000
    * Modified By: GG 08/12/02 - #17811 - old/new template pricing, added @saledate input
    *				GF 03/07/2003 - issue #20673 - when checking date for OldMinAmt was using NewRate. whoops
    *				GF 01/14/2003 - issue #23491 - last cost not being set correctly for non std um.
    *				GF 03/17/2004 - issue #24038 - pass in phase group and phase for pricing
    *				GF 08/08/2005 - issue #29515 um conversion factors should be defined as bUnitCost.
	*				GP 06/09/2008 - Issue #127986 - added input params MatlVendor and VendorGroup. Return 
	*									UnitPrice & ECM when MatlVendor and VendorGroup exist.
	*				GP 08/13/2008 - Issue #129396 - moved code to find UnitPrice & ECM when @phase is null
	*									outside of check for null @phase.
	*				DAN SO 09/15/2009 - Issue #135570 - Get UnitPrice with specific MatlVendor
	*				GF 08/16/2012 TK-17224 need a found flag for price template detail found may be problem for existing customers
	*				GF 08/16/2012 TK-17221 do not use vendor group for material vendor price find
    *
    *
    *
    * USAGE:   Called from other MSTicEntry SP to get default
    *  unit price and ecm.
    * ALSO USING IN PM FOR Quote and Material Order Pricing. BE CAREFUL!!
    *
    * INPUT PARAMETERS
    *  MS Company, MatlGroup, Material, LocGroup, FromLoc, UM, Quote, PriceTemplate,
    *  JC Company, Job, CustGroup, Customer, IN To Company, IN To Location, PriceOpt, SalesType
    *
    * OUTPUT PARAMETERS
    *  Unit Price
    *  ECM
    *  Minimum Amount
    *  @msg      error message if error occurs
    * RETURN VALUE
    *   0         Success
    *   1         Failure
    *
    **************************************/
   (@msco bCompany = null, @matlgroup bGroup = null, @material bMatl = null, @locgroup bGroup = null,
    @fromloc bLoc = null, @um bUM = null, @quote varchar(10) = null, @pricetemplate smallint = null,
    @saledate bDate = null, @tojcco bCompany = null, @job bJob = null, @custgroup bGroup = null,
    @customer bCustomer = null, @toinco bCompany = null, @toloc bLoc = null, @priceopt tinyint = null,
    @salestype char(1) = null, @phasegroup bGroup = null, @phase bPhase = null,
	@MatlVendor bVendor = null, @VendorGroup bGroup = null,  
    @unitprice bUnitCost = null output, @ecm bECM = null output, @minamt bDollar = null output,
    @msg varchar(255) output)
   as
   set nocount on
    
declare @rcode int, @msqd_found tinyint, @msqdup bUnitCost, @msqdecm bECM, @rate bRate, @stdum bUM,
		@stdunitcost bUnitCost, @stdecm bECM, @torate bRate, @applyrate bRate, @injobrate bRate,
		@incustrate bRate, @ininvrate bRate, @lastcost bUnitCost, @lastcostecm bECM,
		@avgcost bUnitCost, @avgcostecm bECM, @stdprice bUnitCost, @stdpriceecm bECM,
		@inumconv bUnitCost, @incost bUnitCost, @incostecm bECM, @inprice bUnitCost, @inpriceecm bECM,
		@hqumconv bUnitCost, @hqcost bUnitCost, @hqcostecm bECM, @hqprice bUnitCost,
		@hqpriceecm bECM, @category varchar(10), @salesum bUM, @salesunitcost bUnitCost,
		@salesecm bECM, @stocked bYN, @effectivedate bDate, @inlastcost bUnitCost,
		@pphase bPhase, @validphasechars INT
		----TK-17224
		,@MSMD_Found TINYINT, @MSTP_Found TINYINT
    
   
select @rcode = 0, @msqd_found = 0, @unitprice = 0, @ecm = 'E', @torate = 0, @applyrate = 0,
       @msqdup = 0, @msqdecm = 'E', @unitprice = 0, @minamt = 0
       
----TK-17224
SET @MSMD_Found = 0
SET @MSTP_Found = 0

----TK-17221 if missing vendor group get it
IF @VendorGroup IS NULL
	BEGIN
	SELECT @VendorGroup = h.VendorGroup
	FROM dbo.bMSCO m
	JOIN dbo.bHQCO h ON h.HQCo = m.APCo
	WHERE m.MSCo = @msco
	END

-- set HQMT variables
select @stdum=StdUM, @stdunitcost=Cost, @stdecm=CostECM, @salesum=SalesUM,
      @salesunitcost=Price, @salesecm=PriceECM, @category=Category, @stocked=Stocked
from bHQMT with (nolock) where MatlGroup=@matlgroup and Material=@material
if @@rowcount = 0
     begin
     select @msg = 'Material not set up in HQ Material', @rcode = 1
     goto bspexit
     end

-- validate JC Company -  get valid portion of phase code
SET @validphasechars = 0
if @tojcco is not null
	begin
	select @validphasechars = ValidPhaseChars from JCCO with (nolock) where JCCo = @tojcco
	if @@rowcount = 0 set @validphasechars = len(@phase)
	end

-- format valid portion of Phase
SET @pphase = NULL
if isnull(@phase,'') <> ''
	begin
	if @validphasechars > 0
		set @pphase = substring(@phase,1,@validphasechars) + '%'
	else
		set @pphase = @phase
	end

   
   
   -- SECTION ONE:
   -- get material unit price defaults. Look for defaults by quote
   -- or price template in MS first. If found with a valid unit price then you are done.
   -- look for unit price in MSQD quote detail - need to consider job quotes and use phase
   if @quote is not null and @material is not null and @fromloc is not null
   begin
   		-- look for MSQD using phase group and phase if Job Sale
   		if @tojcco is not null and @phase is not null
   		begin

			-- Issue 127986
			-- Return UnitPrice and ECM based on input of MatlVendor/VendorGroup
			IF @MatlVendor is not null and @VendorGroup is not null
				BEGIN
				SELECT @msqdup=UnitPrice, @msqdecm=ECM
				FROM bMSQD 
				WHERE MSCo=@msco and Quote=@quote and FromLoc=@fromloc and MatlGroup=@matlgroup 
					and Material=@material and UM=@um and PhaseGroup=@phasegroup and Phase=@phase 
					and MatlVendor=@MatlVendor and VendorGroup=@VendorGroup
				IF @@rowcount <> 0
					BEGIN
					SET @msqd_found = 1
					GOTO MSMD_Price_Overrides
					END

				-- Search MSQD using valid part phase and with MatlVendor/VendorGroup 
				SELECT TOP 1 @msqdup=UnitPrice, @msqdecm=ECM
				FROM bMSQD 
				WHERE MSCo=@msco and Quote=@quote and FromLoc=@fromloc and MatlGroup=@matlgroup 
					and Material=@material and UM=@um and PhaseGroup=@phasegroup and Phase like @pphase
					and MatlVendor=@MatlVendor and VendorGroup=@VendorGroup
				GROUP BY MSCo, Quote, FromLoc, MatlGroup, Material, UM, PhaseGroup, Phase, MatlVendor, VendorGroup, UnitPrice, ECM
				IF @@rowcount <> 0 
					BEGIN
					SET @msqd_found = 1
					GOTO MSMD_Price_Overrides
					END
				
			END --IF @MatlVendor is not null


   			select @msqdup=UnitPrice, @msqdecm=ECM
   			from bMSQD where MSCo=@msco and Quote=@quote and FromLoc=@fromloc
   			and MatlGroup=@matlgroup and Material=@material and UM=@um
   			and PhaseGroup=@phasegroup and Phase=@phase
   			if @@rowcount <> 0
   				begin
   				set @msqd_found = 1
   				goto MSMD_Price_Overrides
   				end
   
   			-- search MSQD using valid part phase 
   			select Top 1 @msqdup=UnitPrice, @msqdecm=ECM
   			from bMSQD where MSCo=@msco and Quote=@quote and FromLoc=@fromloc
   			and MatlGroup=@matlgroup and Material=@material and UM=@um
   			and PhaseGroup=@phasegroup and Phase like @pphase
   			group by MSCo, Quote, FromLoc, MatlGroup, Material, UM, PhaseGroup, Phase, UnitPrice, ECM
   			if @@rowcount <> 0 
   				begin
   				set @msqd_found = 1
   				goto MSMD_Price_Overrides
   				end
   		
   		end --if @tojcco is not null and @phase is not null


		-- Issue 127986/129396
		IF @MatlVendor IS NOT NULL and @VendorGroup is not null
			BEGIN
			-- Look for MSQD without phase and with MatlVendor/VendorGroup
			SELECT @msqdup=UnitPrice, @msqdecm=ECM
			FROM bMSQD with(nolock) 
			WHERE MSCo=@msco and Quote=@quote and FromLoc=@fromloc and MatlGroup=@matlgroup 
				and Material=@material and UM=@um and Phase is null 
				and MatlVendor=@MatlVendor and VendorGroup=@VendorGroup
			IF @@rowcount <> 0 
				BEGIN
				SET @msqd_found = 1
				GOTO MSMD_Price_Overrides
				END
			END --IF @MatlVendor is not null
   

   		-- look for MSQD without phase
   		select top 1 @msqdup=UnitPrice, @msqdecm=ECM
   		from bMSQD with (nolock) where MSCo=@msco and Quote=@quote and FromLoc=@fromloc
   		and MatlGroup=@matlgroup and Material=@material and UM=@um and Phase is null
		order by MSCo, Quote, FromLoc, Material, UM, MatlVendor
   		if @@rowcount <> 0 select @msqd_found = 1
   	
   end --if @quote is not null and @material is not null and @fromloc is not null
   
   
MSMD_Price_Overrides:
-- look for unit price in MSMD price overrides for quote
-- added phase group and phase levels to search of MSMD
if @quote is not null and @locgroup is not null and @category is not null
   	begin
   
   	-- first level with location and phase
   	if @tojcco is not null and @phase is not null
   		begin
   		select @unitprice=UnitPrice, @ecm=ECM, @rate=Rate, @minamt=MinAmt
   		from bMSMD with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and Loc=@fromloc
   		and MatlGroup=@matlgroup and Category=@category and UM=@um
   		and PhaseGroup=@phasegroup and Phase=@phase
   		if @@rowcount <> 0
   			BEGIN
   			SET @MSMD_Found = 1
   			GOTO cleanup
			END
			
   		-- second level with location and valid part phase
   		select Top 1 @unitprice=UnitPrice, @ecm=ECM, @rate=Rate, @minamt=MinAmt
   		from bMSMD with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and Loc=@fromloc
   		and MatlGroup=@matlgroup and Category=@category and UM=@um
   		and PhaseGroup=@phasegroup and Phase like @pphase
   		group by MSCo, Quote, LocGroup, Loc, MatlGroup, Category, UM, PhaseGroup, Phase, UnitPrice, ECM, Rate, MinAmt
   		if @@rowcount <> 0
   			BEGIN
   			SET @MSMD_Found = 1
   			GOTO cleanup
			END
   
   		-- third level phase and no location
   		select @unitprice=UnitPrice, @ecm=ECM, @rate=Rate, @minamt=MinAmt
   		from bMSMD with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and Loc is null
   		and MatlGroup=@matlgroup and Category=@category and UM=@um
   		and PhaseGroup=@phasegroup and Phase=@phase
   		if @@rowcount <> 0
   			BEGIN
   			SET @MSMD_Found = 1
   			GOTO cleanup
			END
   
   		-- fourth level valid part phase and no location
   		select Top 1 @unitprice=UnitPrice, @ecm=ECM, @rate=Rate, @minamt=MinAmt
   		from bMSMD with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and Loc is null
   		and MatlGroup=@matlgroup and Category=@category and UM=@um
   		and PhaseGroup=@phasegroup and Phase like @pphase
   		group by MSCo, Quote, LocGroup, Loc, MatlGroup, Category, UM, PhaseGroup, Phase, UnitPrice, ECM, Rate, MinAmt
   		if @@rowcount <> 0
   			BEGIN
   			SET @MSMD_Found = 1
   			GOTO cleanup
			END
			
   		END ---- end tojcco and phase
   
   	-- fifth level with location and no phase
   	select @unitprice=UnitPrice, @ecm=ECM, @rate=Rate, @minamt=MinAmt
   	from bMSMD with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and Loc=@fromloc
   	and MatlGroup=@matlgroup and Category=@category and UM=@um and Phase is null
   	if @@rowcount <> 0
		BEGIN
		SET @MSMD_Found = 1
		GOTO cleanup
		END
   
   	-- sixth level with no location and no phase
   	select @unitprice=UnitPrice, @ecm=ECM, @rate=Rate, @minamt=MinAmt
   	from bMSMD with (nolock) where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and Loc is null
   	and MatlGroup=@matlgroup and Category=@category and UM=@um and Phase is null
   	if @@rowcount <> 0
		BEGIN
		SET @MSMD_Found = 1
		GOTO cleanup
		END
			
	END ---- end quote, locgroup, category
	
    
-- look for unit price in MSTP price templates
if @pricetemplate is not null and @locgroup is not null and @category is not null
	BEGIN
	-- get Template effective date - #17811
	select @effectivedate = EffectiveDate from bMSTH where MSCo = @msco and PriceTemplate = @pricetemplate
    -- only search levels 1-2 if from location is not null
    if @fromloc is not null
 		BEGIN
        -- first level
        if @material is not null
        	BEGIN
			-- #17811 pull old/new rate based on dates
            select @unitprice = case when @saledate < @effectivedate then OldUnitPrice else NewUnitPrice end,
				@ecm = case when @saledate < @effectivedate then OldECM else NewECM end,
				@rate = case when @saledate < @effectivedate then OldRate else NewRate end,
				@minamt = case when @saledate < @effectivedate then OldMinAmt else NewMinAmt end
            from bMSTP with (nolock) 
			where MSCo=@msco and PriceTemplate=@pricetemplate and LocGroup=@locgroup
            and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
            and Material=@material and UM=@um
   			if @@rowcount <> 0
				BEGIN
				SET @MSTP_Found = 1
				GOTO cleanup
				END
            END ----end material
            
		-- second level
		-- #17811 pull old/new rate based on dates
        select @unitprice = case when @saledate < @effectivedate then OldUnitPrice else NewUnitPrice end,
			@ecm = case when @saledate < @effectivedate then OldECM else NewECM end,
			@rate = case when @saledate < @effectivedate then OldRate else NewRate end,
			@minamt = case when @saledate < @effectivedate then OldMinAmt else NewMinAmt end
        from bMSTP with (nolock) 
		where MSCo=@msco and PriceTemplate=@pricetemplate and LocGroup=@locgroup
        and FromLoc=@fromloc and MatlGroup=@matlgroup and Category=@category
        and Material is null and UM=@um
   		if @@rowcount <> 0
			BEGIN
			SET @MSTP_Found = 1
			GOTO cleanup
			END
     	END ----end from lOC
     	
	-- third level
    if @material is not null
		BEGIN
		-- #17811 pull old/new rate based on dates
        select @unitprice = case when @saledate < @effectivedate then OldUnitPrice else NewUnitPrice end,
			@ecm = case when @saledate < @effectivedate then OldECM else NewECM end,
			@rate = case when @saledate < @effectivedate then OldRate else NewRate end,
			@minamt = case when @saledate < @effectivedate then OldMinAmt else NewMinAmt end
        from bMSTP with (nolock) 
		where MSCo=@msco and PriceTemplate=@pricetemplate and LocGroup=@locgroup
         	and FromLoc is null and MatlGroup=@matlgroup and Category=@category and Material=@material and UM=@um
		if @@rowcount <> 0
			BEGIN
			SET @MSTP_Found = 1
			GOTO cleanup
			END
        END ---- end material
            
	-- fourth level
	-- #17811 pull old/new rate based on dates
	select @unitprice = case when @saledate < @effectivedate then OldUnitPrice else NewUnitPrice end,
			@ecm = case when @saledate < @effectivedate then OldECM else NewECM end,
			@rate = case when @saledate < @effectivedate then OldRate else NewRate end,
			@minamt = case when @saledate < @effectivedate then OldMinAmt else NewMinAmt end
    from bMSTP with (nolock) 
	where MSCo=@msco and PriceTemplate=@pricetemplate and LocGroup=@locgroup
    	and FromLoc is null and MatlGroup=@matlgroup and Category=@category and Material is null and UM=@um
	if @@rowcount <> 0
		BEGIN
		SET @MSTP_Found = 1
		GOTO cleanup
		END
	END ---- end price template
   
   
cleanup:

if @msqd_found <> 0
	begin
	select @unitprice = @msqdup, @ecm=@msqdecm, @rate = 0
	goto bspexit
	end

if @unitprice <> 0
	begin
	if @ecm is null select @ecm = 'E', @rate = 0
	goto bspexit
	end
    
IF @rate IS NULL SET @rate = 0
IF @ecm IS NULL SET @ecm = 'E'
    
----TK-17224 quote price detail defaults found
IF @MSMD_Found > 0 GOTO bspexit

----TK-177224 price template defaults found
IF @MSTP_Found > 0 GOTO bspexit	



-- SECTION TWO:
-- get defaults using pricing options in IN and the markup/discount rates from
-- ARCM, JCJM tables. Apply to standard prices in IN materials for stocked or
-- HQ Materials for non-stocked. If a markup/discount rate was found in
-- section one, then that rate is used to calculate unit price.
    
    
-- set rate by sales type if no applicable rate in MS
if @rate = 0
	BEGIN
	if @salestype = 'J'
		begin
        -- set job markup/discount rate
        select @torate=MarkUpDiscRate
        from bJCJM with (nolock) where JCCo=@tojcco and Job=@job
        if @@rowcount = 0 select @torate = 0
        end
    if @salestype = 'C'
        begin
        -- set customer markup/discount rate
        select @torate=MarkupDiscPct
        from bARCM with (nolock) where CustGroup=@custgroup and Customer=@customer
        if @@rowcount = 0 select @torate = 0
        end
    if @salestype = 'I'
        begin
        -- no applicable rate for inventory to location
        select @torate = 0
        end
	END
    
-- use rate from MS if not zero
if @rate <> 0 select @torate = @rate
if @torate is null select @torate = 0
    
-- handle non-stocked material
if @stocked = 'N'
	BEGIN
    if @stdum <> @um
		begin
        select @salesunitcost=Price, @salesecm=PriceECM
        from bHQMU with (nolock) 
		where MatlGroup=@matlgroup and Material=@material and UM=@um
        if @@rowcount = 0
			begin
            select @salesunitcost = 0, @salesecm = 'E'
            end
        end
    select @ecm=@salesecm, @unitprice=@salesunitcost - (@salesunitcost*@torate)
    goto bspexit
 	END
    
    -- handle stocked material
    select @lastcost=LastCost, @lastcostecm=LastECM, @avgcost=AvgCost, @avgcostecm=AvgECM,
    	   @stdunitcost=StdCost, @stdecm=StdECM, @stdprice=StdPrice, @stdpriceecm=PriceECM,
           @injobrate=JobRate, @incustrate=CustRate, @ininvrate=InvRate
    from bINMT with (nolock) 
    where INCo=@msco and Loc=@fromloc and MatlGroup=@matlgroup and Material=@material
    if @@rowcount = 0
         begin
         select @msg = 'Not set up in IN Materials', @rcode=1
         goto bspexit
         end
    
    -- check to rate by sales type
    if @salestype = 'J'
    	begin
        if @torate <> 0 select @applyrate=@torate
        if @applyrate = 0 and @injobrate <> 0 select @applyrate = @injobrate
       	end
    if @salestype = 'C'
        begin
        if @torate <> 0 select @applyrate=@torate
        if @applyrate = 0 and @incustrate <> 0 select @applyrate = @incustrate
        end
    if @salestype = 'I'
        begin
        if @torate <> 0 select @applyrate=@torate
        if @applyrate = 0 and @ininvrate <> 0 select @applyrate = @ininvrate
        end
   
   
   if @um <> @stdum
   	begin
       select @inumconv=Conversion, @incost=StdCost, @incostecm=StdCostECM,
        	   @inprice=Price, @inpriceecm=PriceECM, @inlastcost=LastCost
   	from bINMU with (nolock) 
   	where MatlGroup=@matlgroup and INCo=@msco and Material=@material and Loc=@fromloc and UM=@um
   	if @@rowcount <> 0
   		begin
   		select @avgcost = @avgcost * @inumconv,
                  @stdunitcost = @incost, @stdprice = @inprice, 
    			   @stdecm = @incostecm, @stdpriceecm = @inpriceecm,
    			   @lastcost = @inlastcost --@lastcost * @inumconv
    			   -- @lastcost= case when @inlastcost = 0 then @lastcost * @inumconv else @inlastcost end
   		end
   	else
   		begin
   		select @hqumconv=Conversion, @hqcost=Cost, @hqcostecm=CostECM, @hqprice=Price, @hqpriceecm=PriceECM
   		from HQMU with (nolock) 
    		where MatlGroup=@matlgroup and Material=@material and UM = @um
   		if @@rowcount <> 0
   			begin
   			select @avgcost = @avgcost * @hqumconv, 
   				   @lastcost = @hqcost, --@lastcost * @hqumconv,
                	   @stdunitcost=@hqcost, @stdprice=@hqprice, 
   				   @stdecm=@hqcostecm, @stdpriceecm=@hqpriceecm
   			end
   		end
   	end
   
   
if @priceopt = 1
	begin
	select  @unitprice = @avgcost + (@avgcost*@applyrate), @ecm=@avgcostecm
	goto bspexit
	end

if @priceopt = 2
	begin
	select  @unitprice = @lastcost + (@lastcost*@applyrate), @ecm=@lastcostecm
	goto bspexit
	end

if @priceopt = 3
	begin
	select  @unitprice = @stdunitcost + (@stdunitcost*@applyrate), @ecm=@stdecm
	goto bspexit
	end

if @priceopt = 4
	begin
	select  @unitprice = @stdprice -(@stdprice*@applyrate), @ecm=@stdpriceecm
	goto bspexit
	end



bspexit:
	if @rcode <> 0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTicMatlPriceGet] TO [public]
GO
