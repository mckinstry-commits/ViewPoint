SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
  CREATE    procedure [dbo].[vspDDGridGroupingInsert]
  /***********************************************************
   * CREATED BY:	GP 3/16/2010
   * MODIFIED By : 
   *
   * USAGE:
   * Saves grouping for the grid by Form (Parent Form), Tab (nullable),
   * UserName, and Column.
   *
   * INPUTS:
   * Form - Parent Form.
   * Tab - Tab on Parent Form, nullable if Form is only used as related grid.
   * UserName - User to save settings for.
   * Column - Column to save
   *
   ************************************************************************/
  	(@Form varchar(30) = null, @Tab tinyint = null, @UserName bVPUserName = null, @ColumnList varchar(max) = null, 
  		@msg varchar(255) output)

	as
	set nocount on

	declare @rcode int, @Column varchar(50), @ID bigint, @OldID bigint
	select @rcode = 0, @Column = null, @OldID = null
  
	
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
	
	if @ColumnList is null
	begin
		select @msg = 'Column list is missing!', @rcode = 1
		goto vspexit		
	end
  
  
	--get old key id
	select @OldID = KeyID 
	from dbo.vDDGridGroupingForm with (nolock) 
	where Form=@Form and Tab=isnull(@Tab,Tab) and UserName=@UserName
		
	--delete related column records
	if exists (select top 1 1 from dbo.vDDGridGroupingColumn with (nolock) where FormID=@OldID)
	begin
		delete dbo.vDDGridGroupingColumn
		where FormID = @OldID
	end
  
	--insert new form record
	if @OldID is null
	begin
		insert into dbo.vDDGridGroupingForm (Form, Tab, UserName)
		values (@Form, @Tab, @UserName)
		select @ID = scope_identity()
	end;	
	
	--insert related column records
	insert into dbo.vDDGridGroupingColumn ([Column], [Order], FormID)
	select Names, row_number() over(order by (SELECT 1)), isnull(@OldID,@ID)
	from vfTableFromArray(@ColumnList)
  


	vspexit:
  		return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDDGridGroupingInsert] TO [public]
GO
