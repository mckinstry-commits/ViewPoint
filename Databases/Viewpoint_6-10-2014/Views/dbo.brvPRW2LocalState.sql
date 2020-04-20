SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    View [dbo].[brvPRW2LocalState]
     
     as
     
     Select PRCo=isnull(PRWS.PRCo,PRWL.PRCo), TaxYear=isnull(PRWS.TaxYear,PRWL.TaxYear), 
            Employee=isnull(PRWS.Employee,PRWL.Employee),
            State=isnull(PRWS.State,PRWL.State) ,StateTaxID=PRWS.TaxID, LocalTaxID=PRWL.TaxID,
            StateWages=PRWS.Wages,
            StateTax=PRWS.Tax,
            PRWS.Misc1Amt, PRWS.Misc2Amt,PRWS.Misc3Amt, PRWS.Misc4Amt,
            PRWL.LocalCode,
            LocalWages=PRWL.Wages,
            LocalTax=PRWL.Tax
     From PRWS
     Full Outer Join PRWL on 
        PRWL.PRCo=PRWS.PRCo and PRWL.TaxYear=PRWS.TaxYear and 
        PRWL.Employee=PRWS.Employee and PRWL.State=PRWS.State

GO
GRANT SELECT ON  [dbo].[brvPRW2LocalState] TO [public]
GRANT INSERT ON  [dbo].[brvPRW2LocalState] TO [public]
GRANT DELETE ON  [dbo].[brvPRW2LocalState] TO [public]
GRANT UPDATE ON  [dbo].[brvPRW2LocalState] TO [public]
GRANT SELECT ON  [dbo].[brvPRW2LocalState] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvPRW2LocalState] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvPRW2LocalState] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvPRW2LocalState] TO [Viewpoint]
GO
