SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQUDDelete    Script Date: 8/28/99 9:32:34 AM ******/
CREATE proc [dbo].[vspHQUDDelete]
/***********************************************************
* CREATED BY	: kb 9/29/00
* MODIFIED BY	: RM 05/03/01 - Delete Form Lookups before deleting DDFI entry
* Danf 06/27/01 - Added removal from Import Templates.
* kb 1/9/2 - issue #15811
* kb 1/9/2 - issue #15451
* kb 6/25/2 - issue #15451 - fixed so can delete user memo that exists on a form that has it in all grids
* kb 12/16/2 - issue #18924 - added LoadSeq to DDFL
* RM 03/27/03 - Issue#20691 - Delete User Input entries before DDFI entries.
* JRK 12/21/06 - convert to vsp:  Use "v" tables and "vsp" stored procs.  Eliminate resequencing code.
* JRK 7/19/07 - Removed related form logic and will call this from code for related forms.
* JRK 10/11/07 - Need to try to drop a constraint that would be there if the column has a default.
* JRK 10/26/07 - Ignore non-error msg coming back from vspDDSLUserColumn.
* DANF 12/6/07 - Issue 126353 Custom fields where not being remove from Import related tables. Added exec of bspHQUDDeleteImport.
* JRK 12/17/07 - Issue 126353 bspHQUDDeleteImport dropped @formname from the parameters list, so drop it here where we call it.
* JRK 12/28/07 - Issue 122335 If @tablename is null or "" then exit after removing field from DDFIc.  eg, for APUnappInvRev.
* JonathanP 08/28/2008 - Issue 129567 - We will now only delete the column and the DDSL entries if the given column name only exists in DDFIc once.
* JonathanP 09/17/2008 - Issue 129847 - We now call vspRefreshView instead of vspVAViewGen to refresh the view.
* GF 05/09/2010 - issue #139442 - added code to call new procedure to remove from PM Tracking and Import Detail.
* RM 05/14/2010 - 136368 - Removed code related to APUnappInvRev added for issue 122335.  This is a hack, and the correct solution is to ensure that the CustomFieldTable is filled in in DDFH.
* AL 08/1/2012 - Added error handling to the RefreshViews call(line 232). 
* Chris G 09/07/12 - B-10065 - Added call to update UDVersion
*
*
* USED IN:
* VA Custom Fields Wizard
*
* USAGE:
* The relationships of forms, tables and views:
*   In a straight-forward situation adding a custom field means altering the CustomFieldTable, regenerating a view
*   and creating a vDDFIc entry for it.
*   When adding a custom field to certain forms (and the underlying table) there may be special circumstances:
*   - There may be other forms that the field should appear on.  Eg, PM and JC are closely related.
*   - There may be other views that use the underlying table that need to be regenerated.
*   - If the form is batch posting form, there are related batch tables that need a column added to.
*	- If the FormName column of DDFR is null, there is no vDDFIc entry needed.
*
* INPUT PARAMETERS
*  @deletefromothers is zero (no others) or non-zero, meaning the column was added to related views.  
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
    
           (@formname varchar(30)=null,		-- The key to DDFH.
			@tablename varchar(30)=null,	-- The CustomTableName from DDFH.
            @viewname varchar(30)=null,		-- The ViewName from DDFH.
			@columnname varchar(30)=null,	-- ColumnName beginning with "ud"
            @msg varchar(512) = '' output)	-- output.
			with execute as 'viewpointcs'
        as
set nocount on
    
declare @rcode int, @columndatatype varchar(255), @altertablestmt varchar(255),
@ddfiquery varchar(255), 
@ddfiseq int,
@postedtable varchar(30),	-- 
@postedview varchar(30),
@seq int, @Datatype varchar(30)
-- @gridyn bYN, @relatedform varchar(30), @usermemotab tinyint,
-- @relatedseq int, @relatedtable varchar(30), @relatedview varchar(30),
-- @linkedgrids bYN,  @ddtablename varchar(30)

select @rcode = 0, @seq = -1

if @formname is null begin
	select @msg = 'Form name is missing', @rcode = 1
	goto bspexit
end
if @tablename is null begin
	select @msg = 'Table name is missing', @rcode = 1
	goto bspexit
end
if @viewname is null begin
	select @msg = 'View name is missing', @rcode = 1
	goto bspexit
end
if @columnname is null begin
	select @msg = 'Column name is missing', @rcode = 1
	goto bspexit
end

-- Get the Seq and Datatype of the custom field.
select @seq = Seq, @Datatype = Datatype from vDDFIc where Form = @formname and ColumnName = @columnname
if @@rowcount <> 1
begin
	select @msg = 'Problem determining Seq when deleting from DDFIc. ', @rcode=1
	select @seq = -1
	--goto bspexit
end

-- Get the PostedTable.  Posting routines have a transaction history table.  Eg, bAPTH is for APEntry.
select @postedtable = PostedTable from vDDFH
where Form = @formname

-- Derive the PostedView from the PostedTable.
if @postedtable is null
	select @postedview = null
else
	select @postedview = substring(@postedtable, 2, len(@postedtable) - 1) --Strip off leading "b" or "v" to get the view name.

-- Get the number of times the column name appears in DDFIc. Used for various checks below.
declare @columnNameCountInDDFIc int

--begin transaction

if @seq <> -1
begin
	-- Delete lookups first.
	delete from vDDFLc where Form = @formname and Seq = @seq 

	--Now delete User Customized Options
	delete from vDDUI where Form=@formname and Seq=@seq

	-- R E M O V E   R O W   F R O M   D D F I c
	-- Delete the custom field from vDDFIc.
	delete from vDDFIc where Form = @formname and ColumnName = @columnname
	and Seq = @seq	

	-- Issue 129567
	select @columnNameCountInDDFIc = COUNT(c.ColumnName) from DDFHShared f join DDFIc c on f.Form = c.Form 
									 where f.CustomFieldTable = @tablename and c.ColumnName = @columnname

	if @columnNameCountInDDFIc = 0
	begin
		-- R E M O V E   F R O M   D D S L c
		-- Delete vDDSLc (security link) entries for the column-main table.	
		begin
			declare @tempmsg varchar(255) -- We may get a message that we can ignore.
			exec @rcode = dbo.vspDDSLUserColumn @tablename, @Datatype, @columnname, null, 'Deletion', @tempmsg output
			-- I think @rcode will only be non-zero if you don't pass in a tablename or columnname.
			if @rcode <> 0 begin
				select @msg = 'Error Removing Column From Security Links table.' + @msg
				--rollback transaction
				goto bspexit
			end
	--		else begin
	--			if @tempmsg <> 'Invalid Security Data Type'
	--				select @msg = @tempmsg --this is a message we care about.
	--		end
			-- Repeat for the PostedTable
			if @postedtable is not null
			begin
				exec @rcode = dbo.vspDDSLUserColumn @postedtable, @Datatype, @columnname, null, 'Deletion', @msg output
				-- I think @rcode will only be non-zero if you don't pass in a tablename or columnname.
				if @rcode <> 0 begin
					select @msg = 'Error Removing Column From Security Links table.' + @msg
					--rollback transaction
					goto bspexit
				end
			end
		end
	end
end

-- Issue 129567
select @columnNameCountInDDFIc = COUNT(c.ColumnName) from DDFHShared f join DDFIc c on f.Form = c.Form 
								 where f.CustomFieldTable = @tablename and c.ColumnName = @columnname

if @columnNameCountInDDFIc = 0
begin
	-- R E M O V E   C O L U M N   F R O M   T A B L E
	if exists(select * from syscolumns where name = @columnname
	  and id = object_id(@tablename))
	begin
		BEGIN TRY
			select @altertablestmt = 'Alter table ' + @tablename + ' drop CONSTRAINT  [DF__' + @tablename + '__' + @columnname + '__DEFAULT]'
			--SELECT @msg = @msg + @altertablestmt
			exec(@altertablestmt)
		END TRY
		BEGIN CATCH 
			SELECT @msg = @msg + ' Dropping CONSTRAINT from table ' + @tablename + ' failed. '
		END CATCH 
		BEGIN TRY
			select @altertablestmt = 'Alter table ' + @tablename + ' drop column ' + @columnname
			exec(@altertablestmt)
		END TRY
		BEGIN CATCH 
			SELECT @msg = @msg + ' Dropping column from table ' + @tablename + ' failed. '
		END CATCH 
		-- Repeat for the PostedTable
		if @postedtable is not null
		begin
			select @altertablestmt = 'Alter table ' + @postedtable + ' drop column ' + @columnname
			BEGIN TRY 
				select @altertablestmt = 'Alter table ' + @postedtable + ' drop column ' + @columnname
				exec(@altertablestmt)
			END TRY 
			BEGIN CATCH 
				SELECT @msg = @msg + ' Dropping column from table ' + @postedtable + ' failed. '
			END CATCH 
		end
	 end

	-- R E M O V E   C O L U M N   F R O M   I M P O R T   T A B L E S
	If @formname is not null and @tablename is not null and @columnname is not null
		begin
		---- We call the old "bsp" stored proc for the main form.
		exec @rcode = bspHQUDDeleteImport @tablename, @viewname, @columnname, @msg output --No longer passing @formname since it isn't used.
		if @rcode <> 0
			begin
			select @msg = 'Error removing column from Import Templates for main table.'
			goto bspexit
			end
		
		---- #139442
		---- call the stored procedure to delete usage of the user memo from PM Tracking and Import Detail
		exec @rcode = dbo.vspHQUDDeleteForPM @tablename, @viewname, @columnname, @msg output --No longer passing @formname since it isn't used.
		if @rcode <> 0
			begin
			select @msg = 'Error removing column from PM Document Tracking or PM Import Templates for main table.'
			goto bspexit
			end
		end
end
-- Regenerate the view.
	BEGIN TRY
		exec vspRefreshViews @viewname
	END TRY
	BEGIN CATCH
		select @msg='Error regenerating view: ' + isnull(ERROR_MESSAGE(),'') + ' or its parent or child views.', @rcode = 1
		if @@TRANCOUNT > 0
			--rollback transaction
		goto bspexit	
	END CATCH

-- Regenerate the view for the posted table if there is one.
if @postedtable is not null
begin
	select @postedview = substring(@postedtable, 2, len(@postedtable) - 1)
	
	if @postedview is not null
	begin
		exec vspRefreshViews @postedview
	end
end

EXEC vspUDVersionUpdate @viewname

--if @@TRANCOUNT > 0
--	commit transaction

bspexit:

return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspHQUDDelete] TO [public]
GO
