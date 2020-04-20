SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




/******************************************************/
CREATE    proc [dbo].[bspPMSLSubCoGet]
/***********************************************************
 * Created By:   GF 04/17/2000
 * Modified By:	GF 04/03/2002 - Removed Project from where clause. Due to significant part job.
 *				GF 04/26/2008 - issue #127908 SubCo numbering by ACO
 *				GF 02/07/2010 - issue #137761 SLItemType = '2'
 *				GF 06/28/2010 - issue #135813 SL expanded to 30 characters
 *				GF 10/05/2011 TK-08876 put back code to use the company option for one subco per ACO
 *				DAN SO 01/16/2012 - TK-11597 - get next SubCO - removed PMSubcontrctCO SELECT statement
 *				GF 04/01/2012 TK-13768 use parameter @CreateSingleChangeOrder
 *
 *
 * USAGE:
 * Gets the next sequential SubCo number. Gets max(subco) from PMSL
 * for the subcontract and item type is 1, 2 or 4.
 * Then gets the max(SLChangeOrder) from SLCD for the subcontract
 * and item type is 1, 2 or 4. Returns value plus one.
 *
 * INPUT PARAMETERS
 *   pmco, project, slco, sl, slitemtype
 *
 * OUTPUT PARAMETERS
 *   SubCo   next sequential subco
 *   msg     description, or error message
 *
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/
(@pmco bCompany = null, @project bJob = null, @slco bCompany = null, @sl VARCHAR(30) = null,
 @slitem bItem = null, @itemtype tinyint = null, @seq int = null,
 @subco smallint = null output, @aco bPCO = null, @acoitem bPCOItem = null,
 @vendor bVendor = null,
 ---- TK-13139 
 @CreateSingleChangeOrder VARCHAR(1) = NULL,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int, @validcnt int, @validcnt2 int, @validcnt3 int, @pmsubco smallint,
		@slsubco smallint, @useapprsubco bYN, @acosubco smallint, @pco bPCO, @pcoitem bPCOItem

select @rcode = 0, @pmsubco = 0, @slsubco = 0, @subco = null

-- TK-11597 --
DECLARE	@retcode smallint
SET @retcode = 0


if @pmco is null
       begin
       select @msg='Missing PM Company!', @rcode = 1
       goto bspexit
       end

if @project is null
       begin
       select @msg='Missing Project!', @rcode = 1
       goto bspexit
       end

if @slco is null
       begin
       select @msg='Missing SL Company!', @rcode = 1
       goto bspexit
       end

if @sl is null
       begin
       select @msg='Missing Subcontract!', @rcode = 1
       goto bspexit
       end

if @slitem is null
       begin
       select @msg='Missing Subcontract Item!', @rcode = 1
       goto bspexit
       end

if @itemtype not in (1,2,3,4)
	begin
	select @msg='Invalid subcontract item type!', @rcode = 1
	goto bspexit
	end

---- set @seq if new detail record
if @seq is null select @seq = -1

---- if backcharge item, then no subco
if @itemtype = 3 goto bspexit

---- get PMCO info
select @useapprsubco=UseApprSubCo
from dbo.bPMCO with (nolock) where PMCo=@pmco
if @@rowcount = 0 select @useapprsubco = 'N'

---- TK-13768
if @CreateSingleChangeOrder is null set @CreateSingleChangeOrder = @useapprsubco

---- get subcontract/vendor from PMSL for change orders
---- then look for an existing subco for same SL and vendor
---- TK-13768
if @itemtype in (1,2,4) AND @CreateSingleChangeOrder = 'Y' /*and @useapprsubco = 'Y'*/ and isnull(@aco,'') <> ''
	begin
	select @acosubco=isnull(min(SubCO),0)
	from dbo.bPMSL with (nolock) where PMCo=@pmco and Project=@project
	and SL=@sl and Vendor=@vendor and ACO=@aco and Seq<>@seq
	if @acosubco <> 0
		begin
		select @subco=@acosubco
		goto bspexit
		end
	end
	
---- if original or add-on item, no subco if not in SLIT and PMSL
if @itemtype in (1,4)
	begin
	select @validcnt=count(*) from bSLIT with (nolock) where SLCo=@slco and SL=@sl and SLItem=@slitem
	if @validcnt = 0
		begin
		select @validcnt2=count(*) from dbo.bPMSL with (nolock) 
		where SLCo=@slco and SL=@sl and SLItem=@slitem and RecordType = 'O' and InterfaceDate is null and Seq <> @seq
		if @validcnt2 = 0
			begin
            select @validcnt3=count(*) from dbo.bPMSL with (nolock) 
            where SLCo=@slco and SL=@sl and SLItem=@slitem and RecordType = 'C' and InterfaceDate is null and Seq < @seq
            if @validcnt3 = 0 
				begin
				select @subco = 0 ----#137661
				goto bspexit
				end
            end
         end
      end

---- generate maximum subco + 1 for item types 1 and 2
if @itemtype in (1,2)
	BEGIN
	
		-- GET NEXT SUBCO -- TK-11597
		EXEC @retcode = dbo.vspPMSubCOGetNext @slco, @sl, @subco OUTPUT, @msg OUTPUT
		IF @retcode <> 0
			BEGIN
    			SET @rcode = 1
				GOTO bspexit
			END
			
		IF ISNULL(@subco,0) = 0 SET @subco = 1
	
	-------- get maximum SubCO rom vPMSubcontractCO
	----SELECT @subco = isnull(max(SubCO) + 1, 1)
	----FROM dbo.vPMSubcontractCO
	----WHERE PMCo = @pmco
	----	AND SLCo = @slco
	----	AND SL = @sl
	----IF ISNULL(@subco,0) = 0 SET @subco = 1
	END
	------ get maximum SubCo from bPMSL
	--select @pmsubco=isnull(max(SubCO),0)
	--from dbo.bPMSL with (nolock) where PMCo=@pmco and SLCo=@slco and SL=@sl
		
	------ get maximum SLChangeOrder from bSLCD
	--select @slsubco=isnull(max(a.SLChangeOrder),0)
	--from dbo.bSLCD a with (nolock) join dbo.bSLIT b with (nolock) on b.SLCo=a.SLCo and b.SL=a.SL
	--where a.SLCo=@slco and a.SL=@sl

	------ set subco to highest + 1
	--if @pmsubco >= @slsubco
	--	begin
	--	select @subco=@pmsubco+1
	--	end
	--else
	--	begin
	--	select @subco=@slsubco+1
	--	end
	--end


---- set subco for add-on item to maximum subco found in PMSL for subcontract
---- and item that has not been interfaced
--if @itemtype = 4
--	begin
--	select @pmsubco=isnull(max(SubCO),0) from dbo.bPMSL with (nolock) 
--	where PMCo=@pmco and SLCo=@slco and SL=@sl and SLItemType in (1,2) and InterfaceDate is null
--	if @pmsubco = 0
--		begin
--		select @subco=1
--		end
--	else
--		begin
--		select @subco=@pmsubco
--		end
--	end




bspexit:
	if @subco = 0 select @subco = null
	if @rcode<>0 select @msg = isnull(@msg,'')
   	return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspPMSLSubCoGet] TO [public]
GO
