SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       procedure [dbo].[vspINBOUnitsWeightGet]
    /***********************************************************************************
    * Created By: TRL 03/02/06
    *
    *
    * Pulls the Location Group's Bill of Material List Override Components to calc to percent
    *
    *
    * Pass:
    *	INCo      Company
    *   LocGroup
    *   Material  Material
    *   MatlGroup MatlGroup
    *
    * Success returns:
    *	0
    *
    * Error returns:
    *	1 and error message
    ************************************************************************************/
    	(@inco bCompany = null, @loc varchar(10) = null, @finmatl varchar(20) = null,  @matlgroup bGroup = null, @msg varchar(256) output)
    as
   set nocount on

declare @rcode int
select  @rcode= 0

    if @inco is null
        begin
        select @msg='Missing IN Company', @rcode=1
        goto vspexit
        end
    
    if @loc is null
        begin
        select @msg='Missing Location', @rcode=1
        goto vspexit
        end
    
    if @finmatl is null
        begin
        select @msg='Missing Finished Material', @rcode=1
        goto vspexit
        end
    
    if @matlgroup is null
        begin
        select @msg='Missing Material Group', @rcode=1
        goto vspexit
        end

    --get Location Group for this location
    --select @locgroup=LocGroup from bINLM where INCo=@inco and Loc=@location
    --if @@rowcount=0
      --begin
      --select @msg='Invalid Location', @rcode=1
      --goto vspexit
       --end
  

Select INBO.CompMatl, INBO.Units ,
IsNull(Case INBO.Units When 0 then 0 else case CINMT.WeightConv When 0 then 0 else case FINMT.WeightConv When 0 then 0 else (INBO.Units / (FINMT.WeightConv/CINMT.WeightConv)) end end end,0) as WeightConv
From dbo.INBO with(nolock)
Left Join dbo.INMT FINMT with(nolock) on FINMT.INCo=INBO.INCo and FINMT.Loc=INBO.Loc and FINMT.MatlGroup=INBO.MatlGroup and FINMT.Material=INBO.FinMatl
Left Join dbo.INMT CINMT with(nolock) on CINMT.INCo=INBO.INCo and CINMT.Loc=INBO.CompLoc and CINMT.MatlGroup=INBO.MatlGroup and CINMT.Material=INBO.CompMatl
where INBO.INCo=@inco and INBO.MatlGroup=@matlgroup and INBO.Loc=@loc and INBO.FinMatl=@finmatl 
   
vspexit:
      --  if @rcode<>0 select @msg=@msg + char(13) + char(10) + '[vspINBOUnitsWieghtGet]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspINBOUnitsWeightGet] TO [public]
GO
