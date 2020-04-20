SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE         View [dbo].[brvCMAC]
   
   /* Used in VA Datatype Security Report By Group/User */
   
    as 
   
    Select CMCo,CMAcct=Convert(char(4),CMAcct),Description
    From CMAC

GO
GRANT SELECT ON  [dbo].[brvCMAC] TO [public]
GRANT INSERT ON  [dbo].[brvCMAC] TO [public]
GRANT DELETE ON  [dbo].[brvCMAC] TO [public]
GRANT UPDATE ON  [dbo].[brvCMAC] TO [public]
GO
