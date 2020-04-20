SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspIMFormatingOptions]
    /************************************************************************
    * CREATED:   MH 7/26/00
    * MODIFIED:  DANF 09/14/00
    *            bc 04/18/01 - included @decipos as an input parameter for the call to
    *                          bspIMFormatFixedToDeci
    *            DANF 05/17/01 - Temp fix for YYMM and YYMMDD date formats.
    *			MH  6/14/01 - Help file states the STRIPX0 formats can be used
    *			 				to strip any character by just replacing the 0 with the character
    *			 				to strip.  Added code to do that.  Issue 13755
    *            DANF 09/4/01 - Add MM/01/YYYY FORMAT.
    *			MH 1/9/02 - Corrected MM/DD/YY format.  Issue 15734
    *			RBT 05/15/03 - Add MM/DD/YY 00:00 and MM/DD/YYYY 00:00 formats, issue 18727.
    *			RBT 06/09/03 - Issue #21014, Check slashed date formats for existence of slashes.
    *						Also changed @msg size from 80 to 100.
    * 		    RBT 06/24/03 - Issue #21606, Modified LEN formatting option to accept any values.
    *			RBT 07/07/03 - Issue #21698, Fixed date format so it doesn't look for a 3rd slash.
    *			RBT 09/04/03 - Issue #21014r2, added date error checking and fixed LEN call that was
    *						subtracting an integer from a string.
    *			RBT 11/06/03 - Issue #22939, add formats: YYYYMMDD, YYYYMM01
    *			RBT 02/01/06 - Issue #120122, add formats: MM/01/YY[YY] 00:00, MM/01/YY[YY]
	*			CC 03/19/2008 - Issue #122980, add support for notes
	*			CC 09/25/2008 - Issue #129958, add support for international date formats
    *
    * Purpose of Stored Procedure:
    *
    *    	Given a formatting scheme, determine which stored procedure
    *    	to execute.
    *
    * Notes about Stored Procedure:
    *
    * 		returns 0 if successful
    * 		returns 1 and error msg if failed
    *
    * Supported Formats:
    *		#.
    *		STRIPCOMMA
    *		STRIPL?
    *		STRIPT?
    *		STRIPB?
    *		STRIPA?
    *		M[M]/D[D]/YY[YY]
    *		MMDDYY[YY]
    *		YYMM[DD]
    *		YYMM01
    *		MM/01/YY[YY]
    *		LEN[2, 12]
    *		MM/DD/YY[YY] 00:00	- Issue #18727.
    *
    *************************************************************************/
    
        (@format varchar(100), @invalue varchar(max), @outvalue varchar(max) output, @msg varchar(100) = '' output)
    
    as
    set nocount on
    
       declare @rcode int, @side varchar(1), @testval varchar(max), @decipos int, @stripchar varchar(10),
               @fdt varchar(20), @fpt int, @spt int, @dl int
    
    	declare @slashpos int, @slashcount int
   	declare @leftside varchar(max), @rightside varchar(max), @middle varchar(max), @remain varchar(max)
   	declare @mth varchar(10)
   
       select @rcode = 0
       select @msg = null

        if @format is null
            begin
                select @msg = 'Missing Format!.', @rcode = 1
                goto bspexit
            end
    
        if @invalue is null or @invalue = ''
            begin
                --select @msg = 'Missing Value to format!.', @rcode = 1
   			--no error...just asssume nothing to format.
                goto bspexit
            end
    
    
        if left(@format, 2) = '#.'
            begin
                select @decipos = (charindex('.', reverse(@format), 1) - 1)
                exec @rcode = bspIMFormatFixedToDeci @invalue, @decipos, @outvalue output, @msg output
                if @rcode <> 0
                    begin
                        select @rcode = 1
                        goto errmsg
                    end
                else
                    goto bspexit
            end
    
        if @format = 'STRIPCOMMA'
            begin
                exec @rcode = bspIMFormatStripComma @invalue, @outvalue output, @msg output
                if @rcode <> 0
                    begin
                        select @rcode = 1
                        goto errmsg
                    end
                else
                    goto bspexit
         end
    
    
        if @format = 'STRIPL0'
            begin
                select @side = 'L'
                exec @rcode = bspIMFormatStripZeros @side, @invalue, @outvalue output, @msg output
                if @rcode <> 0
                    begin
                        select @rcode = 1
                        goto errmsg
                    end
                else
                    goto bspexit
            end
    
        if @format = 'STRIPT0'
            begin
                select @side = 'R'
                exec @rcode = bspIMFormatStripZeros @side, @invalue, @outvalue output, @msg output
                if @rcode <> 0
                    begin
                        select @rcode = 1
                        goto errmsg
                    end
                else
                    goto bspexit
            end
    
        if @format = 'STRIPB0'
            begin
                select @side = 'R'
                exec @rcode = bspIMFormatStripZeros @side, @invalue, @outvalue output, @msg output
                if @rcode <> 0
                    begin
                        select @rcode = 1
                        goto errmsg
                    end
    
                select @invalue = @outvalue
    
                select @side = 'L'
                exec @rcode = bspIMFormatStripZeros @side, @invalue, @outvalue output, @msg output
                if @rcode <> 0
                    begin
                        select @rcode = 1
               goto errmsg
                    end
                else
                    goto bspexit
            end
    
        if left(@format,6) = 'STRIPA'
            begin
                select @stripchar = substring (@format,7,1)
                select @side = 'A'
                exec @rcode = bspIMFormatStripChar @invalue, @stripchar, @outvalue output, @msg output
                if @rcode <> 0
                    begin
                        select @rcode = 1
                        goto errmsg
                    end
                else
                    goto bspexit
            end
    
    --begin MH  6/14/01
    	--for strip only.
    	if len(@format) = 5
    		begin
    		    if @format = 'STRIP'
            		begin
    			      select @outvalue = (select rtrim(@invalue))
                	  select @outvalue = (select ltrim(@outvalue))
    	              goto bspexit
            		end
    		end
    
    	--strip a leading or trailing character....or both
    	if len(@format) = 7
    		begin
    			--stripti
    			if left(@format, 5) = 'STRIP'
    				begin
    					select @stripchar = right(@format, 1)
    					select @side = substring(@format, 6, 1)
    					exec @rcode = bspIMFormatStripTLChar @invalue, @stripchar, @side, @outvalue output, @msg output
    					if @rcode <> 0
    						begin
    							select @rcode = 1
    							goto errmsg
    						end
    					else
    						goto bspexit
    				end
    		end
    
    --end MH  6/14/01
   
   --RT 6/25/03
        if upper(left(@format,3)) = 'LEN'
        begin
   		declare @lenstart int, @lenlength int, @commapos int, @subformat varchar(100)
   		select @subformat = substring(@format, 4, len(@format) - 3)
   		select @commapos = charindex(',', @subformat)
   		if @commapos = 0
   		begin
   			select @rcode = 1, @msg = 'LEN format must have the form: LEN [start],[length]'
   			goto bspexit
   		end
   		select @lenstart = substring(@subformat, 1, @commapos - 1)
   		select @lenlength = substring(@subformat, @commapos + 1, len(@subformat) - @commapos)
   		if @lenlength <= 0	--if length is zero or less, return the remainder of the input.
   		begin
   			select @lenlength = len(@invalue) - @lenstart + 1	
   		end
   		select @outvalue = substring(@invalue, @lenstart, @lenlength)
           goto bspexit
        end
   --end RT 6/25/03
   
   
   	if @format = 'MM/DD/YYYY' or @format = 'MM/DD/YY' or @format = 'M/D/YY' or 
   		@format = 'M/D/YYYY' or @format = 'M/DD/YY' or @format = 'M/DD/YYYY' or
   		@format = 'MM/D/YY' or @format = 'MM/D/YYYY'
   		begin
   			select @testval = @invalue
   
   			select @slashpos = 0, @slashcount = 0
   
   			select @slashpos = charindex('/', @testval)
   			if @slashpos = 0
   			begin 
   				select @rcode = 1
   				select @msg = 'Slash character not found in date field in source data. Check template date format.'
   				goto bspexit
   			end
   			select @leftside = substring(@testval, 1, @slashpos - 1)
   			select @remain = substring(@testval, @slashpos + 1, len(@testval) - @slashpos)
   
   			select @slashpos = charindex('/', @remain)
   			if @slashpos = 0
   			begin 
   				select @rcode = 1
   				select @msg = 'Slash character not found in date field in source data. Check template date format.'
   				goto bspexit
   			end
   			select @middle = substring(@remain, 1, @slashpos - 1)
   			select @remain = substring(@remain, @slashpos + 1, len(@remain) - @slashpos)
   
   			select @rightside = @remain
   			--select @formated_mth = @leftside + '/01/' + @rightside
   			select @outvalue = @leftside + '/' + @middle + '/' + @rightside
  			if isdate(@outvalue) <> 1
  			begin
  				select @rcode = 1
  				select @msg = 'Unable to format date: ' + @invalue + '.  Check Work Edit.'
  			end
  
   			goto bspexit
   
   		end
   --mark 2/6/02
   
   	if @format = 'MMDDYY'
   	begin
   		select @testval = @invalue
   
   		if len(@testval) = 6
   		begin
   			select @leftside = substring(@testval, 1, 2)
   			select @middle = substring(@testval, 3, 2)
   			select @rightside = substring(@testval, 5, 2)
   		
   			select @outvalue = @leftside + '/' + @middle + '/' + @rightside 
  			if isdate(@outvalue) <> 1
  			begin
  				select @rcode = 1
  				select @msg = 'Unable to format date: ' + @invalue + '.  Check Work Edit.'
  			end
  
   			goto bspexit
   		end
   		else
   		begin
   			select @msg = 'Selected date format MMDDYY requires 6-character import value.'
   			select @rcode = 1
   			goto bspexit
   		end
   	end
   
   	 if @format = 'MMDDYYYY'
   	 begin
   		select @testval = @invalue
   		select @leftside = substring(@testval, 1, 2)
   		select @middle = substring(@testval, 3, 2)
   		select @rightside = right(@testval, 4)
   		select @outvalue = @leftside + '/' + @middle + '/' + @rightside
  		if isdate(@outvalue) <> 1
  		begin
  			select @rcode = 1
  			select @msg = 'Unable to format date: ' + @invalue + '.  Check Work Edit.'
  		end
  
   		goto bspexit
   	  end

	--issue #120082
	if @format = 'MM01YY'
	begin
		select @leftside = substring(@invalue,1,2)
		select @rightside = right(@invalue,2)
		select @outvalue = @leftside + '/01/' + @rightside
		if isdate(@outvalue) <> 1
		begin
			select @rcode = 1
			select @msg = 'Unable to format date: ' + @invalue + '.  Check Work Edit.'
		end
		goto bspexit
	end

	--issue #120082
	if @format = 'MM01YYYY'
	begin
		select @leftside = substring(@invalue,1,2)
		select @rightside = right(@invalue,4)
		select @outvalue = @leftside + '/01/' + @rightside
		if isdate(@outvalue) <> 1
		begin
			select @rcode = 1
			select @msg = 'Unable to format date: ' + @invalue + '.  Check Work Edit.'
		end
		goto bspexit
	end
   
        if @format = 'YYMM'
            begin
    			select @outvalue = substring(@invalue, 3, 2) + '/' + substring(@invalue, 1, 2)
  			if isdate(@outvalue) <> 1
  			begin
  				select @rcode = 1
  				select @msg = 'Unable to format date: ' + @invalue + '.  Check Work Edit.'
  			end
              goto bspexit
            end
    
        if @format = 'YYMMDD'
        begin
   		--issue 11762 - need to check if value is already in proper format.
   		if @outvalue = @invalue
   			goto bspexit
   		else
   		begin
   		--end issue 11762
              select @outvalue = substring(@invalue, 3, 2) + '/' + right(@invalue, 2) + '/' + left(@invalue, 2)
  			if isdate(@outvalue) <> 1
  			begin
  				select @rcode = 1
  				select @msg = 'Unable to format date: ' + @invalue + '.  Check Work Edit.'
  			end
  
           	goto bspexit
   		end
        end
    
        if @format = 'YYMM01'
            begin
    			--issue 11762 - need to check if value is already in proper format.
    
    			if @outvalue = @invalue
    				goto bspexit
    			else
  			begin
  			--end issue 11762
  	           	select @outvalue = substring(@invalue, 3, 2) + '/01/' + left(@invalue, 2)
  				if isdate(@outvalue) <> 1
  				begin
  					select @rcode = 1
  					select @msg = 'Unable to format date: ' + @invalue + '.  Check Work Edit.'
  				end
          	  	goto bspexit
  			end
            end
    
 		--issue 22939
 		if @format = 'YYYYMMDD'
 		begin
 			select @outvalue = substring(@invalue,5,2)+'/'+substring(@invalue,7,2)+'/'+substring(@invalue,1,4)
 			if isdate(@outvalue) <> 1
 			begin
 				select @rcode = 1
 				select @msg = 'Unable to format date: ' + @invalue + '.  Check Work Edit.'
 			end
 			goto bspexit
 		end
 
 		if @format = 'YYYYMM01'
 		begin
 			select @outvalue = substring(@invalue,5,2)+'/01/'+substring(@invalue,1,4)
 			if isdate(@outvalue) <> 1
 			begin
 				select @rcode = 1
 				select @msg = 'Unable to format date: ' + @invalue + '.  Check Work Edit.'
 			end
 			goto bspexit			
 		end
 		--end issue 22939
 
        if @format = 'MM/01/YY'
            begin
    
                select @fpt = PATINDEX('%''''%',@invalue)
                if @fpt <>0
                 begin
                  select @side = 'A', @stripchar = char(34)
                  exec @rcode = bspIMFormatStripChar @invalue, @stripchar, @outvalue output, @msg output
                  if @rcode = 0 select @invalue = @outvalue
                 end
    
                   --reformat Month with two //
                    select @dl = DATALENGTH(@invalue)
                    select @fpt = PATINDEX('%/%',@invalue)
                    select @spt = PATINDEX('%/%',substring(@invalue,@fpt+1,@dl-@fpt))
                    --print @dl
                    --print @fpt
                    --print @spt
                    if @fpt <> 0 and @spt <> 0
    	                begin
        		            select @outvalue = substring(@invalue,1,@fpt-1) + '/01/' + substring(@invalue,(@spt+@fpt+1),(@dl-@spt+@fpt+1))
                		end
                            --dates such as mmddyy not being formated.  added the else code.  mh 04/12/01
    				else
    					select @outvalue = substring(@invalue, 1, 2) + '/01/' + substring(@invalue, 5, 4)
  				if isdate(@outvalue) <> 1
  				begin
  					select @rcode = 1
  					select @msg = 'Unable to format date: ' + @invalue + '.  Check Work Edit.'
  				end
    
                goto bspexit
            end
    
        if @format = 'MM/01/YYYY'
            begin
    
                select @fpt = PATINDEX('%''''%',@invalue)
                if @fpt <>0
                 begin
                  select @side = 'A', @stripchar = char(34)
                  exec @rcode = bspIMFormatStripChar @invalue, @stripchar, @outvalue output, @msg output
                  if @rcode = 0 select @invalue = @outvalue
                 end
    
                   --reformat Month with two //
                    select @dl = DATALENGTH(@invalue)
                    select @fpt = PATINDEX('%/%',@invalue)
                    select @spt = PATINDEX('%/%',substring(@invalue,@fpt+1,@dl-@fpt))
                    --print @dl
                    --print @fpt
                    --print @spt
                    if @fpt <> 0 and @spt <> 0
    	                begin
        		            select @outvalue = substring(@invalue,1,@fpt-1) + '/01/' + substring(@invalue,(@spt+@fpt+3),(@dl-@spt+@fpt+3))
                		end
                            --dates such as mmddyy not being formated.  added the else code.  mh 04/12/01
    				else
    					select @outvalue = substring(@invalue, 1, 2) + '/01/' + substring(@invalue, 5, 4)
  				if isdate(@outvalue) <> 1
  				begin
  					select @rcode = 1
  					select @msg = 'Unable to format date: ' + @invalue + '.  Check Work Edit.'
  				end
  
                goto bspexit
            end
    
   	 --issue 18727, strip off time
   	 if @format = 'MM/DD/YY 00:00'
   	 begin
   		select @testval = substring(@invalue, 1, 8)
   
   		select @slashpos = 0, @slashcount = 0
   
   		select @slashpos = charindex('/', @testval)
   		select @leftside = substring(@testval, 1, @slashpos - 1)
   		select @remain = substring(@testval, @slashpos + 1, len(@testval) - @slashpos)
   
   		select @slashpos = charindex('/', @remain)
   		select @middle = substring(@remain, 1, @slashpos - 1)
   		select @remain = substring(@remain, @slashpos + 1, len(@remain) - @slashpos)
   
   		select @rightside = substring(@remain, 1, 2)
   		select @outvalue = @leftside + '/' + @middle + '/' + @rightside
   		goto bspexit
   	 end
   
   	 if @format = 'MM/DD/YYYY 00:00'
   	 begin
   		select @testval = substring(@invalue, 1, 10)
   
   		select @slashpos = 0, @slashcount = 0
   
   		select @slashpos = charindex('/', @testval)
   		select @leftside = substring(@testval, 1, @slashpos - 1)
   		select @remain = substring(@testval, @slashpos + 1, len(@testval) - @slashpos)
   
   		select @slashpos = charindex('/', @remain)
   		select @middle = substring(@remain, 1, @slashpos - 1)
   		select @remain = substring(@remain, @slashpos + 1, len(@remain) - @slashpos)
   
   		select @rightside = substring(@remain, 1, 4)
   		select @outvalue = @leftside + '/' + @middle + '/' + @rightside
   		goto bspexit
   	 end
   	 --end issue 18727
    
	--issue #120082
   	 if @format = 'MM/01/YY 00:00'
   	 begin
   		select @testval = substring(@invalue, 1, 8)
   
   		select @slashpos = 0, @slashcount = 0
   
   		select @slashpos = charindex('/', @testval)
   		select @leftside = substring(@testval, 1, @slashpos - 1)
   		select @remain = substring(@testval, @slashpos + 1, len(@testval) - @slashpos)
   
   		select @slashpos = charindex('/', @remain)
   		select @middle = '01'
   		select @remain = substring(@remain, @slashpos + 1, len(@remain) - @slashpos)
   
   		select @rightside = substring(@remain, 1, 2)
   		select @outvalue = @leftside + '/' + @middle + '/' + @rightside
   		goto bspexit
   	 end

	--issue #120082
   	 if @format = 'MM/01/YYYY 00:00'
   	 begin
   		select @testval = substring(@invalue, 1, 10)
   
   		select @slashpos = 0, @slashcount = 0
   
   		select @slashpos = charindex('/', @testval)
   		select @leftside = substring(@testval, 1, @slashpos - 1)
   		select @remain = substring(@testval, @slashpos + 1, len(@testval) - @slashpos)
   
   		select @slashpos = charindex('/', @remain)
   		select @middle = '01'
   		select @remain = substring(@remain, @slashpos + 1, len(@remain) - @slashpos)
   
   		select @rightside = substring(@remain, 1, 4)
   		select @outvalue = @leftside + '/' + @middle + '/' + @rightside
   		goto bspexit
   	 end

	--Issue 129958 interantional dates
	IF CHARINDEX('M',UPPER(@format)) <> 0 AND CHARINDEX('Y',UPPER(@format)) <> 0
		BEGIN
			DECLARE @ConvertToPeriodFormat bYN
			IF CHARINDEX('1', @format) <> 0
				SET @ConvertToPeriodFormat = 'Y'
			ELSE 
				SET @ConvertToPeriodFormat = 'N'

			DECLARE @DateSeperator VARCHAR(1)
			SELECT @DateSeperator = 
			REPLACE(
					REPLACE(
							REPLACE(
									REPLACE(
											REPLACE(
													REPLACE(UPPER(@format)
														,'M','')
												,'Y','')
										,'D','')
								,'0','')
						,':','')
				,'1','')

			EXEC vspIMFormatDate @DateValue = @invalue, 
					  			@SourceFormat = @format, 
								@DateSeperator = @DateSeperator, 
								@DestinationFormat = 'MDY',
								@ConvertToMonthFormat = @ConvertToPeriodFormat, 
								@ReturnDate = @outvalue OUTPUT
		GOTO bspexit
		END


        --If @format did not fall into one of the above if statements
        --then it is undefined.  Exit with error.
    
        select @rcode = 1
        select @msg = 'Undefined format: ' + @format + '.  Unable to format value.'
        goto bspexit
    
    
    errmsg:
    
        if @rcode = 1 and @msg is null
            begin
                select @msg = 'Unable to format value!'
                goto bspexit
            end
    
    bspexit:
    
         return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspIMFormatingOptions] TO [public]
GO
