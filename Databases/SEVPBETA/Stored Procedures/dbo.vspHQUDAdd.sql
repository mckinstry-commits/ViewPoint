SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspHQUDAdd    Script Date: 8/28/99 9:32:34 AM ******/
CREATE proc [dbo].[vspHQUDAdd]
       /***********************************************************
        * CREATED BY	: kb 9/29/00
        * MODIFIED BY	: kb 3/13/01
        * : danf 06/18/01 Added Update to Import templates
        * : kb 9/22/1 - issue #14663
        * : kb 12/19/1 - issue #15575
        * : kb 4/3/2 - issue #16740
        * : RM 05/08/03 - Issue# 16336 - Allow numerics
   		* :	RM 08/13/03 - Issue# 17253 - Do not allow datatype and inputtype.
  		* :	DANF 03/08/2004 - Issue #20536 - Update DDSL with User Memo Column.
		* : JRK 11/6/06 - Assorted changes to upgrade this for VP6.
		* : JRK 01/23/07 - Revise to accomodate redesigned vDDFR.
		* : 10/11/07 JRK Adding a Required field means setting NOT NULL and setting DEFAULT value.
		* : 10/26/07 JRK Add parameter @activelookup and set field in DDFI.
		* : 11/08/07 JRK commented out code that set controltype to 6 if bNotes.  There's a new control type 17 for bNotes.
		* : 11/13/07 GF - issue #126185 see if there is a base view that needs to be re-generated also.
		* : 11/16/07 JRK - #126086 - Accept -2 in ValParams and substitute in the new Seq nbr.
		* : 12/28/07 JRK - #122335 - Forms without a custom field table pass in "" for tablename; add checks for "" to bypass steps like adding field to a table; just add a DDFIc entry.
		* : 05/13/08 JonathanP - #127092 - Replaced vspVAViewGen calls with vspRefreshViews.
		* : 03/30/09 AL - #131766 - Added an if to ensure that duplicate DDFIc entries are not created 
		* : 04/09/09 JonathanP - #133044 - Fixed If statement to not have a -5 when checking if a DDFIc entry already exists.
		* : 02/12/10 AL - #132892 - Added a check for the Mask field.
		* : 09/07/12 Chris G - B-10065 - Added call to update UDVersion
		* : 09/17/12 Andy 2 - B-07373/TK-17928 DDUF.DestTable supports up 30 characters
		* : 01/16/13 Paul Wiegardt - B-11858 Allow Users to create UD Notes Fields For Standard Forms
		*				Added @showOnGrid = 'N' when @sysdatatype 'bFormattedNotes'
        * USED IN:
        *
        * USAGE:
        *
        * INPUT PARAMETERS
        *  @addladd is a flag indicating this is not the first call to this proc; when "Y" it means this is for related form.
        * OUTPUT PARAMETERS
        *   @msg      error message if error occurs
        * RETURN VALUE
        *   0         success
        *   1         Failure
        *****************************************************/
  
       (@formname varchar(30),			--  1
		@tabnbr tinyint,				--  2
		@tablename varchar(30),			--  3
		@viewname varchar(30),			--  4
		@columnname varchar(30),		--  5
		@usedatatype bYN,				--  6
		@inputtype tinyint = null,		--  7
		@inputlen int= null,			--  8
		@sysdatatype varchar(30)= null,	--  9
		@inputmask varchar(30)= null,	-- 10
		@prec int= null,				-- 11
		@labeltext bDesc= null,			-- 12
		@columnhdrtext bDesc= null,		-- 13
		@statustext varchar(256)= null, -- 14
		@required bYN = null,			-- 15
		@desc bDesc = null,				-- 16
		@controltype tinyint,			-- 17
		@combotype varchar(20) = null,	-- 18
		@vallevel tinyint = null,		-- 19
		@valproc varchar(60) = null,	-- 20
		@valparams varchar(256) = null,	-- 21
		@valmin varchar(20) = null,		-- 22
		@valmax varchar(20) = null,		-- 23
		@valexpr varchar(256) = null,   -- 24
		@valexprerror varchar(256) = null, -- 25
		@defaulttype tinyint = null,	-- 26
		@defaultvalue varchar(256) = null, -- 27
		@activelookup bYN = null, --28
		@msg varchar(255) output)		-- 29
	with execute as 'viewpointcs'
as
set nocount on

declare @rcode int, @columndatatype varchar(255), @altertable varchar(255),
		@ddfiquery varchar(255), @ddfiseq int, @usermemotab tinyint,
		@alterview varchar(255), @viewtable varchar(5), @ddfiviewname varchar(30),
		@relatedtable varchar(30), @relatedview varchar(30), @relatedform varchar(30),
		@relatedseq int, @postedtable varchar(30), @postedview varchar(30),
		@plainmask varchar(30), @showonform bYN, @gridform varchar(30),
		@baseviewname varchar(30), @showOnGrid bYN

