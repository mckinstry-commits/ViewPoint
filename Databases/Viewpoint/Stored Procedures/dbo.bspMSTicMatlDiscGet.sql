SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[bspMSTicMatlDiscGet]
    /*************************************
     * Created By:   GF 07/06/2000
     * Modified By:  GF 08/02/2001 - fix for zero discount rate
     *				  GF 11/06/2003 - issue #18762 - use MSQH.PayTerms if not null else ARCM.PayTerms
     *
     * USAGE:   Called from other MSTicEntry SP to get default discount rate.
     *
     *
     * INPUT PARAMETERS
     *  MS Company, MatlGroup, Material, Category, LocGroup, FromLoc, UM, Quote, DiscTemplate
     *
     * OUTPUT PARAMETERS
     *  PayDiscRate
     *  @msg      error message if error occurs
     * RETURN VALUE
     *   0         Success
     *   1         Failure
     *
     **************************************/
    (@msco bCompany = null, @matlgroup bGroup = null, @material bMatl = null,
     @category varchar(10) = null, @locgroup bGroup = null, @fromloc bLoc = null,
     @um bUM = null, @quote varchar(10) = null, @disctemplate smallint = null,
     @paydiscrate bUnitCost output, @found tinyint output, @msg varchar(255) output)
    as
    set nocount on
    
    declare @rcode int, @validcnt int, @payterms bPayTerms, @hqpt_discrate bUnitCost
    
    select @rcode = 0, @paydiscrate = 0, @hqpt_discrate = 0, @found = 1
    
    -- look for discount rate from MSDX
    if @quote is not null
    BEGIN
   	-- check for pay terms override - if exists get rate then lookup for override
   	select @payterms=PayTerms from bMSQH with (nolock) where MSCo=@msco and Quote=@quote
   	if isnull(@payterms,'') <> ''
   		begin
   		select @hqpt_discrate=DiscRate from bHQPT with (nolock) where PayTerms=@payterms
   		end
   
        -- only search levels 1-2 if from location is not null
        if @fromloc is not null
        BEGIN
            -- first level
            if @material is not null
                begin
                select @paydiscrate=PayDiscRate from bMSDX with (nolock) 
                where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and Loc=@fromloc
                and MatlGroup=@matlgroup and Category=@category and Material=@material and UM=@um
                if @@rowcount <> 0 goto bspexit
                end
            -- second level
            select @paydiscrate=PayDiscRate from bMSDX with (nolock) 
            where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and Loc=@fromloc
            and MatlGroup=@matlgroup and Category=@category and Material is null and UM=@um
            if @@rowcount <> 0 goto bspexit
        END
        -- third level
        if @material is not null
            begin
            select @paydiscrate=PayDiscRate from bMSDX with (nolock) 
            where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and Loc is null
            and MatlGroup=@matlgroup and Category=@category and Material=@material and UM=@um
            if @@rowcount <> 0 goto bspexit
            end
        -- fourth level
        select @paydiscrate=PayDiscRate from bMSDX with (nolock) 
        where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and Loc is null
        and MatlGroup=@matlgroup and Category=@category and Material is null and UM=@um
        if @@rowcount <> 0 goto bspexit
    END
    
    -- get discount rate from MSDD
    if @disctemplate is not null
    BEGIN
        -- only search levels 1-2 if from location is not null
        if @fromloc is not null
        BEGIN
            -- first level
            if @material is not null
                begin
                select @paydiscrate=PayDiscRate from bMSDD with (nolock) 
                where MSCo=@msco and DiscTemplate=@disctemplate and LocGroup=@locgroup and FromLoc=@fromloc
                and MatlGroup=@matlgroup and Category=@category and Material=@material and UM=@um
                if @@rowcount <> 0 goto bspexit
                end
            -- second level
            select @paydiscrate=PayDiscRate from bMSDD with (nolock) 
            where MSCo=@msco and DiscTemplate=@disctemplate and LocGroup=@locgroup and FromLoc=@fromloc
            and MatlGroup=@matlgroup and Category=@category and Material is null and UM=@um
            if @@rowcount <> 0 goto bspexit
        END
        -- third level
        if @material is not null
            begin
            select @paydiscrate=PayDiscRate from bMSDD with (nolock) 
            where MSCo=@msco and DiscTemplate=@disctemplate and LocGroup=@locgroup and FromLoc is null
            and MatlGroup=@matlgroup and Category=@category and Material=@material and UM=@um
            if @@rowcount <> 0 goto bspexit
            end
        -- fourth level
        select @paydiscrate=PayDiscRate from bMSDD with (nolock) 
        where MSCo=@msco and DiscTemplate=@disctemplate and LocGroup=@locgroup and FromLoc is null
        and MatlGroup=@matlgroup and Category=@category and Material is null and UM=@um
        if @@rowcount <> 0 goto bspexit
    END
   
   -- use quote pay terms override if there is one
   if @hqpt_discrate <> 0
   	set @paydiscrate=@hqpt_discrate
   else
    	set @found = 0



bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTicMatlDiscGet] TO [public]
GO
