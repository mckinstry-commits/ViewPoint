SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************************************/
CREATE proc [dbo].[vspINMUCostPriceUpdate]
/*************************************
* CREATED BY:	???
* Modified By:	GF 05/27/2008 - issue #124102
*				GP 06/05/2008 - Issue #128566, Update message in INLocationMaterials was giving incorrect count
*									on Costs/Qtys tab when updating both StdUnitCost & StdUnitPrice simultaneously.
*				GF 07/03/2008 - issue #128891 when comparing INMU cost price need to cast as numeric(16,5) for rounding
*				GP 02/05/2009 - Issue #132038, on updatetype 2 and 3 now checking @@rowcount instead of count(*).
*
*
* Used By form INLocationMaterials to update INMU std cost and price
*
* Pass:
* INCo			IN Company  
* MatlGroup		Material Group
* Loc			IN Location
* Material		IN Location Material
* UpdateType	INMU update type (1-both, 2-cost,3-price)
* StdCost		New std cost
* StdPrice		New std price
* OldStdCost	Old std cost
* OldStdPrice	Old std price
*
*
* Success returns:
* @updatecount	Record count
*
* Error returns:
*	1 and error message
**************************************/
(@inco bCompany =null, @matlgroup bGroup=null, @loc bLoc = null, @material bMatl=null,
 @updatetype int = null, @stdcost bUnitCost = null, @stdprice bUnitCost = null,
 @oldstdcostvalue bUnitCost = null, @oldstdpricevalue bUnitCost = null,
 @updatecount int output, @msg varchar(256)=null output)

as
set nocount on

declare @rcode int, @CostUpdateCount int, @PriceUpdateCount int
Select @rcode = 0, @updatecount = 0

If IsNull(@inco,0)=0
begin
	select @msg = 'Missing IN Company',@rcode = 1
	goto vspexit	
end

If IsNull(@matlgroup,0)=0
begin
	select @msg = 'Missing Material Group!',@rcode = 1
	goto vspexit	
end
If IsNull(@loc,'')=''
begin
	select @msg = 'Missing Location!',@rcode = 1
	goto vspexit	
end
If IsNull(@material,'')=''
begin
	select @msg = 'Missing Material!',@rcode = 1
	goto vspexit	
end	

select @msg = 'No Records found to update.'

--Update All UM
If @updatetype = 1
begin
	--Costs
	Update dbo.INMU
	Set StdCost=@stdcost * Conversion
	Where INCo = @inco and MatlGroup = @matlgroup and Loc=@loc and Material = @material
	and Conversion <> 0 and CAST((StdCost/Conversion) as numeric(16,5)) = @oldstdcostvalue
	----(@oldstdcostvalue/Conversion)
	
	SET @CostUpdateCount = @@rowcount --Issue #128566

	--Price
	Update dbo.INMU
	Set Price=@stdprice * Conversion
	Where INCo = @inco and MatlGroup = @matlgroup and Loc=@loc and Material = @material
	and Conversion <> 0 and CAST((Price/Conversion) as numeric(16,5)) = @oldstdpricevalue
	----(@oldstdpricevalue/Conversion)

	SET @PriceUpdateCount = @@rowcount -- ssue #128566
	
	IF @CostUpdateCount > 0 or @PriceUpdateCount > 0 --Issue #128566
	BEGIN
		SELECT @msg = 'Additional UM records updated.' + char(13) + char(10) + Convert(varchar(8),@CostUpdateCount) + ' Std Unit Cost and ' + 
					Convert(varchar(8),@PriceUpdateCount) + ' Std Unit Price.'
		SET @updatecount = @CostUpdateCount + @PriceUpdateCount
		GOTO vspexit
	END
End

--StdCost Update
If @updatetype = 2
Begin
	Update dbo.INMU
	Set StdCost=@stdcost * Conversion
	Where INCo = @inco and MatlGroup = @matlgroup and Loc=@loc and Material = @material
	and Conversion <> 0 and CAST((StdCost/Conversion) as numeric(16,5)) = @oldstdcostvalue
	set @updatecount=@@rowcount
	----(@oldstdcostvalue/Conversion)
	
	if @updatecount > 0 
	begin
		select @msg = Convert(varchar,@updatecount) +  ' additional UMs updated.'
		goto vspexit
	end
End

--StdPrice Update
If @updatetype = 3 
Begin
	Update dbo.INMU
	Set Price=@stdprice * Conversion
	Where INCo = @inco and MatlGroup = @matlgroup and Loc=@loc and Material = @material
	and Conversion <> 0 and CAST((Price/Conversion) as numeric(16,5)) = @oldstdpricevalue
	set @updatecount=@@rowcount
	----(@oldstdpricevalue/Conversion)

	if @updatecount > 0 
	begin
		select @msg = Convert(varchar,@updatecount) +  ' additional UMs updated.'
		goto vspexit
	end
End

vspexit:
	Return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspINMUCostPriceUpdate] TO [public]
GO
