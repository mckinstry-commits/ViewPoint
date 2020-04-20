SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*********************************************************/
CREATE      procedure [dbo].[bspMSTDTrigProc]
/*-----------------------------------------------------------------
    * Created By:	GG 10/26/00
    * Modified By:	GG 07/03/01 - add hierarchal Quote search  - #13888
    *				GF 06/21/2005 - routine to get @umconv worked differently than in MSTD triggers. Made the same.
	*				GF 02/08/2006 - issue #120087 - added check for to material group material std um <> posted um
	*				GF 08/07/2012 TK-16813 change how we back out sold units from MSQD
	*				GF 08/10/2012 TK-16962 added MSQD updates for material vendor if we have one
    *
    *
    *
    * Called by bMSTD update and delete triggers to back out 'old' units
    * and totals from MS Quote Detail and Sales Activity tables.
    *
    */----------------------------------------------------------------
(@msco bCompany, @mth bMonth, @oldfromloc bLoc, @oldmatlgroup bGroup, @oldmaterial bMatl,
 @oldsaletype char(1), @oldcustgroup bGroup, @oldcustomer bCustomer, @oldcustjob varchar(20),
 @oldcustpo varchar(20), @oldjcco bCompany, @oldjob bJob, @oldinco bCompany, @oldtoloc bLoc,
 @oldmatlum bUM, @oldmatlunits bUnits, @oldmatltotal bDollar, @oldhaultotal bDollar,
 @oldtaxtotal bDollar, @olddiscoff bDollar
 ----TK-16813
 ,@oldPhaseGroup bGroup = NULL, @oldMatlPhase bPhase = NULL
 ----TK-16962
 ,@oldVendorGroup bGroup = NULL, @oldMatlVendor bVendor = NULL, @oldNew CHAR(1) = 'O'
 ,@errmsg varchar(255) output)
AS
SET NOCOUNT ON
 
  
declare @rcode int, @stdum bUM, @umconv bUnitCost, @mssaseq int, @quote varchar(10), @validcnt int,
		@tomatlstdum bUM, @tomatlgroup bGroup
		----TK-16813
		,@msqdphase bPhase, @pphase bPhase, @validphasechars INT
		----TK-16962
		,@found TINYINT

SET @rcode = 0
SET @umconv = 1
SET @found = 0 --false
  
----get old Material
select @stdum = StdUM from bHQMT with (nolock) where MatlGroup = @oldmatlgroup and Material = @oldmaterial
if @@rowcount = 0
   begin
   select @errmsg = 'Invalid material: ' + isnull(@oldmaterial,''), @rcode = 1
   goto bspexit
   end

---- new routine
if @oldmatlum <> @stdum
  	begin
   	select @umconv=Conversion from bINMU with (nolock) 
   	where INCo = @msco and Loc = @oldfromloc and MatlGroup = @oldmatlgroup and Material = @oldmaterial and UM = @oldmatlum
   	if @@rowcount = 0
   		begin
   		select @umconv=Conversion from bHQMU with (nolock)
   		where MatlGroup = @oldmatlgroup and Material = @oldmaterial and UM = @oldmatlum
   		if @@rowcount <> 1
   	        begin
   	        select @errmsg = 'Invalid unit of measure: ' + isnull(@oldmatlum,''), @rcode = 1
   	        goto bspexit
   	        end
   		end

	---- verify that material-UM exists at sell to location
	if @oldsaletype = 'I'
		begin
		select @tomatlgroup=MatlGroup from bHQCO with (nolock) where HQCo=@oldinco
		-- -- -- check if um for to location is the STD UM
		select @tomatlstdum=StdUM from bHQMT with (nolock) where MatlGroup=@tomatlgroup and Material=@oldmaterial
		-- -- -- when to std um <> um then must exists in bINMU
		if @tomatlstdum <> @oldmatlum
			begin
			select @validcnt = count(*) from bINMU with (nolock)
			where INCo = @oldinco and Loc = @oldtoloc and MatlGroup = @tomatlgroup and Material = @oldmaterial and UM = @oldmatlum
			if @validcnt = 0
				begin
				select @errmsg = 'Invalid UM: ' + isnull(@oldmatlum,'') + ' Material: ' + isnull(@oldmaterial,'') + ' at sell To Location: ' + isnull(@oldtoloc,'')
				select @rcode = 1
				goto bspexit
				end
			end
		end
	end

