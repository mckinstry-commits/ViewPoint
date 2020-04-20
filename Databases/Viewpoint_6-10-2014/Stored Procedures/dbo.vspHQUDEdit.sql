SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE                 Proc [dbo].[vspHQUDEdit]
      /**********************************
      	Created: 06/30/03 RM 
      
     	Modified
		: 08/12/04 RM - 25318, Added code to deal with odd views in JC and PM
   		: 04/13/05 RM - 26948, Recompile View after edit.
		: 05/16/2007 JRK - Port to VP6.
		: 07/25/07 JRK DDFR has been restructured.  Pass in more values.  Rewritten except for section about verifying the mask is correct.
		: 10/11/07 JRK Changing to Required means setting DEFAULT value.
		: 11/27/07 JRK Allow @tabnbr to be null.
		: 04/09/09 JonathanP 133044 - This procedure now calls vspRefreshViews instead of vspVAViewGen
        : 10/18/10 GarthT 138039 - When altering table use underlying sqldatatype for pre-defined.
      	
      	Usage: Used by the VA Custom Field Wizard (was HQUDEdit program) to change field properties
      			and alter the column in the table if necessary.
      
		Allow data to grow bigger but not smaller.

		If null is passed in for DDFIc values, null will be written into the field.  Ie, nulls don't mean to leave the field unchanged.

		If the field has a Datatype, the InputType and InputLength come from DDDTShared.
		If there is InputType there should be InputLength.
      ***********************************/
       (@form varchar(30)=null, 
		@columnname varchar(30), --Cannot be changed.
		--@datatype varchar(30)=null, --DataType is a predefined value like bMonth.
		--@inputtype tinyint = null, --InputType can be 0 string, 1 numeric, 2 date or 3 month.
		@prec int= null, --Precision can be 0 = tinyint, 1 = smallint, 2 = int, 3 = numeric (ie, decimal).  It can grow, not shrink.
		@inputmask varchar(30) = null, -- Mask can change as long as @prec = 3
		@inputlength int = null, --InputLength can grow, not shrink.
		@tabnbr tinyint = null, --required value passed in
		@controltype tinyint = null, --required value passed in
		@required bYN = null, --required value passed in
		@desc bDesc = null,					--  9
      	@statustext varchar(256) = null,	-- 10
      	@labeltext varchar(30) = null,		-- 11
		@gridcolheading varchar(30) = null,	-- 12
		@combotype varchar(20) = null,		-- 13
		@vallevel tinyint = null,			-- 14
		@valproc varchar(60) = null,		-- 15
		@valparams varchar(256) = null,		-- 16
		@minvalue varchar(20) = null,		-- 17
		@maxvalue varchar(20) = null,		-- 18
		@valexpr varchar(256) = null,		-- 19
		@valexprerror varchar(256) = null,	-- 20
		@defaulttype tinyint = null,			-- 21
		@defaultvalue varchar(256) = null,		-- 22
		@errmsg varchar(512) output)		-- 23
		with execute as 'viewpointcs'
      as

	declare @rcode int, @debugmsg varchar(2000)

	select @rcode=0, @errmsg=''

	if @form is null or @columnname is null or @controltype is null or @required is null
	begin
		select @errmsg='@form, @columnname, @controltype and @required are required.', @rcode=1
		goto bspexit
	end
	if @inputlength < len(@inputmask)
	begin
		select @errmsg='Input length is less than the length of the mask.',@rcode=1
		goto bspexit
	end
      
	declare @seq int, @alterstring varchar(1000), @tempmask varchar(100), @decpos int,
	@leftofdecimal int, @rightofdecimal int, 
	@oldinputtype  tinyint, @oldprec int, @oldinputlength int, @oldscale int, @olddatatype varchar(30),
	@olddefaultvalue varchar(256),
	@tablename varchar(30), @numerictype varchar(255),
	@sqldatatype varchar(255), @viewname varchar(30),
	@dropconstraint varchar(256), @addconstraint varchar(256), @constraintname varchar(128),
	@defaultprec tinyint 



	-- S K I P   T A B L E   A L T E R   I F   P O S S I B L E
	-- We don't need to alter tables or regenerate views if the data type isn't changing.
    select @alterstring = ''
	select @debugmsg ='Start.  '

	-- Gather existing values about the type of data column.
    select  @seq=i.Seq, @olddatatype=i.Datatype, @oldinputtype=i.InputType, 
	@oldinputlength=i.InputLength, @oldprec = i.Prec, 
	@viewname=i.ViewName, @tablename=h.CustomFieldTable, @olddefaultvalue = i.DefaultValue
    from vDDFIc i
	join vDDFH h on i.Form = h.Form
    where i.Form=@form and i.ColumnName=@columnname
	if @@rowcount = 0
	begin
      	select @errmsg='No such record in DDFIc.',@rcode=1
      	goto bspexit
	end

	if @olddatatype is not null
	begin
		select @sqldatatype = SQLDatatype
		from DDDTShared
		where Datatype = @olddatatype
	end
	
	-- If the field has a Datatype, the InputType and InputLength come from DDDTShared.
	if @olddatatype is not null
	begin
		select @oldinputtype = InputType, @oldinputlength = InputLength from DDDTShared where Datatype = @olddatatype
		select @inputlength = null --ignore if passed in.
	end
	-- Compare values passed in to the existing values.
