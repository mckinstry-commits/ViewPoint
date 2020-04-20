SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************
     * Created By: Darin H 06/18/2002
     * Modified By:
     *
     **********************************/
    
    
    CREATE    View  [dbo].[brvPMSLCOACOSubCoSort] as
    -- Drop View brvPMSLCOACOSubCoSort
    Select Distinct b.PMCo,b.Project,b.SLCo,b.SL,b.SLItem,b.SubCO,b.ACO,b.ACOItem,b.PhaseGroup,b.Phase,VendorGroup = Null, Vendor = Null,Units = Null,UM = Null,UnitCost=Null,DetailAmount = 0,PrevAmount = b.Amount,OrigCost = 0,LT ='Previous'
    From PMSL b
    Inner Join PMSL c on b.PMCo = c.PMCo and b.Project = c.Project and 
    b.SLCo = c.SLCo and b.SLItem = b.SLItem and 
    b.SubCO < c.SubCO and b.ACO < c.ACO
    Where b.ACO <> Null and b.SL <> Null and b.SubCO <> Null
    
    Union
    
    Select a.PMCo,a.Project,a.SLCo,a.SL,a.SLItem,a.SubCO,a.ACO,a.ACOItem,a.PhaseGroup,a.Phase,a.VendorGroup,a.Vendor,a.Units,a.UM,a.UnitCost,a.Amount,0,b.OrigCost,LT = 'Detail'
    From PMSL a 
    Inner join SLIT b on a.SLCo = b.SLCo and a.SL = b.SL
    Where a.ACO <> Null and a.SL <> Null and a.SubCO <> Null

GO
GRANT SELECT ON  [dbo].[brvPMSLCOACOSubCoSort] TO [public]
GRANT INSERT ON  [dbo].[brvPMSLCOACOSubCoSort] TO [public]
GRANT DELETE ON  [dbo].[brvPMSLCOACOSubCoSort] TO [public]
GRANT UPDATE ON  [dbo].[brvPMSLCOACOSubCoSort] TO [public]
GRANT SELECT ON  [dbo].[brvPMSLCOACOSubCoSort] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvPMSLCOACOSubCoSort] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvPMSLCOACOSubCoSort] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvPMSLCOACOSubCoSort] TO [Viewpoint]
GO
