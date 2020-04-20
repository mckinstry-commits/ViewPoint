SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     procedure [dbo].[vspINBMUnitsWeightGet]
    /***********************************************************************************
    * Created By: TRL 05/26/06
    * Modified:	
    *
    *Used on Form IN Bill of Mateials
	*Calculates Total Percentage for BOM
    *
    * Pass:
    *	INCo      Company
    *   Location  Location
    *   Material  Material
    *   MatlGroup MatlGroup
    *
    * Success returns:
    *	0
    *
    * Error returns:
    *	1 and error message
    ************************************************************************************/
    	( @inco tinyint = null, 
                @locgroup int = null , 
                @material varchar(20) = null, 
                @matlgroup tinyint = null, 
                 @msg varchar(256) output)
    as
   set nocount on
  declare @rcode int
     select  @rcode= 0

    if @inco is null
        begin
        select @msg='Missing IN Company', @rcode=1
        goto vspexit
        end
    
    if @locgroup is null
        begin
        select @msg='Missing Location Group', @rcode=1
        goto vspexit
        end
    
    if @material is null
        begin
        select @msg='Missing Material', @rcode=1
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
  

Select INBM.CompMatl, INBM.Units ,
IsNull(Case INBM.Units When 0 then 0 else case HQMT.WeightConv When 0 then 0 else  case FINHQMT.WeightConv When 0 then 0 else (INBM.Units / (FINHQMT.WeightConv/HQMT.WeightConv)) end end end,0) as WeightConv
From dbo.INBM with(nolock)
Left Join HQMT with(nolock)on INBM.MatlGroup=HQMT.MatlGroup and INBM.CompMatl=HQMT.Material
Left Join HQMT FINHQMT with(nolock)on INBM.MatlGroup=FINHQMT.MatlGroup and INBM.FinMatl=FINHQMT.Material
where INBM.INCo=@inco and INBM.MatlGroup=@matlgroup and INBM.LocGroup=@locgroup and INBM.FinMatl=@material
    

    
    vspexit:
     
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspINBMUnitsWeightGet] TO [public]
GO