--Variables for input mask testing
declare @decright varchar(30),@decleft varchar(30),@decindex int

select @rcode = 0

if @formname is null
     begin
     select @msg = 'Form name is missing', @rcode = 1
     goto bspexit
     end

if @tablename is null
     begin
     select @msg = 'Table name is missing', @rcode = 1
     goto bspexit
     end

if @viewname is null
     begin
     select @msg = 'View name is missing', @rcode = 1
     goto bspexit
     end

if @columnname is null
     begin
     select @msg = 'Column name is missing', @rcode = 1
     goto bspexit
     end

if @usedatatype is null
     begin
     select @msg = 'Datatype option is missing', @rcode = 1
     goto bspexit
     end

if @inputlen < len(@inputmask)
	begin
	select @msg='Input length is less than the length of the mask.',@rcode=1
	goto bspexit
	end

/*select @usermemotab = Tab from DDFT where Form = @formname and Title = 'Memos'*/

---- Not using a predefined data type like bDate or bJob?
if @usedatatype = 'N'  --or @inputtype in (2,3)
	begin
	if @inputtype is null
		begin
		select @msg = 'InputType option is missing while UseDataType=N', @rcode = 1
		goto bspexit
		end

	--select @sysdatatype = null
	select @columndatatype = @sysdatatype/*= case @inputtype
			when 0 then 'varchar(' + convert(varchar(10),isnull(@inputlen,30)) + ')'
			when 1 then 'int'
			when 2 then 'smalldatetime'
			when 3 then 'smalldatetime'
			end*/
	end
else  -- Yes, predefined.
	begin
	-- Call simple proc to look up the datatype and return info about it.  Error if not set up in DDDT.
	exec @rcode = vspDDDTGetDatatypeInfo @sysdatatype, @inputtype output, @inputmask output,
 			@inputlen output, @prec output, @columndatatype output, @msg output
	if @rcode <> 0 goto bspexit
	--select @inputtype= null, @inputmask= null, @inputlen = null, @prec = null
	end


if @columndatatype is null
	begin
	select @columndatatype = 
			case @inputtype  -- String=0, Numeric=1, Date=2, Month=3.
			when 0 then 'varchar(' + convert(varchar(10),isnull(@inputlen,30)) + ')'
			when 1 then 
			case @prec 
				when 0 then 'tinyint' 
				when 1 then 'smallint'
				when 2 then 'int' 
				when 3 then 'numeric'
				else 'int' end
			when 2 then 'smalldatetime'
			when 3 then 'smalldatetime'
			end

	if @columndatatype is null
		begin
		select @msg = 'Invalid datatype', @rcode = 1
		goto bspexit
		end
	end
    -- select @inputtype= null, @inputmask= null, @inputlen = null, @prec = null


if @inputmask is null
	begin
	if @columndatatype='numeric'
		begin
		select @columndatatype='numeric(' + convert(varchar(30),isnull(@inputlen,10)) + ',' + 
				case 
				when isnull(@inputlen,10) < 3 then convert(char(1),@inputlen) 
				when isnull(@inputlen,10) >= 3 then  '3' 
				end + ')'
		end
	end
else
	begin
	set @plainmask = replace(@inputmask,'R','')
	set @plainmask = replace(@plainmask,'L','')

	if @columndatatype='numeric'
		begin
		select	@decindex = isnull(charindex('.',@plainmask),0)
		if @decindex = 0
			begin
				select @msg='Invalid Mask.  This field must have an input mask with a decimal, because it is numeric.',@rcode=1
					goto bspexit
			end
		else
			begin
			--select @decleft = replace(replace(substring(@inputmask,1,@decindex - 1),'R',''),'L','')
			select @decright= substring(@plainmask,@decindex + 1,len(@inputmask) - @decindex)
			set @plainmask = replace(@plainmask,',','')
			set @plainmask = replace(@plainmask,'.','')
			select @columndatatype='numeric(' + convert(varchar(10),len(@plainmask)) + ',' + convert(varchar(10),len(@decright)) + ')'
			end
		end
	end

-- If the field is going on a tab that is a related form but the related form
-- doesn't show on the VP Main Menu, then it goes into a grid and there is no form.
select @gridform = t.GridForm
from DDFTShared t (nolock)
left outer join DDFHShared h (nolock) on t.GridForm = h.Form
where t.Form = @formname and Tab = @tabnbr
if @gridform = null
begin
	select @showonform = 'Y'
