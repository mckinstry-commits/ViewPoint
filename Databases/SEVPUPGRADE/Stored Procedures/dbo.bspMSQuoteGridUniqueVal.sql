SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspMSQuoteGridUniqueVal]
   /*************************************
   * Created By:   GF 03/15/2000
   * Modified By:  GF 10/11/2000
   *				GF 03/15/2004 - issue #24036 - changes for pricing by phase. New table bMSHO also
   *				DAN SO 10/30/2009 - ISSUE: #129350 - Handle Surcharge Overrides
   *
   * validates table uniqueness for the following MS Quote Tables:
   * MSQD: MSCo,Quote,Loc,MatlGroup,Material,UM,PhaseGroup,Phase
   * MSMD: MSCo,Quote,LocGroup,Loc,MatlGroup,Category,UM,PhaseGroup,Phase
   * MSDX: MSCo,Quote,LocGroup,Loc,MatlGroup,Category,Material,UM
   * MSHX: MSCo,Quote,LocGroup,Loc,MatlGroup,Category,Material,TruckType,UM,HaulCode
   * MSPX: MSCo,Quote,LocGroup,Loc,MatlGroup,Category,Material,TruckType,VendorGroup,Vendor,Truck,UM,PayCode
   * MSJP: MSCo,Quote,LocGroup,Loc,MatlGroup,Category,Material
   * MSHO: MSCo,Quote,LocGroup,Loc,MatlGroup,Category,Material,TruckType,UM,HaulCode,PhaseGroup,Phase
   * MSSurchargeOverrides: MSCo,Quote,LocGroup,Loc,MatlGroup,Category,Material,TruckType,UM,SurchargeCode
   *
   * Pass:
   *   MSCo,Quote,Table,LocGroup,Loc,MatlGroup,Category,Material,UM,
   *   TruckType,HaulCode,VendorGroup,Vendor,Truck,PayCode,Seq,PhaseGroup,Phase
   *   MatlVendor,SurchargeCode,EffectiveDate
   *
   * Success returns:
   *	0
   *
   * Error returns:
   *	1 and error message
   **************************************/
   (@msco bCompany = null, @quote varchar(10) = null, @table varchar(30) = null,
    @locgroup bGroup, @loc bLoc = NULL, @matlgroup bGroup, @category varchar(10) = null,
    @material bMatl = null, @um bUM = null, @trucktype varchar(10) = null, @haulcode bHaulCode = null,
    @vendorgroup bGroup = null, @vendor bVendor = null, @truck bTruck = null, @paycode bPayCode = null,
    @seq int = null, @phasegroup bGroup = null, @phase bPhase = null, @MatlVendor bVendor = null,
    @SurchargeCode smallint = null, @EffectiveDate bDate = null, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int, @validcnt int, @quotetype char(1)
   
   select @rcode = 0, @msg=''
	
   if @msco is null
       begin
       select @msg = 'Missing MS Company!', @rcode=1
       goto bspexit
       end
   
   if @quote is null
       begin
       select @msg = 'Missing Quote!', @rcode=1
       goto bspexit
       end
   
   if @table is null
       begin
       select @msg = 'Missing Quote Detail Table Name', @rcode=1
       goto bspexit
       end
   
   -- validate quote - get quote type
   select @quotetype=QuoteType from bMSQH with (nolock) where MSCo=@msco and Quote=@quote
   if @@rowcount = 0
       begin
       select @msg = 'Invalid MS Quote', @rcode=1
       goto bspexit
       end
   
   
   -- check for table uniqueness
   if @table='MSQD'
       begin
       if @seq is null
           begin
   		if @quotetype = 'J'
   			begin
   	        select @validcnt = Count(*) from bMSQD with (nolock) 
   	        where MSCo=@msco and Quote=@quote and FromLoc=@loc and MatlGroup=@matlgroup 
   			and Material=@material and UM=@um and PhaseGroup=@phasegroup 
			and isnull(MatlVendor,'')=isnull(@MatlVendor,'')
   			and isnull(Phase,'')=isnull(@phase,'')
	 	    if @validcnt >0
   	            begin
   	            select @msg = 'Duplicate record, cannot insert!', @rcode=1
   	            goto bspexit
   	            end
   	        else
   	            goto bspexit
   			end
   		else
   			begin
   	        select @validcnt = Count(*) from bMSQD with (nolock) 
   	        where MSCo=@msco and Quote=@quote and FromLoc=@loc and MatlGroup=@matlgroup 
   			and Material=@material and UM=@um and PhaseGroup is null and Phase is null 
			and isnull(MatlVendor,'')=isnull(@MatlVendor,'')
   	        if @validcnt >0
   	            begin
   	            select @msg = 'Duplicate record, cannot insert!', @rcode=1
   	            goto bspexit
   	            end
   	        else
   	            goto bspexit
   			end
   		end
       else
           begin
   		if @quotetype = 'J'
   			begin
   	        select @validcnt = Count(*) from bMSQD with (nolock) 
   	        where MSCo=@msco and Quote=@quote and FromLoc=@loc and MatlGroup=@matlgroup 
   			and Material=@material and UM=@um and Seq<>@seq 
			and isnull(MatlVendor,'')=isnull(@MatlVendor,'')
   			and PhaseGroup=@phasegroup and isnull(Phase,'')=isnull(@phase,'')
   	        if @validcnt >0
   	            begin
   	            select @msg = 'Duplicate record, cannot insert!', @rcode=1
   	            goto bspexit
   	            end
   	        else
   	            goto bspexit
   			end
   		else
   			begin
   	        select @validcnt = Count(*) from bMSQD with (nolock) 
   	        where MSCo=@msco and Quote=@quote and FromLoc=@loc and MatlGroup=@matlgroup 
   			and Material=@material and UM=@um and Seq<>@seq 
			and isnull(MatlVendor,'')=isnull(@MatlVendor,'')
   			and PhaseGroup is null and Phase is null
   	        if @validcnt >0
   	            begin
   	            select @msg = 'Duplicate record, cannot insert!', @rcode=1
   	            goto bspexit
   	            end
   	        else
   	            goto bspexit
   	        end
   		end
   	goto bspexit
       end
   
   
   
   IF @table='MSMD'
       begin
       if @seq is null
           begin
   		if @quotetype = 'J'
   			begin
   	        select @validcnt = Count(*) from bMSMD with (nolock)
   	        where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and Loc=@loc
   	        and MatlGroup=@matlgroup and Category=@category and UM=@um
   			and PhaseGroup=@phasegroup and isnull(Phase,'')=isnull(@phase,'')
   	        if @validcnt >0
   	            begin
   	            select @msg = 'Duplicate record, cannot insert!', @rcode=1
   	            goto bspexit
   	            end
   	        else
   	            goto bspexit
   			end
   		else
   			begin
   	        select @validcnt = Count(*) from bMSMD with (nolock) 
   	        where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and Loc=@loc
   	        and MatlGroup=@matlgroup and Category=@category and UM=@um
   			and PhaseGroup is null and Phase is null
   	        if @validcnt >0
   	            begin
   	            select @msg = 'Duplicate record, cannot insert!', @rcode=1
   	            goto bspexit
   	            end
   	        else
   	            goto bspexit
   			end
   		end
       else
           begin
   		if @quotetype = 'J'
   			begin
   	        select @validcnt = Count(*) from bMSMD with (nolock) 
   	        where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and Loc=@loc
   	        and MatlGroup=@matlgroup and Category=@category and UM=@um and Seq<>@seq
   			and PhaseGroup=@phasegroup and isnull(Phase,'')=isnull(@phase,'')
   	        if @validcnt >0
   	            begin
   	            select @msg = 'Duplicate record, cannot insert!', @rcode=1
   	            goto bspexit
   	            end
   	        else
   	            goto bspexit
   			end
   		else
   			begin
   	        select @validcnt = Count(*) from bMSMD with (nolock) 
   	        where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and Loc=@loc
   	        and MatlGroup=@matlgroup and Category=@category and UM=@um and Seq<>@seq
   			and PhaseGroup is null and Phase is null
   	        if @validcnt >0
   	            begin
   	            select @msg = 'Duplicate record, cannot insert!', @rcode=1
   	            goto bspexit
   	            end
   	        else
   	            goto bspexit
   	        end
   		end
   	goto bspexit
       end
   
   
   IF @table='MSDX'
       begin
       if @seq is null
           begin
           select @validcnt = Count(*) from bMSDX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and Loc=@loc
           and MatlGroup=@matlgroup and Category=@category and Material=@material and UM=@um
           if @validcnt >0
               begin
               select @msg = 'Duplicate record, cannot insert!', @rcode=1
               goto bspexit
               end
           else
               goto bspexit
           end
       else
           begin
           select @validcnt = Count(*) from bMSDX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and Loc=@loc
           and MatlGroup=@matlgroup and Category=@category and Material=@material and UM=@um
           and Seq<>@seq
           if @validcnt >0
               begin
               select @msg = 'Duplicate record, cannot insert!', @rcode=1
               goto bspexit
               end
           else
               goto bspexit
           end
   	goto bspexit
       end
   
   
   IF @table='MSHX'
       begin
       if @seq is null
           begin
           select @validcnt = Count(*) from bMSHX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@loc
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and UM=@um
           if @validcnt >0
   			begin
               select @msg = 'Duplicate record, cannot insert!', @rcode=1
               goto bspexit
               end
           else
               goto bspexit
           end
       else
           begin
           select @validcnt = Count(*) from bMSHX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@loc
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and UM=@um and Seq<>@seq
           if @validcnt >0
               begin
               select @msg = 'Duplicate record, cannot insert!', @rcode=1
               goto bspexit
               end
           else
               goto bspexit
           end
   	goto bspexit
       end
   
   
   IF @table='MSPX'
       begin
       if @seq is null
           begin
           select @validcnt = Count(*) from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@loc
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck=@truck and UM=@um 
           if @validcnt >0
               begin
               select @msg = 'Duplicate record, cannot insert!', @rcode=1
               goto bspexit
               end
           else
               goto bspexit
           end
       else
           begin
           select @validcnt = Count(*) from bMSPX with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@loc
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           and TruckType=@trucktype and VendorGroup=@vendorgroup and Vendor=@vendor
           and Truck=@truck and UM=@um and Seq<>@seq 
           if @validcnt >0
               begin
               select @msg = 'Duplicate record, cannot insert!', @rcode=1
               goto bspexit
               end
           else
               goto bspexit
           end
   	goto bspexit
       end
   
   
   IF @table='MSJP'
       begin
       if @seq is null
           begin
           select @validcnt = Count(*) from bMSJP with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@loc
           and MatlGroup=@matlgroup and Category=@category and Material=@material
           if @validcnt >0
               begin
               select @msg = 'Duplicate record, cannot insert!', @rcode=1
               goto bspexit
               end
           else
               goto bspexit
           end
       else
           begin
           select @validcnt = Count(*) from bMSJP with (nolock) 
           where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@loc
           and MatlGroup=@matlgroup and Category=@category and Material=@material and Seq<>@seq
           if @validcnt >0
               begin
               select @msg = 'Duplicate record, cannot insert!', @rcode=1
               goto bspexit
               end
           else
               goto bspexit
           end
   	goto bspexit
       end
   
   
   if @table = 'MSHO'
       begin
       if @seq is null
           begin
   		if @quotetype = 'J'
   			begin
   	        select @validcnt = Count(*) from bMSHO with (nolock) 
   	        where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@loc
   	        and MatlGroup=@matlgroup and Category=@category and Material=@material
   	        and TruckType=@trucktype and UM=@um and HaulCode=@haulcode
   			and PhaseGroup=@phasegroup and isnull(Phase,'')=isnull(@phase,'')
   	        if @validcnt >0
   	            begin
   	            select @msg = 'Duplicate record, cannot insert!', @rcode=1
   	            goto bspexit
   	            end
   	        else
   	            goto bspexit
   			end
   		else
   			begin
   	        select @validcnt = Count(*) from bMSHO with (nolock) 
   	        where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@loc
   	        and MatlGroup=@matlgroup and Category=@category and Material=@material
   	        and TruckType=@trucktype and UM=@um and HaulCode=@haulcode
   			and PhaseGroup is null and Phase is null
   	        if @validcnt >0
   	            begin
   	            select @msg = 'Duplicate record, cannot insert!', @rcode=1
   	            goto bspexit
   	            end
   	        else
   	            goto bspexit
   			end
   		end
       else
           begin
   		if @quotetype = 'J'
   			begin
   	        select @validcnt = Count(*) from bMSHO with (nolock) 
   	        where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@loc
   	        and MatlGroup=@matlgroup and Category=@category and Material=@material
   	        and TruckType=@trucktype and UM=@um and HaulCode=@haulcode and Seq<>@seq
   			and PhaseGroup=@phasegroup and isnull(Phase,'')=isnull(@phase,'')
   	        if @validcnt >0
   	            begin
   	            select @msg = 'Duplicate record, cannot insert!', @rcode=1
   	            goto bspexit
   	            end
   	        else
   	            goto bspexit
   			end
   		else
   			begin
   	        select @validcnt = Count(*) from bMSHO with (nolock) 
   	        where MSCo=@msco and Quote=@quote and LocGroup=@locgroup and FromLoc=@loc
   	        and MatlGroup=@matlgroup and Category=@category and Material=@material
   	        and TruckType=@trucktype and UM=@um and HaulCode=@haulcode and Seq<>@seq
   			and PhaseGroup is null and Phase is null
   	        if @validcnt >0
   	            begin
   	            select @msg = 'Duplicate record, cannot insert!', @rcode=1
   	            goto bspexit
   	            end
   	        else
   	            goto bspexit
   	        end
   		end
   	goto bspexit
       end
   
   
	---------------------------------
	-- HANDLE MSSurchargeOverrides --
	---------------------------------
	-- ISSUE: #129350 --
	-- @haulcode - HOLDS SurchargeCode VALUE --
	--			 MSQuoteSurchargeOverrides
	IF @table = 'MSQuoteSurchargeOverrides'
		BEGIN
		IF @seq is null
			BEGIN
			SELECT @validcnt = COUNT(*) 
			FROM bMSSurchargeOverrides WITH (NOLOCK) 
			WHERE MSCo = @msco AND Quote = @quote AND LocGroup=@locgroup AND isnull(FromLoc,'') = isnull(@loc,'')
			AND MatlGroup = @matlgroup AND isnull(Category,'') = isnull(@category,'')
			AND isnull(Material,'') = isnull(@material,'')
			AND isnull(TruckType,'') = isnull(@trucktype,'') AND isnull(UM,'') = isnull(@um,'')
			AND SurchargeCode = @SurchargeCode
			----AND PhaseGroup = @phasegroup AND ISNULL(Phase, '') = ISNULL(@phase, '')
			IF @validcnt > 0
				BEGIN
				SELECT @msg = 'Duplicate record, cannot insert!', @rcode=1
				GOTO bspexit
				END
			ELSE
				GOTO bspexit
			END
		else
			BEGIN
			SELECT @validcnt = COUNT(*) 
			FROM bMSSurchargeOverrides WITH (NOLOCK)  
			WHERE MSCo = @msco AND Quote = @quote AND LocGroup=@locgroup AND isnull(FromLoc,'') = isnull(@loc,'')
			AND MatlGroup = @matlgroup AND isnull(Category,'') = isnull(@category,'')
			AND isnull(Material,'') = isnull(@material,'')
			AND isnull(TruckType,'') = isnull(@trucktype,'') AND isnull(UM,'') = isnull(@um,'')
			AND SurchargeCode = @SurchargeCode
			and Seq <> @seq
			----AND PhaseGroup IS NULL AND Phase IS NULL
			IF @validcnt > 0
				BEGIN
				SELECT @msg = 'Duplicate record, cannot insert!', @rcode=1
				GOTO bspexit
				END
			ELSE
				GOTO bspexit
			END
			
		goto bspexit
		END
		
		----			IF @quotetype = 'J'
		----				BEGIN
		----					SELECT @validcnt = COUNT(*) 
		----					  FROM bMSSurchargeOverrides WITH (NOLOCK) 
		----					 WHERE MSCo = @msco AND Quote = @quote AND LocGroup=@locgroup AND isnull(FromLoc,'') = isnull(@loc,'')
		----					   AND MatlGroup = @matlgroup AND isnull(Category,'') = isnull(@category,'')
		----					   AND isnull(Material,'') = isnull(@material,'')
		----					   AND isnull(TruckType,'') = isnull(@trucktype,'') AND isnull(UM,'') = isnull(@um,'')
		----					   AND SurchargeCode = @haulcode
		----					   ----AND PhaseGroup = @phasegroup AND ISNULL(Phase, '') = ISNULL(@phase, '')
	
		----					IF @validcnt > 0
		----						BEGIN
		----							SELECT @msg = 'Duplicate record, cannot insert!', @rcode=1
		----							GOTO bspexit
		----						END
		----					ELSE
		----						GOTO bspexit
		----				END 
		----			ELSE
		----				BEGIN
		----					SELECT @validcnt = COUNT(*) 
		----					  FROM bMSSurchargeOverrides WITH (NOLOCK)  
		----					 WHERE MSCo = @msco AND Quote = @quote AND LocGroup=@locgroup AND isnull(FromLoc,'') = isnull(@loc,'')
		----					   AND MatlGroup = @matlgroup AND isnull(Category,'') = isnull(@category,'')
		----					   AND isnull(Material,'') = isnull(@material,'')
		----					   AND isnull(TruckType,'') = isnull(@trucktype,'') AND isnull(UM,'') = isnull(@um,'')
		----					   AND SurchargeCode = @haulcode and Seq<>@seq
		----					   ----AND PhaseGroup IS NULL AND Phase IS NULL
							   
		----					IF @validcnt > 0
		----						BEGIN
		----							SELECT @msg = 'Duplicate record, cannot insert!', @rcode=1
		----							GOTO bspexit
		----						END
		----					ELSE
		----						GOTO bspexit
	
		----				END --IF @quotetype = 'J' 
		----		END --(@SEQ IS NULL)
		----	ELSE
		----		BEGIN
		----			IF @quotetype = 'J'
		----				BEGIN
						
		----					SELECT @validcnt = COUNT(*) 
		----					  FROM bMSSurchargeOverrides WITH (NOLOCK) 
		----					 WHERE MSCo = @msco AND Quote = @quote AND LocGroup = @locgroup AND FromLoc = @loc
		----					   AND MatlGroup = @matlgroup AND Category = @category AND Material = @material
		----					   AND TruckType = @trucktype AND UM = @um and SurchargeCode = @haulcode AND Seq <> @seq
		----					   AND PhaseGroup = @phasegroup AND ISNULL(Phase, '') = ISNULL(@phase, '')
	
		----					IF @validcnt > 0
		----						BEGIN
		----							SELECT @msg = 'Duplicate record, cannot insert!', @rcode=1
		----							GOTO bspexit
		----						END
		----					ELSE
		----						GOTO bspexit
		----				END
		----			ELSE
		----				BEGIN
	
		----					SELECT @validcnt = COUNT(*) 
		----					  FROM bMSSurchargeOverrides WITH (NOLOCK) 
		----					 WHERE MSCo = @msco AND Quote = @quote AND LocGroup = @locgroup AND FromLoc = @loc
		----					   AND MatlGroup = @matlgroup AND Category = @category AND Material = @material
		----					   AND TruckType = @trucktype AND UM = @um AND SurchargeCode = @haulcode AND Seq <> @seq
		----					   AND PhaseGroup IS NULL AND Phase IS NULL
	
		----					IF @validcnt > 0
		----						BEGIN
		----							SELECT @msg = 'Duplicate record, cannot insert!', @rcode=1
		----							GOTO bspexit
		----						END
		----					ELSE
		----						GOTO bspexit
		----				END --IF @quotetype = 'J'
		----		END ----(@SEQ IS NOT NULL) 
				
		----	GOTO bspexit
		
		----END --IF @table = 'MSSurchargeOverrides'
   
   
   bspexit:
       IF @rcode <> 0 SET @msg = ISNULL(@msg, '')
   	   RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSQuoteGridUniqueVal] TO [public]
GO
