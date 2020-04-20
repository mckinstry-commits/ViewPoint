SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  PROC dbo.brptGLFinDet    Script Date: 3/3/97 2:24:47 PM ******/
     CREATE      PROC [dbo].[brptGLFinDet]
      (@GLCo bCompany, @BegAcct bGLAcct='          ', @EndAcct bGLAcct='zzzzzzzzzz',
      @BegMonth bMonth ='01/01/1950', @EndMonth bMonth = '12/01/2050', @IncludeInactive char(1)='N',
      @Source varchar(20)=' ', @Journal varchar(20)=' ', @DetailLevel char(1) = 'D')
   	/*created 8/26/97 */
   	/*changed report to use GLAC instead of GLAC for security*/
   	/*mod JRE 3/27/02 Timing out for large GLs.  Re-wrote the get beginning balance to be more effecient
   	  by eliminating an update by using a derived table in the insert, and reducing the size of #GLDetail*/
   	/*changed TRL 4/3/2002 Took out the IF BEGIN END statements used for selecting by detail level.  Added Union
    	   statements and RecType field */
    	/*mod JRE 4/23/03  issue 21042 change  GLCO .. NOT NULL to GLCO .. NULL */
   	/* Issue 23660 Remove the #GLDetail table for Beg Balance and add Union statement with RecType='B' 03/04/04 NF */
     	/* Issue 26210 Moved the select statement into a secondary procedure for performance reasons */
     	/* Issue 26959 Places additional inputs into the stored procedure for efficiency 03/17/04 NF */
 	/* Issue 29223 Add @IncludeInactive to Where clause 7/6/5 NF*/
   	
      as
      set nocount on
      declare @FYEMO bMonth, @FYBMO bMonth, @EndAcctFull bGLAcct,@ErrorMessage varchar(60)
      select @EndAcctFull=RTrim(@EndAcct)+'zzzzzzzzzz'
   
      
      /* if no begin month then get it from the end month */
      if @BegMonth is null
      begin
      select @BegMonth = GLFY.BeginMth
      from GLFY  
      where GLFY.GLCo=@GLCo and @EndMonth>=GLFY.BeginMth and @EndMonth<=GLFY.FYEMO
      if @@rowcount=0
      	begin
      	select @ErrorMessage= '**** Fiscal Year End not set up in GLFY ****'
     	end
      	goto selectresults
      end
      
      /* get Fiscal Year Begin Month */
      select @FYBMO = GLFY.BeginMth, @FYEMO=GLFY.FYEMO
      from GLFY 
      where GLFY.GLCo=@GLCo and @BegMonth>=GLFY.BeginMth and @BegMonth<=GLFY.FYEMO
      if @@rowcount=0
      	begin
      	select @ErrorMessage= '**** Fiscal Year End Beginning Month not set up****'
      	goto selectresults
      	end
      
      /* check if ending month is in same year as begin month */
      if @EndMonth <@BegMonth or @FYBMO is null
      	begin
      	select @ErrorMessage= '**** End month may not be less than the begin month ****'
     	goto selectresults
      	end
      if @EndMonth > @FYEMO or @FYEMO is null
      	begin
      	select @ErrorMessage= '**** End month is not in the same fiscal year as begin month ****'
      	goto selectresults
      	end
    
    
    --******************************************************************************************************
    --* select the results
    --******************************************************************************************************
    
    selectresults:
 	exec dbo.brptGLFinDetSelect @GLCo , @BegAcct , @EndAcct , @BegMonth, 
 		@EndMonth ,@IncludeInactive, @Source, @Journal, @DetailLevel,
 		@FYEMO, @FYBMO, @EndAcctFull, @ErrorMessage

GO
GRANT EXECUTE ON  [dbo].[brptGLFinDet] TO [public]
GO