end
else
begin
	declare @showonmenu bYN
	select @showonmenu = h.ShowOnMenu
	from DDFHShared h (nolock)
	where h.Form = @gridform
	if @showonmenu = 'Y'
		select @showonform = 'N'
	else
		select @showonform = 'Y'
end

-- IF the field is type bFormattedNotes then we don't want to show the field on the Grid view
if @sysdatatype = 'bFormattedNotes'
	select @showOnGrid = 'N'
else
	select @showOnGrid = 'Y'
	
---- ok now we're gonna do a begin trans because if there is a problem from
---- here on out we need to set everything back to their previous state.

begin transaction

/******** GG 1/15/07 - due to VP6.0 changes in vDDFH and vDDFR the following code should be carefully reviewed
		We now track the CustomFieldTable in vDDFH and vDDFR only includes related forms  ***************/ 

        --in a few situations with PM and JC the view that the form goes with
		--and its related table are different (ie view JCJMPM, table bJCCM).
        --These were added to DDFR with a blank form name.  These views are
		--based on other views that will be updated, so we just need to recompile these.
        --The base view matches the tablename from DDFH, just strip off the leading "b".
		--Look for this record and replace the tablename with it

	-- The following looks for a matching entry in DDFR and possibly changes the value in @tablename.

	/* JRK 07/16/07 This condition no longer exists:  RelatedForm is never null.
	if exists(select * from vDDFR where Form = @formname and RelatedForm is null)
    begin
        select @tablename = h.ViewName from vDDFR r join vDDFH h on h.Form = r.Form 
		  where r.Form = @formname and r.RelatedForm is null 

        select @saveview = @viewname

        /*select @viewname = ViewName from DDFR where Form = @formname and
          FormName is null and TableName = @tablename and  ViewName <> @viewname*/
    end
	*/

/**************************************************
 ****   A D D   C O L U M N   T O   T A B L E   ****
 **************************************************/