/*
	if @datatype is not null and @datatype <> @olddatatype
	begin
		select @errmsg='Cannot change DataType.', @rcode=1
		goto bspexit
	end
*/
/*
	if @inputtype is not null and @inputtype <> @oldinputtype
	begin
		select @errmsg='Cannot change the InputType.', @rcode=1
		goto bspexit
	end
*/
	if @required <> 'Y'
		select @required = 'N'

	if @olddatatype is null and @oldinputtype = 0 --string
	begin
		if @inputlength is not null and @inputlength < @oldinputlength
		begin 
			select @errmsg='Cannot make the data size smaller.', @rcode=1
			goto bspexit
		end
		if @inputlength is not null and @inputlength > @oldinputlength
		begin 
			select @alterstring = 'alter table ' + @tablename + ' alter column ' + @columnname + ' varchar(' + convert(varchar(5),@inputlength) + ') null'
		end
	end
	if @oldinputtype = 1 and @prec is not null and @oldprec > @prec
	begin
		select @errmsg='Cannot make numeric size (Prec) smaller.', @rcode=1
		goto bspexit
	end
	if @oldinputtype = 1 and @prec is not null and (@prec > 3 or @prec < 0)
	begin
		select @errmsg='Numeric size (Prec) must be in the range of 0 to 3.', @rcode=1
		goto bspexit
	end

	--  START BUILDING AN ALTER TABLE STRING THAT VARIES BASED ON THE DATATYPE.
	if @sqldatatype is not null 
		select @alterstring = 'alter table ' + @tablename + ' alter column ' + @columnname + ' ' + @sqldatatype + ' null'
	else -- not a pre-defined data type.
	begin
		if @oldinputtype = 0 or @oldinputtype = 5 --String or Multi-part
			select @alterstring = 'alter table ' + @tablename + ' alter column ' + @columnname + + ' varchar(' + convert(varchar(5),@inputlength) + ') null'
		if @oldinputtype = 1 --Allow numeric types some latitue of change.
		begin
			-- Finally, for decimal make sure the mask is correct.
			--Save a copy of the input mask
			select @tempmask=@inputmask
			--strip out the positioning characters and other characters
			select @tempmask=replace(replace(@tempmask,'R',''),'L','')
			select @tempmask=replace(@tempmask,',','')
			select @decpos = charindex('.',@tempmask,1)
			if @prec=3 /*numeric, decimal*/
			begin
				if @decpos = 0 /*no decimal pt error*/
				begin
					select @errmsg='Invalid Mask.  This field must have an input mask with a decimal, because it is numeric.',@rcode=1
					goto bspexit
				end
				-- Is the mask valid?
  				select @leftofdecimal=@decpos-1
  				select @rightofdecimal=len(@tempmask)-@leftofdecimal-1

  				select @oldprec=prec, @oldscale=scale from syscolumns where name=@columnname and id=object_id(@tablename)
				if @oldprec is not null and @oldscale is not null
				begin
					if @leftofdecimal < @oldprec - @oldscale - 1
					begin
						select @errmsg = 'Invalid Mask.  Number of digits to the left of the decimal must be at least ' + isnull(convert(varchar(10),@oldprec - @oldscale),'') + '.' + ' ' + isnull(@columnname,''),@rcode=1
						goto bspexit
					end
				end --@oldprec/@oldscale not null
				-- The mask is valid so use it to alter the table.
				select @numerictype='dec(' + convert(varchar(5),@leftofdecimal + @rightofdecimal + 1) + ',' + convert(varchar(5),@rightofdecimal) + ')'
  				select @alterstring = 'alter table ' + @tablename + ' alter column ' + @columnname + ' ' + @numerictype + ' null'
			end --@prec=3
			else
			begin --@prec<>3 (must be tinyint, smallint or int)

				if @decpos <> 0 /*decimal, not allowed.  int, smallint or tinyint */
				begin
					select @errmsg='Cannot have an input mask with a decimal on this field, because it is not setup as a numeric type field.',@rcode=1
					goto bspexit
				end		      
  				if @sqldatatype is null
  				begin
  					if @oldinputtype is null --Then old field was based on a datatype
  					begin
  						select @oldinputtype = InputType, @prec=Prec from DDDTShared where Datatype=(select Datatype from vDDFIc where Form=@form and Seq=@seq)
  					end 
  					else --@oldinputtype is null (else)
 					begin
 	 					if @oldinputtype = 0 --text
 	 					begin
 	 						select @alterstring = 'alter table ' + @tablename + ' alter column ' + @columnname + ' varchar(' + convert(varchar(30),@inputlength) + ') null'
 	 					end --@oldinputtype=0
 	 					if @oldinputtype = 1 --numeric
 	 					begin
 	 						select @alterstring = 'alter table ' + @tablename + ' alter column ' + @columnname + case @prec when 0 then ' tinyint' when 1 then ' smallint' else ' int' end + ' null'
 	 					end --@oldinputtype=0
						/* We're not going to alter column is set up as Date (@oldinputtype=2)  or Month (@oldinputtype=3). */
 					end 
  				end --@sqldatatype is null
  				else
  				begin --else @sqldatatype is not null

  					select @alterstring = 'alter table ' + @tablename + ' alter column ' + @columnname + ' ' + @sqldatatype + ' null'
  				end --@sqldatatype is null (else)
			end --@prec<>3 (else)	end
		end -- @inputtype = 1
		if @oldinputtype = 2 -- date
			select @alterstring = 'alter table ' + @tablename + ' alter column ' + @columnname + ' bDate null'
		if @oldinputtype = 3 -- month
			select @alterstring = 'alter table ' + @tablename + ' alter column ' + @columnname + ' bMonth null'
	end



