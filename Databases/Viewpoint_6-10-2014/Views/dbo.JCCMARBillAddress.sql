SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
* Created By:	GF 10/10/2008 - view to replace user-defined function
* Modfied By:
*
* Provides a view of ARCM returning billing address for use
* in JCCM and PM Contract Master
*
*****************************************/
   
CREATE view [dbo].[JCCMARBillAddress] as 
		select CustGroup, Customer, 'ARBillAddress' = 
			case when isnull(BillAddress,'') <> '' or isnull(BillCity,'') <> ''
					  or isnull(BillState,'') <> '' or isnull(BillZip,'') <> ''
					  or isnull(BillCountry,'') <> '' or isnull(BillAddress2,'') <> ''
				 then isnull(BillAddress,'') + ',  ' + isnull(BillCity,'') + ',  ' + isnull(BillState,'')
					+ '  ' + isnull(BillZip,'') + '  ' + isnull(BillCountry,'') + char(13) + char(10) + isnull(BillAddress2,'')
				 else '' end
from dbo.ARCM with (nolock)

GO
GRANT SELECT ON  [dbo].[JCCMARBillAddress] TO [public]
GRANT INSERT ON  [dbo].[JCCMARBillAddress] TO [public]
GRANT DELETE ON  [dbo].[JCCMARBillAddress] TO [public]
GRANT UPDATE ON  [dbo].[JCCMARBillAddress] TO [public]
GRANT SELECT ON  [dbo].[JCCMARBillAddress] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCCMARBillAddress] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCCMARBillAddress] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCCMARBillAddress] TO [Viewpoint]
GO
