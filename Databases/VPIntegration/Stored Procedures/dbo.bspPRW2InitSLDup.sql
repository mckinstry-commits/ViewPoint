SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRW2InitSLDup    Script Date: 7/22/2003 9:39:01 AM ******/
   CREATE      procedure [dbo].[bspPRW2InitSLDup]
   /************************************************************
    * CREATED:     DC 05/02/03  Issue #19615
    * MODIFIED:    DC  7/22/03  #21254  
	*				EN 3/7/08 - #127081  in declare statements change State declarations to varchar(4)
    *
    * USAGE:
    * Check the PRWT table and check for duplicate DednCodes.
    *
    * INPUT PARAMETERS
    *   @PRCo      PRCo
    *   @TaxYear   TaxYear
    *
    * OUTPUT PARAMETERS
    *   @errmsg     if something went wrong
    * RETURN VALUE
    *   0   success
    *   1   fail
    ************************************************************/
   	@PRCo bCompany, @TaxYear char(4), @errmsg varchar(255) output
   
   as
   set nocount on
   
   declare @rcode int, 
   	@dedncd bEDLCode, 
   	@state varchar(4),
   	@localcd bLocalCode,
   	@rcount int,
   	@lcode int
   
   Declare @t_local table(State char(2), LocalCode varchar(10), DednCode smallint)
   
   select @rcode = 0, @rcount = 0, @lcode = 0
   
   /* verify Tax Year Ending Month */
   if @TaxYear is null
   	begin
   	select @errmsg = 'Tax Year has not been selected.', @rcode = 1
   	goto bspexit
   	end
   
   BEGIN
   
       Declare  @prco_c bCompany,
   	@taxyear_c char(4),
   	@state_c varchar(4),
   	@localcd_c bLocalCode,
   	@dedncd_c bEDLCode
   
   --  Check for duplicate values using a cursor.
       declare bPRWT_id cursor local fast_forward for
   	select PRCo, TaxYear, State, LocalCode, DednCode
   	from bPRWT
   	Where PRCo = @PRCo and TaxYear = @TaxYear and Initialize = 'Y'
       OPEN bPRWT_id
       FETCH NEXT FROM bPRWT_id
       INTO @prco_c,@taxyear_c,@state_c,@localcd_c,@dedncd_c
   
       While @@FETCH_STATUS = 0
       Begin 	
   	insert into @t_local(State,LocalCode,DednCode)
   	select State, LocalCode, DednCode
   	from bPRWT 
   	where PRCo = @PRCo and TaxYear = @TaxYear and Initialize = 'Y'
   		and DednCode = @dedncd_c --and (State <> @state_c and LocalCode <> @localcd) 
   	if exists(select top 1 1 from @t_local)
   	BEGIN
   		Declare bPRWT_temp cursor local fast_forward for
   		Select State,LocalCode, DednCode
   		from @t_local
   		open bPRWT_temp
   		FETCH NEXT from bPRWT_temp
   		into @state,@localcd, @dedncd
   		select @errmsg = 'Deduction code ' + convert(varchar(3),@dedncd) + ' is assigned to ' + @state_c
   		
   		While @@FETCH_STATUS = 0
   		BEGIN
   			IF not (@state = @state_c and @localcd = @localcd_c and @dedncd = @dedncd_c)
   				BEGIN
   				IF @rcount <> 0 
   					BEGIN
   					if @lcode <> 1
   					  BEGIN	
   					  Select @errmsg = @errmsg + '; '
   					  END
   					END
   				if @state = @state_c
   					BEGIN
   					IF @lcode <> 1 
   					  BEGIN
   					  select @errmsg = @errmsg + @localcd_c + ', '
   					  END
   					ELSE
   					  BEGIN
   					  select @errmsg = @errmsg + ', '
   					  END
   					select @errmsg = @errmsg + @localcd
   					select @rcode = 1, @lcode = 1
   					END
   				ELSE
   					BEGIN
   					select @errmsg = @errmsg + @state	
   					select @rcode = 1
   					END
   				END
   				select @rcount = @rcount +1
   			FETCH NEXT FROM bPRWT_temp
   			INTO @state,@localcd, @dedncd 
   		END
   		CLOSE bPRWT_temp
   		DEALLOCATE bPRWT_temp
   	END
   	if @rcode = 1 
   	BEGIN
   		CLOSE bPRWT_id
   		DEALLOCATE bPRWT_id
   		select @errmsg = @errmsg + '.  Deduction codes should only be assigned to a single state or local code.'
   		goto bspexit
   	END
   	delete from @t_local
   	FETCH NEXT FROM bPRWT_id
   	INTO @prco_c,@taxyear_c,@state_c,@localcd_c,@dedncd_c
       end
   
       CLOSE bPRWT_id
       DEALLOCATE bPRWT_id
   END
   
   if @rcode = 0 select @errmsg = null
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRW2InitSLDup] TO [public]
GO
