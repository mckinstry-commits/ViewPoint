SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE View [dbo].[PRCAEmployerItemLookup]
as

select Distinct PRCAEmployerItems.PRCo, PRCAEmployerItems.TaxYear, 
PRCAEmployerItems.T4BoxNumber, PRCAItems.T4BoxDescription
from PRCAEmployerItems 
Join PRCAItems on PRCAEmployerItems.PRCo = PRCAItems.PRCo and 
PRCAEmployerItems.TaxYear = PRCAItems.TaxYear and PRCAEmployerItems.T4BoxNumber = PRCAItems.T4BoxNumber 



GO
GRANT SELECT ON  [dbo].[PRCAEmployerItemLookup] TO [public]
GRANT INSERT ON  [dbo].[PRCAEmployerItemLookup] TO [public]
GRANT DELETE ON  [dbo].[PRCAEmployerItemLookup] TO [public]
GRANT UPDATE ON  [dbo].[PRCAEmployerItemLookup] TO [public]
GO