if @tablename is not null and @tablename <> ''
	BEGIN TRY
	begin
	if not exists(select * from syscolumns where name = @columnname
				and id = object_id(@tablename))
		begin
		-- Make the column nullable and DDFI enforces it.
		select @altertable = 'Alter table ' + @tablename + ' add ' +
                @columnname  + ' ' + /*@sysdatatype*/ @columndatatype  + ' NULL'
		-- DefaultType 2 means fixed value.  0 means none, 1 means previous value and 3 means variable date.
		if @defaulttype = 2 and @defaultvalue is not null
		begin
			-- Add a default constraint.  Give it a name so we can drop it if we drop the column.
			select @altertable = @altertable + ' CONSTRAINT [DF__' + @tablename + '__' + @columnname + '__DEFAULT]'
			if @inputtype = 1 --Numeric
				 select @altertable = @altertable + ' DEFAULT ' + @defaultvalue
			else
				select @altertable = @altertable + ' DEFAULT ''' + @defaultvalue + ''''
			if @required = 'Y'
				select @altertable = @altertable + ' WITH VALUES'

		end
		select @msg = @msg + ' /* ' + @altertable + ' */'
		exec(@altertable)
		end
	end
	END TRY
	BEGIN CATCH
		select @msg='Error adding column to table ' + isnull(@tablename,'') + '.', @rcode = 1
		if @@TRANCOUNT > 0
			rollback transaction
		goto bspexit
	END CATCH
/************************************************************************************************
 ****   A D D   R O W   T O   D D F I c   I F   N O T   A N   I N T E R F A C E D   F O R M   ****
 ************************************************************************************************/

-- @formname could be passed in as null, but only if @addnladd is 'Y'.

if @formname is not null
	begin
	
		/*
			if @gridYN = 'Y'
            begin
				select @ddfiseq = isnull(max(Seq),0)+  1 from DDFI where
				  Form = @formname and ControlType=4 and Seq > @begingridseq
				  and Seq <=@endgridseq
				  select 'DDFISeq' = @ddfiseq, @begingridseq, @endgridseq
				select @usermemotab = Tab from DDFI where Form = @formname
				  and ControlType = 4 and Seq = @begingridseq
            end
			else            begin
		*/

/*
	if @columndatatype='bNotes'
		begin
		select @controltype=6 --custom textbox	
		end
*/
	
	-- Set the Seq value to a number >= 5000.
	select @ddfiseq = isnull(max(Seq),5000)+  5 from vDDFIc where Form = @formname and Seq >=5000

		/*end*/

	----------
		/* Per Kate, 11/6/06, this no longer applies. (jrk)
			--issue #15575 (interfaced grid)
			if exists(select * from vDDFIc where Form = @formname and ColumnName = @columnname)
			begin
				if @controltype <> 4 goto endinsert -- controltype "4" means grid.

				select @sameseq = min(Seq) from vDDFIc where Form = @formname and
				ColumnName = @columnname /*and Seq > @begingridseq and Seq <= @endgridseq*/
				if @sameseq is not null goto endinsert
			end
		*/
	------------

		/* if not exists(select * from DDFI where Form = @formname
			and ColumnName = @columnname) or
			(@controltype = 4 and not exists(select * from DDFI where
			Form = @formname and ColumnName = @columnname
			and @ddfiseq > @begingridseq and @ddfiseq <= @endgridseq))
			begin
		*/

	BEGIN TRY
	if not exists (select * from vDDFIc where Form = @formname and Seq = @ddfiseq)
	begin
				insert vDDFIc(Form, Seq, ViewName, ColumnName, 
				[Description], Label, GridColHeading, 
				Datatype, InputType, InputMask, InputLength, Prec, DefaultType,
				DefaultValue, InputSkip, StatusText, ControlPosition, TabIndex,
				Tab, Req, UpdateGroup, ControlType, FieldType, ShowGrid, ShowForm, 
				AutoSeqType, ValLevel, GridCol, ComboType, ValProc, ValParams, 
				MinValue, MaxValue, ValExpression, ValExpError, ActiveLookup,
				LookupLoadSeq)

				select @formname, @ddfiseq, @viewname, @columnname,
				@desc, @labeltext, @columnhdrtext,
				-- Datatype:
				case @usedatatype when 'Y' then @sysdatatype else null end, 
				-- InputType:
				--case @usedatatype when 'Y' then null else @inputtype end, --(JRK) always supply inputtype; can't be null or VPForm chokes.
				@inputtype,
				-- InputMask:
				case @usedatatype when 'Y' then null else @inputmask end,
				-- InputLength:
				case @usedatatype when 'Y' then null else @inputlen end , 
				-- Prec:
				case @usedatatype when 'Y' then null else @prec end,
				-- DefaultType:
				@defaulttype, 
				-- DefaultValue:
				@defaultvalue, 
				-- InputSkip:
				null, 
				-- StatusText:
				@statustext, 
				-- ControlPosition (x, y, width, height):
				'5, 5, 500, 21', 
				-- TabIndex:
				99, 
				-- Tab:
				@tabnbr, --1/*@usermemotab*/, 
				-- Required:
				isnull(@required,null),
				-- UpdateGroup:
				null, 
				-- ControlType:
				@controltype, 
				-- FieldType:
				4, 
				-- ShowGrid:
				@showOnGrid, 
				-- ShowForm:
				@showonform, 
				-- AutoSeqType and ValLevel:
				0, @vallevel,
				-- GridCol:  Make it the same as the DDFI Seq #
				@ddfiseq,
				-- ComboType, ValProc, ValParams, MinValue, MaxValue
				@combotype,
				@valproc,
				REPLACE(@valparams, '-2', @ddfiseq), --Substitue the new Seq nbr for '-2', if present.
				@valmin, @valmax, @valexpr, @valexprerror,
				isnull(@activelookup,'N'),
				0
				/* end */
		end
		
		EXEC vspUDVersionUpdate @viewname
		
	END TRY
	BEGIN CATCH
		select @msg='Error inserting into vDDFIc.', @rcode = 1
		if @@TRANCOUNT > 0
			rollback transaction
		goto bspexit
	END CATCH

	end

endinsert:

	/********************************************
	****   R E G E N E R A T E   V I E W S   ****
	********************************************/
BEGIN TRY
if @viewname is not null and @tablename is not null and @tablename <> ''
    begin
	---- if not a v6 base view, try to find a base view
	--if datalength(@viewname) <> 4
		--begin
		--select @baseviewname=TABLE_NAME from INFORMATION_SCHEMA.VIEW_TABLE_USAGE WHERE VIEW_NAME = @viewname
		--if @@rowcount <> 0 and left(@baseviewname,1) not in ('b','v') and @baseviewname <> @viewname
			--begin
			------ regenerate the base view if there is one
			--exec @rcode = vspVAViewGen @baseviewname, @tablename, @msg output
			--
			--if @rcode <> 0
			--begin
				--select @msg='Error regenerating view: ' + isnull(@viewname,'') + '.', @rcode = 1
				--if @@TRANCOUNT > 0
					--rollback transaction
				--goto bspexit
			--end
			--
			--end
		--end
	--Regenerate the view.  mh 10/10
	
	
	--exec @rcode = vspVAViewGen @viewname, @tablename, @msg output
	
	-- See issue #127092. Now the all of the views will be refreshed that are related to this view (parents and children)
	BEGIN TRY
		exec vspRefreshViews @viewname
	END TRY
	BEGIN CATCH
		select @msg='Error regenerating view: ' + isnull(@viewname,'') + ' or its parent or child views.', @rcode = 1
		if @@TRANCOUNT > 0
			rollback transaction
		goto bspexit	
	END CATCH
		
    end
END TRY
BEGIN CATCH
	select @msg='Error regenerating view ' + isnull(@viewname,'') + '.', @rcode = 1
	if @@TRANCOUNT > 0
		rollback transaction
	goto bspexit
END CATCH

	/******************************************************************************
	****   A D D   C O L U M N   T O   B A T C H   P O S T I N G   T A B L E   ****
	******************************************************************************/
BEGIN TRY
select @postedtable = PostedTable --, @postedview =PostedView --(JRK) PostedView was dropped. Need to derive it by stripping off leading "b".
from DDFHShared where Form = @formname

if @postedtable is not null
    begin
	if not exists(select * from syscolumns where name = @columnname and id = object_id(@postedtable))
		begin
		select @altertable = 'Alter table ' + @postedtable + ' add ' +
		@columnname  + ' ' + @columndatatype + ' NULL'
		exec(@altertable)
		end
    end
END TRY
BEGIN CATCH
	select @msg='Error adding column to batch table ' + isnull(@postedtable,'') + '.', @rcode = 1
	if @@TRANCOUNT > 0
		rollback transaction
	goto bspexit
END CATCH

	/****************************************************************
	****   A D D   C O L U M N   T O   I M P O R T   T A B L E   ****
	****************************************************************/
BEGIN TRY
if @formname is not null and @tablename is not null and @tablename <> '' and @viewname is not null
    begin
	declare @ImportForm varchar(30)
	select @ImportForm = Form 
	from DDUF where DestTable = substring(@tablename,2,30)--TK-17928 30 characters
	if @ImportForm is not null
		begin
								
		exec @rcode = bspHQUDAddImport @formname, @tablename, @viewname, @columnname, @usedatatype,
								@sysdatatype, @columndatatype, @labeltext, @ddfiseq, @msg output
		if @rcode <> 0
			begin
			select @msg='Error Adding User Memo to Import Templates.', @rcode = 1
			if @@TRANCOUNT > 0
				rollback transaction
			goto bspexit
			end
		end

	/********************************************************************************
	****   A D D   C O L U M N   T O   S E C U R I T Y   L I N K S   T A B L E   ****
	********************************************************************************/
	exec @rcode = dbo.bspDDSLUserColumn @tablename, @sysdatatype, @columnname, @formname, 'Addition', @msg output
	if @rcode <> 0
		begin
		select @msg='Error Adding User Memo Security Links Table. ', @rcode = 1
		if @@TRANCOUNT > 0
			rollback transaction
		goto bspexit
        end
	end

 	/************************************************************************
	****   R E G E N E R A T E   S E C U R I T Y   L I N K S   V I E W   ****
	************************************************************************/
END TRY
BEGIN CATCH
	select @msg='Error adding column to import table or security links table.', @rcode = 1
	if @@TRANCOUNT > 0
		rollback transaction
	goto bspexit
END CATCH

BEGIN TRY
if @postedtable is not null
	begin
		select @postedview = substring(@postedtable, 2, len(@postedtable) - 1) --(JRK) Derive PostedView from PostedTable.
		if @postedview is not null
			begin
			
				-- See issue #127092. Now the all of the views will be refreshed that are related to this view (parents and children)
				BEGIN TRY
					exec vspRefreshViews @postedview
				END TRY
				BEGIN CATCH
					select @msg='Error regenerating view: ' + isnull(@viewname,'') + ' or its parent or child views.', @rcode = 1
					if @@TRANCOUNT > 0
						rollback transaction
					goto bspexit	
				END CATCH
								
				--
				--exec @rcode = vspVAViewGen @postedview, @postedtable, @msg output
				--if @rcode <> 0
					--begin
						--select @msg='Error regenerating view', @rcode = 1
						--if @@TRANCOUNT > 0
							--rollback transaction
						--goto bspexit
					--end
			end
	end
END TRY
BEGIN CATCH
	select @msg='Error regenerating the view of the Posted Table.', @rcode = 1
	if @@TRANCOUNT > 0
		rollback transaction
	goto bspexit
END CATCH


if @@TRANCOUNT > 0
	commit transaction




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQUDAdd] TO [public]
GO