/* --This is old logic based on the old DDFR layout.
     --in a few situations with PM and JC the view that the form goes with
     --and its related table are differen (ie view , table bJCCM
     --not  these were added to DDFR with a blank form name where
     --the view matches the tablename from DDFH, look for this record and
     --replace the tablename with it
     if exists(select * from DDFR where Form = @form and FormName is null
     		and ViewName = @tablename and TableName <> 'b' + @tablename)
     begin
     	select @tablename = TableName from DDFR where Form = @form and
     		FormName is null and ViewName = @tablename and TableName <> 'b' + @tablename
     
     	if substring(@tablename,1,1) = 'b'
     		select @tablename = substring(@tablename,2,len(@tablename) - 1)
     end
*/
     


transtart:
	begin tran --start a transaction, so it will get rolled back if anything goes wrong.
	--Alter the table column to change the datatype if necessary.
	--select @debugmsg = @debugmsg + ' @alterstring = ' + @alterstring

	--print 'H = ' + isnull(@alterstring,'')
	--select @errmsg = @errmsg + ' ' + @alterstring
	--goto bspexit

	if @alterstring <> ''
	begin
	-- Deal with default values.
		select @constraintname = 'DF__' + @tablename + '__' + @columnname + '__DEFAULT'
		--select @errmsg = @errmsg + ' NEW=' + @defaultvalue + ' OLD=' + @olddefaultvalue + ' CONSTRAINT = ' + @constraintname
		--goto bspexit

		if exists(select name from sys.default_constraints where name = @constraintname
		and @defaultvalue <> @olddefaultvalue)
		begin
			-- Drop the default constraint, if it exists.
			BEGIN TRY
				select @dropconstraint = 'Alter table ' + @tablename + ' DROP CONSTRAINT ' + @constraintname
				--SELECT @errmsg =  @errmsg + ' About to drop.' --+ @dropconstraint
				--GOTO bspexit
				exec(@dropconstraint)
				--select @errmsg = @errmsg + ' Drop constraint successful.'
			END TRY
			BEGIN CATCH 
				SELECT @errmsg = @errmsg + ' Dropping CONSTRAINT from table ' + @tablename + ' failed; reason:  ' + ERROR_MESSAGE(), @rcode=1
				goto bspexit
			END CATCH 
		end
		
			--SELECT @errmsg =  @errmsg + ' Skipping the drop. '