---- get Quote
if @oldsaletype = 'C'
   begin
    -- look for Customer Quote
   select @quote = Quote
   from bMSQH with (nolock) 
   where MSCo = @msco and QuoteType = 'C' and CustGroup = @oldcustgroup and Customer = @oldcustomer
   and isnull(CustJob,'') = isnull(@oldcustjob,'') and isnull(CustPO,'') = isnull(@oldcustpo,'')
   if @@rowcount = 0
       begin
       -- if no Quote at Cust PO level, check for one at Cust Job level
       select @quote = Quote
       from bMSQH with (nolock) 
       where MSCo = @msco and QuoteType = 'C' and CustGroup = @oldcustgroup and Customer = @oldcustomer
       and isnull(CustJob,'') = isnull(@oldcustjob,'') and CustPO is null
       if @@rowcount = 0
            begin
            -- if no Quote at Cust PO level, check for one at Cust Job level
            select @quote = Quote
            from bMSQH with (nolock) 
            where MSCo = @msco and QuoteType = 'C' and CustGroup = @oldcustgroup and Customer = @oldcustomer
            and CustJob is null and CustPO is null
            end
        end
   -- look for Sales Activity
   select @mssaseq = Seq
   from bMSSA with (nolock) 
   where MSCo = @msco and Mth = @mth and Loc = @oldfromloc and MatlGroup = @oldmatlgroup and Material = @oldmaterial
   and SaleType = 'C' and CustGroup = @oldcustgroup and Customer = @oldcustomer
   and isnull(CustJob,'') = isnull(@oldcustjob,'') and isnull(CustPO,'') = isnull(@oldcustpo,'')
   end

if @oldsaletype = 'J'
   begin
   -- look for Job Quote
   select @quote = Quote
   from bMSQH with (nolock) 
   where MSCo = @msco and QuoteType = 'J' and JCCo = @oldjcco and Job = @oldjob
   -- look for Sales Activity
   select @mssaseq = Seq
   from bMSSA with (nolock) 
   where MSCo = @msco and Mth = @mth and Loc = @oldfromloc and MatlGroup = @oldmatlgroup and Material = @oldmaterial
   and SaleType = 'J' and JCCo = @oldjcco and Job = @oldjob

	----TK-16813 get old valid phase characters
	SELECT @validphasechars = j.ValidPhaseChars
	FROM dbo.bJCCO j JOIN dbo.bHQCO h ON h.HQCo = j.JCCo
	WHERE j.JCCo = @oldjcco
	
	---- set valid part material phase
	IF @validphasechars > 0
		SET @pphase = SUBSTRING(@oldMatlPhase, 1, @validphasechars) + '%'
	ELSE
		SET @pphase = @oldMatlPhase
	END


if @oldsaletype = 'I'
   begin
   -- look for Inventory Quote
   select @quote = Quote
   from bMSQH with (nolock) 
   where MSCo = @msco and QuoteType = 'I' and INCo = @oldinco and Loc = @oldtoloc
   -- look for Sales Activity
   select @mssaseq = Seq
   from bMSSA with (nolock) 
   where MSCo = @msco and Mth = @mth and Loc = @oldfromloc and MatlGroup = @oldmatlgroup and Material = @oldmaterial
   and SaleType = 'I' and INCo = @oldinco and ToLoc = @oldtoloc
   end

