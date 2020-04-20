SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[brvARHighCredit] as
    /*declare @HC6M money
    select @HC6M=Max(ARMT.HighestCredit)  from ARMT
    where ARMT.Mth between DATEADD(month, -5, getdate()) and getdate()*/
    /*
    select  @HC12M=Max(ARMT.HighestCredit) from ARMT
    where ARMT.ARCo=1 and ARMT.CustGroup=1 and ARMT.Customer=800 and
    ARMT.Mth between DATEADD(month, -12,  getdate()) and getdate()
    */
    
    select distinct ARMT.ARCo,ARMT.CustGroup,ARMT.Customer,
    HCCurrent=(select Max(a.HighestCredit) from ARMT a
    where a.Mth =  getdate()
    and a.ARCo=ARMT.ARCo and a.CustGroup=ARMT.CustGroup and a.Customer=ARMT.Customer),
    
    HC3M=(select Max(a.HighestCredit) from ARMT a
    where a.Mth between DATEADD(month, -3, getdate()) and getdate()
    and a.ARCo=ARMT.ARCo and a.CustGroup=ARMT.CustGroup and a.Customer=ARMT.Customer),
    
    HC6M=(select Max(a.HighestCredit) from ARMT a
    where a.Mth between DATEADD(month, -6, getdate()) and getdate()
    and a.ARCo=ARMT.ARCo and a.CustGroup=ARMT.CustGroup and a.Customer=ARMT.Customer),
    
    HC12M=(select Max(a.HighestCredit) from ARMT a
    where a.Mth between DATEADD(month, -12, getdate()) and getdate()
    and a.ARCo=ARMT.ARCo and a.CustGroup=ARMT.CustGroup and a.Customer=ARMT.Customer),
    
    HCToDate=(select Max(a.HighestCredit) from ARMT a
    where a.Mth <=GETDATE()
    and a.ARCo=ARMT.ARCo and a.CustGroup=ARMT.CustGroup and a.Customer=ARMT.Customer)
    from ARMT

GO
GRANT SELECT ON  [dbo].[brvARHighCredit] TO [public]
GRANT INSERT ON  [dbo].[brvARHighCredit] TO [public]
GRANT DELETE ON  [dbo].[brvARHighCredit] TO [public]
GRANT UPDATE ON  [dbo].[brvARHighCredit] TO [public]
GRANT SELECT ON  [dbo].[brvARHighCredit] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvARHighCredit] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvARHighCredit] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvARHighCredit] TO [Viewpoint]
GO
