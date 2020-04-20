SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspHQAPEFTPrenoteExport]
  /************************************
  * Created: 10/27/99 GF
  * Modified: 5/10/02 EN issue 17306 include Batch Header and Assign Bank fields in return values
  *			 10/3/2002 GF - Issue #18530 added input param for CMAcct used for CM account info.
  *			  07/09/2007 MV - #124967 use CM Company's HQCO.Name not AP Company's HQCO.Name  
  *
  * This SP is used in HQExport form frmAPEFTPreNoteExport.
  * Any changes here will require changes to the form.
  *
  ***********************************/
  (@hqco bCompany, @cmacct bCMAcct)
 
 as
 set nocount on
 
 select a.HQCo, /*a*/e.Name, b.Vendor, b.Name, b.EFT, b.RoutingId, b.BankAcct, b.AcctType,
        c.CMCo, d.CMAcct, d.BankAcct, d.ImmedDest, d.ImmedOrig, d.CompanyId, d.RoutingId,
        d.ServiceClass, d.AcctType, d.BankName, d.DFI,
 	   case isnull(d.AssignBank,'') WHEN '' THEN a.Name ELSE d.AssignBank END ,d.BatchHeader
 
 from bHQCO a INNER JOIN bAPCO c ON a.HQCo = c.APCo
 INNER JOIN bAPVM b ON a.VendorGroup = b.VendorGroup
 LEFT OUTER JOIN bCMAC d ON c.CMCo = d.CMCo and d.CMAcct=@cmacct
 LEFT OUTER JOIN bHQCO e on c.CMCo = e.HQCo
 WHERE a.HQCo = @hqco and b.EFT = 'P' and d.CMAcct = @cmacct
 ORDER BY a.HQCo, c.CMCo, d.CMAcct, b.Vendor

GO
GRANT EXECUTE ON  [dbo].[bspHQAPEFTPrenoteExport] TO [public]
GO
