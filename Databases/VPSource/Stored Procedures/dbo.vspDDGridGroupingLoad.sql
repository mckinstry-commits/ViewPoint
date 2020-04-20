SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  CREATE    procedure [dbo].[vspDDGridGroupingLoad]
  /***********************************************************
   * CREATED BY:	GP 3/16/2010
   * MODIFIED By : 
   *
   * USAGE:
   * Loads grouping for the grid by Form (Parent Form), Tab (nullable),
   * and UserName.
   *
   * INPUTS:
   * Form - Parent Form.
   * Tab - Tab on Parent Form, nullable if Form is only used as related grid.
   * UserName - User to save settings for.
   * 
   * OUTPUTS:
   * Columns as dataset
   *
   ************************************************************************/
  	(@Form varchar(30) = null, @Tab tinyint = null, @UserName bVPUserName = null, 
  		@msg varchar(255) output)

	as
	set nocount on

	declare @rcode int, @ID bigint
	select @rcode = 0
	
	--setup default grouping of Bid Package and Scope
	declare @DefaultGrouping table ([Column] int not null)
	insert @DefaultGrouping ([Column]) --Bid Package
	values (100)
	insert @DefaultGrouping ([Column]) --Scope
	values (105)	
  
  
	--validation
	if @Form is null
	begin
		select @msg = 'Form is missing!', @rcode = 1
		goto vspexit		
	end
	
	if @UserName is null
	begin
		select @msg = 'UserName is missing!', @rcode = 1
		goto vspexit		
	end
  
  
	--get key id
	select @ID = KeyID 
	from dbo.vDDGridGroupingForm with (nolock) 
	where Form=@Form and Tab=isnull(@Tab,Tab) and UserName=@UserName
	
	--get list of columns
	if exists (select top 1 1 from dbo.vDDGridGroupingColumn where FormID=@ID)
	begin
		select [Column] from dbo.vDDGridGroupingColumn where FormID=@ID
		order by [Order]
	end
	else --get default columns if none found above
	begin
		select [Column] from @DefaultGrouping
	end


	vspexit:
  		return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspDDGridGroupingLoad] TO [public]
GO
