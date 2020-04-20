SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     proc [dbo].[vspINMatlCopyLMInfoGet]

  /*************************************
  * CREATED BY:  TRL 08/16/06
  * Modified By:
  *
  * Gets the INLM Location information
  * Used by INMatlCopy
  *
  * Pass:
  *   INCo - Inventory Company  
  *  Source Location
  *  Category
  *  Material
  * Success returns:
  *
  *
  * Error returns:
  *	1 and error message
  **************************************/
  (@inco bCompany = null,  @sourceloc varchar(10) = null, @category varchar(10) = null, @material varchar(20) = null, 
@allLoc varchar(2) = 'L', @active varchar(1) = 'N',  @msg varchar(256) output)
  as
  set nocount on
  
  declare @rcode int
  
  select @rcode = 0
  
  if @inco is null
  	begin
  	select @msg = 'Missing IN Company.', @rcode = 1
  	goto vspexit
  	end


If @allLoc = 'L'
	Begin
		if @sourceloc is not null and @material is not null  and @category is null 
		--Get INLM information with material and category is null
		begin
			select Loc, Description, Active  from dbo.bINLM with (nolock) 
			where INCo = @inco   and Loc<>@sourceloc and Active  = case when @active ='Y' then @active else Active end
			and Loc Not In (Select Loc From dbo.INMT with(nolock) Where INCo = @inco and Material = @material)
		end
		if @sourceloc is not null and @material is null  and @category is not null 
		--Get INLM information with category and material is null
		begin
			select Loc, Description, Active    from dbo.bINLM with (nolock) 
			where INCo = @inco   and Loc<>@sourceloc 	and  Active  = case when @active ='Y' then @active else Active end
			and Loc Not In (Select INMT.Loc From dbo.INMT with(nolock) Inner Join dbo.HQMT with(nolock) on INMT.MatlGroup = HQMT.MatlGroup and INMT.Material = HQMT.Material Where INMT.INCo = @inco and  HQMT.Category = @category)
		end
		if @sourceloc is not null and @material is null  and @category is null  
		--Get INLM information when category and material are null
		Begin
			select Loc, Description, Active    from dbo.bINLM with (nolock) 
			where INCo = @inco   and Loc<>@sourceloc and Active  = case when @active ='Y' then @active else Active end
		end
End

If @allLoc = 'A'
Begin
		if @sourceloc is not null and @material is not null  and @category is null 
		--Get INLM information with material and category is null
		begin
			select Loc, Description, Active    from dbo.bINLM with (nolock) 
			where INCo = @inco  and  Loc<>@sourceloc and Active  = case when @active ='Y' then @active else Active end
		end
		if @sourceloc is not null and @material is null  and @category is not null 
		--Get INLM information with category and material is null
		begin
			select Loc, Description, Active    from dbo.bINLM with (nolock) 
			where INCo = @inco   and Loc<>@sourceloc 	and Active  = case when @active ='Y' then @active else Active end
		end
		if @sourceloc is not null and @material is null  and @category is null  
		--Get INLM information when category and material are null
		begin
			select Loc, Description, Active   from dbo.bINLM with (nolock) 
			where INCo = @inco   and Loc<>@sourceloc and Active  = case when @active ='Y' then @active else Active end
		end
End


vspexit:
    --  if @rcode<>0 select @msg=@msg + char(13) + char(10) + '[vspINMatlCopyLMInfoGet]'
  	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspINMatlCopyLMInfoGet] TO [public]
GO
