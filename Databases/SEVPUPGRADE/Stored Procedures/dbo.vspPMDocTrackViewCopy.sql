SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPMDocTrackViewCopy    Script Date: 11/26/08 9:33:07 AM ******/
   
   CREATE  proc [dbo].[vspPMDocTrackViewCopy]
    	(@SourceView varchar(10), @CopyTo varchar(10), @CopyToDesc varchar(30) = null,
		@msg varchar(255) output)
    as
    set nocount on
    /***********************************************************
     * CREATED BY:		GP 11/26/2008
     * MODIFIED By :
     *
     * USAGE:
     *	Validates the source view against the copy to view
	 *	in the form PMDocTrackViewCopy. Facilitates copy of
	 *	records from PMVM, PMVG, and PMVC.
     *
     * INPUT PARAMETERS
     *  SourceView  Source view name
	 *	CopyTo		CopyTo view name
     *
     * OUTPUT PARAMETERS
     *  @msg		Error message
	 *
     * RETURN VALUE
     *   0			Success
     *   1			Failure
     *****************************************************/
    declare @rcode int
   
    set @rcode = 0

	----------------
	-- Validation --
	----------------
    if @SourceView is null
    begin
    	select @msg = 'Missing Source View Name!', @rcode = 1
       	goto vspexit
    end
	if @CopyTo is null
    begin
    	select @msg = 'Missing Destination View Name!', @rcode = 1
       	goto vspexit
    end

	-- Check to make sure Source View Name exists in PMVM.
	if not exists(select top 1 1 from bPMVM with(nolock) where ViewName = @SourceView)
	begin
		select @msg = 'Source view name must exist in PM Document Tracking Views.', @rcode = 1
		goto vspexit
	end

	-- Check if View Name already exists in PMVM, PMVG, and PMVC.
	if exists(select top 1 1 from bPMVM with(nolock) where ViewName = @CopyTo)
	begin
		select @msg = 'The view name entered already exists in PM Document Tracking View Master, please enter a new name.', @rcode = 1
		goto vspexit
	end

	if exists(select top 1 1 from bPMVG with(nolock) where ViewName = @CopyTo)
	begin
		select @msg = 'The view name entered already exists in PM Document Tracking View Grids, please enter a new name.', @rcode = 1
		goto vspexit
	end

	if exists(select top 1 1 from bPMVC with(nolock) where ViewName = @CopyTo)
	begin
		select @msg = 'The view name entered already exists in PM Document Tracking View Columns, please enter a new name.', @rcode = 1
		goto vspexit
	end

	-----------------------------
	-- Copy Associated Records --
	-----------------------------
	begin try
		begin transaction

		-- PMVM Insert
		insert bPMVM(ViewName, Description)
		values(@CopyTo, @CopyToDesc)
				
		-- PMVG Insert
		if not exists(select @CopyTo, ViewGrid, GridTitle, Hide, Notes, Form from bPMVG with(nolock) where ViewName = @SourceView)
		begin
			insert bPMVG(ViewName, ViewGrid, GridTitle, Hide, Notes, Form)
			select @CopyTo, ViewGrid, GridTitle, Hide, Notes, Form from bPMVG with(nolock) where ViewName = @SourceView
		end

		-- PMVC Insert
		if not exists(select @CopyTo, ViewGrid, TableView, ColumnName, ColTitle, ColSeq, Visible, Notes, Form, GridCol
			from bPMVC with(nolock) where ViewName = @SourceView)
		begin
			insert bPMVC(ViewName, ViewGrid, TableView, ColumnName, ColTitle, ColSeq, Visible, Notes, Form, GridCol)
			select @CopyTo, ViewGrid, TableView, ColumnName, ColTitle, ColSeq, Visible, Notes, Form, GridCol
				from bPMVC with(nolock) where ViewName = @SourceView
		end

		commit transaction
	end try

	begin catch
		select @msg = error_message(), @rcode = 1
		rollback transaction
	end catch


    vspexit:
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDocTrackViewCopy] TO [public]
GO