--/*
		-- Add a default constraint using the @alterstring.  Give it a name so we can drop it if we drop the column.
		BEGIN TRY
			if @defaulttype = 2 and @defaultvalue is not null and @defaultvalue <> @olddefaultvalue 
			begin

				select @addconstraint = 'Alter table ' + @tablename + ' ADD CONSTRAINT ' + @constraintname
				-- Add a default constraint.  Give it a name so we can drop it if we drop the column.
				if @oldinputtype = 1 --Numeric
					 select @addconstraint = @addconstraint + ' DEFAULT ' + @defaultvalue + ' FOR ' + @columnname
				else
					select @addconstraint = @addconstraint + ' DEFAULT ''' + @defaultvalue + ''' FOR ' + @columnname
				select @addconstraint = @addconstraint
				SELECT @errmsg =  @errmsg + ' ** @addconstraint = ' + @addconstraint + ' **. '
--				if @required = 'Y'
--					select @addconstraint = @addconstraint + ' WITH VALUES'
				exec(@addconstraint)




/*
				if @oldinputtype = 0 or @oldinputtype = 5
					select @addconstraint = @addconstraint + ' DEFAULT ' + char(39) + @defaultvalue + char(39)

				if @oldinputtype = 1 --Numeric
				begin
					declare @tempprec tinyint
					if @prec is null
						select @tempprec = @oldprec
					else
						select @tempprec = @prec

					if @tempprec = 0
					BEGIN
						declare @defaulttiny tinyint
						select @defaulttiny = CONVERT(tinyint, @defaultvalue)
						select @addconstraint = @addconstraint + @defaulttiny
					END
					if @tempprec = 1
					BEGIN
						declare @defaultsmall smallint
						select @defaultsmall = CONVERT(smallint, @defaultvalue)
						select @addconstraint = @addconstraint + @defaulttiny
					END
					if @tempprec =  2 
					BEGIN
						declare @defaultint int
						select @defaultint = CONVERT(int, @defaultvalue)
						select @addconstraint = @addconstraint + @defaultint
					END
					if @tempprec =  3 
					BEGIN
						declare @defaultdec dec
						select @defaultdec = CONVERT(dec, @defaultvalue)
						select @addconstraint = @addconstraint + @defaultdec
					END
				end -- @oldinputtype = 1 --Numeric
				else
				begin
					if @oldinputtype = 0 or @oldinputtype = 5 -- string or multi-part.
						select @addconstraint = @addconstraint + ' DEFAULT ' + char(39) + @defaultvalue + char(39)
					else -- must be date or month
					begin
						declare @tempdate smalldatetime
						select @tempdate = convert(smalldatetime,@defaultvalue)
						select @addconstraint = @addconstraint + ' DEFAULT ' + @tempdate
					end
				end

				select @addconstraint = @addconstraint + ' FOR ' + @columnname
*/

				/*		You cannot use WITH VALUES on an existing column. 
				if @required = 'Y'
					select @addconstraint = @addconstraint + ' WITH VALUES'
				*/
				--select @errmsg = @errmsg + ' Add constraint successful.'
			end
		END TRY
		BEGIN CATCH 
			SELECT @errmsg = @errmsg + ' Adding CONSTRAINT to table ' + @tablename + ' failed; reason:  ' + ERROR_MESSAGE(), @rcode=1
			goto bspexit
		END CATCH 