----TK-16962 update Quote Detail if old material was quoted (back out units sold)
----first process non job tickets. quote may be inactive
IF @quote IS NOT NULL AND @oldsaletype <> 'J' AND ISNULL(@oldmatlunits,0) <> 0
	BEGIN
	----TK-16962 try update by material vendor if we have one
	IF @oldMatlVendor IS NOT NULL AND @oldVendorGroup IS NOT NULL
		BEGIN
		UPDATE dbo.bMSQD
			SET SoldUnits = CASE WHEN @oldNew = 'O' THEN SoldUnits - @oldmatlunits
								 ELSE SoldUnits + @oldmatlunits
								 END,
				AuditYN = 'N'   -- set audit flag
		FROM dbo.bMSQD
		WHERE MSCo = @msco  -- may be any status
			AND Quote = @quote
			AND FromLoc = @oldfromloc
			AND MatlGroup = @oldmatlgroup
			AND Material = @oldmaterial 
			AND UM = @oldmatlum
			AND VendorGroup = @oldVendorGroup
			AND MatlVendor = @oldMatlVendor
			AND Phase IS NULL
		IF @@ROWCOUNT = 0
			BEGIN
			UPDATE dbo.bMSQD
			SET SoldUnits = CASE WHEN @oldNew = 'O' THEN SoldUnits - @oldmatlunits
								 ELSE SoldUnits + @oldmatlunits
								 END,
				AuditYN = 'N'   -- set audit flag
			FROM dbo.bMSQD  -- may be any status
			WHERE MSCo = @msco
				AND Quote = @quote
				AND FromLoc = @oldfromloc
				AND MatlGroup = @oldmatlgroup
				AND Material = @oldmaterial 
				AND UM = @oldmatlum 
				AND Phase IS NULL
				AND MatlVendor IS NULL
			END
		END
	ELSE
		----no material vendor
		BEGIN
		UPDATE dbo.bMSQD
		SET SoldUnits = CASE WHEN @oldNew = 'O' THEN SoldUnits - @oldmatlunits
							 ELSE SoldUnits + @oldmatlunits
							 END,
				AuditYN = 'N'   -- set audit flag
			FROM dbo.bMSQD  -- may be any status
			WHERE MSCo = @msco
				AND Quote = @quote
				AND FromLoc = @oldfromloc
				AND MatlGroup = @oldmatlgroup
				AND Material = @oldmaterial 
				AND UM = @oldmatlum 
				AND Phase IS NULL
				AND MatlVendor IS NULL
		END
		
	----reset audit flag
	UPDATE dbo.bMSQD SET AuditYN = 'Y'
	WHERE MSCo = @msco  -- may be any status
		AND Quote = @quote
		AND FromLoc = @oldfromloc
		AND MatlGroup = @oldmatlgroup
		AND Material = @oldmaterial
		AND UM = @oldmatlum
		AND Phase IS NULL

	END
	
