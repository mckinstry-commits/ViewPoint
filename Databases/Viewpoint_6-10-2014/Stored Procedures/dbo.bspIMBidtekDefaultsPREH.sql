SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspIMBidtekDefaultsPREH    Script Date: 7/10/2002 9:04:28 AM ******/
   
   /****** Object:  Stored Procedure dbo.bspIMBidtekDefaultsPREH    Script Date: 6/27/2002 8:31:30 AM ******/
   
   CREATE    procedure [dbo].[bspIMBidtekDefaultsPREH]
   /************************************************************************
   * CREATED:    
   * MODIFIED:    
   *
   * Purpose of Stored Procedure
   *
   *    
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
   (@Company bCompany, @ImportId varchar(20), @ImportTemplate varchar(20), @Form varchar(20), @rectype varchar(30), @msg varchar(120) output)
   
   as
   set nocount on
   
   declare @rcode int, @desc varchar(120)
   declare @recseq int, @ident int, @tablename varchar(20), @column varchar(30), @uploadval varchar(60),
   @complete int, @PRCo bCompany,  @uploaddate smalldatetime, @sortname varchar(15), @valid int, @count int,
   @Identifier int
          
   
   select @rcode = 0
   
   /*
   if @ImportId is null
   begin
   	select @desc = 'Missing ImportId.', @rcode = 1
   	goto bspexit
   end
   
   if @ImportTemplate is null
   begin
   	select @desc = 'Missing ImportTemplate.', @rcode = 1
   	goto bspexit
   end
   
   if @Form is null
   begin
   	select @desc = 'Missing Form.', @rcode = 1
   	goto bspexit
   end
   
   select IMTD.DefaultValue
   From IMTD
   Where IMTD.ImportTemplate=@ImportTemplate AND IMTD.DefaultValue = '[Bidtek]'
   and IMTD.RecordType = @rectype
   
   if @@rowcount = 0
   begin
   	select @desc='No Bidtek Defaults set up for ImportTemplate ' + @ImportTemplate +'.'
   	goto bspexit
   end
   
   declare WorkEditCursor cursor for
   	select IMWE.RecordSeq, IMWE.Identifier, DDUD.TableName, DDUD.ColumnName, IMWE.UploadVal
   	from IMWE
   	inner join DDUD on IMWE.Identifier = DDUD.Identifier and DDUD.Form = IMWE.Form
   	where IMWE.ImportId = @ImportId and IMWE.ImportTemplate = @ImportTemplate and IMWE.Form = @Form
   	Order by IMWE.RecordSeq, IMWE.Identifier
   
   open WorkEditCursor
   
   fetch next from WorkEditCursor into @recseq, @ident, @tablename, @column, @uploadval
   
   --select @currrecseq = @Recseq, @complete = 0, @counter = 1
   select @complete = 0
   while @complete = 0
   begin
   
   	if @@fetch_status <> 0
       	select @complete = 1
   
   --if rec sequence = current rec sequence flag
   --	if @Recseq = @currrecseq
   --	begin
   
   	    If @column='PRCo' and  isnumeric(@uploadval) =1 
   		begin
   			select @PRCo = Convert( int, @uploadval)
   
   			update IMWE
   			set IMWE.UploadVal = @PRCo
   			where IMWE.ImportTemplate=@ImportTemplate and IMWE.ImportId=@ImportId and 
   			IMWE.RecordSeq=@recseq and IMWE.Identifier = @Identifier
   		end
   
   		If @column='UploadDate' and isdate(@uploadval) =1 select @uploaddate = Convert( smalldatetime, @uploadval)
   
   		--need to validate this
   		If @column='SortName' and @uploadval is not null select @sortname = upper(left(@uploadval, 15))
   		begin
   			select @valid = 0
   			while @valid = 0
   			begin
   				select @count = count(SortName) from PREH where SortName = @sortname
   				if @count <> 0 
   					begin
   						select @count = @count + 1
   						select @sortname = upper(left(@uploadval, 15) + @count)
   					end
   				else
   					select @valid = 1
   			end							
   		end
   
   		fetch next from WorkEditCursor into @recseq, @ident, @tablename, @column, @uploadval	
   end
   */
   
   
   
   bspexit:
   
       --poss error and clean up code goes here
   	select @msg = isnull(@desc,'Employee') + char(13) + char(10) + '[bspBidtekDefaultPREH]'
       return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMBidtekDefaultsPREH] TO [public]
GO
