SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspPMMSQuote]
   /***********************************************************
    * CREATED BY	: GF 04/08/2002
    * MODIFIED BY	: 
    *
    *
    * USAGE:
    * validates MQ MSCo/Quote/Location/Material/UM to insure that it is unique.  Checks MSQD
    *
    * INPUT PARAMETERS
    *   MSCo      	MS Co to validate against
    *   PMCo      	PM Company
    *   Project   	PM Project
    *   Quote		MS Quote to Validate
    *   Location	MS Quote Location to Validate
    *   RecordType Type of record being validated 'O' or 'C'
    *   PMMFSeq   	PM Material sequence of record
    *	 Material	MS Quote Material to validate
    *	 UM			MS Quote UM to validate
    *
    *
    * OUTPUT PARAMETERS
    *   @msquoteexists  Where does quote detail exists (N - does not exist, S - exists in MS, P - exists in PM
    *   @msunitcost  	If quote detail found, unit cost from MSQD or PMMF
    *   @msecm       	If quote detail found, ECM from MSQD or PMMF
    *   @msg
    * RETURN VALUE
    *   0         success
    *   1         Failure  'if Fails THEN it fails.
    *****************************************************/
   (@msco bCompany = 0, @pmco bCompany, @project bJob, @quote varchar(10), @location bLoc,
    @recordtype char(1), @pmmfseq int, @material bMatl, @um bUM, @msquoteexists char(1) output,
    @msunitcost bUnitCost output, @msecm bECM output, @msg varchar(255) output)
   as
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0, @msg = '', @msquoteexists = 'N'
   
   -- If the user is working on Original materials and the quote detail exists in MSQD then default UP and ecm.
   -- If the user is working on change orders and the quote detail already exists in MSQD, then we need to default all other fields.
   -- If the quote detail already exists in PMMF, then they cannot enter it again here.
   -- If the quote detail does not exist, then it is ok, but we need to default the item type as original.
   
   -- Added this because sometimes it was coming here needed information
   If @msco is null or @pmco is null or @project is null or @quote is null or @location is null or @material is null or @um is null
       begin
       goto bspexit
       end
   
   
   -- check MSQD first
   Select @msunitcost=UnitPrice, @msecm=ECM
   from MSQD with (nolock) where MSCo=@msco and Quote=@quote and FromLoc=@location and Material=@material and UM=@um
   If @@rowcount = 1
       begin
       select @msquoteexists='S', @msg = 'Exists in MSQD'
       goto bspexit
       end
   
   Select @msg=MtlDescription, @msunitcost=UnitCost, @msecm=ECM
   from PMMF with (nolock) where PMCo=@pmco and Project=@project and MSCo=@msco and Quote=@quote and Location=@location
   and MaterialCode=@material and UM=@um and RecordType='O' and Seq <> isnull(@pmmfseq,99999999)
   If @@rowcount = 1
       begin
       if @recordtype = 'O'
           begin
           select @msg = 'Original Quote detail already exists in PMMF.', @rcode=1
           goto bspexit
           end
   
       select @msquoteexists='P'
       goto bspexit
       end
   
   Select @msg=MtlDescription, @msunitcost=UnitCost, @msecm=ECM
   from PMMF with (nolock) where PMCo=@pmco and Project=@project and MSCo=@msco and Quote=@quote and Location=@location
   and MaterialCode=@material and UM=@um and RecordType='C' and Seq <> isnull(@pmmfseq,99999999)
   If @@rowcount = 1
       begin
       select @msquoteexists='P'
       goto bspexit
       end
   
   
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMMSQuote] TO [public]
GO
