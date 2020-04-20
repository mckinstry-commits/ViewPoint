SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*******************************************/
CREATE   proc [dbo].[bspPMSubOrMatlChgAdd]
/***********************************************************
* Created By:	GF 07/13/2001
* Modified By:	GF 08/28/2003 - issue #22306 - rounding problem with unit cost. Data type bDollar, s/b bUnitCost
*				GF 01/14/2009 - issue #131843 if units=0, amount<>0, and UM<>'LS' then do not add
*				GF 07/22/2009 - issue #129667 add material options with estimates
*				GF 11/30/2009 - issue #136810 missing material group
*				GF 12/09/2009 - issue #136967 - use phase description flag to set PMSL or PMMF description
*				JG 02/17/2011 - V1# B-02366 copy vendor, sl/po, purchase amount to SL/PO
*				GF 04/04/2011 - TK-03354 fix for B-02366
*				JG 05/03/2011 - TK-04820 Material Code
*				TRL  07/27/2011  TK-07143  Expand bPO parameters/varialbles to varchar(30)
*				GF 09/26/2011 TK-08632 WRAP @purchamt with isnull
*				GF 02/12/2012 TK-12381 #145741 get SL Item information for update to PMSL when SL and Item assigned
*				TRL 06/25/2013 User Story 53894, Bug 50974: SCO not being create for SL Cost Type in PM Company Parameters
*
*
* USAGE:
* adds a original detail record to PMSL using the generate options from PMCO. Up to 2 PMSL records will be created.
*
* Will be called from btPMOLi trigger.
*
* INPUT PARAMETERS
* @pmco        PM Company
* @project     PM Project
* @phasegroup  Phase Group
* @phase       Phase
* @costtype    Phase CostType
* @units       Estimate Units
* @um          Unit of Measure
* @unitcost    Estimate unit cost
* @amount      Estimate Cost
* @pcotype     PM PCO Type
* @pco         PM PCO
* @pcoitem     PM PCO Item
* @aco         PM ACO
* @acoitem     PM ACO Item
* @vendor	   Vendor
* @po		   PO
* @sl		   Subcontract
* @POSLitem	   PO/SL Item
* @purchamt	   Purchase Amount
*
* OUTPUT PARAMETERS
*   @msg
* RETURN VALUE
*   0         success
*   1         Failure  'if Fails THEN it fails.
*****************************************************/
(@pmco bCompany, @project bJob, @phasegroup bGroup, @phase bPhase, @costtype bJCCType, @units bUnits,
 @um bUM, @unitcost bUnitCost, @amount bDollar, @pcotype bDocType, @pco bPCO, @pcoitem bPCOItem,
 @aco bACO, @acoitem bACOItem, @vendor bVendor, @po varchar(30), @sl VARCHAR(30), @poslitem bItem, @purchamt bDollar,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @dfltwcretpct bPct, @seqnum int, @slcosttype bJCCType,
		@slcosttype2 bJCCType,  @mtlcosttype bJCCType, @mtlcosttype2 bJCCType,
		@addpmsl char(1), @addpmmf char(1), @apco bCompany, @inco bCompany, @msco bCompany,
		@vendorgroup bGroup, @materialgroup bGroup, @phasedesc_flag bYN,
		@matlphasedesc bYN, @phasedesc bItemDesc, 
		----TK-04820
		@matlCode bMatl,
		----TK-03354
		@SLItemType TINYINT,
		---- TK-12381
		@WCRetPct bPct, @SMRetPct bPct, @TaxGroup bGroup, @TaxType TINYINT,
		@TaxCode bTaxCode
		
select @rcode = 0, @msg = '', @dfltwcretpct = 0, @addpmsl = 'N', @addpmmf = 'N'

if isnull(@costtype,'') = '' goto bspexit
----TK-08632
SET @purchamt = ISNULL(@purchamt,0)

-- get needed information from PMCO for cost type creation
select @slcosttype=SLCostType, @slcosttype2=SLCostType2,
		@mtlcosttype=MtlCostType, @mtlcosttype2 = MatlCostType2,
		@apco=APCo, @inco=INCo, @msco=MSCo, @phasedesc_flag=PhaseDescYN,
		@matlphasedesc=MatlPhaseDesc
from dbo.PMCO with (nolock) where PMCo=@pmco

---- get vendorgroup and material group from HQCO
select @vendorgroup=VendorGroup, @materialgroup=MatlGroup
from dbo.HQCO with (nolock) where HQCo=@apco
if @@rowcount = 0
	begin
	select @vendorgroup=VendorGroup
	from dbo.HQCO with (nolock) where HQCo=@pmco
	end
	

-- get default retg pct from JCCI to use as a default
select @dfltwcretpct = isnull(i.RetainPCT,0), @phasedesc=p.Description
from dbo.JCJP p with (nolock) 
join dbo.JCCI i with (nolock) on i.JCCo=p.JCCo and i.Contract=p.Contract and i.Item=p.Item
where p.JCCo=@pmco and p.Job=@project and p.PhaseGroup=@phasegroup and p.Phase=@phase


-- Set unit cost to the purchase amount price
IF @units <> 0
BEGIN
	SELECT @unitcost = @purchamt/@units
END

-- set units and unit cost to zero if UM = 'LS'
if @um = 'LS'
   begin
   select @units = 0, @unitcost = 0
   end

-- check if subcontract cost type. If valid set add flag.
if isnull(@slcosttype,'') = @costtype
   begin
   set @addpmsl = 'Y'
   end
if isnull(@slcosttype2,'') = @costtype
   begin
   set @addpmsl = 'Y'
   end

---- check if material cost type. if valid set add flag
if isnull(@mtlcosttype,'') = @costtype
	begin
	set @addpmmf = 'Y'
	end
if isnull(@mtlcosttype2,'') = @costtype
	begin
	set @addpmmf = 'Y'
	end


-- add record to PMSL
if @addpmsl = 'Y'
	BEGIN
   -- check if exists in PMSL
   if exists (select Project from dbo.PMSL with (nolock) where PMCo=@pmco and Project=@project and isnull(PCOType,'') = isnull(@pcotype,'')
           and isnull(PCO,'') = isnull(@pco,'') and isnull(PCOItem,'') = isnull(@pcoitem,'')
           and isnull(ACO,'') = isnull(@aco,'') and isnull(ACOItem,'') = isnull(@acoitem,'')
           and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype)
       goto bspexit
   else
       begin
		---- #131843 if units = 0, amount <> 0, and @um <> 'LS' then we do not want to add
		if isnull(@units,0) = 0 and isnull(@purchamt,0) <> 0 and isnull(@um,'LS') <> 'LS'
			begin
			goto bspexit
			end

	   -- get next sequence number from bPMSL
	   select @seqnum = isnull(max(Seq),0) +1
	   from dbo.PMSL with (nolock) where PMCo=@pmco and Project=@project

		----TK-03354
		SET @SLItemType = NULL
		---- TK-12381 get SL Item information
		SET @WCRetPct = 0
		SET @SMRetPct = 0
		SET @TaxGroup = NULL
		SET @TaxType = NULL
		SET @TaxCode = NULL
		
		---- get PMSL data first
		SELECT TOP 1 @SLItemType = PMSL.SLItemType, @WCRetPct = PMSL.WCRetgPct,
					@SMRetPct = PMSL.SMRetgPct, @TaxGroup = PMSL.TaxGroup,
					@TaxType = PMSL.TaxType, @TaxCode = PMSL.TaxCode
		FROM dbo.bPMSL PMSL
		WHERE PMSL.SLCo=@apco
			AND SL = @sl
			AND SLItem = @poslitem
		
		---- get SLIT data second
		IF @sl IS NOT NULL AND @poslitem IS NOT NULL 
			AND EXISTS(SELECT 1 FROM dbo.bSLIT WHERE SLCo=@apco AND SL = @sl AND SLItem = @poslitem)
			BEGIN
			SELECT @SLItemType = SLIT.ItemType, @WCRetPct = SLIT.WCRetPct,
					@SMRetPct = SLIT.SMRetPct, @TaxGroup = SLIT.TaxGroup,
					@TaxType = SLIT.TaxType, @TaxCode = SLIT.TaxCode
			FROM dbo.bSLIT SLIT
			WHERE SLIT.SLCo=@apco
				AND SLIT.SL = @sl
				AND SLIT.SLItem = @poslitem
			END
			
		if @SLItemType NOT IN (1,2) GOTO bspexit
		----TK-03354 TK-12381
		
       begin transaction

	   -- V1# B-02366
	   IF ISNULL(@sl,'') <> ''
			BEGIN
			---- insert bPMSL
			insert into dbo.PMSL (PMCo, Project, Seq, RecordType, PCOType, PCO, PCOItem,
					ACO, ACOItem, PhaseGroup, Phase, CostType, VendorGroup, SLCo,
					SLItemType, Units, UM, UnitCost, Amount, SendFlag, WCRetgPct,
					SMRetgPct, TaxGroup, TaxType, TaxCode, SLItemDescription,
					Vendor, SL, SLItem)
			select @pmco, @project, @seqnum, 'C', @pcotype, @pco, @pcoitem,
					@aco, @acoitem, @phasegroup, @phase, @costtype, @vendorgroup, @apco,
					ISNULL(@SLItemType,2), @units, @um, @unitcost, @purchamt, 'Y',
					----TK-12381
					ISNULL(@WCRetPct,@dfltwcretpct),
					ISNULL(@SMRetPct,@dfltwcretpct),
					@TaxGroup, @TaxType, @TaxCode,
					case when isnull(@phasedesc_flag,'N') = 'Y' then @phasedesc else NULL END,
					@vendor, @sl, @poslitem	
			END
	   ELSE
			BEGIN
			insert into dbo.PMSL (PMCo, Project, Seq, RecordType, PCOType, PCO, PCOItem, ACO, ACOItem,
					PhaseGroup, Phase, CostType, VendorGroup, SLCo, SLItemType, Units, UM, UnitCost,
					Amount, SendFlag, WCRetgPct, SMRetgPct, SLItemDescription, Vendor)
			select @pmco, @project, @seqnum, 'C', @pcotype, @pco, @pcoitem, @aco, @acoitem, @phasegroup,
					   @phase, @costtype, @vendorgroup, @apco, 2, @units, @um, @unitcost,
					   @purchamt, 'Y', @dfltwcretpct, @dfltwcretpct,
					   case when isnull(@phasedesc_flag,'N') = 'Y' then @phasedesc else NULL END,
					   @vendor
			END
       
                
       if @@rowcount <> 1
           begin
           select @msg= 'Error inserting cost type ' + convert(varchar(3),@costtype) + ' into PMSL', @rcode = 1
           rollback transaction
           goto bspexit
           end

       commit transaction
       end

	goto bspexit
	END


-- add record to PMMF
if @addpmmf = 'Y'
	BEGIN
	---- check if exists in PMMF
	if exists (select Project from dbo.PMMF with (nolock) where PMCo=@pmco and Project=@project
			and isnull(PCOType,'') = isnull(@pcotype,'')
			and isnull(PCO,'') = isnull(@pco,'') and isnull(PCOItem,'') = isnull(@pcoitem,'')
			and isnull(ACO,'') = isnull(@aco,'') and isnull(ACOItem,'') = isnull(@acoitem,'')
			and PhaseGroup=@phasegroup and Phase=@phase and CostType=@costtype)
		begin
		goto bspexit
		end
	else
		begin
		---- #131843 if units = 0, amount <> 0, and @um <> 'LS' then we do not want to add
		if isnull(@units,0) = 0 and isnull(@purchamt,0) <> 0 and isnull(@um,'LS') <> 'LS'
			begin
			goto bspexit
			end

		-- get next sequence number from PMMF
		select @seqnum = isnull(max(Seq),0) +1
		from dbo.PMMF with (nolock) where PMCo=@pmco and Project=@project

		begin transaction

		-- V1# B-02366
	    IF ISNULL(@po,'') <> ''
	    BEGIN
			
			---- TK-04820
			SELECT @matlCode=Material FROM dbo.POITPM
			WHERE POCo = @pmco
			AND Job = @project
			AND PO = @po
			AND POItem = @poslitem
			
			IF @matlCode IS NULL
			BEGIN
				SELECT @matlCode=MaterialCode FROM dbo.PMMF
				WHERE InterfaceDate IS NOT NULL
				AND PMCo = @pmco
				AND Project = @project
				AND PO = @po
				AND POItem = @poslitem
			END
	    
	    
			insert into dbo.PMMF(PMCo, Project, Seq, RecordType, PCOType, PCO, PCOItem, ACO, ACOItem,
					MaterialGroup, PhaseGroup, Phase, CostType, VendorGroup, MaterialOption, POCo,
					RecvYN, UM, Units, UnitCost, ECM, Amount, SendFlag, MtlDescription,
					Vendor, PO, POItem, MaterialCode)
			select @pmco, @project, @seqnum, 'C', @pcotype, @pco, @pcoitem, @aco, @acoitem,
					@materialgroup, @phasegroup, @phase, @costtype, @vendorgroup, 'P', @apco,
					'N', @um, @units, @unitcost, 'E', @purchamt, 'Y',
					case when isnull(@matlphasedesc,'N') = 'Y' then @phasedesc else null END,
					@vendor, @po, @poslitem, 
					---- TK-04820
					@matlCode
	    END
	    ELSE
	    BEGIN
			insert into dbo.PMMF(PMCo, Project, Seq, RecordType, PCOType, PCO, PCOItem, ACO, ACOItem,
				MaterialGroup, PhaseGroup, Phase, CostType, VendorGroup, MaterialOption, POCo,
				RecvYN, UM, Units, UnitCost, ECM, Amount, SendFlag, MtlDescription, Vendor)
			select @pmco, @project, @seqnum, 'C', @pcotype, @pco, @pcoitem, @aco, @acoitem,
				@materialgroup, @phasegroup, @phase, @costtype, @vendorgroup, 'P', @apco,
				'N', @um, @units, @unitcost, 'E', @purchamt, 'Y',
				case when isnull(@matlphasedesc,'N') = 'Y' then @phasedesc else null END,
				@vendor
		END

		if @@rowcount <> 1
			begin
			select @msg= 'Error inserting cost type ' + convert(varchar(3),@costtype) + ' into PMMF', @rcode = 1
			rollback transaction
			goto bspexit
			end

       commit transaction
       end

	goto bspexit
	END



   
bspexit:
	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPMSubOrMatlChgAdd] TO [public]
GO
