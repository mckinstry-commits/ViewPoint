SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLPriorInitialize    Script Date: 8/28/99 9:34:44 AM ******/
   CREATE  procedure [dbo].[bspGLPriorInitialize]
   /*******************************************************************
    * Used by GL Prior Yearsto initialize GLYB and GLBL
    * 
    * Created By SAE 1/24/97
    * Last modified By SAE 1/24/97
    *					MV 01/31/03 - #20246 dbl quote cleanup.
    *
    * pass in 
    *   @GLCo   = Company to initialize Balances in
    *   @FYEMO  = FYEMO to initialize 
    *   @Msg    = Error message if error, otherwise # of Accounts initialized
    *
    * Skips inactive accounts, and does not initialize text or user memo
    *  
    * returns 0 and message reporting number of Accounts found, and
    * number of Accounts successfully copied.
    * Returns 1 and error message if unable to process.
    ********************************************************************/
   
   @GLCo  bCompany,
   @FYEMO bMonth, 
   @Msg varchar(100) output
   
   as
   set nocount on
   declare @rows int, @rcode tinyint
   
    /*Create a temporary table witht the months we need to insert.      
     * This will allow us to do SQL Statements to add and delete months */
   
   
   select @rcode = 0
   
   
   declare @BMth bMonth, @EMth bMonth
   
   create table #Mths(Co tinyint NOT NULL, Mth smalldatetime NOT NULL)
   
    Select @BMth=Y.BeginMth, @EMth=Y.FYEMO from bGLFY Y where Y.GLCo=@GLCo and Y.FYEMO=@FYEMO
   
     While @BMth<=@EMth 
      Begin
        insert into #Mths(Co, Mth) values(@GLCo, @BMth) 
        Select @BMth=dateadd(mm,1,@BMth)
      End
   
   
    /* Initialize GLYB entries that dont exist  */
   
   Begin Tran
     insert into bGLYB(GLCo, FYEMO, GLAcct, BeginBal, NetAdj) 
        select @GLCo, @FYEMO, c.GLAcct, 0, 0 
          from bGLAC c 
          where c.GLCo=@GLCo and c.AcctType <> 'H' and c.AcctType <> 'M' and c.Active <> 'N' and
                not exists(select * from bGLYB b where b.GLCo=c.GLCo and 
   		        b.GLAcct=c.GLAcct and b.FYEMO=@FYEMO)
   
   
   select @rows=@@rowcount
   
    /* Now Initialize GLBL entries that dont exist  */
   
     insert into bGLBL(GLCo, GLAcct, Mth, NetActivity, Debits, Credits) 
        select @GLCo, c.GLAcct, Mth, 0, 0, 0
          from bGLAC c 
          JOIN #Mths m on c.GLCo=m.Co	
          where c.GLCo=@GLCo and c.AcctType <> 'H' and c.AcctType <> 'M' and c.Active <> 'N' and
                not exists(select * from bGLBL l where l.GLCo=c.GLCo and 
   		        l.GLAcct=c.GLAcct and l.Mth=m.Mth)
   
   Commit Tran
      drop table #Mths
   
   
   bspExit:
   
   	select @rcode=0, @Msg=convert(varchar(10), @rows) + ' Successfully added to GLYB.'
      return @rcode
   
   bspError:
   	select @Msg = 'Error on initialize.'
      return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLPriorInitialize] TO [public]
GO