----TK-16962 update Quote Detail if old material was quoted (back out units sold)
----first process non job tickets. quote may be inactive
IF @quote IS NOT NULL AND @oldsaletype = 'J' AND ISNULL(@oldmatlunits,0) <> 0
	BEGIN
	----TK-16962
	SET @found = 0 --false
	
	----TK-16962 try update by material vendor if we have one
	IF @oldMatlVendor IS NOT NULL AND @oldVendorGroup IS NOT NULL
		BEGIN
		---- phase exact match first
		UPDATE dbo.bMSQD 
			SET SoldUnits = CASE WHEN @oldNew = 'O' THEN SoldUnits - @oldmatlunits
								 ELSE SoldUnits + @oldmatlunits
								 END,
			AuditYN = 'N'   -- set audit flag
		FROM dbo.bMSQD  -- may be any status
		WHERE MSCo = @msco
			AND Quote = @quote
			AND FromLoc = @oldfromloc
			AND MatlGroup =@oldmatlgroup
			AND Material = @oldmaterial
			AND UM = @oldmatlum 
			AND PhaseGroup = @oldPhaseGroup
			AND Phase = @oldMatlPhase
			AND VendorGroup = @oldVendorGroup
			AND MatlVendor = @oldMatlVendor
		IF @@ROWCOUNT = 0
			BEGIN
			---- look for valid part phase second
			SELECT TOP 1 @msqdphase = Phase
			FROM dbo.bMSQD
			WHERE MSCo = @msco
				AND Quote = @quote
				AND FromLoc = @oldfromloc
				AND MatlGroup = @oldmatlgroup 
				AND Material = @oldmaterial
				AND UM = @oldmatlum
				AND PhaseGroup = @oldPhaseGroup
				AND Phase like @pphase
				AND VendorGroup = @oldVendorGroup
				AND MatlVendor = @oldMatlVendor
			GROUP BY MSCo, Quote, FromLoc, MatlGroup, Material, UM, PhaseGroup, Phase, UnitPrice, ECM, VendorGroup, MatlVendor
			IF @@ROWCOUNT <> 0
				BEGIN
				---- update valid part phase
				UPDATE dbo.bMSQD 
					SET SoldUnits = CASE WHEN @oldNew = 'O' THEN SoldUnits - @oldmatlunits
									ELSE SoldUnits + @oldmatlunits
									END,
						AuditYN = 'N'   -- set audit flag
				FROM dbo.bMSQD 
				WHERE MSCo = @msco
					AND Quote = @quote
					AND FromLoc = @oldfromloc
					AND MatlGroup = @oldmatlgroup
					AND Material = @oldmaterial
					AND UM = @oldmatlum
					AND PhaseGroup = @oldPhaseGroup
					AND Phase = @msqdphase
					AND VendorGroup = @oldVendorGroup
					AND MatlVendor = @oldMatlVendor
				IF @@ROWCOUNT <> 0 SET @found = 1 --true
				END
			END
		ELSE
			BEGIN
			SET @found = 1 --true
			END
		
		---- reset audit flag
		IF @found = 1
			BEGIN
			UPDATE dbo.bMSQD SET AuditYN = 'Y'
			WHERE MSCo = @msco  -- may be any status
				AND Quote = @quote
				AND FromLoc = @oldfromloc
				AND MatlGroup = @oldmatlgroup
				AND Material = @oldmaterial
				AND UM = @oldmatlum
				AND Phase IS NOT NULL
				AND VendorGroup = @oldVendorGroup
				AND MatlVendor = @oldMatlVendor
			END
		END
	
	---- sale type 'J' look for exact match phase first
	IF @found = 0
		BEGIN
		UPDATE dbo.bMSQD 
			SET SoldUnits = CASE WHEN @oldNew = 'O' THEN SoldUnits - @oldmatlunits
								 ELSE SoldUnits + @oldmatlunits
								 END,
				AuditYN = 'N'   -- set audit flag
		FROM dbo.bMSQD
		WHERE MSCo = @msco
			AND Quote = @quote
			AND FromLoc = @oldfromloc
			AND MatlGroup =@oldmatlgroup
			AND Material = @oldmaterial
			AND UM = @oldmatlum 
			AND PhaseGroup = @oldPhaseGroup
			AND Phase = @oldMatlPhase
			AND MatlVendor IS NULL
		IF @@ROWCOUNT <> 0
			BEGIN
			UPDATE dbo.bMSQD SET AuditYN = 'Y'
			WHERE MSCo = @msco
				AND Quote = @quote
				AND FromLoc = @oldfromloc
				AND MatlGroup = @oldmatlgroup
				AND Material = @oldmaterial
				AND UM = @oldmatlum
				AND PhaseGroup = @oldPhaseGroup
				AND Phase = @oldMatlPhase
				AND MatlVendor IS NULL
			END
		ELSE
			BEGIN
			---- look for valid part phase second
			SELECT TOP 1 @msqdphase = Phase
			FROM dbo.bMSQD
			WHERE MSCo = @msco
				AND Quote = @quote
				AND FromLoc = @oldfromloc
				AND MatlGroup = @oldmatlgroup 
				AND Material = @oldmaterial
				AND UM = @oldmatlum
				AND PhaseGroup = @oldPhaseGroup
				AND Phase like @pphase
				AND MatlVendor IS NULL
			GROUP BY MSCo, Quote, FromLoc, MatlGroup, Material, UM, PhaseGroup, Phase, UnitPrice, ECM
			IF @@ROWCOUNT <> 0
				BEGIN
				---- update valid part phase
				UPDATE dbo.bMSQD 
					SET SoldUnits = CASE WHEN @oldNew = 'O' THEN SoldUnits - @oldmatlunits
								 ELSE SoldUnits + @oldmatlunits
								 END,
						AuditYN = 'N'   -- set audit flag
				FROM dbo.bMSQD 
				WHERE MSCo = @msco
					AND Quote = @quote
					AND FromLoc = @oldfromloc
					AND MatlGroup = @oldmatlgroup
					AND Material = @oldmaterial
					AND UM = @oldmatlum
					AND PhaseGroup = @oldPhaseGroup
					AND Phase = @msqdphase
					AND MatlVendor IS NULL
					
				UPDATE dbo.bMSQD SET AuditYN = 'Y'
				WHERE MSCo = @msco
					AND Quote = @quote
					AND FromLoc = @oldfromloc
					AND MatlGroup = @oldmatlgroup
					AND Material = @oldmaterial
					AND UM = @oldmatlum
					AND PhaseGroup = @oldPhaseGroup
					AND Phase = @msqdphase
					AND MatlVendor IS NULL
				END
			ELSE
				BEGIN
				---- update with no phase
				UPDATE dbo.bMSQD
					SET SoldUnits = CASE WHEN @oldNew = 'O' THEN SoldUnits - @oldmatlunits
								 ELSE SoldUnits + @oldmatlunits
								 END,
						AuditYN = 'N'   -- set audit flag
				FROM dbo.bMSQD  ---- may be any status
				WHERE MSCo = @msco
					AND Quote = @quote
					AND FromLoc = @oldfromloc
					AND MatlGroup = @oldmatlgroup
					AND Material = @oldmaterial
					AND UM = @oldmatlum
					AND Phase IS NULL
					AND MatlVendor IS NULL
					
				UPDATE dbo.bMSQD SET AuditYN = 'Y'
				WHERE MSCo = @msco  -- may be any status
					AND Quote = @quote
					AND FromLoc = @oldfromloc
					AND MatlGroup = @oldmatlgroup
					AND Material = @oldmaterial
					AND UM = @oldmatlum
					AND Phase IS NULL
					AND MatlVendor IS NULL
				END
			END
		END
	END

		

----update MS Sales Activity (backout units and dollars)
if @mssaseq is not NULL AND @oldNew = 'O'
   begin
   update dbo.bMSSA
   set MatlUnits = MatlUnits - (@umconv * @oldmatlunits), -- convert to std u/m
       MatlTotal = MatlTotal - @oldmatltotal, HaulTotal = HaulTotal - @oldhaultotal,
       TaxTotal = TaxTotal - @oldtaxtotal, DiscOff = DiscOff - @olddiscoff
   where MSCo = @msco and Mth = @mth and Loc = @oldfromloc and MatlGroup = @oldmatlgroup
   and Material = @oldmaterial and Seq = @mssaseq
   if @@rowcount <> 1
       begin
       select @errmsg = 'Unable to update MS Sales Activity', @rcode = 1
       goto bspexit
       end
   end




bspexit:
	if @rcode <> 0 select @errmsg = @errmsg
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspMSTDTrigProc] TO [public]
GO
