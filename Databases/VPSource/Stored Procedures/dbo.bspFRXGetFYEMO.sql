SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspFRXGetAcctMask    Script Date: 8/28/99 9:34:37 AM ******/
   CREATE   proc [dbo].[bspFRXGetFYEMO](@glco bCompany, @fiscalyr smallint)
   as
   /* this procedure will return FYEMO on the from a Period and A Year
    * Using a procedure to grab the value instead of constantly joining these 
    * tables over and over again
    * JRE 04/14/04
    */
   select 
   --Last month in fiscal year
   FYEMO =isnull(convert(varchar(10),FYEMO,101),'12/1/2050'),
   --First month in fiscal year
   BeginMonth =isnull(convert(varchar(10),BeginMth,101),'12/1/2050')
   from GLFP 
   left join GLFY on GLFY.GLCo=GLFP.GLCo  and GLFP.Mth>=GLFY.BeginMth and GLFP.Mth<=GLFY.FYEMO 
   where GLFP.GLCo=@glco  and GLFP.FiscalPd=1 and GLFP.FiscalYr=@fiscalyr

GO
GRANT EXECUTE ON  [dbo].[bspFRXGetFYEMO] TO [public]
GO