--*/
		BEGIN TRY
			exec(@alterstring)
		END TRY
		BEGIN CATCH
			SELECT @errmsg = @errmsg + ' The table alter failed for ' + @tablename + '; reason:  ' + ERROR_MESSAGE()
			select @rcode = 1
			goto bspexit
		END CATCH

		-- R E G E N E R A T E   T H E   M A I N   T A B L E ' S   V I E W
		--declare @viewmsg varchar(256)
  -- 		exec @rcode = vspVAViewGen @viewname, @tablename, @viewmsg output
  -- 		if @rcode <> 0
  -- 		begin
  -- 			select @errmsg = 'Could not regenerate base view ''' + isnull(@tablename,'NULL') + '''', @rcode=1
  -- 			goto bspexit
  -- 		end
	
		-- #133044
		exec vspRefreshViews @viewname

		-- A L T E R   T H E  P O S T E D T A B L E   I F   N E C E S S A R Y
		declare  @postedtable varchar(30)
		select @postedtable = PostedTable from DDFHShared where Form = @form
		if @postedtable is not null
		begin
			if exists(select * from syscolumns where name = @columnname and id = object_id(@postedtable))
			begin
				declare @alterpostedtable varchar(200)
				select @alterpostedtable = replace(@alterstring, @tablename, @postedtable)
				exec(@alterpostedtable)

				-- R E G E N E R A T E   T H E   P O S T E D   T A B L E ' S   V I E W
				declare @postedview varchar(30)
				select @postedview = substring(@postedtable, 2, len(@postedtable) - 1)
   				
   				--exec @rcode = vspVAViewGen @postedview, @postedtable, @viewmsg output
   				--if @rcode <> 0
   				--begin
   				--	select @errmsg = 'Could not regenerate posted table view ''' + isnull(@postedtable,'NULL') + '''', @rcode=1
   				--	goto bspexit
   				--end
   				
   				-- #133044
   				exec vspRefreshViews @postedview
   				
			end
		end -- @postedtable is not null
	end -- @altertable <> ''

	-- Build up an UPDATE DDFIc SET string:
	declare @updatestring varchar(1000)
	select @updatestring = 'update vDDFIc SET '
	if @tabnbr is not null
		select @updatestring = @updatestring + '[Tab]=' + convert(varchar(5), @tabnbr) + ','
	select @updatestring = @updatestring + ' [ControlType]=' + convert(varchar(5), @controltype)
	select @updatestring = @updatestring + ', [Req]=''' + @required + ''''

	if @desc is null
		select @updatestring = @updatestring + ', [Description]=null'
	else
		select @updatestring = @updatestring + ', [Description]=''' + @desc + ''''

	if @inputmask is null
		select @updatestring = @updatestring + ', [InputMask]=null'
	else
		select @updatestring = @updatestring + ', [InputMask]=''' + @inputmask + ''''

	if @inputlength is null
		select @updatestring = @updatestring + ', [InputLength]=null'
	else
		select @updatestring = @updatestring + ', [InputLength]=' + convert(varchar(5),@inputlength)

	if @statustext is null
		select @updatestring = @updatestring + ', [StatusText]=null'
	else
		select @updatestring = @updatestring + ', [StatusText]=''' + @statustext + ''''

	if @labeltext is null
		select @updatestring = @updatestring + ', [Label]=null'
	else
		select @updatestring = @updatestring + ', [Label]=''' + @labeltext + ''''

	if @gridcolheading is null
		select @updatestring = @updatestring + ', [GridColHeading]=null'
	else
		select @updatestring = @updatestring + ', [GridColHeading]=''' + @gridcolheading + ''''

	if @prec is null
		select @updatestring = @updatestring + ', [Prec]=null'
	else
		select @updatestring = @updatestring + ', [Prec]=' + convert(varchar(5),@prec)

	if @combotype is null
		select @updatestring = @updatestring + ', [ComboType]=null'
	else
		select @updatestring = @updatestring + ', [ComboType]=''' + @combotype + ''''

	if @vallevel is null
		select @updatestring = @updatestring + ', [ValLevel]=null'
	else
		select @updatestring = @updatestring + ', [ValLevel]=' + convert(varchar(5),@vallevel)

	if @valproc is null
		select @updatestring = @updatestring + ', [ValProc]=null'
	else
		select @updatestring = @updatestring + ', [ValProc]=''' + @valproc + ''''

	if @valparams is null
		select @updatestring = @updatestring + ', [ValParams]=null'
	else
		select @updatestring = @updatestring + ', [ValParams]=''' + @valparams + ''''

	if @minvalue is null
		select @updatestring = @updatestring + ', [MinValue]=null'
	else
		select @updatestring = @updatestring + ', [MinValue]=''' + @minvalue + ''''

	if @maxvalue is null
		select @updatestring = @updatestring + ', [MaxValue]=null'
	else
		select @updatestring = @updatestring + ', [MaxValue]=''' + @maxvalue + ''''

	if @defaulttype is null
		select @updatestring = @updatestring + ', [DefaultType]=null'
	else
		select @updatestring = @updatestring + ', [DefaultType]=' + convert(varchar(5),@defaulttype)

	if @defaultvalue is null
		select @updatestring = @updatestring + ', [DefaultValue]=null'
	else
		select @updatestring = @updatestring + ', [DefaultValue]=''' + @defaultvalue + ''''

	if @valexpr is null
		select @updatestring = @updatestring + ', [ValExpression]=null'
	else
		select @updatestring = @updatestring + ', [ValExpression]=''' + @valexpr + ''''

	if @valexprerror is null
		select @updatestring = @updatestring + ', [ValExpError]=null'
	else
		select @updatestring = @updatestring + ', [ValExpError]=''' + @valexprerror + ''''

	select @updatestring = @updatestring + ' where [Form]=''' + @form + ''' and [Seq]=' + convert(varchar(5),@seq)
	-- E X E C U T E   T H E   D D F I c   U P D A T E   C O M M A N D
	select @debugmsg = @debugmsg + ' @updatestring = ' + isnull(@updatestring,'')
	BEGIN TRY
		exec (@updatestring)
	END TRY
	BEGIN CATCH
		Select @errmsg = 'DDFIc updated failed; reason:  ' + ERROR_MESSAGE(), @rcode=1
		goto bspexit
	END CATCH
	
	EXEC vspUDVersionUpdate @viewname

	-- U P D A T E   I M P O R T   T A B L E   I F   N E C E S S A R Y

	/* DanF */   

	-- U P D A T E   S E C U R I T Y   L I N K S   T A B L E   I F   N E C E S S A R Y

	/* DanF */   



 /*  -- There is logic in the front end to find related tables and repeatedly call this stored proc.

   declare @ddfrtable varchar(500), @ddfrcolumn varchar(500)
     
      declare bcDDFR cursor local fast_forward for
      Select i.Form,i.Seq from DDFIc i join DDFR r on i.Form=r.FormName
      Where i.ColumnName in (select ColumnName from DDFIc where Form=@form and Seq=@seq)
      and r.Form = @form
     
      open bcDDFR

      fetch next from bcDDFR into @form,@seq
      while @@fetch_status=0
      begin
     	 update DDFIc
      	 set Description=@desc,
     	 	Datatype=@datatype,
     	 	InputMask=@inputmask,
     	 	InputLength=@inputlength,
     	 	InputType=@inputtype,
     	 	StatusText=@statustext,
     	 	Prec=@prec
      	 where Form=@form and Seq=@seq
     
     	select @ddfrtable=TableName, @ddfrcolumn=ColumnName from DDFIc where Form=@form and Seq=@seq
     
     	 select @alterstring = replace(replace(@originalalterstring, '##TABLENAME##',@ddfrtable),'##COLUMNNAME##',@ddfrcolumn)
     	 exec(@alterstring)
     
     	 select @postedtable = Right(PostedTable,len(PostedTable)-1) from
                 DDFHShared where Form = @form
     
               if @postedtable is not null
                   begin
                   if exists(select * from syscolumns where name = @columnname
                     and id = object_id(@postedtable))
                       begin
                       select @alterstring = replace(replace(@originalalterstring, '##TABLENAME##',@postedtable),'##COLUMNNAME##',@ddfrcolumn)
     		  exec(@alterstring)
                       end
                   end
   	/* Recompile View for Related table*/
   	select @viewgentable = 'b' + @ddfrtable
   	exec @rcode = vspVAViewGen @ddfrtable,@viewgentable, @errmsg output
   	
   	if @rcode <> 0
   	begin
   		select @errmsg = 'Could not regenerate related view ''' + isnull(@ddfrtable,'NULL') + '''', @rcode=1
   		goto bspexit
   	end
      fetch next from bcDDFR into @form,@seq 
      end
      
      close bcDDFR
      deallocate bcDDFR
         
*/     
      
		commit tran

      
bspexit:
	if @rcode=1
	begin
		--select @errmsg = isnull(@errmsg,'') 
		if @@TRANCOUNT >0
			rollback tran
	end
	else
		if @@TRANCOUNT >0
			commit tran
	return @rcode
      
      
/*
	  begin try

      --Execute Insert Statement
      exec(@insertstmt)
	
	  end try 
   
	  begin catch
        select @errcode = ERROR_NUMBER(), @rcode = 1

        Update IMWM
        Set Error = ERROR_NUMBER(), Message = ERROR_MESSAGE()
        where ImportId = @importid and ImportTemplate = @template and Form = @form and RecordSeq = @recseq
    
        if @@rowcount <> 1
          begin
          Insert IMWM ( ImportId, ImportTemplate, Form, RecordSeq, Error, Message)
          values (@importid, @template, @form, @recseq, ERROR_NUMBER(), ERROR_MESSAGE())
    	  end
	  end catch

*/

GO
GRANT EXECUTE ON  [dbo].[vspHQUDEdit] TO [public]
GO
